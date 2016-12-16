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
  List   <- !.  /  Comma Id List
  Id     <- Sp {[a-z]+} / %{errId}
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
  "ErrComma  <-  ('' -> 'errComma' => recorderror) " .. sync('[a-z]+') .. "\n" ..
	"ErrId     <-  ('' -> 'errId' => recorderror) " .. sync('","') .. "-> default" 
	, {g = g, recorderror  = recorderror, default = "NONE"})

function mymatch (g, s)
	errors = {}
	subject = s	
	io.write("Input: ", s, "\n")
	local r = { g:match(s) }
	io.write("Captures (separated by ';'): ")
	for k, v in pairs(r) do
		io.write(v .. "; ")
	end
	io.write("\nSyntactic errors found: " .. #errors)
	if #errors > 0 then
		io.write("\n")
		local out = {}
    for i, err in ipairs(errors) do
    	local msg = "Error at line " .. err.line .. " (col " .. err.col .. "): " .. err.msg
      table.insert(out,  msg)
    end
    io.write(table.concat(out, "\n"))
  end
	print("\n")
	return r
end
  
mymatch(grec, "one,two")
mymatch(grec, "one two three")
mymatch(grec, "1,\n two, \n3,")
mymatch(grec, "one\n two123, \nthree,")
