local m = require'lpeglabel'

local errUndef = 0
local errId = 1
local errComma = 2

local terror = {
	[errUndef] = "Error",
	[errId] = "Error: expecting an identifier",
	[errComma] = "Error: expecting ','",
}

local g = m.P{
  "S",
  S = m.V"Id" * m.V"List",
  List = -m.P(1) + ("," + m.T(errComma)) * m.V"Id" * m.V"List",
  Id = m.R'az'^1 + m.T(errId),
}

function mymatch (g, s)
	local r, e, sfail = g:match(s)
	if not r then
		return r, terror[e] .. " before '" .. sfail .. "'"
	end
	return r
end
	
print(mymatch(g, "a,b"))
print(mymatch(g, "a b"))
print(mymatch(g, ", b"))


