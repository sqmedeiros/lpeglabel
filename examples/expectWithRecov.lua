local lpeg = require"lpeglabel"

local R, S, P, V = lpeg.R, lpeg.S, lpeg.P, lpeg.V
local C, Cc, Ct, Cmt = lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.Cmt
local T, Lc = lpeg.T, lpeg.Lc

local labels = {
  {"NoExp",     "no expression found"},
  {"Extra",     "extra characters found after the expression"},
  {"ExpTerm",   "expected a term after the operator"},
  {"ExpExp",    "expected an expression after the parenthesis"},
  {"MisClose",  "missing a closing ')' after the expression"},
}

local function labelIndex(labname)
  for i, elem in ipairs(labels) do
    if elem[1] == labname then
      return i
    end
  end
  error("could not find label: " .. labname)
end

local errors = {}

local function expect(patt, labname)
  local i = labelIndex(labname)
  function recordError(input, pos)
    table.insert(errors, {i, pos})
    return true
  end
  return patt + Cmt("", recordError) * T(i)
end

local num = R("09")^1 / tonumber
local op = S("+-*/")

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

local g = P {
  "Exp",
  Exp = Ct(V"Term" * (C(op) * V"OpRecov")^0) / compute;
  OpRecov = Lc(V"Operand", Cc(0), labelIndex("ExpTerm"));
  Operand = expect(V"Term", "ExpTerm");
  Term = num + V"Group";
  Group = "(" * V"InnerExp" * Lc(expect(")", "MisClose"), P"", labelIndex("MisClose"));
  InnerExp = Lc(expect(V"Exp", "ExpExp"), (P(1) - ")")^0 * Cc(0), labelIndex("ExpExp"));
}

g = expect(g, "NoExp") * expect(-P(1), "Extra")

local function eval(input)
  local result, label, suffix = g:match(input)
  if #errors == 0 then
    return result
  else
    local out = ""
    for i, err in ipairs(errors) do
      local pos = err[2]
      local msg = labels[err[1]][2]
      out = out .. "syntax error: " .. msg .. " (at index " .. pos .. ")\n"
    end
    errors = {}
    return nil, out
  end
end

print(eval "98-76*(54/32)")
--> 37.125

print(eval "(1+1-1*2/2")
--> syntax error: missing a closing ')' after the expression (at index 11)

print(eval "(1+)-1*(2/2)")
--> syntax error: expected a term after the operator (at index 4)

print(eval "(1+1)-1*(/2)")
--> syntax error: expected an expression after the parenthesis (at index 10)

print(eval "1+(1-(1*2))/2x")
--> syntax error: extra chracters found after the expression (at index 14)

print(eval "-1+(1-(1*2))/2")
--> syntax error: no expression found (at index 1)

print(eval "(1+1-1*(2/2+)-():")
--> syntax error: expected a term after the operator (at index 13)
--> syntax error: expected an expression after the parenthesis (at index 16)
--> syntax error: missing a closing ')' after the expression (at index 17)
--> syntax error: extra characters found after the expression (at index 17)
