local lpeg = require"lpeglabel"

local R, S, P, V = lpeg.R, lpeg.S, lpeg.P, lpeg.V
local C, Cc, Ct, Cmt = lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.Cmt
local T, Lc = lpeg.T, lpeg.Lc

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

-- The `labelIndex` function gives us the index of a label in the
-- `labels` table, which serves as the integer representation of the label.
-- We need this because LPegLabel requires us to use integers for the labels.
local function labelIndex(labname)
  for i, elem in ipairs(labels) do
    if elem[1] == labname then
      return i
    end
  end
  error("could not find label: " .. labname)
end

-- The `errors` table will hold the list of errors recorded during parsing
local errors = {}

-- The `expect` function takes a pattern and a label and returns a pattern
-- that throws the specified label if the original pattern fails to match.
-- Before throwing the label, it records the label to be thrown along with
-- the position of the failure (index in input string) into the `errors` table.
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
local g = P {
  "Exp",
  Exp = Ct(V"Term" * (C(op) * V"OpRecov")^0) / compute;
  -- `OpRecov` handles missing terms/operands by returning a dummy (zero).
  OpRecov = Lc(V"Operand", Cc(0), labelIndex("ExpTerm"));
  Operand = expect(V"Term", "ExpTerm");
  Term = num + V"Group";
  -- `Group` handles missing closing parenthesis by simply ignoring it.
  -- Like all the others, the error is still recorded of course.
  Group = "(" * V"InnerExp" * Lc(expect(")", "MisClose"), P"", labelIndex("MisClose"));
  -- `InnerExp` handles missing expressions by skipping to the next closing
  -- parenthesis. A dummy (zero) is returned in place of the expression.
  InnerExp = Lc(expect(V"Exp", "ExpExp"), (P(1) - ")")^0 * Cc(0), labelIndex("ExpExp"));
}

g = expect(g, "NoExp") * expect(-P(1), "Extra")

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
      local msg = labels[err[1]][2]
      table.insert(out, "syntax error: " .. msg .. " (at index " .. pos .. ")")
    end
    errors = {}
    return nil, table.concat(out, "\n")
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
