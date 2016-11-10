local m = require 'lpeglabelrec'

local p, r, l, s, serror

local function checkeqlab (x, ...)
  y = { ... }
  assert(type(x) == "table")
  assert(#x == #y)
  for i = 1, 3 do
    assert(x[i] == y[i])
  end
end

local function checkeq (x, y, p)
if p then print(x,y) end
  if type(x) ~= "table" then assert(x == y)
  else
    for k,v in pairs(x) do checkeq(v, y[k], p) end
    for k,v in pairs(y) do checkeq(v, x[k], p) end
  end
end

-- throws a label 
p = m.T(1)
s = "abc"
r, l, serror = p:match(s) 
assert(r == nil and l == 1 and serror == "abc")

-- throws a label that is not caught by ordinary choice
p = m.T(1) + m.P"a"
r, l, serror = p:match(s)
assert(r == nil and l == 1 and serror == "abc")

-- again throws a label that is not caught by ordinary choice
local g = m.P{
	"S",
	S = m.V"A" + m.V"B",
	A = m.T(1),
	B = m.P"a"
}
r, l, serror = g:match(s)
assert(r == nil and l == 1 and serror == "abc")


-- throws a label that is not caught by the recovery operator
p = m.Rec(m.T(2), m.P"a", 1, 3)
r, l, serror = p:match(s)
assert(r == nil and l == 2 and serror == "abc")

-- wraps the previous pattern with a recovery that catches label "2"
p = m.Rec(p, m.P"a", 2)
assert(p:match(s) == 2)

-- throws a label that is caught by recovery 
p = m.Rec(m.T(25), m.P"a", 25)
assert(p:match(s) == 2)

-- "fail" is label "0"
-- throws the "fail" label after the recovery
s = "bola"
r, l, serror = p:match("bola")
assert(r == nil and l == 0 and serror == "bola")

-- Recovery does not catch "fail" by default
p = m.Rec(m.P"b", m.P"a", 1)

r, l, serror = p:match("abc") 
assert(r == nil and l == 0 and serror == "abc")

assert(p:match("bola") == 2)


-- recovery operator catches "1" or "3"
p = m.Rec((m.P"a" + m.T(1)) * m.T(3), (m.P"a" + m.P"b"), 1, 3)
assert(p:match("aac") == 3)
assert(p:match("abc") == 3)
r, l, serror = p:match("acc")
assert(r == nil and l == 0 and serror == "cc")

--throws 1, recovery pattern matches 'b', throw 3, and rec pat mathces 'a'
assert(p:match("bac") == 3)

r, l, serror = p:match("cab")
assert(r == nil and l == 0 and serror == "cab")


-- associativity
-- (p1 / %1) //{1} (p2 / %2) //{2} p3
-- left-associativity
-- ("a" //{1}  "b") //{2} "c"
p = m.Rec(m.Rec(m.P"a" + m.T(1), m.P"b" + m.T(2), 1), m.P"c", 2)
assert(p:match("abc") == 2)
assert(p:match("bac") == 2)
assert(p:match("cab") == 2)
r, l, serror = p:match("dab")
assert(r == nil and l == 0 and serror == "dab")


-- righ-associativity
-- "a" //{1}  ("b" //{2} "c")
p = m.Rec(m.P"a" + m.T(1), m.Rec(m.P"b" + m.T(2), m.P"c", 2), 1)
assert(p:match("abc") == 2)
assert(p:match("bac") == 2)
assert(p:match("cab") == 2)
r, l, serror = p:match("dab")
assert(r == nil and l == 0 and serror == "dab")


-- associativity -> in this case the error thrown by p1 is only
--                  recovered when we have a left-associative operator
-- (p1 / %2) //{1} (p2 / %2) //{2} p3
-- left-associativity
-- ("a" //{1}  "b") //{2} "c"
p = m.Rec(m.Rec(m.P"a" + m.T(2), m.P"b" + m.T(2), 1), m.P"c", 2)
assert(p:match("abc") == 2)
r, l, serror = p:match("bac")
assert(r == nil and l == 0 and serror == "bac")
assert(p:match("cab") == 2)
r, l, serror = p:match("dab")
assert(r == nil and l == 0 and serror == "dab")


-- righ-associativity
-- "a" //{1}  ("b" //{2} "c")
p = m.Rec(m.P"a" + m.T(2), m.Rec(m.P"b" + m.T(2), m.P"c", 2), 1)
assert(p:match("abc") == 2)
r, l, serror = p:match("bac")
assert(r == nil and l == 2 and serror == "bac")
r, l, serror = p:match("cab")
assert(r == nil and l == 2 and serror == "cab")
r, l, serror = p:match("dab")
assert(r == nil and l == 2 and serror == "dab")



-- tests related to predicates
p = #m.T(1) + m.P"a"
r, l, serror = p:match("abc")
assert(r == nil and l == 1 and serror == "abc")

p = ##m.T(1) + m.P"a"
r, l, serror = p:match("abc")
assert(r == nil and l == 1 and serror == "abc")

p = -m.T(1) * m.P"a"
r, l, serror = p:match("abc")
assert(r == nil and l == 1 and serror == "abc")

p = -m.T(1) * m.P"a"
r, l, serror = p:match("bbc")
assert(r == nil and l == 1 and serror == "bbc")

p = -(-m.T(1)) * m.P"a"
r, l, serror = p:match("abc")
assert(r == nil and l == 1 and serror == "abc")

p = m.Rec(-m.T(22), m.P"a", 22)
r, l, serror = p:match("abc")
assert(r == nil and l == 0 and serror == "bc")

assert(p:match("bbc") == 1)

p = m.Rec(#m.T(22), m.P"a", 22)
assert(p:match("abc") == 1)

p = #m.Rec(m.T(22), m.P"a", 22)
assert(p:match("abc") == 1)

p = m.Rec(m.T(22), #m.P"a", 22)
assert(p:match("abc") == 1)

p = m.Rec(#m.T(22), m.P"a", 22)
r, l, serror = p:match("bbc")
assert(r == nil and l == 0 and serror == "bbc")


-- tests related to repetition
p = m.T(1)^0
r, l, serror = p:match("ab")
assert(r == nil and l == 1 and serror == "ab")

p = (m.P"a" + m.T(1))^0
r, l, serror = p:match("aa")
assert(r == nil and l == 1 and serror == "")


-- Bug reported by Matthew Allen
-- some optmizations performed by LPeg should not be
-- applied in case of labeled choices
p = m.Rec(m.P"A", m.P(true), 1) + m.P("B")
assert(p:match("B") == 2)

p = m.Rec(m.P"A", m.P(false), 1) + m.P("B")
assert(p:match("B") == 2)


--[[
S -> A //{1} 'a'
A -> B
B -> %1
]]
g = m.P{
	"S",
	S = m.Rec(m.V"A", m.P"a", 1),
	A = m.V"B",
	B = m.T(1),
}
assert(g:match("ab") == 2)
r, l, serror = g:match("bc")
assert(r == nil and l == 0 and serror == "bc")


--[[
S -> A 
A -> (B (';' / %{1}))*
B -> 'a'
]]
g = m.P{
	"S",
	S = m.V"A",
	A = m.P(m.V"B" * (";" + m.T(1)))^0,
	B = m.P'a',
}
assert(g:match("a;a;") == 5)

r, l, serror = g:match("a;a")
assert(r == nil and l == 1 and serror == "")


-- %1 //{1,3} %2 //{2} 'a'
p = m.Rec(m.Rec(m.T(1), m.T(2), 1, 3), m.P"a", 2)
assert(p:match("abc") == 2)

r, l, serror = p:match("")
assert(r == nil and l == 0 and serror == "")

p = m.Rec(m.T(1), m.Rec(m.T(2), m.P"a", 2), 1, 3)
assert(p:match("abc") == 2)

r, l, serror = p:match("")
assert(r == nil and l == 0 and serror == "")


-- Infinte Loop TODO: check the semantics
-- %1 //{1} %1 
p = m.Rec(m.T(1), m.T(1), 1)
--r, l, serror = p:match("ab")
--assert(r == nil and l == 1 and serror == "ab")

-- %1 //{1} 'a' (!. / %1) 
p = m.Rec(m.T(1), m.P"a" * (-m.P(1) + m.T(1)), 1)
r, l, serror = p:match("ab")
assert(r == nil and l == 0 and serror == "b")

r, l, serror = p:match("cd")
assert(r == nil and l == 0 and serror == "cd")

-- %1 //{1} . (!. / %1) 
p = m.Rec(m.T(1), m.P(1) * (-m.P(1) + m.T(1)), 1)
assert(p:match("abc") == 4)


-- testing the limit of labels
-- can only throw labels between 1 and 255
local r = pcall(m.Rec, m.P"b", m.P"a", 0)
assert(r == false)

local r = pcall(m.Rec, m.P"b", m.P"a", 256)
assert(r == false)

local r = pcall(m.Rec, m.P"b", m.P"a", -1)
assert(r == false)

local r = pcall(m.T, 0)
assert(r == false)

local r = pcall(m.T, 256)
assert(r == false)

local r = pcall(m.T, -1)
assert(r == false)


local r = m.Rec(m.P"b", m.P"a", 255)
assert(p:match("a") == 2)

p = m.T(255)
s = "abc"
r, l, serror = p:match(s) 
assert(r == nil and l == 255 and serror == "abc")



print("+")

--[[ grammar based on Figure 8 of paper submitted to SCP
S  -> S0 //{1} ID //{2} ID '=' Exp //{3} 'unsigned'* 'int' ID //{4} 'unsigned'* ID ID / %error
S0 -> S1 / S2 / &'int' %3
S1 -> &(ID '=') %2  /  &(ID !.) %1  /  &ID %4
S2 -> &('unsigned'+ ID) %4  /  & ('unsigned'+ 'int') %3 
]]
local sp = m.S" \t\n"^0
local eq = sp * m.P"="

g = m.P{
	"S",
	S = m.Rec(
         m.Rec(
            m.Rec(
               m.Rec(m.V"S0", m.V"ID", 1),
               m.V"ID" * eq * m.V"Exp", 2
               ),
            m.V"U"^0 * m.V"I" * m.V"ID", 3
            ),
         m.V"U"^0 * m.V"ID" * m.V"ID", 4) 
       + m.T(5), -- error
	S0 = m.V"S1"  +  m.V"S2"  +  #m.V"I" * m.T(3),
	S1 = #(m.V"ID" * eq) * m.T(2) + sp * #(m.V"ID" * -m.P(1)) * m.T(1) + #m.V"ID" * m.T(4),
	S2 = #(m.V"U"^1 * m.V"ID") * m.T(4)  +  #(m.V"U"^1 * m.V"I") * m.T(3),
	ID = sp * m.P"a",
	U = sp * m.P"unsigned",
	I = sp * m.P"int",
	Exp = sp * m.P"E",
}

local s = "a"
assert(g:match(s) == #s + 1) --1
s = "a = E"
assert(g:match(s) == #s + 1) --2
s = "int a"
assert(g:match(s) == #s + 1) --3
s = "unsigned int a"
assert(g:match(s) == #s + 1) --3
s = "unsigned a a"
assert(g:match(s) == #s + 1) --4

s = "b" 
r, l, serror = g:match(s)
assert(r == nil and l == 5 and serror == "b")

s = "unsigned" 
r, l, serror = g:match(s)
assert(r == nil and l == 5 and serror == s)

s = "unsigned a" 
r, l, serror = g:match(s)
assert(r == nil and l == 5 and serror == s)

s = "unsigned int" 
r, l, serror = g:match(s)
assert(r == nil and l == 5 and serror == s)


print("+")


local re = require 'relabelrec'

g = re.compile[['a' //{4,9} [a-z]
]]
assert(g:match("a") == 2)
r, l, serror = g:match("b")
assert(r == nil and l == 0 and serror == "b")

g = re.compile[['a' //{4,9} [a-f] //{5, 7} [a-z]
]]
assert(g:match("a") == 2)
r, l, serror = g:match("b")
assert(r == nil and l == 0 and serror == "b")

g = re.compile[[%{1} //{4,9} [a-z]
]]
r, l, serror = g:match("a")
assert(r == nil and l == 1 and serror == "a")


g = re.compile[[%{1} //{4,1} [a-f]
]]
assert(g:match("a") == 2)
r, l, serror = g:match("h")
assert(r == nil and l == 0 and serror == "h")

g = re.compile[[[a-f]%{9} //{4,9} [a-c]%{7} //{5, 7} [a-z] ]]
r, l, serror = g:match("a")
assert(r == nil and l == 0 and serror == "")
r, l, serror = g:match("aa")
assert(r == nil and l == 0 and serror == "")
assert(g:match("aaa") == 4)

r, l, serror = g:match("ad")
assert(r == nil and l == 0 and serror == "d")

r, l, serror = g:match("g")
assert(r == nil and l == 0 and serror == "g")


--[[ grammar based on Figure 8 of paper submitted to SCP
S  -> S0 //{1} ID //{2} ID '=' Exp //{3} 'unsigned'* 'int' ID //{4} 'unsigned'* ID ID / %error
S0 -> S1 / S2 / &'int' %3
S1 -> &(ID '=') %2  /  &(ID !.) %1  /  &ID %4
S2 -> &('unsigned'+ ID) %4  /  & ('unsigned'+ 'int') %3 
]]

g = re.compile([[
	S <- S0 //{1} ID //{2} ID %s* '=' Exp //{3} U* Int ID //{4} U ID ID / %{5}
  S0 <- S1 / S2 / &Int %{3}
  S1 <- &(ID %s* '=') %{2} / &(ID !.) %{1} / &ID %{4}
  S2 <- &(U+ ID) %{4} / &(U+ Int) %{3}
  ID <- %s* 'a' 
  U <- %s* 'unsigned'
  Int <- %s* 'int'
  Exp <- %s* 'E'
]])

local s = "a"
assert(g:match(s) == #s + 1) --1
s = "a = E"
assert(g:match(s) == #s + 1) --2
s = "int a"
assert(g:match(s) == #s + 1) --3
s = "unsigned int a"
assert(g:match(s) == #s + 1) --3
s = "unsigned a a"
assert(g:match(s) == #s + 1) --4
s = "b" 
r, l, serror = g:match(s)
assert(r == nil and l == 5 and serror == s)
s = "unsigned" 
r, l, serror = g:match(s)
assert(r == nil and l == 5 and serror == s)
s = "unsigned a" 
r, l, serror = g:match(s)
assert(r == nil and l == 5 and serror == s)
s = "unsigned int" 
r, l, serror = g:match(s)
assert(r == nil and l == 5 and serror == s)



local terror = { ['cmdSeq'] = "Missing ';' in CmdSeq",
                 ['ifExp'] = "Error in expresion of 'if'",
                 ['ifThen'] = "Error matching 'then' keyword",
                 ['ifThenCmdSeq'] = "Error matching CmdSeq of 'then' branch",
                 ['ifElseCmdSeq'] = "Error matching CmdSeq of 'else' branch",
                 ['ifEnd'] = "Error matching 'end' keyword of 'if'",
                 ['repeatCmdSeq'] = "Error matching CmdSeq of 'repeat'",
                 ['repeatUntil'] = "Error matching 'until' keyword",
                 ['repeatExp'] = "Error matching expression of 'until'",
                 ['assignOp'] = "Error matching ':='",
                 ['assignExp'] = "Error matching expression of assignment",
                 ['readName'] = "Error matching 'NAME' after 'read'",
                 ['writeExp'] = "Error matching expression after 'write'",
                 ['simpleExp'] = "Error matching 'SimpleExp'",
                 ['term'] = "Error matching 'Term'",
                 ['factor'] = "Error matching 'Factor'",
                 ['openParExp'] = "Error matching expression after '('",
                 ['closePar'] = "Error matching ')'",
                 ['undefined'] = "Undefined Error"}

g = re.compile([[
  Tiny       <- CmdSeq //{1} '' -> cmdSeq //{2} '' -> ifExp //{3} '' -> ifThen //{4} '' -> ifThenCmdSeq
                       //{5} '' -> ifElseCmdSeq  //{6}  '' -> ifEnd  //{7} '' -> repeatCmdSeq
                       //{8} '' -> repeatUntil  //{9} '' -> repeatExp  //{10} '' -> assignOp
                       //{11} '' -> assignExp  //{12} '' -> readName  //{13}  '' -> writeExp
                       //{14} '' -> simpleExp  //{15} '' -> term  //{16} '' -> factor
                       //{17} '' -> openParExp  //{18} '' -> closePar / '' -> undefined
  CmdSeq     <- (Cmd (SEMICOLON / %{1})) (Cmd (SEMICOLON / %{1}))*
  Cmd        <- IfCmd / RepeatCmd / ReadCmd / WriteCmd  / AssignCmd 
  IfCmd      <- IF  (Exp / %{2})  (THEN / %{3})  (CmdSeq / %{4})  (ELSE (CmdSeq / %{5}) / '') (END / %{6})
  RepeatCmd  <- REPEAT  (CmdSeq / %{7})  (UNTIL / %{8})  (Exp / %{9})
  AssignCmd  <- NAME  (ASSIGNMENT / %{10})  (Exp / %{11})
  ReadCmd    <- READ  (NAME / %{12})
  WriteCmd   <- WRITE  (Exp / %{13})
  Exp        <- SimpleExp  ((LESS / EQUAL) (SimpleExp / %{14}) / '')
  SimpleExp  <- Term  ((ADD / SUB)  (Term / %{15}))*
  Term       <- Factor ((MUL / DIV) (Factor / %{16}))*
  Factor     <- OPENPAR  (Exp / %{17})  (CLOSEPAR / %{18})  / NUMBER  / NAME
  ADD        <- Sp '+'
  ASSIGNMENT <- Sp ':='
  CLOSEPAR   <- Sp ')'
  DIV        <- Sp '/'
  IF         <- Sp 'if'
  ELSE       <- Sp 'else'
  END        <- Sp 'end'
  EQUAL      <- Sp '='
  LESS       <- Sp '<'
  MUL        <- Sp '*'
  NAME       <- !RESERVED Sp [a-z]+
  NUMBER     <- Sp [0-9]+
  OPENPAR    <- Sp '('
  READ       <- Sp 'read'
  REPEAT     <- Sp 'repeat'
  SEMICOLON  <- Sp ';'
  SUB        <- Sp '-'
  THEN       <- Sp 'then'
  UNTIL      <- Sp 'until'
  WRITE      <- Sp 'write'
	RESERVED   <- (IF / ELSE / END / READ / REPEAT / THEN / UNTIL / WRITE) ![a-z]+
  Sp         <- (%s / %nl)*	
]], terror)

s = [[
n := 5;]]
assert(g:match(s) == #s + 1) 

s = [[
n := 5;
f := 1;
repeat
  f := f * n;
  n := n - 1;
until (n < 1);
write f;]]
assert(g:match(s) == #s + 1) 

-- a ';' is missing in 'read a' 
s = [[
read a]]
assert(g:match(s) == terror['cmdSeq']) 


-- a ';' is missing in 'n := n - 1' 
s = [[
n := 5;
f := 1;
repeat
  f := f * n;
  n := n - 1
until (n < 1);
write f;]]
assert(g:match(s) == terror['cmdSeq']) 


-- IF expression 
s = [[
if a then a := a + 1; end;]]
assert(g:match(s) == #s + 1) 

-- IF expression 
s = [[
if a then a := a + 1; else write 2; end;]]
assert(g:match(s) == #s + 1) 

-- Error in expression of 'if'. 'A' is not a valida name
s = [[
if A then a := a + 1; else write 2; end;]]
assert(g:match(s) == terror['ifExp']) 

-- Error matching the 'then' keyword
s = [[
if a a := a + 1; else write 2; end;]]
assert(g:match(s) == terror['ifThen']) 

-- Error matching the CmdSeq inside of 'then' branch 
s = [[
if a then 3 := 2; else write 2; end;]]
assert(g:match(s) == terror['ifThenCmdSeq']) 

-- Error matching the CmdSeq inside of 'else' branch 
s = [[
if a then b := 2; else A := 2; end;]]
assert(g:match(s) == terror['ifElseCmdSeq']) 

-- Error matching 'end' of 'if' 
s = [[
if a then b := 2; else a := 2; 77;]]
assert(g:match(s) == terror['ifEnd']) 

-- Error matching the CmdSeq of 'repeat'
s = [[repeat
  F := f * n;
  n := n - 1;
until (n < 1);]]
assert(g:match(s) == terror['repeatCmdSeq']) 

-- Error matching 'until'
s = [[repeat
  f := f * n;
  n := n - 1;
88 (n < 1);]]
assert(g:match(s) == terror['repeatUntil']) 

-- Error matching expression of 'until'
s = [[repeat
  f := f * n;
  n := n - 1;
until ; (n < 1);]]
assert(g:match(s) == terror['repeatExp']) 

-- Error matching ':='
s = [[
f = f * n;]]
assert(g:match(s) == terror['assignOp']) 

-- Error matching expression of assignment
s = [[
f := A * n;]]
assert(g:match(s) == terror['assignExp']) 

-- Error matching 'name'
s = [[
read 2;]]
assert(g:match(s) == terror['readName']) 

-- Error matching expression after 'write'
s = [[
write [a] := 2;]]
assert(g:match(s) == terror['writeExp']) 

-- Error matching 'SimpleExp'
s = [[
a := a < A;]]
assert(g:match(s) == terror['simpleExp']) 

-- Error matching 'Term'
s = [[
a := a + A;]]
assert(g:match(s) == terror['term']) 

-- Error matching 'Factor'
s = [[
a := a * A;]]
assert(g:match(s) == terror['factor']) 

-- Error matching expression after '('
s = [[
a := (A);]]
assert(g:match(s) == terror['openParExp']) 

-- Error matching ')'
s = [[
a := (a];]]
assert(g:match(s) == terror['closePar']) 

-- Error undefined
s = [[
A := a;]]
assert(g:match(s) == terror['undefined']) 


print("+")


p = m.Rec("a", "b", 3) 
assert(p:match("a") == 2)
checkeqlab({nil, 0, "b"}, p:match("b"))
checkeqlab({nil, 0, "c"}, p:match("c"))

p = m.Rec(m.T(3), "b", 1) 
checkeqlab({nil, 3, "a"}, p:match("a"))
checkeqlab({nil, 3, "b"}, p:match("b"))

p = m.Rec(m.T(3), "b", 3) 
checkeqlab({nil, 0, "a"}, p:match("a"))
assert(p:match("b") == 2)

--[[
S -> (A //{128} (!c .)*) C
A -> a*b / %128
C -> c+
]]
g = m.P{
	"S",
	S = m.Rec(m.V"A", (-m.P"c" * m.P(1))^0, 128) * m.V"C",
	A = m.P"a"^0 * "b" + m.T(128),
	C = m.P"c"^1,
}

assert(g:match("abc") == 4)
assert(g:match("aabc") == 5)
assert(g:match("aadc") == 5)  
assert(g:match("dc") == 3)
checkeqlab({nil, 0, "bc"}, g:match("bbc"))
assert(g:match("xxc") == 4) 
assert(g:match("c") == 2)
checkeqlab({nil, 0, ""}, g:match("fail"))
checkeqlab({nil, 0, ""}, g:match("aaxx"))


--[[
S -> (A //{99} (!c .)*) C
A -> a+ (b / ^99) 
C -> c+
]]
g = m.P{
	"S",
	S = m.Rec(m.V"A", (-m.P"c" * m.P(1))^0, 99) * m.V"C",
	A = m.P"a"^1 * ("b" + m.T(99)),
	C = m.P"c"^1,
}

assert(g:match("abc") == 4)
assert(g:match("aabc") == 5)
assert(g:match("aadc") == 5)
checkeqlab({nil, 0, "bc"}, g:match("bc"))
checkeqlab({nil, 0, "bbc"}, g:match("bbc"))
checkeqlab({nil, 0, "b"}, g:match("abb"))
checkeqlab({nil, 0, ""}, g:match("axx"))
assert(g:match("accc") == 5)
assert(g:match("axxc") == 5)
checkeqlab({nil, 0, "c"}, g:match("c"))
checkeqlab({nil, 0, "fail"}, g:match("fail"))



-- Matthew's recovery example 
lpeg = m

local R, S, P, V = lpeg.R, lpeg.S, lpeg.P, lpeg.V
local C, Cc, Ct, Cmt = lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.Cmt
local T, Lc = lpeg.T, lpeg.Lc

local labels = {
  {"NoExp",     "no expression found"},
  {"Extra",     "extra characters found after the expression"},
  {"ExpTerm",   "expected a term after the operator"},
  {"ExpExp",    "expected an expression after the parenthesis"},
  {"MisClose",  "missing a closing ')' after the expression"},
}

local function labelindex(labname)
  for i, elem in ipairs(labels) do
    if elem[1] == labname then
      return i
    end
  end
  error("could not find label: " .. labname)
end

local errors = {}

local function expect(patt, labname)
  local i = labelindex(labname)
  function recorderror(input, pos)
    table.insert(errors, {i, pos})
    return true
  end
  return patt + Cmt("", recorderror) * T(i)
end

local num = R("09")^1 / tonumber
local op = S("+-*/")

local function compute(tokens)
  local result = tokens[1]
  for i = 2, #tokens, 2 do
    if tokens[i] == '+' then
      result = result + tokens[i+1]
    elseif tokens[i] == '-' then
      result = result - tokens[i+1]
    elseif tokens[i] == '*' then
      result = result * tokens[i+1]
    elseif tokens[i] == '/' then
      result = result / tokens[i+1]
    else
      error('unknown operation: ' .. tokens[i])
    end
  end
  return result
end

local g = P {
  "Exp",
  Exp = Ct(V"Term" * (C(op) * V"OpRecov")^0) / compute;
  OpRecov = m.Rec(V"Operand", Cc(0), labelindex("ExpTerm"));
  Operand = expect(V"Term", "ExpTerm");
  Term = num + V"Group";
  Group = "(" * V"InnerExp" * m.Rec(expect(")", "MisClose"), P"", labelindex("MisClose"));
  InnerExp = m.Rec(expect(V"Exp", "ExpExp"), (P(1) - ")")^0 * Cc(0), labelindex("ExpExp"));
}

g = expect(g, "NoExp") * expect(-P(1), "Extra")

local function eval(input)
  local result, label, suffix = g:match(input)
  if #errors == 0 then
    return result
  else
    local out = {}
    for i, err in ipairs(errors) do
      local pos = err[2]
      local msg = labels[err[1]][2]
      table.insert(out, "syntax error: " .. msg .. " (at index " .. pos .. ")")
    end
    errors = {}
    return nil, table.concat(out, "\n")
  end
end

print(eval "98-76*(54/32)")
--> 37.125

print(eval "(1+1-1*2/2")
--> syntax error: missing a closing ')' after the expression (at index 11)

print(eval "(1+)-1*(2/2)")
--> syntax error: expected a term after the operator (at index 4)

print(eval "(1+1)-1*(/2)")
--> syntax error: expected an expression after the parenthesis (at index 10)

print(eval "1+(1-(1*2))/2x")
--> syntax error: extra chracters found after the expression (at index 14)

print(eval "-1+(1-(1*2))/2")
--> syntax error: no expression found (at index 1)

print(eval "(1+1-1*(2/2+)-():")
--> syntax error: expected a term after the operator (at index 13)
--> syntax error: expected an expression after the parenthesis (at index 16)
--> syntax error: missing a closing ')' after the expression (at index 17)
--> syntax error: extra characters found after the expression (at index 


print("+")

local g = m.P{
	"S",
	S = V"End" + V'A' * V'S',
	A = P'a' + T(1),
	End = P"." * (-P(1) + T(2)),
}

assert(g:match("a.") == 3)
assert(g:match("aa.") == 4)
assert(g:match(".") == 2)
checkeqlab({nil, 1, "ba."}, g:match("ba."))
checkeqlab({nil, 1, "ba."}, g:match("aba."))
checkeqlab({nil, 1, "cba."}, g:match("cba."))
checkeqlab({nil, 2, "a"}, g:match("a.a"))


local g2 = m.P{
	"S",
	S = m.Rec(g, V"B", 1),
	B = P'b'^1 + T(3)
}

assert(g2:match("a.") == 3)
assert(g2:match("aa.") == 4)
assert(g2:match(".") == 2)
assert(g2:match("ba.") == 4)
assert(g2:match("aba.") == 5)
checkeqlab({nil, 3, "cba."}, g2:match("cba."))
checkeqlab({nil, 2, "a"}, g2:match("a.a"))

local g3 = m.P{
	"S",
	S = m.Rec(g2, V"C", 2, 3),
	C = P'c'^1 + T(4)
}

assert(g3:match("a.") == 3)
assert(g3:match("aa.") == 4)
assert(g3:match(".") == 2)
assert(g3:match("ba.") == 4)
assert(g3:match("aba.") == 5)
assert(g3:match("cba.") == 5)
checkeqlab({nil, 4, "a"}, g3:match("a.a"))
checkeqlab({nil, 4, "dc"}, g3:match("dc"))
checkeqlab({nil, 4, "d"}, g3:match(".d"))


-- testing more captures
local g = re.compile[[
	S <- ( %s* &. {A} )* 
  A <- [0-9]+ / %{5}
]]

checkeq({"523", "624", "346", "888"} , {g:match("523 624  346\n888")}) 
checkeq({nil, 5, "a 123"}, {g:match("44 a 123")})

local g2 = m.Rec(g, ((-m.R("09") * m.P(1))^0) / "58", 5)

checkeq({"523", "624", "346", "888"} , {g2:match("523 624  346\n888")}) 
checkeq({"44", "a ", "58", "123"}, {g2:match("44 a 123")})


local g = re.compile[[
	S <- ( %s* &. A )* 
  A <- {[0-9]+} / %{5}
]]

checkeq({"523", "624", "346", "888"} , {g:match("523 624  346\n888")}) 
checkeq({nil, 5, "a 123"}, {g:match("44 a 123")})

local g2 = m.Rec(g, ((-m.R("09") * m.P(1))^0) / "58", 5)

checkeq({"523", "624", "346", "888"} , {g2:match("523 624  346\n888")}) 
checkeq({"44", "58", "123"}, {g2:match("44 a 123")})


local R, S, P, V = lpeg.R, lpeg.S, lpeg.P, lpeg.V
local C, Cc, Ct, Cmt = lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.Cmt
local T, Lc, Rec = lpeg.T, lpeg.Lc, lpeg.Rec

local labels = {
  {"NoExp",     "no expression found"},
  {"Extra",     "extra characters found after the expression"},
  {"ExpTerm",   "expected a term after the operator"},
  {"ExpExp",    "expected an expression after the parenthesis"},
  {"MisClose",  "missing a closing ')' after the expression"},
}

local function labelindex(labname)
  for i, elem in ipairs(labels) do
    if elem[1] == labname then
      return i
    end
  end
  error("could not find label: " .. labname)
end

local errors = {}

local function expect(patt, labname, recpatt)
  local i = labelindex(labname)
  function recorderror(input, pos)
    table.insert(errors, {i, pos})
    return true
  end
	if not recpatt then recpatt = P"" end
  --return Rec(patt, Cmt("", recorderror) * recpatt)
  return patt + T(i)
end

local num = R("09")^1 / tonumber
local op = S("+-*/")

local function compute(tokens)
  local result = tokens[1]
  for i = 2, #tokens, 2 do
    if tokens[i] == '+' then
      result = result + tokens[i+1]
    elseif tokens[i] == '-' then
      result = result - tokens[i+1]
    elseif tokens[i] == '*' then
      result = result * tokens[i+1]
    elseif tokens[i] == '/' then
      result = result / tokens[i+1]
    else
      error('unknown operation: ' .. tokens[i])
    end
  end
  return result
end


local g = P {
"Exp",
Exp = Ct(V"Term" * (C(op) * V"Operand")^0) / compute,
Operand = expect(V"Term", "ExpTerm"),
Term = num,
}
local rg = Rec(g, Cc(3), labelindex("ExpTerm"))
                 
local function eval(input)
  local result, label, suffix = rg:match(input)
  if #errors == 0 then
    return result
  else
    local out = {}
    for i, err in ipairs(errors) do
      local pos = err[2]
      local msg = labels[err[1]][2]
      table.insert(out, "syntax error: " .. msg .. " (at index " .. pos .. ")")
    end
    errors = {}
    return nil, table.concat(out, "\n")
  end
end

assert(eval("98-76*54/32") == 37.125)
--> 37.125

assert(eval("1+") == 4)
--> syntax error: expected a term after the operator (at index 3)


print("OK")
