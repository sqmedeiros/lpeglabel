local lpeg = require"lpeglabelrec"

local R, S, P, V = lpeg.R, lpeg.S, lpeg.P, lpeg.V
local C, Cc, Ct, Cmt = lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.Cmt
local T, Rec = lpeg.T, lpeg.Rec

local labels = {
  {"NoExp",     "no expression found"},
  {"Extra",     "extra characters found after the expression"},
  {"ExpTerm",   "expected a term after the operator"},
  {"ExpExp",    "expected an expression after the parenthesis"},
  {"MisClose",  "missing a closing ')' after the expression"},
}

local function labelindex(labname)
  for i, elem in ipairs(labels) do
    if elem[1] == labname then
      return i
    end
  end
  error("could not find label: " .. labname)
end

local errors = {}

local function expect(patt, labname, recpatt)
  local i = labelindex(labname)
  function recorderror(input, pos)
    table.insert(errors, {i, pos})
    return true
  end
  return patt + T(i)
end

local num = R("09")^1 / tonumber
local op = S("+-")

local function compute(tokens)
  local result = tokens[1]
  for i = 2, #tokens, 2 do
    if tokens[i] == '+' then
      result = result + tokens[i+1]
    elseif tokens[i] == '-' then
      result = result - tokens[i+1]
    else
      error('unknown operation: ' .. tokens[i])
    end
  end
  return result
end

local g = P {
	"Exp",
	Exp = Ct(V"Operand" * (C(op) * V"Operand")^0) / compute,
	Operand = expect(V"Term", "ExpTerm"),
	Term = num + V"Group",
	Group = "(" *  V"InnerExp" * expect(")", "MisClose", "");
  InnerExp = expect(V"Exp", "ExpExp", (P(1) - ")")^0 * Cc(0));

}

local subject, errors

function recorderror(pos, lab)
	local line, col = re.calcline(subject, pos)
	table.insert(errors, { line = line, col = col, msg = terror[lab] })
end

function record (labname)
	return (m.Cp() * m.Cc(labelindex(labname))) / recorderror
end

function sync (p)
	return (-p * m.P(1))^0
end

function defaultValue ()
	return m.Cc"NONE" 
end

local recg = P {
	"S",
	S = Rec(m.V"A", Cc(0), labelindex("ExpTerm")), -- default value is 0
	A = Rec(m.V"B", Cc(0), labelindex("ExpExp")),
	B = Rec(m.V"Sg", Cc(0), labelindex("InnerExp")),
	Sg = Rec(g, Cc(0), labelindex("MisClose")),
	ErrExpTerm = record(labelindex("ExpTerm")) * sync() * defaultValue()
}
 
                
local function eval(input)
  local result, label, suffix = recg:match(input)
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

print(eval "90-70*5")
--> 20

print(eval "2+")
--> 2 + 0

print(eval "-2")
--> 0 - 2 


print(eval "1+3+-9")
--> 1 + 3 + 0 - 9

