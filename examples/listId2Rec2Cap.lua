local m = require'lpeglabelrec'
local re = require'relabelrec'

local terror = {}

local function newError(s)
  table.insert(terror, s)
  return #terror
end

local errUndef = newError("undefined")
local errId = newError("expecting an identifier")
local errComma = newError("expecting ','")

local id = m.R'az'^1

local g = m.P{
  "S",
  S = m.V"Id" * m.V"List",
  List = -m.P(1) + m.V"Comma" * m.V"Id" * m.V"List",
  Id = m.V"Sp" * m.C(id) + m.T(errId),
  Comma = m.V"Sp" * "," + m.T(errComma),
  Sp = m.S" \n\t"^0,
}

local subject, errors

function recorderror(pos, lab)
	local line, col = re.calcline(subject, pos)
	table.insert(errors, { line = line, col = col, msg = terror[lab] })
end

function record (lab)
	return (m.Cp() * m.Cc(lab)) / recorderror
end

function sync (p)
	return (-p * m.P(1))^0
end

function defaultValue ()
	return m.Cc"NONE" 
end

local grec = m.P{
  "S",
  S = m.Rec(m.Rec(g, m.V"ErrComma", errComma), m.V"ErrId", errId),
  ErrComma = record(errComma) * sync(-m.P(1) + id),
	ErrId = record(errId) * sync(-m.P(1) + ",") * defaultValue() 
}


function mymatch (g, s)
	errors = {}
	subject = s	
	io.write("Input: ", s, "\n")
	local r = { g:match(s) }
	io.write("Captures (separated by ';'): ")
	for k, v in pairs(r) do
		io.write(v .. "; ")
	end
	io.write("\nSyntactic errors found: " .. #errors)
	if #errors > 0 then
		io.write("\n")
		local out = {}
    for i, err in ipairs(errors) do
    	local msg = "Error at line " .. err.line .. " (col " .. err.col .. "): " .. err.msg
      table.insert(out,  msg)
    end
    io.write(table.concat(out, "\n"))
  end
	print("\n")
	return r
end
  
mymatch(grec, "one,two")
mymatch(grec, "one two three")
mymatch(grec, "1,\n two, \n3,")
mymatch(grec, "one\n two123, \nthree,")
