local m = require 'lpeglabel'

local p = m.T(1, 2, 5)
assert(p:match("abc") == nil)

-- throws a label that is not caught by ordinary choice
p = m.T(1) + m.P"a"
assert(p:match("abc") == nil)

-- again throws a label that is not caught by ordinary choice
local g = m.P{
	"S",
	S = m.V"A" + m.V"B",
	A = m.T(1),
	B = m.P"a"
}
assert(g:match("abc") == nil)

-- throws a label that is not caught by labeled choice
p = m.Lc(m.T(2), m.P"a", 1, 3)
assert(p:match("abc") == nil)

-- modifies previous pattern
-- adds another labeled choice to catch label "2"
p = m.Lc(p, m.P"a", 2)
assert(p:match("abc") == 2)

-- throws a label that is caught by labeled choice
p = m.Lc(m.T(25), m.P"a", 25)
assert(p:match("abc") == 2)
assert(p:match("bola") == nil)

-- labeled choice does not catch "fail" by default
p = m.Lc(m.P"b", m.P"a", 1)
assert(p:match("abc") == nil)
assert(p:match("bola") == 2)

-- "fail" is label "0"
-- labeled choice can catch "fail"
p = m.Lc(m.P"b", m.P"a", 0)
assert(p:match("abc") == 2)
assert(p:match("bola") == 2)

-- "fail" is label "0"
-- labeled choice catches "fail" or "3"
p = m.Lc(m.P"a" * m.T(3), (m.P"a" + m.P"b"), 0, 3)
assert(p:match("abc") == 2)
assert(p:match("bac") == 2)
assert(p:match("cab") == nil)

-- tests related to predicates
p = #m.T(1) + m.P"a"
assert(p:match("abc") == nil)

p = ##m.T(1) + m.P"a"
assert(p:match("abc") == nil)

p = #m.T(0) * m.P"a"
assert(p:match("abc") == fail)

p = #m.T(0) + m.P"a"
assert(p:match("abc") == 2)

p = -m.T(1) * m.P"a"
assert(p:match("abc") == nil)

p = -(-m.T(1)) * m.P"a"
assert(p:match("abc") == nil)

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
assert(p:match("ab") == nil)

p = m.T(0)^0
assert(p:match("ab") == 1)

p = (m.P"a" + m.T(1))^0
assert(p:match("aa") == nil)

p = (m.P"a" + m.T(0))^0
assert(p:match("aa") == 3)


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
assert(g:match("bc") == nil)


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
assert(g:match("a;a") == nil)


-- %1 /{1,3} %2 /{2} 'a'
p = m.Lc(m.Lc(m.T(1), m.T(2), 1, 3), m.P"a", 2)
assert(p:match("abc") == 2)
assert(p:match("") == nil)

p = m.Lc(m.T(1), m.Lc(m.T(2), m.P"a", 2), 1, 3)
assert(p:match("abc") == 2)
assert(p:match("") == nil)

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
       + m.T(5),
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
assert(g:match(s) == nil) 
s = "unsigned" 
assert(g:match(s) == nil) 
s = "unsigned a" 
assert(g:match(s) == nil) 
s = "unsigned int" 
assert(g:match(s) == nil) 


print("+")

local re = require 'relabel'

g = re.compile[['a' /{4,9} [a-z]
]]
assert(g:match("a") == 2)
assert(g:match("b") == nil)

g = re.compile[['a' /{4,9} [a-f] /{5, 7} [a-z]
]]
assert(g:match("a") == 2)
assert(g:match("b") == nil)

g = re.compile[[%{1} /{4,9} [a-z]
]]
assert(g:match("a") == nil)

g = re.compile[[%{1} /{4,1} [a-f]
]]
assert(g:match("a") == 2)
assert(g:match("h") == nil)

g = re.compile[[[a-f]%{15, 9} /{4,9} [a-c]%{7} /{5, 7} [a-z] ]]
assert(g:match("a") == 2)
assert(g:match("c") == 2)
assert(g:match("d") == nil)
assert(g:match("g") == nil)

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
assert(g:match(s) == nil) 
s = "unsigned" 
assert(g:match(s) == nil) 
s = "unsigned a" 
assert(g:match(s) == nil) 
s = "unsigned int" 
assert(g:match(s) == nil) 

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


print("OK")
