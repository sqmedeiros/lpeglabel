local m = require"lpeglabelrec"
local re = require"relabelrec"

local R, S, P, V = m.R, m.S, m.P, m.V
local C, Cc, Ct, Cmt = m.C, m.Cc, m.Ct, m.Cmt
local T, Rec = m.T, m.Rec

local num = R("09")^1 / tonumber
local op = S("+-")

local labels = {}
local nlabels = 0

local function newError(lab, msg, psync, pcap)
	nlabels = nlabels + 1
	psync = psync or m.P(-1)
	pcap = pcap or m.P""
	labels[lab] = { id = nlabels, msg = msg, psync = psync, pcap = pcap }
end

newError("ExpTermFirst", "expected an expression", op + ")", m.Cc(1000)) 
newError("ExpTermOp", "expected a term after the operator", op + ")", m.Cc(1000))
newError("MisClose",  "missing a closing ')' after the expression",  m.P")")
newError("Extra", "extra characters found after the expression") 

local errors, subject

local function expect(patt, labname)
  local i = labels[labname].id
  return patt + T(i)
end

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
	Exp = Ct(V"OperandFirst" * (C(op) * V"Operand")^0) / compute,
	OperandFirst = expect(V"Term", "ExpTermFirst"),
	Operand = expect(V"Term", "ExpTermOp"),
	Term = num + V"Group",
	Group = "(" * V"Exp" * expect(")", "MisClose"),
}

function recorderror(pos, lab)
	local line, col = re.calcline(subject, pos)
	table.insert(errors, { line = line, col = col, msg = labels[lab].msg })
end

function record (labname)
	return (m.Cp() * m.Cc(labname)) / recorderror
end

function sync (p)
	return (-p * m.P(1))^0
end

function defaultValue (p)
	return p or m.Cc(1000) 
end

local recg2 = g
for k, v in pairs(labels) do
	recg2 = Rec(recg2, record(k) * sync(v.psync) * v.pcap, v.id)
end

local recg = P {
	"S",
	S = Rec(V"A", V"ErrExpTermFirst", labels["ExpTermFirst"].id), -- default value is 0
	A = Rec(V"Sg", V"ErrExpTermOp", labels["ExpTermOp"].id),
	Sg = Rec(g, V"ErrMisClose", labels["MisClose"].id),
	ErrExpTermFirst = record("ExpTermFirst") * sync(op + ")") * defaultValue(),
	ErrExpTermOp = record("ExpTermOp") * sync(op + ")") * defaultValue(),
	ErrMisClose = record("MisClose") * sync(P")") * defaultValue(m.P""),
}
 
                
local function eval(input)
	errors = {}
	subject = input
  local result, label, suffix = recg2:match(input)
  if #errors > 0 then
    local out = {}
    for i, err in ipairs(errors) do
      local pos = err.col
      local msg = err.msg
      table.insert(out, "syntax error: " .. msg .. " (at index " .. pos .. ")")
    end
    print(table.concat(out, "\n"))
  end
	return result	
end

print(eval "90-70*5")
--> 20

print(eval "2+")
--> 2 + 0

print(eval "-2")
--> 0 - 2 

print(eval "1+3+-9")
--> 1 + 3 + [0] - 9

print(eval "1+()3+")
--> 1 + ([0]) [+] 3 + [0]

print(eval "8-(2+)-5")
--> 8 - (2 + [0]) - 5 

print(eval "()")

print(eval "")

print(eval "1+()+")

print(eval "1+(")

print(eval "3)")

