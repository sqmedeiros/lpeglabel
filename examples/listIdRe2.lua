local re = require 'relabel' 

local errinfo = {
	{"errUndef",  "undefined"},
	{"errId",     "expecting an identifier"},
	{"errComma",  "expecting ','"},
}

local errmsgs = {}
local labels = {}

for i, err in ipairs(errinfo) do
  errmsgs[i] = err[2]
  labels[err[1]] = i
end

re.setlabels(labels)

local function calcline (s, i)
  if i == 1 then return 1, 1 end
  local rest, line = s:sub(1,i):gsub("[^\n]*\n", "")
  local col = #rest
  return 1 + line, col ~= 0 and col or 1
end


local g = re.compile[[
  S      <- Id List
  List   <- !.  /  (',' /	%{errComma}) (Id / %{errId}) List
  Id     <- Sp [a-z]+
  Comma  <- Sp ','
  Sp     <- %s*
]]

function mymatch (g, s)
	local r, e, sfail = g:match(s)
	if not r then
		local line, col = calcline(s, #s - #sfail)
		local msg = "Error at line " .. line .. " (col " .. col .. "): "
		return r, msg .. errmsgs[e] .. " before '" .. sfail .. "'"
	end
	return r
end

print(mymatch(g, "one,two"))
print(mymatch(g, "one two"))
print(mymatch(g, "one,\n two,\nthree,"))

