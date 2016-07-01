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

local g = re.compile[[
  S      <- Id List
  List   <- !.  /  (',' /  %{errComma}) (Id / %{errId}) List
  Id     <- Sp [a-z]+
  Comma  <- Sp ','
  Sp     <- %s*
]]

function mymatch (g, s)
  local r, e, sfail = g:match(s)
  if not r then
    local line, col = re.calcline(s, #s - #sfail)
    local msg = "Error at line " .. line .. " (col " .. col .. "): "
    return r, msg .. errmsgs[e] .. " before '" .. sfail .. "'"
  end
  return r
end

print(mymatch(g, "one,two"))
print(mymatch(g, "one two"))
print(mymatch(g, "one,\n two,\nthree,"))

