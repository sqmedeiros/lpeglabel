local m = require'lpeglabelrec'
local re = require'relabelrec'

local id = m.R'az'^1

local g = m.P{
  "S",
  S = m.V"Id" * m.V"List",
  List = -m.P(1) + m.V"Comma" * m.V"Id" * m.V"List",
  Id = m.V"Sp" * id + m.T(1),
  Comma = m.V"Sp" * "," + m.T(2),
  Sp = m.S" \n\t"^0,
}

function mymatch (g, s)
  local r, e, sfail = g:match(s)
  if not r then
    local line, col = re.calcline(s, #s - #sfail)
    local msg = "Error at line " .. line .. " (col " .. col .. ")"
    if e == 1 then
      return r, msg .. ": expecting an identifier before '" .. sfail .. "'"
    elseif e == 2 then
      return r, msg .. ": expecting ',' before '" .. sfail .. "'"
    else
      return r, msg
    end
  end
  return r
end
  
print(mymatch(g, "one,two"))
print(mymatch(g, "one two"))
print(mymatch(g, "one,\n two,\nthree,"))
