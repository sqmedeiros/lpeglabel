local m = require'lpeglabel'

local terror = {}

local function newError(s)
	table.insert(terror, s)
	return #terror
end

local errUndef = newError("undefined")
local errId = newError("expecting an identifier")
local errComma = newError("expecting ','")

local function calcline (s, i)
  if i == 1 then return 1, 1 end
  local rest, line = s:sub(1,i):gsub("[^\n]*\n", "")
  local col = #rest
  return 1 + line, col ~= 0 and col or 1
end

local g = m.P{
  "S",
  S = m.Lc(m.Lc(m.V"Id" * m.V"List", m.V"ErrId", errId),
           m.V"ErrComma", errComma),
  List = -m.P(1) + (m.V"Comma" + m.T(errComma)) * (m.V"Id" + m.T(errId)) * m.V"List",
  Id = m.V"Sp" * m.R'az'^1,
	Comma = m.V"Sp" * ",",
	Sp = m.S" \n\t"^0,
	ErrId = m.Cc(errId) / terror,
	ErrComma = m.Cc(errComma) / terror
}

function mymatch (g, s)
	local r, e, sfail = g:match(s)
	if not r then
		local line, col = calcline(s, #s - #sfail)
		local msg = "Error at line " .. line .. " (col " .. col .. "): "
		return r, msg .. terror[e] .. " before '" .. sfail .. "'"
	end
	return r
end

print(mymatch(g, "one,two"))
print(mymatch(g, "one two"))
print(mymatch(g, "one,\n two,\nthree,"))
