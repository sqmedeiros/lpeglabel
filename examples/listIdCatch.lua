local m = require'lpeglabel'

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
  S = m.Lc(m.Lc(m.V"Id" * m.V"List", m.V"ErrId", errId),
           m.V"ErrComma", errComma),
  List = -m.P(1) + (m.V"Comma" + m.T(errComma)) * (m.V"Id" + m.T(errId)) * m.V"List",
  Id = m.V"Sp" * m.R'az'^1,
  Comma = m.V"Sp" * ",",
  Sp = m.S" \n\t"^0,
  ErrId = m.Cc(errId) / terror,
  ErrComma = m.Cc(errComma) / terror
}

print(m.match(g, "one,two"))
print(m.match(g, "one two"))
print(m.match(g, "one,\n two,\nthree,"))
