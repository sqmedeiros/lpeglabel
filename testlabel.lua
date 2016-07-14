local m = require 'lpeglabel'

local p, r, l, s, serror

local function checkeqlab (x, ...)
  y = { ... }
  assert(type(x) == "table")
  assert(#x == #y)
  for i = 1, 3 do
    assert(x[i] == y[i])
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

-- throws a label that is not caught by labeled choice
p = m.Lc(m.T(2), m.P"a", 1, 3)
r, l, serror = p:match(s)
assert(r == nil and l == 2 and serror == "abc")

-- modifies previous pattern
-- adds another labeled choice to catch label "2"
p = m.Lc(p, m.P"a", 2)
assert(p:match(s) == 2)

-- throws a label that is caught by labeled choice
p = m.Lc(m.T(25), m.P"a", 25)
assert(p:match(s) == 2)

-- "fail" is label "0"
-- throws the "fail" label that is not caught by the labeled choice
s = "bola"
r, l, serror = p:match("bola")
assert(r == nil and l == 0 and serror == "bola")

-- labeled choice does not catch "fail" by default
p = m.Lc(m.P"b", m.P"a", 1)

r, l, serror = p:match("abc") 
assert(r == nil and l == 0 and serror == "abc")

assert(p:match("bola") == 2)

-- labeled choice can catch "fail"
p = m.Lc(m.P"b", m.P"a", 0)
assert(p:match("abc") == 2)
assert(p:match("bola") == 2)

-- "fail" is label "0"
-- labeled choice catches "fail" or "3"
p = m.Lc(m.P"a" * m.T(3), (m.P"a" + m.P"b"), 0, 3)
assert(p:match("abc") == 2)
assert(p:match("bac") == 2)

r, l, serror = p:match("cab")
assert(r == nil and l == 0 and serror == "cab")

-- tests related to predicates
p = #m.T(1) + m.P"a"
r, l, serror = p:match("abc")
assert(r == nil and l == 1 and serror == "abc")

p = ##m.T(1) + m.P"a"
r, l, serror = p:match("abc")
assert(r == nil and l == 1 and serror == "abc")

p = #m.T(0) * m.P"a"
assert(p:match("abc") == fail)

p = #m.T(0) + m.P"a"
assert(p:match("abc") == 2)

p = -m.T(1) * m.P"a"
r, l, serror = p:match("abc")
assert(r == nil and l == 1 and serror == "abc")

p = -(-m.T(1)) * m.P"a"
r, l, serror = p:match("abc")
assert(r == nil and l == 1 and serror == "abc")

p = -m.T(0) * m.P"a"
assert(p:match("abc") == 2)

p = -m.T(0) + m.P"a"
assert(p:match("abc") == 1)

p = -(-m.T(0)) + m.P"a"
assert(p:match("abc") == 2)

p = m.Lc(-m.T(22), m.P"a", 22)
assert(p:match("abc") == 2)

p = m.Lc(-m.T(0), m.P"a", 0)
assert(p:match("abc") == 1)

p = m.Lc(#m.T(22), m.P"a", 22)
assert(p:match("abc") == 2)

p = m.Lc(#m.T(0), m.P"a", 0)
assert(p:match("abc") == 2)

-- tests related to repetition
p = m.T(1)^0
r, l, serror = p:match("ab")
assert(r == nil and l == 1 and serror == "ab")

p = m.T(0)^0
assert(p:match("ab") == 1)

p = (m.P"a" + m.T(1))^0
r, l, serror = p:match("aa")
assert(r == nil and l == 1 and serror == "")

p = (m.P"a" + m.T(0))^0
assert(p:match("aa") == 3)

-- Bug reported by Matthew Allen
-- some optmizations performed by LPeg should not be
-- applied in case of labeled choices
p = m.Lc(m.P"A", m.P(true), 1) + m.P("B")
assert(p:match("B") == 2)

p = m.Lc(m.P"A", m.P(false), 1) + m.P("B")
assert(p:match("B") == 2)


--[[
S -> A /{1} 'a'
A -> B
B -> %1
]]
g = m.P{
	"S",
	S = m.Lc(m.V"A", m.P"a", 1),
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


-- %1 /{1,3} %2 /{2} 'a'
p = m.Lc(m.Lc(m.T(1), m.T(2), 1, 3), m.P"a", 2)
assert(p:match("abc") == 2)

r, l, serror = p:match("")
assert(r == nil and l == 0 and serror == "")

p = m.Lc(m.T(1), m.Lc(m.T(2), m.P"a", 2), 1, 3)
assert(p:match("abc") == 2)

r, l, serror = p:match("")
assert(r == nil and l == 0 and serror == "")

-- testing the limit of labels
p = m.T(0)
s = "abc"
r, l, serror = p:match(s) 
assert(r == nil and l == 0 and serror == "abc")

p = m.T(255)
s = "abc"
r, l, serror = p:match(s) 
assert(r == nil and l == 255 and serror == "abc")

local r = pcall(m.T, -1)
assert(r == false)

local r = pcall(m.T, 256)
assert(r == false)


print("+")

--[[ grammar based on Figure 8 of paper submitted to SCP
S  -> S0 /{1} ID /{2} ID '=' Exp /{3} 'unsigned'* 'int' ID /{4} 'unsigned'* ID ID / %error
S0 -> ID S1 / 'unsigned' S2 / 'int' %3
S1 -> '=' %2  /  !. %1  /  ID %4
S2 -> 'unsigned' S2  /  ID %4  /  'int' %3 
]]

local sp = m.S" \t\n"^0
local eq = sp * m.P"="

g = m.P{
	"S",
	S = m.Lc(
         m.Lc(
            m.Lc(
               m.Lc(m.V"S0", m.V"ID" * (m.P(1) + ""), 1),
               m.V"ID" * eq * m.V"Exp", 2
               ),
            m.V"U"^0 * m.V"I" * m.V"ID", 3
            ),
         m.V"U"^0 * m.V"ID" * m.V"ID", 4) 
       + m.T(5), -- error
	S0 = m.V"ID" * m.V"S1"  +  m.V"U" * m.V"S2"  +  m.V"I" * m.T(3),
	S1 = eq * m.T(2) + sp * -m.P(1) * m.T(1) + m.V"ID" * m.T(4),
	S2 = m.V"U" * m.V"S2"  +   m.V"ID" * m.T(4)  +   m.V"I" * m.T(3),
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

local re = require 'relabel'

g = re.compile[['a' /{4,9} [a-z]
]]
assert(g:match("a") == 2)
r, l, serror = g:match("b")
assert(r == nil and l == 0 and serror == "b")

g = re.compile[['a' /{4,9} [a-f] /{5, 7} [a-z]
]]
assert(g:match("a") == 2)
r, l, serror = g:match("b")
assert(r == nil and l == 0 and serror == "b")

g = re.compile[[%{1} /{4,9} [a-z]
]]
r, l, serror = g:match("a")
assert(r == nil and l == 1 and serror == "a")


g = re.compile[[%{1} /{4,1} [a-f]
]]
assert(g:match("a") == 2)
r, l, serror = g:match("h")
assert(r == nil and l == 0 and serror == "h")

g = re.compile[[[a-f]%{9} /{4,9} [a-c]%{7} /{5, 7} [a-z] ]]
assert(g:match("a") == 2)
assert(g:match("c") == 2)
r, l, serror = g:match("d")
assert(r == nil and l == 0 and serror == "d")
r, l, serror = g:match("g")
assert(r == nil and l == 0 and serror == "g")

--[[ grammar based on Figure 8 of paper submitted to SCP
S  -> S0 /{1} ID /{2} ID '=' Exp /{3} 'unsigned'* 'int' ID /{4} 'unsigned'* ID ID / %error
S0 -> ID S1 / 'unsigned' S2 / 'int' %3
S1 -> '=' %2  /  !. %1  /  ID %4
S2 -> 'unsigned' S2  /  ID %4  /  'int' %3 
]]


g = re.compile([[
	S <- S0 /{1} ID /{2} ID %s* '=' Exp /{3} U* Int ID /{4} U ID ID /{0} %{5}
  S0 <- ID S1 / U S2 / Int %{3}
  S1 <- %s* '=' %{2} / !. %{1} / ID %{4}
  S2 <- U S2 / ID %{4} / Int %{3}
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
  Tiny       <- CmdSeq /{1} '' -> cmdSeq /{2} '' -> ifExp /{3} '' -> ifThen /{4} '' -> ifThenCmdSeq
                       /{5} '' -> ifElseCmdSeq  /{6}  '' -> ifEnd  /{7} '' -> repeatCmdSeq
                       /{8} '' -> repeatUntil  /{9} '' -> repeatExp  /{10} '' -> assignOp
                       /{11} '' -> assignExp  /{12} '' -> readName  /{13}  '' -> writeExp
                       /{14} '' -> simpleExp  /{15} '' -> term  /{16} '' -> factor
                       /{17} '' -> openParExp  /{18} '' -> closePar /{0} '' -> undefined
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


-- test recovery operator
p = m.Rec("a", "b") 
assert(p:match("a") == 2)
assert(p:match("b") == 2)
checkeqlab({nil, 0, "c"}, p:match("c"))

p = m.Rec("a", "b", 3) 
assert(p:match("a") == 2)
checkeqlab({nil, 0, "b"}, p:match("b"))
checkeqlab({nil, 0, "c"}, p:match("c"))

p = m.Rec(m.T(3), "b") 
checkeqlab({nil, 3, "a"}, p:match("a"))
checkeqlab({nil, 3, "b"}, p:match("b"))

p = m.Rec(m.T(3), "b", 3) 
checkeqlab({nil, 0, "a"}, p:match("a"))
assert(p:match("b") == 2)

--[[
S -> (A //{fail} (!c .)*) C
A -> a*b 
C -> c+
]]
g = m.P{
	"S",
	S = m.Rec(m.V"A", (-m.P"c" * m.P(1))^0) * m.V"C",
	A = m.P"a"^0 * "b",
	C = m.P"c"^1,
}

assert(g:match("abc") == 4)
assert(g:match("aabc") == 5)
assert(g:match("aadc") == 5)
assert(g:match("bc") == 3)
checkeqlab({nil, 0, "bc"}, g:match("bbc"))
assert(g:match("xxc") == 4)
assert(g:match("c") == 2)
checkeqlab({nil, 0, ""}, g:match("fail"))

print("OK")

