Here's an example of an LPegLabel grammar that make its own function called
'expect', which takes a pattern and a label as parameters and throws the label
if the pattern fails to be matched. This function can be extended later on to
record all errors encountered once error recovery is implemented.

```lua
local lpeg = require"lpeglabel"

local R, S, P, V, T = lpeg.R, lpeg.S, lpeg.P, lpeg.V, lpeg.T

local labels = {
  {"NoExp",     "no expression found"},
  {"Extra",     "extra chracters found after the expression"},
  {"ExpTerm",   "expected a term after the operator"},
  {"ExpExp",    "expected an expression after the parenthesis"},
  {"MisClose",  "missing a closing ')' after the expression"},
}

local function expect(patt, labname)
  for i, elem in ipairs(labels) do
    if elem[1] == labname then
      return patt + T(i)
    end
  end

  error("could not find label: " .. labname)
end

local num = R("09")^1
local op = S("+-*/")

local g = P {
  "Exp",
  Exp = V"Term" * (op * expect(V"Term", "ExpTerm"))^0;
  Term = num + V"Group";
  Group = "(" * expect(V"Exp", "ExpExp") * expect(")", "MisClose");
}

g = expect(g, "NoExp") * expect(-P(1), "Extra")

local function check(input)
  result, label, suffix = g:match(input)
  if result ~= nil then
    return "ok"
  else
    local pos = input:len() - suffix:len() + 1
    local msg = labels[label][2]
    return "syntax error: " .. msg .. " (at index " .. pos .. ")"
  end
end

print(check "(1+1-1*2/2")
--> syntax error: missing a closing ')' after the expression (at index 11)

print(check "(1+)-1*(2/2)")
--> syntax error: expected a term after the operator (at index 4)

print(check "(1+1)-1*(/2)")
--> syntax error: expected an expression after the parenthesis (at index 10)

print(check "1+(1-(1*2))/2x")
--> syntax error: extra chracters found after the expression (at index 14)

print(check "-1+(1-(1*2))/2")
--> syntax error: no expression found (at index 1)
```
