#!/usr/bin/env lua

local tlparser = require "tlparser"

-- expected result, result, message, subject
local e, r, m, s

local filename = "test.lua"

local function parse (s)
  local r, m = tlparser.parse(s,filename,false,false)
  if not r then m = m .. "\n" end
  return r, m
end

print("> testing lexer...")

-- syntax ok

-- empty files

s = [=[
]=]
--[=[
{  }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
-- testing empty file
]=]
--[=[
{  }
]=]

r, m = parse(s)
assert(r == true)

-- expressions

s = [=[
local _nil,_false,_true,_dots = nil,false,true,...
]=]
--[=[
{ `Local{ { `Id "_nil", `Id "_false", `Id "_true", `Id "_dots" }, { `Nil, `False, `True, `Dots } } }
]=]

r, m = parse(s)
assert(r == true)

-- floating points

s = [=[
local f1 = 1.
local f2 = 1.1
]=]
--[=[
{ `Local{ { `Id "f1" }, { `Number "1.0" } }, `Local{ { `Id "f2" }, { `Number "1.1" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local f1 = 1.e-1
local f2 = 1.e1
]=]
--[=[
{ `Local{ { `Id "f1" }, { `Number "0.1" } }, `Local{ { `Id "f2" }, { `Number "10.0" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local f1 = 1.1e+1
local f2 = 1.1e1
]=]
--[=[
{ `Local{ { `Id "f1" }, { `Number "11.0" } }, `Local{ { `Id "f2" }, { `Number "11.0" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local f1 = .1
local f2 = .1e1
]=]
--[=[
{ `Local{ { `Id "f1" }, { `Number "0.1" } }, `Local{ { `Id "f2" }, { `Number "1.0" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local f1 = 1E1
local f2 = 1e-1
]=]
--[=[
{ `Local{ { `Id "f1" }, { `Number "10.0" } }, `Local{ { `Id "f2" }, { `Number "0.1" } } }
]=]

r, m = parse(s)
assert(r == true)

-- integers

s = [=[
local i = 1
local h = 0xff
]=]
--[=[
{ `Local{ { `Id "i" }, { `Number "1" } }, `Local{ { `Id "h" }, { `Number "255" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local h = 0x76c
local i = 4294967296 -- 2^32
]=]
--[=[
{ `Local{ { `Id "h" }, { `Number "1900" } }, `Local{ { `Id "i" }, { `Number "4294967296" } } }
]=]

r, m = parse(s)
assert(r == true)

-- long comments

s = [=[
--[======[
testing
long
comment
[==[ one ]==]
[===[ more ]===]
[====[ time ]====]
bye
]======]
]=]
--[=[
{  }
]=]

r, m = parse(s)
assert(r == true)

-- long strings

s = [=[
--[[
testing long string1 begin
]]

local ls1 =
[[
testing long string
]]

--[[
testing long string1 end
]]
]=]
--[=[
{ `Local{ { `Id "ls1" }, { `String "testing long string\n" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
--[==[
testing long string2 begin
]==]

local ls2 = [==[ testing \n [[ long ]] \t [===[ string ]===]
\a ]==]

--[==[
[[ testing long string2 end ]]
]==]
]=]
--[=[
{ `Local{ { `Id "ls2" }, { `String " testing \\n [[ long ]] \\t [===[ string ]===]\n\\a " } } }
]=]

r, m = parse(s)
assert(r == true)

-- short strings

s = [=[
-- short string test begin

local ss1_a = "ola mundo\a"
local ss1_b = 'ola mundo\a'

-- short string test end
]=]
--[=[
{ `Local{ { `Id "ss1_a" }, { `String "ola mundo\a" } }, `Local{ { `Id "ss1_b" }, { `String "ola mundo\a" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
-- short string test begin

local ss2_a = "testando,\tteste\n1\n2\n3 --> \"tchau\""
local ss2_b = 'testando,\tteste\n1\n2\n3 --> \'tchau\''

-- short string test end
]=]
--[=[
{ `Local{ { `Id "ss2_a" }, { `String "testando,\tteste\n1\n2\n3 --> \"tchau\"" } }, `Local{ { `Id "ss2_b" }, { `String "testando,\tteste\n1\n2\n3 --> 'tchau'" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
-- short string test begin

local ss3_a = "ola \
'mundo'!"

local ss3_b = 'ola \
"mundo"!'

-- short string test end
]=]
--[=[
{ `Local{ { `Id "ss3_a" }, { `String "ola \n'mundo'!" } }, `Local{ { `Id "ss3_b" }, { `String "ola \n\"mundo\"!" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
-- short string test begin

local ss4_a = "C:\\Temp/"

local ss4_b = 'C:\\Temp/'

-- short string test end
]=]
--[=[
{ `Local{ { `Id "ss4_a" }, { `String "C:\\Temp/" } }, `Local{ { `Id "ss4_b" }, { `String "C:\\Temp/" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
-- short string test begin

local ss5_a = "ola \
mundo \\ \
cruel"

local ss5_b = 'ola \
mundo \\ \
cruel'

-- short string test end
]=]
--[=[
{ `Local{ { `Id "ss5_a" }, { `String "ola \nmundo \\ \ncruel" } }, `Local{ { `Id "ss5_b" }, { `String "ola \nmundo \\ \ncruel" } } }
]=]

r, m = parse(s)
assert(r == true)

-- syntax error

-- floating points

s = [=[
local f = 9e
]=]
--[=[
test.lua:2:1: syntax error, unexpected 'EOF', expecting '=', ',', 'String', '{', '(', ':', '[', '.'
]=]
e = [=[
test.lua:1:11: malformed <number>
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local f = 5.e
]=]
--[=[
test.lua:2:1: syntax error, unexpected 'EOF', expecting '=', ',', 'String', '{', '(', ':', '[', '.'
]=]
e = [=[
test.lua:1:11: malformed <number>
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local f = .9e-
]=]
--[=[
test.lua:1:14: syntax error, unexpected '-', expecting '=', ',', 'String', '{', '(', ':', '[', '.'
]=]
e = [=[
test.lua:1:11: malformed <number>
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local f = 5.9e+
]=]
--[=[
test.lua:1:15: syntax error, unexpected '+', expecting '=', ',', 'String', '{', '(', ':', '[', '.'
]=]
e = [=[
test.lua:1:11: malformed <number>
]=]

r, m = parse(s)
assert(m == e)

-- integers

s = [=[
-- invalid hexadecimal number

local hex = 0xG
]=]
--[=[
test.lua:4:1: syntax error, unexpected 'EOF', expecting '=', ',', 'String', '{', '(', ':', '[', '.'
]=]
e = [=[
test.lua:3:13: malformed <number>
]=]

r, m = parse(s)
assert(m == e)

-- long strings

s = [=[
--[==[
testing long string3 begin
]==]

local ls3 = [===[
testing
unfinised
long string
]==]

--[==[
[[ testing long string3 end ]]
]==]
]=]
--[=[
test.lua:5:13: syntax error, unexpected '[', expecting '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]
e = [=[
test.lua:5:13: unfinished long string
]=]

r, m = parse(s)
assert(m == e)

-- short strings

s = [=[
-- short string test begin

local ss6 = "testing unfinished string

-- short string test end
]=]
--[=[
test.lua:3:13: syntax error, unexpected '"', expecting '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]
e = [=[
test.lua:3:13: malformed <string>
]=]

r, m = parse(s)
assert(m == e)

-- unfinished comments

s = [=[
--[[ testing
unfinished
comment
]=]
--[=[
test.lua:3:1: syntax error, unexpected 'comment', expecting '=', ',', 'String', '{', '(', ':', '[', '.'
]=]
e = [=[
test.lua:4:1: unfinished long comment
]=]

r, m = parse(s)
assert(m == e)

print("> testing parser...")

-- syntax ok

-- anonymous functions

s = [=[
local a,b,c = function () end
]=]
--[=[
{ `Local{ { `Id "a", `Id "b", `Id "c" }, { `Function{ {  }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local test = function ( a , b , ... ) end
]=]
--[=[
{ `Local{ { `Id "test" }, { `Function{ { `Id "a", `Id "b", `Dots }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local test = function (...) return ...,0 end
]=]
--[=[
{ `Local{ { `Id "test" }, { `Function{ { `Dots }, { `Return{ `Dots, `Number "0" } } } } } }
]=]

r, m = parse(s)
assert(r == true)

-- arithmetic expressions

s = [=[
local arithmetic = 1 - 2 * 3 + 4
]=]
--[=[
{ `Local{ { `Id "arithmetic" }, { `Op{ "add", `Op{ "sub", `Number "1", `Op{ "mul", `Number "2", `Number "3" } }, `Number "4" } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local pow = -3^-2^2
]=]
--[=[
{ `Local{ { `Id "pow" }, { `Op{ "unm", `Op{ "pow", `Number "3", `Op{ "unm", `Op{ "pow", `Number "2", `Number "2" } } } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
q, r, f = 3//2, 3%2, 3/2
]=]
--[=[
{ `Set{ { `Index{ `Id "_ENV", `String "q" }, `Index{ `Id "_ENV", `String "r" }, `Index{ `Id "_ENV", `String "f" } }, { `Op{ "idiv", `Number "3", `Number "2" }, `Op{ "mod", `Number "3", `Number "2" }, `Op{ "div", `Number "3", `Number "2" } } } }
]=]

r, m = parse(s)
assert(r == true)

-- assignments

s = [=[
a = f()[1]
]=]
--[=[
{ `Set{ { `Index{ `Id "_ENV", `String "a" } }, { `Index{ `Call{ `Index{ `Id "_ENV", `String "f" } }, `Number "1" } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
a()[1] = 1;
]=]
--[=[
{ `Set{ { `Index{ `Call{ `Index{ `Id "_ENV", `String "a" } }, `Number "1" } }, { `Number "1" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
i = a.f(1)
]=]
--[=[
{ `Set{ { `Index{ `Id "_ENV", `String "i" } }, { `Call{ `Index{ `Index{ `Id "_ENV", `String "a" }, `String "f" }, `Number "1" } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
i = a[f(1)]
]=]
--[=[
{ `Set{ { `Index{ `Id "_ENV", `String "i" } }, { `Index{ `Index{ `Id "_ENV", `String "a" }, `Call{ `Index{ `Id "_ENV", `String "f" }, `Number "1" } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
a[f()] = sub
i = i + 1
]=]
--[=[
{ `Set{ { `Index{ `Index{ `Id "_ENV", `String "a" }, `Call{ `Index{ `Id "_ENV", `String "f" } } } }, { `Index{ `Id "_ENV", `String "sub" } } }, `Set{ { `Index{ `Id "_ENV", `String "i" } }, { `Op{ "add", `Index{ `Id "_ENV", `String "i" }, `Number "1" } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
a:b(1)._ = some_value
]=]
--[=[
{ `Set{ { `Index{ `Invoke{ `Index{ `Id "_ENV", `String "a" }, `String "b", `Number "1" }, `String "_" } }, { `Index{ `Id "_ENV", `String "some_value" } } } }
]=]

r, m = parse(s)
assert(r == true)

-- bitwise expressions

s = [=[
b = 1 & 0 | 1 ~ 1
]=]
--[=[
{ `Set{ { `Index{ `Id "_ENV", `String "b" } }, { `Op{ "bor", `Op{ "band", `Number "1", `Number "0" }, `Op{ "bxor", `Number "1", `Number "1" } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
b = 1 & 0 | 1 >> 1 ~ 1
]=]
--[=[
{ `Set{ { `Index{ `Id "_ENV", `String "b" } }, { `Op{ "bor", `Op{ "band", `Number "1", `Number "0" }, `Op{ "bxor", `Op{ "shr", `Number "1", `Number "1" }, `Number "1" } } } } }
]=]

r, m = parse(s)
assert(r == true)

-- break

s = [=[
while 1 do
  break
end
]=]
--[=[
{ `While{ `Number "1", { `Break } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
while 1 do
  while 1 do
    break
  end
  break
end
]=]
--[=[
{ `While{ `Number "1", { `While{ `Number "1", { `Break } }, `Break } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
repeat
  if 2 > 1 then break end
until 1
]=]
--[=[
{ `Repeat{ { `If{ `Op{ "lt", `Number "1", `Number "2" }, { `Break } } }, `Number "1" } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
for i=1,10 do
  do
    break
    break
    return
  end
end
]=]
--[=[
{ `Fornum{ `Id "i", `Number "1", `Number "10", { `Do{ `Break, `Break, `Return } } } }
]=]

r, m = parse(s)
assert(r == true)

-- block statements

s = [=[
do
  local var = 2+2;
  return
end
]=]
--[=[
{ `Do{ `Local{ { `Id "var" }, { `Op{ "add", `Number "2", `Number "2" } } }, `Return } }
]=]

r, m = parse(s)
assert(r == true)

-- calls

s = [=[
f()
t:m()
]=]
--[=[
{ `Call{ `Index{ `Id "_ENV", `String "f" } }, `Invoke{ `Index{ `Id "_ENV", `String "t" }, `String "m" } }
]=]

r, m = parse(s)
assert(r == true)

-- concatenation expressions

s = [=[
local concat1 = 1 .. 2^3
]=]
--[=[
{ `Local{ { `Id "concat1" }, { `Op{ "concat", `Number "1", `Op{ "pow", `Number "2", `Number "3" } } } } }
]=]

r, m = parse(s)
assert(r == true)

-- empty files

s = [=[
;
]=]
--[=[
{  }
]=]

r, m = parse(s)
assert(r == true)

-- for generic

s = [=[
for k,v in pairs(t) do print (k,v) end
]=]
--[=[
{ `Forin{ { `Id "k", `Id "v" }, { `Call{ `Index{ `Id "_ENV", `String "pairs" }, `Index{ `Id "_ENV", `String "t" } } }, { `Call{ `Index{ `Id "_ENV", `String "print" }, `Id "k", `Id "v" } } } }
]=]

r, m = parse(s)
assert(r == true)

-- for numeric

s = [=[
for i = 1 , 10 , 2 do end
]=]
--[=[
{ `Fornum{ `Id "i", `Number "1", `Number "10", `Number "2", {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
for i=1,10 do end
]=]
--[=[
{ `Fornum{ `Id "i", `Number "1", `Number "10", {  } } }
]=]

r, m = parse(s)
assert(r == true)

-- global functions

s = [=[
function test(a , b , ...) end
]=]
--[=[
{ `Set{ { `Index{ `Id "_ENV", `String "test" } }, { `Function{ { `Id "a", `Id "b", `Dots }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
function test (...) end
]=]
--[=[
{ `Set{ { `Index{ `Id "_ENV", `String "test" } }, { `Function{ { `Dots }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
function t.a:b() end
]=]
--[=[
{ `Set{ { `Index{ `Index{ `Index{ `Id "_ENV", `String "t" }, `String "a" }, `String "b" } }, { `Function{ { `Id "self" }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
function t.a() end
]=]
--[=[
{ `Set{ { `Index{ `Index{ `Id "_ENV", `String "t" }, `String "a" } }, { `Function{ {  }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
function testando . funcao . com : espcacos ( e, com , parametros, ... ) end
]=]
--[=[
{ `Set{ { `Index{ `Index{ `Index{ `Index{ `Id "_ENV", `String "testando" }, `String "funcao" }, `String "com" }, `String "espcacos" } }, { `Function{ { `Id "self", `Id "e", `Id "com", `Id "parametros", `Dots }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

-- goto

s = [=[
goto label
:: label :: return
]=]
--[=[
{ `Goto{ "label" }, `Label{ "label" }, `Return }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
::label::
goto label
]=]
--[=[
{ `Label{ "label" }, `Goto{ "label" } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
goto label
::label::
]=]
--[=[
{ `Goto{ "label" }, `Label{ "label" } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
::label::
do ::label:: goto label end
]=]
--[=[
{ `Label{ "label" }, `Do{ `Label{ "label" }, `Goto{ "label" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
::label::
do goto label ; ::label:: end
]=]
--[=[
{ `Label{ "label" }, `Do{ `Goto{ "label" }, `Label{ "label" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
::label::
do goto label end
]=]
--[=[
{ `Label{ "label" }, `Do{ `Goto{ "label" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
do goto label end
::label::
]=]
--[=[
{ `Do{ `Goto{ "label" } }, `Label{ "label" } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
do do do do do goto label end end end end end
::label::
]=]
--[=[
{ `Do{ `Do{ `Do{ `Do{ `Do{ `Goto{ "label" } } } } } }, `Label{ "label" } }
]=]

r, m = parse(s)
assert(r == true)

-- if-else

s = [=[
if a then end
]=]
--[=[
{ `If{ `Index{ `Id "_ENV", `String "a" }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
if a then return a else return end
]=]
--[=[
{ `If{ `Index{ `Id "_ENV", `String "a" }, { `Return{ `Index{ `Id "_ENV", `String "a" } } }, { `Return } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
if a then
  return a
else
  local c = d
  d = d + 1
  return d
end
]=]
--[=[
{ `If{ `Index{ `Id "_ENV", `String "a" }, { `Return{ `Index{ `Id "_ENV", `String "a" } } }, { `Local{ { `Id "c" }, { `Index{ `Id "_ENV", `String "d" } } }, `Set{ { `Index{ `Id "_ENV", `String "d" } }, { `Op{ "add", `Index{ `Id "_ENV", `String "d" }, `Number "1" } } }, `Return{ `Index{ `Id "_ENV", `String "d" } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
if a then
  return a
elseif b then
  return b
elseif c then
  return c
end
]=]
--[=[
{ `If{ `Index{ `Id "_ENV", `String "a" }, { `Return{ `Index{ `Id "_ENV", `String "a" } } }, `Index{ `Id "_ENV", `String "b" }, { `Return{ `Index{ `Id "_ENV", `String "b" } } }, `Index{ `Id "_ENV", `String "c" }, { `Return{ `Index{ `Id "_ENV", `String "c" } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
if a then return a
elseif b then return
else ;
end
]=]
--[=[
{ `If{ `Index{ `Id "_ENV", `String "a" }, { `Return{ `Index{ `Id "_ENV", `String "a" } } }, `Index{ `Id "_ENV", `String "b" }, { `Return }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
if a then
  return
elseif c then
end
]=]
--[=[
{ `If{ `Index{ `Id "_ENV", `String "a" }, { `Return }, `Index{ `Id "_ENV", `String "c" }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

-- interfaces

s = [=[
local interface Empty end
]=]
--[=[
{ `Interface{ Empty, `TTable{  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local interface X
  x, y, z:number
end
]=]
--[=[
{ `Interface{ X, `TTable{ `TLiteral x:`TBase number, `TLiteral y:`TBase number, `TLiteral z:`TBase number } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local interface Person
  firstname:string
  lastname:string
end
]=]
--[=[
{ `Interface{ Person, `TTable{ `TLiteral firstname:`TBase string, `TLiteral lastname:`TBase string } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local interface Element
  info:number
  next:Element?
end
]=]
--[=[
{ `Interface{ Element, `TRecursive{ Element, `TTable{ `TLiteral info:`TBase number, `TLiteral next:`TUnion{ `TVariable Element, `TNil } } } } }
]=]

r, m = parse(s)
assert(r == true)

-- labels

s = [=[
::label::
do ::label:: end
::other_label::
]=]
--[=[
{ `Label{ "label" }, `Do{ `Label{ "label" } }, `Label{ "other_label" } }
]=]

r, m = parse(s)
assert(r == true)

-- locals

s = [=[
local a
]=]
--[=[
{ `Local{ { `Id "a" }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local a,b,c
]=]
--[=[
{ `Local{ { `Id "a", `Id "b", `Id "c" }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local a = 1 , 1 + 2, 5.1
]=]
--[=[
{ `Local{ { `Id "a" }, { `Number "1", `Op{ "add", `Number "1", `Number "2" }, `Number "5.1" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local a,b,c = 1.9
]=]
--[=[
{ `Local{ { `Id "a", `Id "b", `Id "c" }, { `Number "1.9" } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function test() end
]=]
--[=[
{ `Localrec{ { `Id "test" }, { `Function{ {  }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function test ( a , b , c , ... ) end
]=]
--[=[
{ `Localrec{ { `Id "test" }, { `Function{ { `Id "a", `Id "b", `Id "c", `Dots }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function test(...) return ... end
]=]
--[=[
{ `Localrec{ { `Id "test" }, { `Function{ { `Dots }, { `Return{ `Dots } } } } } }
]=]

r, m = parse(s)
assert(r == true)

-- relational expressions

s = [=[
local relational = 1 < 2 >= 3 == 4 ~= 5 < 6 <= 7
]=]
--[=[
{ `Local{ { `Id "relational" }, { `Op{ "le", `Op{ "lt", `Op{ "not", `Op{ "eq", `Op{ "eq", `Op{ "le", `Number "3", `Op{ "lt", `Number "1", `Number "2" } }, `Number "4" }, `Number "5" } }, `Number "6" }, `Number "7" } } } }
]=]

r, m = parse(s)
assert(r == true)

-- repeat

s = [=[
repeat
  local a,b,c = 1+1,2+2,3+3
  break
until a < 1
]=]
--[=[
{ `Repeat{ { `Local{ { `Id "a", `Id "b", `Id "c" }, { `Op{ "add", `Number "1", `Number "1" }, `Op{ "add", `Number "2", `Number "2" }, `Op{ "add", `Number "3", `Number "3" } } }, `Break }, `Op{ "lt", `Index{ `Id "_ENV", `String "a" }, `Number "1" } } }
]=]

r, m = parse(s)
assert(r == true)

-- return

s = [=[
return
]=]
--[=[
{ `Return }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
return 1
]=]
--[=[
{ `Return{ `Number "1" } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
return 1,1-2*3+4,"alo"
]=]
--[=[
{ `Return{ `Number "1", `Op{ "add", `Op{ "sub", `Number "1", `Op{ "mul", `Number "2", `Number "3" } }, `Number "4" }, `String "alo" } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
return;
]=]
--[=[
{ `Return }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
return 1;
]=]
--[=[
{ `Return{ `Number "1" } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
return 1,1-2*3+4,"alo";
]=]
--[=[
{ `Return{ `Number "1", `Op{ "add", `Op{ "sub", `Number "1", `Op{ "mul", `Number "2", `Number "3" } }, `Number "4" }, `String "alo" } }
]=]

r, m = parse(s)
assert(r == true)

-- tables

s = [=[
local t = { [1] = "alo", alo = 1, 2; }
]=]
--[=[
{ `Local{ { `Id "t" }, { `Table{ `Pair{ `Number "1", `String "alo" }, `Pair{ `String "alo", `Number "1" }, `Number "2" } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local t = { 1.5 }
]=]
--[=[
{ `Local{ { `Id "t" }, { `Table{ `Number "1.5" } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local t = {1,2;
3,
4,



5}
]=]
--[=[
{ `Local{ { `Id "t" }, { `Table{ `Number "1", `Number "2", `Number "3", `Number "4", `Number "5" } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local t = {[1]=1,[2]=2;
[3]=3,
[4]=4,



[5]=5}
]=]
--[=[
{ `Local{ { `Id "t" }, { `Table{ `Pair{ `Number "1", `Number "1" }, `Pair{ `Number "2", `Number "2" }, `Pair{ `Number "3", `Number "3" }, `Pair{ `Number "4", `Number "4" }, `Pair{ `Number "5", `Number "5" } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local t = {{{}}, {"alo"}}
]=]
--[=[
{ `Local{ { `Id "t" }, { `Table{ `Table{ `Table }, `Table{ `String "alo" } } } } }
]=]

r, m = parse(s)
assert(r == true)

-- vararg

s = [=[
local f = function (...)
  return ...
end
]=]
--[=[
{ `Local{ { `Id "f" }, { `Function{ { `Dots }, { `Return{ `Dots } } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local f = function ()
  local g = function (x, y, ...)
    return ...,...,...
  end
end
]=]
--[=[
{ `Local{ { `Id "f" }, { `Function{ {  }, { `Local{ { `Id "g" }, { `Function{ { `Id "x", `Id "y", `Dots }, { `Return{ `Dots, `Dots, `Dots } } } } } } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f (x, ...)
  return ...
end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ { `Id "x", `Dots }, { `Return{ `Dots } } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local f = function (x, ...)
  return ...
end
]=]
--[=[
{ `Local{ { `Id "f" }, { `Function{ { `Id "x", `Dots }, { `Return{ `Dots } } } } } }
]=]

r, m = parse(s)
assert(r == true)

-- while

s = [=[
local i = 0
while (i < 10)
do
  i = i + 1
end
]=]
--[=[
{ `Local{ { `Id "i" }, { `Number "0" } }, `While{ `Paren{ `Op{ "lt", `Id "i", `Number "10" } }, { `Set{ { `Id "i" }, { `Op{ "add", `Id "i", `Number "1" } } } } } }
]=]

r, m = parse(s)
assert(r == true)

-- type annotations

s = [=[
local x:nil
]=]
--[=[
{ `Local{ { `Id "x":`TNil }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:false, y:true
]=]
--[=[
{ `Local{ { `Id "x":`TLiteral false, `Id "y":`TLiteral true }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:1, y:1.1
]=]
--[=[
{ `Local{ { `Id "x":`TLiteral 1, `Id "y":`TLiteral 1.1 }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:"hello", y:'world' 
]=]
--[=[
{ `Local{ { `Id "x":`TLiteral hello, `Id "y":`TLiteral world }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:boolean, y:number, z:string 
]=]
--[=[
{ `Local{ { `Id "x":`TBase boolean, `Id "y":`TBase number, `Id "z":`TBase string }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:any
]=]
--[=[
{ `Local{ { `Id "x":`TAny }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:number?
]=]
--[=[
{ `Local{ { `Id "x":`TUnion{ `TBase number, `TNil } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:number|nil
]=]
--[=[
{ `Local{ { `Id "x":`TUnion{ `TBase number, `TNil } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:number|string|nil
]=]
--[=[
{ `Local{ { `Id "x":`TUnion{ `TBase number, `TBase string, `TNil } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:number|nil|nil|nil|nil
]=]
--[=[
{ `Local{ { `Id "x":`TUnion{ `TBase number, `TNil } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:number|nil|string|nil|number|boolean|string
]=]
--[=[
{ `Local{ { `Id "x":`TUnion{ `TNil, `TBase number, `TBase boolean, `TBase string } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:number|string?
]=]
--[=[
{ `Local{ { `Id "x":`TUnion{ `TBase number, `TBase string, `TNil } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:(number) -> (number)
]=]
--[=[
{ `Local{ { `Id "x":`TFunction{ `TTuple{ `TBase number, `TVararg{ `TValue } }, `TTuple{ `TBase number, `TVararg{ `TNil } } } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:(value*) -> (nil*)
]=]
--[=[
{ `Local{ { `Id "x":`TFunction{ `TTuple{ `TVararg{ `TValue } }, `TTuple{ `TVararg{ `TNil } } } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:(number,string,boolean) -> (string,number,boolean)
]=]
--[=[
{ `Local{ { `Id "x":`TFunction{ `TTuple{ `TBase number, `TBase string, `TBase boolean, `TVararg{ `TValue } }, `TTuple{ `TBase string, `TBase number, `TBase boolean, `TVararg{ `TNil } } } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:(number,string,value*) -> (string,number,nil*)
]=]
--[=[
{ `Local{ { `Id "x":`TFunction{ `TTuple{ `TBase number, `TBase string, `TVararg{ `TValue } }, `TTuple{ `TBase string, `TBase number, `TVararg{ `TNil } } } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:{}
]=]
--[=[
{ `Local{ { `Id "x":`TTable{  } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:{{{{{}}}}}
]=]
--[=[
{ `Local{ { `Id "x":`TTable{ `TBase number:`TUnion{ `TTable{ `TBase number:`TUnion{ `TTable{ `TBase number:`TUnion{ `TTable{ `TBase number:`TUnion{ `TTable{  }, `TNil } }, `TNil } }, `TNil } }, `TNil } } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:{string}
]=]
--[=[
{ `Local{ { `Id "x":`TTable{ `TBase number:`TUnion{ `TBase string, `TNil } } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:{string:number}
]=]
--[=[
{ `Local{ { `Id "x":`TTable{ `TBase string:`TUnion{ `TBase number, `TNil } } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:{'firstname':string, 'lastname':string}
]=]
--[=[
{ `Local{ { `Id "x":`TTable{ `TLiteral firstname:`TBase string, `TLiteral lastname:`TBase string } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:{'tag':string, number:string}
]=]
--[=[
{ `Local{ { `Id "x":`TTable{ `TLiteral tag:`TBase string, `TBase number:`TUnion{ `TBase string, `TNil } } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local x:{'f':(number) -> (number), 't':{number:number}}
]=]
--[=[
{ `Local{ { `Id "x":`TTable{ `TLiteral f:`TFunction{ `TTuple{ `TBase number, `TVararg{ `TValue } }, `TTuple{ `TBase number, `TVararg{ `TNil } } }, `TLiteral t:`TTable{ `TBase number:`TUnion{ `TBase number, `TNil } } } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
for k:number, v:string in ipairs({"hello", "world"}) do end
]=]
--[=[
{ `Forin{ { `Id "k":`TBase number, `Id "v":`TBase string }, { `Call{ `Index{ `Id "_ENV", `String "ipairs" }, `Table{ `String "hello", `String "world" } } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
for k:string, v in pairs({}) do end
]=]
--[=[
{ `Forin{ { `Id "k":`TBase string, `Id "v" }, { `Call{ `Index{ `Id "_ENV", `String "pairs" }, `Table } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
for k, v:boolean in pairs({}) do end
]=]
--[=[
{ `Forin{ { `Id "k", `Id "v":`TBase boolean }, { `Call{ `Index{ `Id "_ENV", `String "pairs" }, `Table } }, {  } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f (x:any) end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ { `Id "x":`TAny }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f (x:any):(any) end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ { `Id "x":`TAny }:`TTuple{ `TAny, `TVararg{ `TNil } }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f (...:any) end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ { `Dots:`TAny }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f (x:any, ...:any) end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ { `Id "x":`TAny, `Dots:`TAny }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f (x, ...:any) end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ { `Id "x", `Dots:`TAny }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f (x:any, ...) end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ { `Id "x":`TAny, `Dots }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f (x:any, ...:any):(any) end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ { `Id "x":`TAny, `Dots:`TAny }:`TTuple{ `TAny, `TVararg{ `TNil } }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f (x:(any) -> (any)):((any) -> (any)) end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ { `Id "x":`TFunction{ `TTuple{ `TAny, `TVararg{ `TValue } }, `TTuple{ `TAny, `TVararg{ `TNil } } } }:`TTuple{ `TFunction{ `TTuple{ `TAny, `TVararg{ `TValue } }, `TTuple{ `TAny, `TVararg{ `TNil } } }, `TVararg{ `TNil } }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f (x:(number, number) -> (number, nil*)):(number*) end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ { `Id "x":`TFunction{ `TTuple{ `TBase number, `TBase number, `TVararg{ `TValue } }, `TTuple{ `TBase number, `TVararg{ `TNil } } } }:`TTuple{ `TVararg{ `TBase number } }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f ():(number, nil*) end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ {  }:`TTuple{ `TBase number, `TVararg{ `TNil } }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f ():number end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ {  }:`TTuple{ `TBase number, `TVararg{ `TNil } }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f ():number? end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ {  }:`TTuple{ `TUnion{ `TBase number, `TNil }, `TVararg{ `TNil } }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f ():(number) | (nil,string) end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ {  }:`TUnionlist{ `TTuple{ `TBase number, `TVararg{ `TNil } }, `TTuple{ `TNil, `TBase string, `TVararg{ `TNil } } }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f ():(number)? end
]=]
--[=[
{ `Localrec{ { `Id "f" }, { `Function{ {  }:`TUnionlist{ `TTuple{ `TBase number, `TVararg{ `TNil } }, `TTuple{ `TNil, `TBase string, `TVararg{ `TNil } } }, {  } } } } }
]=]

r, m = parse(s)
assert(r == true)

-- syntax error

-- anonymous functions

s = [=[
a = function (a,b,) end
]=]
--[=[
test.lua:1:19: syntax error, unexpected ')', expecting '...', 'Name'
]=]
e = [=[
test.lua:1:19: expecting '...'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
a = function (...,a) end
]=]
--[=[
test.lua:1:18: syntax error, unexpected ',', expecting ')', ':'
]=]
e = [=[
test.lua:1:18: missing ')'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local a = function (1) end
]=]
--[=[
test.lua:1:21: syntax error, unexpected '1', expecting ')', '...', 'Name'
]=]
e = [=[
test.lua:1:21: missing ')'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local test = function ( a , b , c , ... )
]=]
--[=[
test.lua:2:1: syntax error, unexpected 'EOF', expecting 'end', 'return', '(', 'Name', 'typealias', 'interface', 'goto', 'break', '::', 'local', 'function', 'const', 'repeat', 'for', 'do', 'while', 'if', ';', ':'
]=]
e = [=[
test.lua:2:1: missing 'end' to close function declaration
]=]

r, m = parse(s)
assert(m == e)

-- arithmetic expressions

s = [=[
a = 3 / / 2
]=]
--[=[
test.lua:1:9: syntax error, unexpected '/', expecting '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]
e = [=[
test.lua:1:9: unexpected '/', expecting '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]

r, m = parse(s)
assert(m == e)

-- bitwise expressions

s = [=[
b = 1 && 1
]=]
--[=[
test.lua:1:8: syntax error, unexpected '&', expecting '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]
e = [=[
test.lua:1:8: unexpected '&', expecting '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
b = 1 <> 0
]=]
--[=[
test.lua:1:8: syntax error, unexpected '>', expecting '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]
e = [=[
test.lua:1:8: unexpected '>', expecting '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
b = 1 < < 0
]=]
--[=[
test.lua:1:9: syntax error, unexpected '<', expecting '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]
e = [=[
test.lua:1:9: unexpected '<', expecting '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]

r, m = parse(s)
assert(m == e)

-- concatenation expressions

s = [=[
concat2 = 2^3..1
]=]
--[=[
test.lua:1:15: syntax error, unexpected '.1', expecting 'return', '(', 'Name', 'typealias', 'interface', 'goto', 'break', '::', 'local', 'function', 'const', 'repeat', 'for', 'do', 'while', 'if', ';', ',', 'or', 'and', '>', '<', '>=', '<=', '==', '~=', '|', '~', '&', '>>', '<<', '..', '-', '+', '%', '/', '//', '*', '^'
]=]
e = [=[
test.lua:1:15: unexpected '.1', expecting 'return', '(', 'Name', 'typealias', 'interface', 'goto', 'break', '::', 'local', 'function', 'const', 'repeat', 'for', 'do', 'while', 'if', ';', ',', 'or', 'and', '>', '<', '>=', '<=', '==', '~=', '|', '~', '&', '>>', '<<', '..', '-', '+', '%', '/', '//', '*', '^'
]=]

r, m = parse(s)
assert(m == e)

-- for generic

s = [=[
for k;v in pairs(t) do end
]=]
--[=[
test.lua:1:6: syntax error, unexpected ';', expecting 'in', ',', ':', '='
]=]
e = [=[
test.lua:1:6: expecting 'in'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
for k,v in pairs(t:any) do end
]=]
--[=[
test.lua:1:23: syntax error, unexpected ')', expecting 'String', '{', '('
]=]
e = [=[
test.lua:1:23: expecting '(' for method call
]=]

r, m = parse(s)
assert(m == e)

-- for numeric

s = [=[
for i=1,10, do end
]=]
--[=[
test.lua:1:13: syntax error, unexpected 'do', expecting '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]
e = [=[
test.lua:1:13: missing 'do' in for statement
]=]

r, m = parse(s)
assert(m == e)

s = [=[
for i=1,n:number do end
]=]
--[=[
test.lua:1:18: syntax error, unexpected 'do', expecting 'String', '{', '('
]=]
e = [=[
test.lua:1:18: expecting '(' for method call
]=]

r, m = parse(s)
assert(m == e)

-- global functions

s = [=[
function func(a,b,c,) end
]=]
--[=[
test.lua:1:21: syntax error, unexpected ')', expecting '...', 'Name'
]=]
e = [=[
test.lua:1:21: expecting '...'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
function func(...,a) end
]=]
--[=[
test.lua:1:18: syntax error, unexpected ',', expecting ')', ':'
]=]
e = [=[
test.lua:1:18: missing ')'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
function a.b:c:d () end
]=]
--[=[
test.lua:1:15: syntax error, unexpected ':', expecting '('
]=]
e = [=[
test.lua:1:15: missing '('
]=]

r, m = parse(s)
assert(m == e)

-- goto

s = [=[
:: label :: return
goto label
]=]
--[=[
test.lua:2:1: syntax error, unexpected 'goto', expecting ';', '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]
e = [=[
test.lua:2:1: unexpected 'goto', expecting ';', '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]

r, m = parse(s)
assert(m == e)

-- if-else

s = [=[
if a then
]=]
--[=[
test.lua:2:1: syntax error, unexpected 'EOF', expecting 'end', 'else', 'elseif', 'return', '(', 'Name', 'typealias', 'interface', 'goto', 'break', '::', 'local', 'function', 'const', 'repeat', 'for', 'do', 'while', 'if', ';'
]=]
e = [=[
test.lua:2:1: missing 'end' to close if statement
]=]

r, m = parse(s)
assert(m == e)

s = [=[
if a then else
]=]
--[=[
test.lua:2:1: syntax error, unexpected 'EOF', expecting 'end', 'return', '(', 'Name', 'typealias', 'interface', 'goto', 'break', '::', 'local', 'function', 'const', 'repeat', 'for', 'do', 'while', 'if', ';'
]=]
e = [=[
test.lua:2:1: missing 'end' to close if statement
]=]

r, m = parse(s)
assert(m == e)

s = [=[
if a then
  return a
elseif b then
  return b
elseif

end
]=]
--[=[
test.lua:7:1: syntax error, unexpected 'end', expecting '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]
e = [=[
test.lua:7:1: missing 'end' to close if statement
]=]

r, m = parse(s)
assert(m == e)

s = [=[
if a:any then else end
]=]
--[=[
test.lua:1:10: syntax error, unexpected 'then', expecting 'String', '{', '('
]=]
e = [=[
test.lua:1:10: expecting '(' for method call
]=]

r, m = parse(s)
assert(m == e)

-- labels

s = [=[
:: blah ::
:: not ::
]=]
--[=[
test.lua:2:4: syntax error, unexpected 'not', expecting 'Name'
]=]
e = [=[
test.lua:2:4: expecting <name> after '::'
]=]

r, m = parse(s)
assert(m == e)

-- locals

s = [=[
local a =
]=]
--[=[
test.lua:2:1: syntax error, unexpected 'EOF', expecting '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]
e = [=[
test.lua:2:1: expecting expression list after '='
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local function t.a() end
]=]
--[=[
test.lua:1:17: syntax error, unexpected '.', expecting '('
]=]
e = [=[
test.lua:1:17: missing '('
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local function test (a,) end
]=]
--[=[
test.lua:1:24: syntax error, unexpected ')', expecting '...', 'Name'
]=]
e = [=[
test.lua:1:24: expecting '...'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local function test(...,a) end
]=]
--[=[
test.lua:1:24: syntax error, unexpected ',', expecting ')', ':'
]=]
e = [=[
test.lua:1:24: missing ')'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local function (a, b, c, ...) end
]=]
--[=[
test.lua:1:16: syntax error, unexpected '(', expecting 'Name'
]=]
e = [=[
test.lua:1:16: expecting <name> in local function declaration
]=]

r, m = parse(s)
assert(m == e)

-- repeat

s = [=[
repeat
  a,b,c = 1+1,2+2,3+3
  break
]=]
--[=[
test.lua:4:1: syntax error, unexpected 'EOF', expecting 'until', 'return', '(', 'Name', 'typealias', 'interface', 'goto', 'break', '::', 'local', 'function', 'const', 'repeat', 'for', 'do', 'while', 'if', ';'
]=]
e = [=[
test.lua:4:1: missing 'until' in repeat statement
]=]

r, m = parse(s)
assert(m == e)

-- return

s = [=[
return
return 1
return 1,1-2*3+4,"alo"
return;
return 1;
return 1,1-2*3+4,"alo";
]=]
--[=[
test.lua:2:1: syntax error, unexpected 'return', expecting ';', '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]
e = [=[
test.lua:2:1: unexpected 'return', expecting ';', '(', 'Name', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not'
]=]

r, m = parse(s)
assert(m == e)

-- tables

s = [=[
t = { , }
]=]
--[=[
test.lua:1:7: syntax error, unexpected ',', expecting '}', '(', '{', 'function', '...', 'true', 'false', 'nil', 'String', 'Number', '#', '~', '-', 'not', 'Name', '[', 'const'
]=]
e = [=[
test.lua:1:7: missing '}'
]=]

r, m = parse(s)
assert(m == e)

-- while

s = [=[
i = 0
while (i < 10)
  i = i + 1
end
]=]
--[=[
test.lua:3:3: syntax error, unexpected 'i', expecting 'do', 'or', 'and', '>', '<', '>=', '<=', '==', '~=', '|', '~', '&', '>>', '<<', '..', '-', '+', '%', '/', '//', '*', '^', 'String', '{', '(', ':', '[', '.'
]=]
e = [=[
test.lua:3:3: missing 'do' in while statement
]=]

r, m = parse(s)
assert(m == e)

-- type annotations

s = [=[
t[x:any] = 1
]=]
--[=[
test.lua:1:8: syntax error, unexpected ']', expecting 'String', '{', '('
]=]
e = [=[
test.lua:1:8: expecting '(' for method call
]=]

r, m = parse(s)
assert(m == e)

s = [=[
x:number, y, z:boolean = 1, nil, true
]=]
--[=[
test.lua:1:9: syntax error, unexpected ',', expecting 'String', '{', '('
]=]
e = [=[
test.lua:1:9: expecting '(' for method call
]=]

r, m = parse(s)
assert(m == e)

s = [=[
x = x:any
]=]
--[=[
test.lua:2:1: syntax error, unexpected 'EOF', expecting 'String', '{', '('
]=]
e = [=[
test.lua:2:1: expecting '(' for method call
]=]

r, m = parse(s)
assert(m == e)

s = [=[
x = ...:any
]=]
--[=[
test.lua:1:8: syntax error, unexpected ':', expecting 'return', '(', 'Name', 'typealias', 'interface', 'goto', 'break', '::', 'local', 'function', 'const', 'repeat', 'for', 'do', 'while', 'if', ';', ',', 'or', 'and', '>', '<', '>=', '<=', '==', '~=', '|', '~', '&', '>>', '<<', '..', '-', '+', '%', '/', '//', '*', '^'
]=]
e = [=[
test.lua:1:8: unexpected ':', expecting 'return', '(', 'Name', 'typealias', 'interface', 'goto', 'break', '::', 'local', 'function', 'const', 'repeat', 'for', 'do', 'while', 'if', ';', ',', 'or', 'and', '>', '<', '>=', '<=', '==', '~=', '|', '~', '&', '>>', '<<', '..', '-', '+', '%', '/', '//', '*', '^'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
f(x:any)
]=]
--[=[
test.lua:1:8: syntax error, unexpected ')', expecting 'String', '{', '('
]=]
e = [=[
test.lua:1:8: expecting '(' for method call
]=]

r, m = parse(s)
assert(m == e)

s = [=[
f(...:any)
]=]
--[=[
test.lua:1:6: syntax error, unexpected ':', expecting ')', ',', 'or', 'and', '>', '<', '>=', '<=', '==', '~=', '|', '~', '&', '>>', '<<', '..', '-', '+', '%', '/', '//', '*', '^'
]=]
e = [=[
test.lua:1:6: missing ')'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local x:number*
]=]
--[=[
test.lua:1:15: syntax error, unexpected '*', expecting 'return', '(', 'Name', 'typealias', 'interface', 'goto', 'break', '::', 'local', 'function', 'const', 'repeat', 'for', 'do', 'while', 'if', ';', '=', ',', '?', '|'
]=]
e = [=[
test.lua:1:15: unexpected '*', expecting 'return', '(', 'Name', 'typealias', 'interface', 'goto', 'break', '::', 'local', 'function', 'const', 'repeat', 'for', 'do', 'while', 'if', ';', '=', ',', '?', '|'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local x:number|
]=]
--[=[
test.lua:2:1: syntax error, unexpected 'EOF', expecting '{', '(', 'Type'
]=]
e = [=[
test.lua:2:1: expecting <type> after '|'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local x:number?|string?
]=]
--[=[
test.lua:1:16: syntax error, unexpected '|', expecting 'return', '(', 'Name', 'typealias', 'interface', 'goto', 'break', '::', 'local', 'function', 'const', 'repeat', 'for', 'do', 'while', 'if', ';', '=', ','
]=]
e = [=[
test.lua:1:16: unexpected '|', expecting 'return', '(', 'Name', 'typealias', 'interface', 'goto', 'break', '::', 'local', 'function', 'const', 'repeat', 'for', 'do', 'while', 'if', ';', '=', ','
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local x:() -> number
]=]
--[=[
test.lua:1:15: syntax error, unexpected 'number', expecting '('
]=]
e = [=[
test.lua:1:15: expecting <type> after '->'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local x:() -> (number)? | (string)?
]=]
--[=[
test.lua:1:35: syntax error, unexpected '?', expecting '->'
]=]
e = [=[
test.lua:1:35: expecting <type> after '|'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local x:{()->():string}
]=]
--[=[
test.lua:1:16: syntax error, unexpected ':', expecting '}', '?', '|'
]=]
e = [=[
test.lua:1:16: missing '}'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local x:{string:t 1}
]=]
--[=[
test.lua:1:19: syntax error, unexpected '1', expecting '}', '?', '|'
]=]
e = [=[
test.lua:1:19: missing '}'
]=]

r, m = parse(s)
assert(m == e)

s = [=[
local x:{{{{{}}}}
]=]
--[=[
test.lua:2:1: syntax error, unexpected 'EOF', expecting '}', '?', '|'
]=]
e = [=[
test.lua:2:1: missing '}'
]=]

r, m = parse(s)
assert(m == e)

-- syntax errors that depend on some semantic information

-- break

s = [=[
break
]=]
--[=[
test.lua:1:1: syntax error, <break> not inside a loop
]=]

r, m = parse(s)
assert(r == true)

s = [=[
function f (x)
  if 1 then break end
end
]=]
--[=[
test.lua:2:13: syntax error, <break> not inside a loop
]=]

r, m = parse(s)
assert(r == true)

s = [=[
while 1 do
end
break
]=]
--[=[
test.lua:3:1: syntax error, <break> not inside a loop
]=]

r, m = parse(s)
assert(r == true)

-- goto

s = [=[
goto label
]=]
--[=[
test.lua:1:1: syntax error, no visible label 'label' for <goto>
]=]

r, m = parse(s)
assert(r == true)

s = [=[
goto label
::other_label::
]=]
--[=[
test.lua:1:1: syntax error, no visible label 'label' for <goto>
]=]

r, m = parse(s)
assert(r == true)

s = [=[
::other_label::
do do do goto label end end end
]=]
--[=[
test.lua:2:10: syntax error, no visible label 'label' for <goto>
]=]

r, m = parse(s)
assert(r == true)

-- interfaces

s = [=[
local interface X
 x:number
 y:number
 z:number
 x:number
end
]=]
--[=[
test.lua:1:7: syntax error, attempt to redeclare field 'x'
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local interface X
 x, y, z, x:number
end
]=]
--[=[
test.lua:1:7: syntax error, attempt to redeclare field 'x'
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local interface boolean end
]=]
--[=[
test.lua:1:7: syntax error, attempt to redeclare type 'boolean'
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local interface number end
]=]
--[=[
test.lua:1:7: syntax error, attempt to redeclare type 'number'
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local interface string end
]=]
--[=[
test.lua:1:7: syntax error, attempt to redeclare type 'string'
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local interface value end
]=]
--[=[
test.lua:1:7: syntax error, attempt to redeclare type 'value'
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local interface any end
]=]
--[=[
test.lua:1:7: syntax error, attempt to redeclare type 'any'
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local interface self end
]=]
--[=[
test.lua:1:7: syntax error, attempt to redeclare type 'self'
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local interface const end
]=]
--[=[
test.lua:1:7: syntax error, attempt to redeclare type 'const'
]=]

r, m = parse(s)
assert(r == true)

-- labels

s = [=[
::label::
::other_label::
::label::
]=]
--[=[
test.lua:3:1: syntax error, label 'label' already defined
]=]

r, m = parse(s)
assert(r == true)

-- vararg

s = [=[
function f ()
  return ...
end
]=]
--[=[
test.lua:2:10: syntax error, cannot use '...' outside a vararg function
]=]

r, m = parse(s)
assert(r == true)

s = [=[
function f ()
  function g (x, y)
    return ...,...,...
  end
end
]=]
--[=[
test.lua:3:12: syntax error, cannot use '...' outside a vararg function
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local function f (x)
  return ...
end
]=]
--[=[
test.lua:2:10: syntax error, cannot use '...' outside a vararg function
]=]

r, m = parse(s)
assert(r == true)

s = [=[
local f = function (x)
  return ...
end
]=]
--[=[
test.lua:2:10: syntax error, cannot use '...' outside a vararg function
]=]

r, m = parse(s)
assert(r == true)

print("OK")
