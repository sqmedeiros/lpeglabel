local m = require 'lpeglabel'

function matchPrint(p, s)
	local r, l, sfail = p:match(s)
	print("Input:", s)
	print("Result:", r, l, sfail)
end

local p = m.P"a"^0 * m.P"b" + m.P"c"

p:pcode()

matchPrint(p, "aab")
matchPrint(p, "ck")
matchPrint(p, "dk")
matchPrint(p, "aak")

local p = m.P"a"^0 * m.P(1) * m.P(1) + m.P"a"^0 * m.P"c"

p:pcode()

matchPrint(p, "aabc")
matchPrint(p, "aac")
matchPrint(p, "aak")
matchPrint(p, "x")
