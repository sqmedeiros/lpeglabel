local m = require'lpeglabel'

local g = m.P{
  "S",
  S = m.V"Id" * m.V"List",
  List = -m.P(1) + ("," + m.T(2)) * m.V"Id" * m.V"List",
  Id = m.R'az'^1 + m.T(1),
}

function mymatch (g, s)
	local r, e, sfail = g:match(s)
	if not r then
		if e == 1 then
    	return r, "Error: expecting an identifier before '" .. sfail .. "'"
  	elseif e == 2 then
    	return r, "Error: expecting ',' before '" .. sfail .. "'"
  	else
    	return r, "Error"
  	end
	end
	return r
end
	
print(mymatch(g, "a,b"))
print(mymatch(g, "a b"))
print(mymatch(g, ", b"))

