local m = require"lpeglabel"
local re = require"relabel"

local labels = {
  {"ExpTermFirst",  "expected an expression"},
  {"ExpTermOp",   "expected a term after the operator"},
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

local errors, subject

local function expect(patt, labname)
  local i = labelindex(labname)
  return patt + m.T(i)
end


local num = m.R("09")^1 / tonumber
local op = m.S("+-")

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

local g = m.P {
	"Exp",
	Exp = m.Ct(m.V"OperandFirst" * (m.C(op) * m.V"Operand")^0) / compute,
	OperandFirst = expect(m.V"Term", "ExpTermFirst"),
	Operand = expect(m.V"Term", "ExpTermOp"),
	Term = num + m.V"Group",
	Group = "(" * m.V"Exp" * expect(")", "MisClose"),
}

function recorderror(pos, lab)
	local line, col = re.calcline(subject, pos)
	table.insert(errors, { line = line, col = col, msg = labels[lab][2] })
end

function record (labname)
	return (m.Cp() * m.Cc(labelindex(labname))) / recorderror
end

function sync (p)
	return (-p * m.P(1))^0
end

function defaultValue (p)
	return p or m.Cc(1000) 
end

local grec = m.P {
	"S",
	S = m.Rec(m.V"A", m.V"ErrExpTermFirst", labelindex("ExpTermFirst")), -- default value is 0
	A = m.Rec(m.V"Sg", m.V"ErrExpTermOp", labelindex("ExpTermOp")),
	Sg = m.Rec(g, m.V"ErrMisClose", labelindex("MisClose")),
	ErrExpTermFirst = record("ExpTermFirst") * sync(op + ")") * defaultValue(),
	ErrExpTermOp = record("ExpTermOp") * sync(op + ")") * defaultValue(),
	ErrMisClose = record("MisClose") * sync(m.P")") * defaultValue(m.P""),
}
               
local function eval(input)
	errors = {}
	io.write("Input: ", input, "\n")
	subject = input
  local result, label, suffix = grec:match(input)
  io.write("Syntactic errors found: " .. #errors, "\n")
	if #errors > 0 then
    local out = {}
    for i, err in ipairs(errors) do
      local pos = err.col
      local msg = err.msg
      table.insert(out, "syntax error: " .. msg .. " (at index " .. pos .. ")")
    end
    print(table.concat(out, "\n"))
  end
	io.write("Result = ")
	return result	
end

print(eval "90-70-(5)+3")
--> 20

print(eval "15+")
--> 2 + 0

print(eval "-2")
--> 0 - 2 

print(eval "1+3+-9")
--> 1 + 3 + [0] - 9

print(eval "1+()3+")
--> 1 + ([0]) [3 +] [0]

print(eval "8-(2+)-5")
--> 8 - (2 + [0]) - 5 

print(eval "()")

print(eval "")

print(eval "1+()+")

print(eval "1+(")

print(eval "3)")

print(eval "11+())3")

