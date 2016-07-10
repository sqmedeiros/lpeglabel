local lpeg = require"lpeglabel"
local re = require"relabel"

local R, S, P, V = lpeg.R, lpeg.S, lpeg.P, lpeg.V
local C, Cc, Ct, Cmt = lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.Cmt
local T, Lc = lpeg.T, lpeg.Lc

local errinfo = {
  {"NoExp",     "no expression found"},
  {"Extra",     "extra characters found after the expression"},
  {"ExpTerm",   "expected a term after the operator"},
  {"ExpExp",    "expected an expression after the parenthesis"},
  {"MisClose",  "missing a closing ')' after the expression"},
}

local labels = {}
local errmsgs = {}

for i, err in ipairs(errinfo) do
  labels[err[1]] = i
  errmsgs[err[1]] = err[2]
end

re.setlabels(labels)

local errors = {}

function recordError(input, pos, label)
  table.insert(errors, {label, pos})
  return true
end

local function compute(tokens)
  local result = tokens[1]
  for i = 2, #tokens, 2 do
    if tokens[i] == '+' then
      result = result + tokens[i+1]
    elseif tokens[i] == '-' then
      result = result - tokens[i+1]
    elseif tokens[i] == '*' then
      result = result * tokens[i+1]
    elseif tokens[i] == '/' then
      result = result / tokens[i+1]
    else
      error('unknown operation: ' .. tokens[i])
    end
  end
  return result
end

local g = re.compile([[
  S         <- (Exp / ErrNoExp) (!. / ErrExtra)
  Exp       <- {| Term (op Operand)* |} -> compute
  Operand   <- Term / ErrExpTerm /{ExpTerm} dummy
  Term      <- num / Group
  Group     <- "(" InnerExp (")" / ErrMisClose /{MisClose} "")
  InnerExp  <- Exp / ErrExpExp /{ExpExp} [^)]* dummy

  op   <- {[-+*/]} 
  num  <- [0-9]+ -> tonumber

  ErrNoExp     <- ("" -> "NoExp"     => recordError) %{NoExp}
  ErrExtra     <- ("" -> "Extra"     => recordError) %{Extra}
  ErrExpTerm   <- ("" -> "ExpTerm"   => recordError) %{ExpTerm}
  ErrExpExp    <- ("" -> "ExpExp"    => recordError) %{ExpExp}
  ErrMisClose  <- ("" -> "MisClose"  => recordError) %{MisClose}

  dummy <- "" -> "0" -> tonumber
]], {
  compute = compute;
  recordError = recordError;
  tonumber = tonumber;
})

local function eval(input)
  local result, label, suffix = g:match(input)
  if #errors == 0 then
    return result
  else
    local out = {}
    for i, err in ipairs(errors) do
      local pos = err[2]
      local msg = errmsgs[err[1]]
      local line, col = re.calcline(input, pos)
      table.insert(out, "syntax error: " .. msg .. " (line " .. line .. ", col " .. col .. ")")
    end
    errors = {}
    return nil, table.concat(out, "\n")
  end
end

print(eval "98-76*(54/32)")
--> 37.125

print(eval "(1+1-1*2/2")
--> syntax error: missing a closing ')' after the expression (line 1, col 10)

print(eval "(1+)-1*(2/2)")
--> syntax error: expected a term after the operator (line 1, col 4)

print(eval "(1+1)-1*(/2)")
--> syntax error: expected an expression after the parenthesis (line 1, col 10)

print(eval "1+(1-(1*2))/2x")
--> syntax error: extra characters found after the expression (line 1, col 14)

print(eval "-1+(1-(1*2))/2")
--> syntax error: no expression found (line 1, col 1)

print(eval "(1+1-1*(2/2+)-():")
--> syntax error: expected a term after the operator (line 1, col 13)
--> syntax error: expected an expression after the parenthesis (line 1, col 16)
--> syntax error: missing a closing ')' after the expression (line 1, col 17)
--> syntax error: extra characters found after the expression (line 1, col 17)
