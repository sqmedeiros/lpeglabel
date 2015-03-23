local re = require 're' 

local errUndef, errId, errComma = 0, 1, 2

local terror = {
	[errUndef] = "Error",
	[errId] = "Error: expecting an identifier",
	[errComma] = "Error: expecting ','",
}

local tlabels = { ["errUndef"] = errUndef,
                  ["errId"]    = errId, 
                  ["errComma"] = errComma }

re.setlabels(tlabels)

local g = re.compile[[
  S    <- Id List
  List <- !.  /  (',' / 	%{errComma}) Id List
  Id   <- [a-z]  /  %{errId}	
]]

function mymatch (g, s)
	local r, e = g:match(s)
	if not r then
		return r, terror[e]
	end
	return r
end
	
print(mymatch(g, "a,b"))
print(mymatch(g, "a b"))
print(mymatch(g, ", b"))


