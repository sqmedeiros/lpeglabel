local lpeg = require"lpeglabel"

local R, S, P, V, C, Ct, T = lpeg.R, lpeg.S, lpeg.P, lpeg.V, lpeg.C, lpeg.Ct, lpeg.T

-- The `labels` table contains the list of labels that we will be using
-- as well as the corresponding error message for each label, which will
-- be used in our error reporting later on.
local labels = {
  {"NoExp",     "no expression found"},
  {"Extra",     "extra characters found after the expression"},
  {"ExpTerm",   "expected a term after the operator"},
  {"ExpExp",    "expected an expression after the parenthesis"},
  {"MisClose",  "missing a closing ')' after the expression"},
}

-- The `expect` function takes a pattern and a label defined in
-- the `labels` table and returns a pattern that throws the specified
-- label if the original pattern fails to match.
-- Note: LPegLabel requires us to use integers for the labels, so we
-- use the index of the label in the `labels` table to represent it.
local function expect(patt, labname)
  for i, elem in ipairs(labels) do
    if elem[1] == labname then
      return patt + T(i)
    end
  end

  error("could not find label: " .. labname)
end

local num = R("09")^1 / tonumber
local op = S("+-*/")

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
-- via parenthesis.
local g = P {
  "Exp",
  Exp = Ct(V"Term" * (C(op) * expect(V"Term", "ExpTerm"))^0) / compute;
  Term = num + V"Group";
  Group = "(" * expect(V"Exp", "ExpExp") * expect(")", "MisClose");
}

g = expect(g, "NoExp") * expect(-P(1), "Extra")

-- The `eval` function takes an input string to match against the grammar
-- we've just defined. If the input string matches, then the result of the
-- computation is returned, otherwise we return the error message and
-- position of the first failure encountered.
local function eval(input)
  local result, label, suffix = g:match(input)
  if result ~= nil then
    return result
  else
    local pos = input:len() - suffix:len() + 1
    local msg = labels[label][2]
    return nil, "syntax error: " .. msg .. " (at index " .. pos .. ")"
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
