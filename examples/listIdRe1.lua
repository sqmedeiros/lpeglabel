local re = require 're' 

local g = re.compile[[
  S    <- Id List
  List <- !.  /  (',' / 	%{2}) Id List
  Id   <- [a-z]  /  %{1}	
]]

function mymatch (g, s)
	local r, e = g:match(s)
	if not r then
		if e == 1 then
    	return r, "Error: expecting an identifier"
  	elseif e == 2 then
    	return r, "Error: expecting ','"
  	else
    	return r, "Error"
  	end
	end
	return r
end
	
print(mymatch(g, "a,b"))
print(mymatch(g, "a b"))
print(mymatch(g, ", b"))


