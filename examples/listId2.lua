local m = require'lpeglabel'
local re = require'relabel'

local terror = {}

local function newError(s)
  table.insert(terror, s)
  return #terror
end

local errUndef = newError("undefined")
local errId = newError("expecting an identifier")
local errComma = newError("expecting ','")

local g = m.P{
  "S",
  S = m.V"Id" * m.V"List",
  List = -m.P(1) + (m.V"Comma" + m.T(errComma)) * (m.V"Id" + m.T(errId)) * m.V"List",
  Id = m.V"Sp" * m.R'az'^1,
  Comma = m.V"Sp" * ",",
  Sp = m.S" \n\t"^0,
}

function mymatch (g, s)
  local r, e, sfail = g:match(s)
  if not r then
    local line, col = re.calcline(s, #s - #sfail)
    local msg = "Error at line " .. line .. " (col " .. col .. "): "
    return r, msg .. terror[e] .. " before '" .. sfail .. "'"
  end
  return r
end
  
print(mymatch(g, "one,two"))
print(mymatch(g, "one two"))
print(mymatch(g, "one,\n two,\nthree,"))
