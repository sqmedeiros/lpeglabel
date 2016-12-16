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


local labelCode = {}
for k, v in ipairs(terror) do 
	labelCode[v.l] = k
end

re.setlabels(labelCode)

local g = re.compile[[
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
  ErrSemi      <- %{errSemi}
	ErrExpIf     <- %{errExpIf}
	ErrThen      <- %{errThen}
	ErrCmdSeq1   <- %{errCmdSeq1}
	ErrCmdSeq2   <- %{errCmdSeq2}
	ErrEnd       <- %{errEnd}
	ErrCmdSeqRep <- %{errCmdSeqRep}
	ErrUntil     <- %{errUntil}
	ErrExpRep    <- %{errExpRep}
	ErrAssignOp  <- %{errAssignOp}
	ErrExpAssign <- %{errExpAssign}
	ErrReadName  <- %{errReadName}
	ErrWriteExp  <- %{errWriteExp}
	ErrSimpExp   <- %{errSimpExp}
	ErrTerm      <- %{errTerm}
	ErrFactor    <- %{errFactor}
	ErrExpFac    <- %{errExpFac}
	ErrClosePar  <- %{errClosePar}
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
]]


local function mymatch(g, s)
	local r, e, sfail = g:match(s)
  if not r then
    local line, col = re.calcline(s, #s - #sfail)
    local msg = "Error at line " .. line .. " (col " .. col .. "): "
		return r, msg .. terror[e].msg
	end 
	return r
end

local s = [[
n := 5;
f := 1;
repeat
  f := f + n;
  n := n - 1
until (n < 1);
write f;]]
print(mymatch(g, s))

s = [[
n := 5;
f := 1;
repeat
  f := f + n;
  n := n - 1;
until (n < 1);
read ;]]
print(mymatch(g, s))

s = [[
if a < 1 then
  b := 2;
else
  b := 3;]]
print(mymatch(g, s))

s = [[
n := 5;
f := 1;
repeat
  f := f + n;
  n := n - 1;
untill (n < 1);
]]
print(mymatch(g, s))

s = [[
n := 5;
f := 1;
repeat
  f := f + n;
  n := n - 1;
3 (n < 1);
]]
print(mymatch(g, s))

print(mymatch(g, "a : 2"))
print(mymatch(g, "a := (2"))

