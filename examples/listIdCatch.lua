local m = require'lpeglabel'

local errUndef, errId, errComma = 0, 1, 2

local terror = {
  [errUndef] = "Error",
  [errId] = "Error: expecting an identifier",
  [errComma] = "Error: expecting ','",
}

g = m.P{
  "S",
	S = m.Lc(m.Lc(m.V"Id" * m.V"List", m.V"ErrId", errId),
           m.V"ErrComma", errComma),
	List = -m.P(1)  +  m.V"Comma" * m.V"Id" * m.V"List",
	Id = m.R'az'^1  +  m.T(errId),
	Comma = ","  +  m.T(errComma),
	ErrId = m.Cc(errId) / terror,
	ErrComma = m.Cc(errComma) / terror
}

print(g:match("a,b"))
print(g:match("a b"))
print(g:match(",b"))

