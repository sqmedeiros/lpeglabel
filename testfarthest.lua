local m = require 'lpeglabel'

function matchPrint(p, s)
	local r, l, sfail = p:match(s)
	print("Input:", s)
	print("Result:", r, l, sfail)
end


local p = (m.P"c" + m.P"a") * m.P("b" + m.P"d") + m.P"xxx"
p:pcode()
matchPrint(p, "ba")

