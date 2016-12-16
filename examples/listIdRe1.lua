local re = require 'relabel' 

local g = re.compile[[
  S      <- Id List
  List   <- !.  /  Comma Id List
  Id     <- Sp [a-z]+ / %{2}
  Comma  <- Sp ',' / %{3}
  Sp     <- %s*
]]

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

