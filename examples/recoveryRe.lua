local re = require"relabel"

-- The `errinfo` table contains the list of labels that we will be using
-- as well as the corresponding error message for each label, which will
-- be used in our error reporting later on.
local errinfo = {
  {"NoExp",     "no expression found"},
  {"Extra",     "extra characters found after the expression"},
  {"ExpTerm",   "expected a term after the operator"},
  {"ExpExp",    "expected an expression after the parenthesis"},
  {"MisClose",  "missing a closing ')' after the expression"},
}

-- We split the errinfo table into two tables: `labels` which is a
-- mapping from the label names to its integer representation, and
-- `errmsgs` which is a mapping from the label names to its
-- corresponding error message.
local labels = {}
local errmsgs = {}

for i, err in ipairs(errinfo) do
  labels[err[1]] = i
  errmsgs[err[1]] = err[2]
end

-- The `labels` table is especially useful for making our re grammar more
-- readable through the use of the `setlabels` function which allows us
-- to use the label names directly in the re grammar instead of the integers.
re.setlabels(labels)

-- The `errors` table will hold the list of errors recorded during parsing
local errors = {}

-- The `recorderror` function simply records the label and position of
-- the failure (index in input string) into the `errors` table.
-- Note: The unused `input` parameter is necessary, as this will be called
-- by LPeg's match-time capture.
local function recorderror(input, pos, label)
  table.insert(errors, {label, pos})
  return true
end

-- The `compute` function takes an alternating list of numbers and
-- operators and computes the result of applying the operations
-- to the numbers in a left to right order (no operator precedence).
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

-- Our grammar is a simple arithmetic expression of integers that
-- does not take operator precedence into account but allows grouping
-- via parenthesis. We have incorporated some error recovery startegies
-- to our grammar so that it may resume parsing even after encountering
-- an error, which allows us to report more errors.
local g = re.compile([[
  S         <- (Exp / ErrNoExp) (!. / ErrExtra)
  Exp       <- {| Term (op Operand)* |} -> compute
  --  If we encounter a missing term/operand, we return a dummy instead.
  Operand   <- Term / ErrExpTerm /{ExpTerm} dummy
  Term      <- num / Group
  -- If we encounter a missing closing parenthesis, we ignore it.
  Group     <- "(" InnerExp (")" / ErrMisClose /{MisClose} "")
  -- If we encounter a missing inner expression, we skip to the next
  -- closing parenthesis, and return a dummy in its place.
  InnerExp  <- Exp / ErrExpExp /{ExpExp} [^)]* dummy

  op   <- {[-+*/]}
  num  <- [0-9]+ -> tonumber

  -- Before throwing an error, we make sure to record it first.
  ErrNoExp     <- ("" -> "NoExp"     => recorderror) %{NoExp}
  ErrExtra     <- ("" -> "Extra"     => recorderror) %{Extra}
  ErrExpTerm   <- ("" -> "ExpTerm"   => recorderror) %{ExpTerm}
  ErrExpExp    <- ("" -> "ExpExp"    => recorderror) %{ExpExp}
  ErrMisClose  <- ("" -> "MisClose"  => recorderror) %{MisClose}

  dummy <- "" -> "0" -> tonumber
]], {
  compute = compute;
  recorderror = recorderror;
  tonumber = tonumber;
})

-- The `eval` function takes an input string to match against the grammar
-- we've just defined. If the input string matches, then the result of the
-- computation is returned, otherwise we return the error messages and
-- positions of all the failures encountered.
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
