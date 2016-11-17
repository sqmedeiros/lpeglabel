local re = require 'relabelrec' 

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
  List   <- !.  /  Comma Id List
  Id     <- Sp [a-z]+ / %{errId}
  Comma  <- Sp ',' / %{errComma}
  Sp     <- %s*
]]

local errors

function recorderror (subject, pos, label)
	local line, col = re.calcline(subject, pos)
	table.insert(errors, { line = line, col = col, msg = errmsgs[labels[label]] })
	return true 
end

function sync (p)
	return '( !(' .. p .. ') .)*'
end

local grec = re.compile(
  "S         <- %g //{errComma} ErrComma //{errId} ErrId" .. "\n" ..
  "ErrComma  <-  ('' -> 'errComma' => recorderror) " .. sync('!. / [a-z]+') .. "\n" ..
	"ErrId     <-  ('' -> 'errId' => recorderror) (!(!. / ',') .)*"
	, {g = g, recorderror  = recorderror})

function mymatch (g, s)
	errors = {}
	local r, e, sfail = g:match(s)
	if #errors > 0 then
		local out = {}
    for i, err in ipairs(errors) do
    	local msg = "Error at line " .. err.line .. " (col " .. err.col .. "): " .. err.msg
      table.insert(out,  msg)
    end
    return nil, table.concat(out, "\n")
  end
  return r
end
  
print(mymatch(grec, "one,two"))
print(mymatch(grec, "one two three"))
print(mymatch(grec, "1,\n two, \n3,"))
print(mymatch(grec, "one\n two123, \nthree,"))
