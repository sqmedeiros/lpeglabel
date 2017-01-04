local m = require'lpeglabel'

function matchPrint(p, s)
	local r, lab, sfail = p:match(s)
	print("r: ", r, "lab: ", lab, "sfail: ", sfail)
end

local p = m.P"a"^0 * m.P"b" + m.P"c"
matchPrint(p, "abc")  --> r: 	3	lab: 	nil	sfail: 	nil
matchPrint(p, "c")    --> r: 	2	lab: 	nil	sfail: 	nil
matchPrint(p, "aac")  --> r: 	nil	lab: 	0	sfail: 	c
matchPrint(p, "xxc")  --> r: 	nil	lab: 	0	sfail: 	xxc


