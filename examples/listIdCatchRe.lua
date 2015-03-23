local re = require're'

local terror = {} 

local function newError(l, msg) 
  table.insert(terror, { l = l, msg = msg } )
end

newError("errId", "Error: expecting an identifier")
newError("errComma", "Error: expecting ','")

local labelCode = {}
local labelMsg = {}
for k, v in ipairs(terror) do 
  labelCode[v.l] = k
  labelMsg[v.l] = v.msg
end

re.setlabels(labelCode)

local p = re.compile([[
  S        <- Id List  /{errId}  ErrId  /{errComma}  ErrComma
  List     <- !.  /  Comma Id List
  Id       <- [a-z]+  /  %{errId}
  Comma    <- ','  /  %{errComma}
  ErrId    <- '' -> errId
  ErrComma <- '' ->  errComma
]], labelMsg)

print(p:match("a,b"))
print(p:match("a b"))
print(p:match(",b"))


