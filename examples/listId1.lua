local m = require'lpeglabel'

local function calcline (s, i)
  if i == 1 then return 1, 1 end
  local rest, line = s:sub(1,i):gsub("[^\n]*\n", "")
  local col = #rest
  return 1 + line, col ~= 0 and col or 1
end

local g = m.P{
  "S",
  S = m.V"Id" * m.V"List",
  List = -m.P(1) + (m.V"Comma" + m.T(2)) * (m.V"Id" + m.T(1)) * m.V"List",
  Id = m.V"Sp" * m.R'az'^1,
  Comma = m.V"Sp" * ",",
  Sp = m.S" \n\t"^0,
}

function mymatch (g, s)
  local r, e, sfail = g:match(s)
  if not r then
    local line, col = calcline(s, #s - #sfail)
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

