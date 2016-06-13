local re = require 'relabel'

local terror = {}

local function newError(l, msg)
	table.insert(terror, { l = l, msg = msg} )
end

newError("errSemi", "Error: missing ';'")  
newError("errExpIf", "Error: expected expression after 'if'") 
newError("errThen", "Error: expected 'then' keyword") 
newError("errCmdSeq1", "Error: expected at least a command after 'then'") 
newError("errCmdSeq2", "Error: expected at least a command after 'else'") 
newError("errEnd", "Error: expected 'end' keyword") 
newError("errCmdSeqRep", "Error: expected at least a command after 'repeat'") 
newError("errUntil", "Error: expected 'until' keyword") 
newError("errExpRep", "Error: expected expression after 'until'") 
newError("errAssignOp", "Error: expected ':=' in assigment") 
newError("errExpAssign", "Error: expected expression after ':='") 
newError("errReadName", "Error: expected an identifier after 'read'") 
newError("errWriteExp", "Error: expected expression after 'write'") 
newError("errSimpExp", "Error: expected '(', ID, or number after '<' or '='")
newError("errTerm", "Error: expected '(', ID, or number after '+' or '-'")
newError("errFactor", "Error: expected '(', ID, or number after '*' or '/'")
newError("errExpFac", "Error: expected expression after '('")
newError("errClosePar", "Error: expected ')' after expression")

local line

local function incLine()
	line = line + 1
	return true
end

local function countLine(s, i)
	line = 1
	local p = re.compile([[
		S <- (%nl -> incLine  / .)*
	]], { incLine = incLine}) 
	p:match(s:sub(1, i))
	return true
end

local labelCode = {}
for k, v in ipairs(terror) do 
	labelCode[v.l] = k
end

re.setlabels(labelCode)

local g = re.compile([[
  Tiny         <- CmdSeq  
  CmdSeq       <- (Cmd (SEMICOLON / ErrSemi)) (Cmd (SEMICOLON / ErrSemi))*
  Cmd          <- IfCmd / RepeatCmd / ReadCmd / WriteCmd  / AssignCmd 
  IfCmd        <- IF (Exp / ErrExpIf)  (THEN / ErrThen)  (CmdSeq / ErrCmdSeq1)  (ELSE (CmdSeq / ErrCmdSeq2)  / '') (END / ErrEnd)
  RepeatCmd    <- REPEAT  (CmdSeq / ErrCmdSeqRep)  (UNTIL / ErrUntil)  (Exp / ErrExpRep)
  AssignCmd    <- NAME  (ASSIGNMENT / ErrAssignOp)  (Exp / ErrExpAssign)
  ReadCmd      <- READ  (NAME / ErrReadName)
  WriteCmd     <- WRITE  (Exp / ErrWriteExp)
  Exp          <- SimpleExp  ((LESS / EQUAL) (SimpleExp / ErrSimpExp) / '')
  SimpleExp    <- Term  ((ADD / SUB)  (Term / ErrTerm))*
  Term         <- Factor  ((MUL / DIV)  (Factor / ErrFactor))*
  Factor       <- OPENPAR  (Exp / ErrExpFac)  (CLOSEPAR / ErrClosePar)  / NUMBER  / NAME
  ErrSemi      <- ErrCount %{errSemi}
	ErrExpIf     <- ErrCount %{errExpIf}
	ErrThen      <- ErrCount %{errThen}
	ErrCmdSeq1   <- ErrCount %{errCmdSeq1}
	ErrCmdSeq2   <- ErrCount %{errCmdSeq2}
	ErrEnd       <- ErrCount %{errEnd}
	ErrCmdSeqRep <- ErrCount %{errCmdSeqRep}
	ErrUntil     <- ErrCount %{errUntil}
	ErrExpRep    <- ErrCount %{errExpRep}
	ErrAssignOp  <- ErrCount %{errAssignOp}
	ErrExpAssign <- ErrCount %{errExpAssign}
	ErrReadName  <- ErrCount %{errReadName}
	ErrWriteExp  <- ErrCount %{errWriteExp}
	ErrSimpExp   <- ErrCount %{errSimpExp}
	ErrTerm      <- ErrCount %{errTerm}
	ErrFactor    <- ErrCount %{errFactor}
	ErrExpFac    <- ErrCount %{errExpFac}
	ErrClosePar  <- ErrCount %{errClosePar}
	ErrCount     <- '' => countLine 
  ADD          <- Sp '+'
  ASSIGNMENT   <- Sp ':='
  CLOSEPAR     <- Sp ')'
  DIV          <- Sp '/'
  IF           <- Sp 'if'
  ELSE         <- Sp 'else'
  END          <- Sp 'end'
  EQUAL        <- Sp '='
  LESS         <- Sp '<'
  MUL          <- Sp '*'
  NAME         <- Sp !RESERVED [a-z]+
  NUMBER       <- Sp [0-9]+
  OPENPAR      <- Sp '('
  READ         <- Sp 'read'
  REPEAT       <- Sp 'repeat'
  SEMICOLON    <- Sp ';'
  SUB          <- Sp '-'
  THEN         <- Sp 'then'
  UNTIL        <- Sp 'until'
  WRITE        <- Sp 'write'
	RESERVED     <- (IF / ELSE / END / READ / REPEAT / THEN / UNTIL / WRITE) ![a-z]+
  Sp           <- %s*	
]], { countLine = countLine })


local function printError(n, e)
	assert(n == nil)
	print("Line " .. line .. ": " .. terror[e].msg)
end

local s = [[
n := 5;
f := 1;
repeat
  f := f + n;
  n := n - 1
until (n < 1);
write f;]]
printError(g:match(s))

s = [[
n := 5;
f := 1;
repeat
  f := f + n;
  n := n - 1;
until (n < 1);
read ;]]
printError(g:match(s))

s = [[
if a < 1 then
  b := 2;
else
  b := 3;]]
printError(g:match(s))

s = [[
n := 5;
f := 1;
repeat
  f := f + n;
  n := n - 1;
untill (n < 1);
]]
printError(g:match(s))

s = [[
n := 5;
f := 1;
repeat
  f := f + n;
  n := n - 1;
3 (n < 1);
]]
printError(g:match(s))

printError(g:match("a : 2"))
printError(g:match("a := (2"))


