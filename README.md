<p align="center"><img src="https://github.com/sqmedeiros/lpeglabel/raw/master/lpeglabel-logo.png" alt="LPegLabel" width="150px"></p>

## LPegLabel - Parsing Expression Grammars (with Labels) for Lua 

---

### Introduction

LPegLabel is a conservative extension of the
[LPeg](http://www.inf.puc-rio.br/~roberto/lpeg)
library that provides an implementation of Parsing
Expression Grammars (PEGs) with labeled failures. 
Labels can be used to signal different kinds of errors
and to specify which recovery pattern should handle a
given label. Labels can also be combined with the standard
patterns of LPeg.

This document describes the new functions available
in LpegLabel and presents some examples of usage.

In LPegLabel, the result of an unsuccessful matching
is a triple **nil, lab, sfail**, where **lab**
is the label associated with the failure, and
**sfail** is the suffix input being matched when
**lab** was thrown. 

With labeled failures it is possible to distinguish
between a regular failure and an error. Usually, a
regular failure is produced when the matching of a
character fails, and it is caught by an ordered choice.
An error, by its turn, is produced by the throw operator
and may be caught by the recovery operator. 
 
Below there is a brief summary of the new functions provided by LpegLabel: 

<table border="1">
<tbody><tr><td><b>Function</b></td><td><b>Description</b></td></tr>
<tr><td><a href="#f-t"><code>lpeglabelrec.T (l)</code></a></td>
  <td>Throws a label <code>l</code> to signal an error</td></tr>
<tr><td><a href="#f-rec"><code>lpeglabelrec.Rec (p1, p2, l1 [, l2, ..., ln])</code></a></td>
  <td>Specifies a recovery pattern <code>p2</code> for <code>p1</code>,
 when the matching of <code>p1</code> gives one of the labels l1, ..., ln.</td></tr>
<tr><td><a href="#re-t"><code>%{l}</code></a></td>
  <td>Syntax of <em>relabelrec</em> module. Equivalent to <code>lpeglabelrec.T(l)</code>
      </td></tr>
<tr><td><a href="#re-rec"><code>p1 //{l1 [, l2, ..., ln} p2</code></a></td>
  <td>Syntax of <em>relabelrec</em> module. Equivalent to <code>lpeglabelrec.Rec(p1, p2, l1, ..., ln)</code>
      </td></tr>
<tr><td><a href="#re-line"><code>relabelrec.calcline(subject, i)</code></a></td>
  <td>Calculates line and column information regarding position <i>i</i> of the subject</code>
      </td></tr>
<tr><td><a href="#re-setl"><code>relabelrec.setlabels (tlabel)</code></a></td>
  <td>Allows to specicify a table with mnemonic labels. 
      </td></tr>
</tbody></table>


### Functions


#### <a name="f-t"></a><code>lpeglabelrec.T(l)</code>


Returns a pattern that throws the label `l`.
A label must be an integer between 1 and 255.


#### <a name="f-rec"></a><code>lpeglabelrec.Rec(p1, p2, l1, ..., ln)</code>

Returns a *recovery pattern*.
If the matching of `p1` gives one of the labels `l1, ..., ln`,
then the matching of `p2` is tried from the failure position of `p1`.
Otherwise, the result of the matching of `p1` is the pattern's result.



#### <a name="f-rec"></a><code>lpeglabel.Rec(p1, p2 [, l1, ..., ln])</code>

The *recovery operator* is similar to labeled order choice except
that the matching of `p2` is tried from the failure position of `p1`.

If no label is provided, the regular PEG failure is caught
i.e. `lpeg.Rec(p1, p2)` is equivalent to `lpeg.Rec(p1, p2, 0)`.


#### <a name="re-t"></a><code>%{l}</code>

Syntax of *relabelrec* module. Equivalent to `lpeg.T(l)`.


#### <a name="re-lc"></a><code>p1 //{l1, ..., ln} p2</code>

Syntax of *relabelrec* module. Equivalent to `lpeglabelrec.Rec(p1, p2, l1, ..., ln)`.

The `//{}` operator is left-associative. 



#### <a name="re-line"></a><code>relabelrec.calcline (subject, i)</code>

Returns line and column information regarding position <i>i</i> of the subject.


#### <a name="re-setl"></a><code>relabelrec.setlabels (tlabel)</code>

Allows to specicify a table with labels. They keys of
`tlabel` must be integers between 1 and 255,
and the associated values should be strings.


### Examples

Below there a few examples of usage of LPegLabel.
The code of these and of other examples is available
in the *examples* directory. 


#### Matching a list of identifiers separated by commas

The following example defines a grammar that matches
a list of identifiers separated by commas. A label
is thrown when there is an error matching an identifier
or a comma.

We use function `newError` to store error messages in a
table and to return the index associated with each error message.


```lua
local m = require'lpeglabelrec'
local re = require'relabelrec'

local terror = {}

local function newError(s)
  table.insert(terror, s)
  return #terror
end

local errUndef = newError("undefined")
local errId = newError("expecting an identifier")
local errComma = newError("expecting ','")

local g = m.P{
  "S",
  S = m.V"Id" * m.V"List",
  List = -m.P(1) + (m.V"Comma" + m.T(errComma)) * (m.V"Id" + m.T(errId)) * m.V"List",
  Id = m.V"Sp" * m.R'az'^1,
  Comma = m.V"Sp" * ",",
  Sp = m.S" \n\t"^0,
}

function mymatch (g, s)
  local r, e, sfail = g:match(s)
  if not r then
    local line, col = re.calcline(s, #s - #sfail)
    local msg = "Error at line " .. line .. " (col " .. col .. "): "
    return r, msg .. terror[e] .. " before '" .. sfail .. "'"
  end
  return r
end
  
print(mymatch(g, "one,two"))              --> 8
print(mymatch(g, "one two"))              --> nil Error at line 1 (col 3): expecting ',' before ' two'
print(mymatch(g, "one,\n two,\nthree,"))  --> nil Error at line 3 (col 6): expecting an identifier before ''
```

In this example we could think about writing rule <em>List</em> as follows:
```lua
List = ((m.V"Comma" + m.T(errComma)) * (m.V"Id" + m.T(errId)))^0,
```

but when matching this expression against the end of input
we would get a failure whose associated label would be **errComma**,
and this would cause the failure of the *whole* repetition.



#### Error Recovery

By using the `Rec` function we can specify a recovery pattern that
should be matched when a label is thrown. After matching the recovery
pattern, and possibly recording the error, the parser will resume
the <em>regular</em> matching. For example, in the example below
we expect to match rule `A`, but when a failure occur the label 42
is thrown and then we will try to match the recovery pattern `recp`:
```lua
local m = require'lpeglabelrec'

local recp = m.P"oast"

local g = m.P{
  "S",
  S = m.Rec(m.V"A", recp, 42) * ".",
  A = m.P"t" * (m.P"est" + m.T(42))
}

print(g:match("test."))   --> 6
print(g:match("toast."))  --> 7
print(g:match("oast."))   --> nil  0  oast.
print(g:match("toward."))   --> nil  0  ward.
```
When trying to match subject 'toast.', in rule `A` the first
't' is matched, then the matching of `m.P"est"` fails and label 42
is thrown, with the associated inpux suffix 'oast.'. In rule
`S` label 42 is caught and the recovery pattern matches 'oast',
so pattern `'.'` matches the rest of the input.

When matching subject 'oast.', pattern `m.P"t"` fails, and
the result of the matching is <b>nil,  0, oast.</b>.

When matching 'toward.', label 42 is thrown after matching 't',
with the associated input suffix 'oward.'. As the matching of the
recovery pattern fails, the result is <b>nil, 0, ward.</b>.

Usually, the recovery pattern is an expression that does not fail.
In the previous example, we could have used `(m.P(1) - m.P".")^0`
as the recovery pattern.

Below we rewrite the grammar that describes a list of identifiers
to use a recovery strategy. Grammar `g` remains the same, but we add a
recovery grammar `grec` that handles the labels thrown by `g`.

In grammar `grec` we use functions `record` and `sync`.
Function `record`, plus function `recorderror`, will help
us to save the input position where a label was thrown,
while function `sync` will give us a synchronization pattern,
that consumes the input while is not possible to match a given
pattern `p`.   

When the matching of an identifier fails, a defaul value ('NONE')
is provided.

```lua
local m = require'lpeglabelrec'
local re = require'relabelrec'

local terror = {}

local function newError(s)
  table.insert(terror, s)
  return #terror
end

local errUndef = newError("undefined")
local errId = newError("expecting an identifier")
local errComma = newError("expecting ','")

local id = m.R'az'^1

local g = m.P{
  "S",
  S = m.V"Id" * m.V"List",
  List = -m.P(1) + m.V"Comma" * m.V"Id" * m.V"List",
  Id = m.V"Sp" * id + m.T(errId),
  Comma = m.V"Sp" * "," + m.T(errComma),
  Sp = m.S" \n\t"^0,
}

local subject, errors

function recorderror(pos, lab)
  local line, col = re.calcline(subject, pos)
  table.insert(errors, { line = line, col = col, msg = terror[lab] })
end

function record (lab)
  return (m.Cp() * m.Cc(lab)) / recorderror
end

function sync (p)
  return (-p * m.P(1))^0
end

local grec = m.P{
  "S",
  S = m.Rec(m.Rec(g, m.V"ErrComma", errComma), m.V"ErrId", errId),
  ErrComma = record(errComma) * sync(id),
  ErrId = record(errId) * sync(m.P",")
}


function mymatch (g, s)
  errors = {}
  subject = s  
  local r, e, sfail = g:match(s)
  if #errors > 0 then
    local out = {}
    for i, err in ipairs(errors) do
      local msg = "Error at line " .. err.line .. " (col " .. err.col .. "): " .. err.msg
      table.insert(out,  msg)
    end
    return nil, table.concat(out, "\n") .. "\n"
  end
  return r
end
  
print(mymatch(grec, "one,two"))
-- Captures (separated by ';'): one; two; 
-- Syntactic errors found: 0

print(mymatch(grec, "one two three"))
-- Captures (separated by ';'): one; two; three; 
-- Syntactic errors found: 2
-- Error at line 1 (col 4): expecting ','
-- Error at line 1 (col 8): expecting ','

print(mymatch(grec, "1,\n two, \n3,"))
-- Captures (separated by ';'): NONE; two; NONE; NONE; 
-- Syntactic errors found: 3
-- Error at line 1 (col 1): expecting an identifier
-- Error at line 2 (col 6): expecting an identifier
-- Error at line 3 (col 2): expecting an identifier

print(mymatch(grec, "one\n two123, \nthree,"))
-- Captures (separated by ';'): one; two; three; NONE; 
-- Syntactic errors found: 3
-- Error at line 2 (col 1): expecting ','
-- Error at line 2 (col 5): expecting ','
-- Error at line 3 (col 6): expecting an identifier
```

##### *relabelrec* syntax

Below we describe again a grammar that matches a list of identifiers,
now using the syntax supported by *relabelrec*, where `//{}` is the
recovery operator, and `%{}` is the throw operator:

```lua
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
  , {g = g, recorderror  = recorderror, default = "NONE"}
)

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

print(mymatch(grec, "one,two"))
-- Captures (separated by ';'): one; two; 
-- Syntactic errors found: 0

print(mymatch(grec, "one two three"))
-- Captures (separated by ';'): one; two; three; 
-- Syntactic errors found: 2
-- Error at line 1 (col 4): expecting ','
-- Error at line 1 (col 8): expecting ','

print(mymatch(grec, "1,\n two, \n3,"))
-- Captures (separated by ';'): NONE; two; NONE; NONE; 
-- Syntactic errors found: 3
-- Error at line 1 (col 1): expecting an identifier
-- Error at line 2 (col 6): expecting an identifier
-- Error at line 3 (col 2): expecting an identifier

print(mymatch(grec, "one\n two123, \nthree,"))
-- Captures (separated by ';'): one; two; three; NONE; 
-- Syntactic errors found: 3
-- Error at line 2 (col 1): expecting ','
-- Error at line 2 (col 5): expecting ','
-- Error at line 3 (col 6): expecting an identifier
```


#### Arithmetic Expressions

Here's an example of an LPegLabel grammar that matches an expression.
We have used a function `expect`, that takes a pattern `patt` and a label as
parameters and builds a new pattern that throws this label when `patt`
fails.

When a subexpression is syntactically invalid, a default value of 1000
is provided by the recovery pattern, so the evaluation of an expression
should always produce a numeric value. 

In this example, we can see that it may be a tedious and error prone
task to build manually the recovery grammar `grec`. In the next example
we will show how to build the recovery grammar in a more automatic way. 

```lua
local m = require"lpeglabelrec"
local re = require"relabelrec"

local labels = {
  {"ExpTermFirst",  "expected an expression"},
  {"ExpTermOp",   "expected a term after the operator"},
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

local errors, subject

local function expect(patt, labname)
  local i = labelindex(labname)
  return patt + m.T(i)
end


local num = m.R("09")^1 / tonumber
local op = m.S("+-")

local function compute(tokens)
  local result = tokens[1]
  for i = 2, #tokens, 2 do
    if tokens[i] == '+' then
      result = result + tokens[i+1]
    elseif tokens[i] == '-' then
      result = result - tokens[i+1]
    else
      error('unknown operation: ' .. tokens[i])
    end
  end
  return result
end

local g = m.P {
  "Exp",
  Exp = m.Ct(m.V"OperandFirst" * (m.C(op) * m.V"Operand")^0) / compute,
  OperandFirst = expect(m.V"Term", "ExpTermFirst"),
  Operand = expect(m.V"Term", "ExpTermOp"),
  Term = num + m.V"Group",
  Group = "(" * m.V"Exp" * expect(")", "MisClose"),
}

function recorderror(pos, lab)
  local line, col = re.calcline(subject, pos)
  table.insert(errors, { line = line, col = col, msg = labels[lab][2] })
end

function record (labname)
  return (m.Cp() * m.Cc(labelindex(labname))) / recorderror
end

function sync (p)
  return (-p * m.P(1))^0
end

function defaultValue (p)
  return p or m.Cc(1000) 
end

local grec = m.P {
  "S",
  S = m.Rec(m.V"A", m.V"ErrExpTermFirst", labelindex("ExpTermFirst")), 
  A = m.Rec(m.V"Sg", m.V"ErrExpTermOp", labelindex("ExpTermOp")),
  Sg = m.Rec(g, m.V"ErrMisClose", labelindex("MisClose")),
  ErrExpTermFirst = record("ExpTermFirst") * sync(op + ")") * defaultValue(),
  ErrExpTermOp = record("ExpTermOp") * sync(op + ")") * defaultValue(),
  ErrMisClose = record("MisClose") * sync(m.P")") * defaultValue(m.P""),
}
               
local function eval(input)
  errors = {}
  io.write("Input: ", input, "\n")
  subject = input
  local result, label, suffix = grec:match(input)
  io.write("Syntactic errors found: " .. #errors, "\n")
  if #errors > 0 then
    local out = {}
    for i, err in ipairs(errors) do
      local pos = err.col
      local msg = err.msg
      table.insert(out, "syntax error: " .. msg .. " (at index " .. pos .. ")")
    end
    print(table.concat(out, "\n"))
  end
  io.write("Result = ")
  return result  
end

print(eval "90-70-(5)+3")
-- Syntactic errors found: 0
-- Result = 18

print(eval "15+")
-- Syntactic errors found: 1
-- syntax error: expected a term after the operator (at index 3)
-- Result = 1015

print(eval "-2")
-- Syntactic errors found: 1
-- syntax error: expected an expression (at index 1)
-- Result = 998

print(eval "1+()+")
-- Syntactic errors found: 2
-- syntax error: expected an expression (at index 4)
-- syntax error: expected a term after the operator (at index 5)
-- Result = 2001

print(eval "1+(")
-- Syntactic errors found: 2
-- syntax error: expected an expression (at index 3)
-- syntax error: missing a closing ')' after the expression (at index 3)
-- Result = 1001

print(eval "3)")
-- Syntactic errors found: 0
-- Result = 3
```

#### Automatically Building the Recovery Grammar 

Below we rewrite the previous example to automatically
build the recovery grammar based on information provided
by the user for each label (error message, recovery pattern, etc). 
In the example below we also throw an error when the grammar
does not match the whole subject.

```lua
local m = require"lpeglabelrec"
local re = require"relabelrec"

local num = m.R("09")^1 / tonumber
local op = m.S("+-")

local labels = {}
local nlabels = 0

local function newError(lab, msg, psync, pcap)
  nlabels = nlabels + 1
  psync = psync or m.P(-1)
  pcap = pcap or m.P""
  labels[lab] = { id = nlabels, msg = msg, psync = psync, pcap = pcap }
end

newError("ExpTermFirst", "expected an expression", op + ")", m.Cc(1000)) 
newError("ExpTermOp", "expected a term after the operator", op + ")", m.Cc(1000))
newError("MisClose",  "missing a closing ')' after the expression",  m.P")")
newError("Extra", "extra characters found after the expression") 

local errors, subject

local function expect(patt, labname)
  local i = labels[labname].id
  return patt + m.T(i)
end

local function compute(tokens)
  local result = tokens[1]
  for i = 2, #tokens, 2 do
    if tokens[i] == '+' then
      result = result + tokens[i+1]
    elseif tokens[i] == '-' then
      result = result - tokens[i+1]
    else
      error('unknown operation: ' .. tokens[i])
    end
  end
  return result
end

local g = m.P {
  "Exp",
  Exp = m.Ct(m.V"OperandFirst" * (m.C(op) * m.V"Operand")^0) / compute,
  OperandFirst = expect(m.V"Term", "ExpTermFirst"),
  Operand = expect(m.V"Term", "ExpTermOp"),
  Term = num + m.V"Group",
  Group = "(" * m.V"Exp" * expect(")", "MisClose"),
}

function recorderror(pos, lab)
  local line, col = re.calcline(subject, pos)
  table.insert(errors, { line = line, col = col, msg = labels[lab].msg })
end

function record (labname)
  return (m.Cp() * m.Cc(labname)) / recorderror
end

function sync (p)
  return (-p * m.P(1))^0
end

function defaultValue (p)
  return p or m.Cc(1000) 
end

local grec = g * expect(m.P(-1), "Extra")
for k, v in pairs(labels) do
  grec = m.Rec(grec, record(k) * sync(v.psync) * v.pcap, v.id)
end

local function eval(input)
  errors = {}
  io.write("Input: ", input, "\n")
  subject = input
  local result, label, suffix = grec:match(input)
  io.write("Syntactic errors found: " .. #errors, "\n")
  if #errors > 0 then
    local out = {}
    for i, err in ipairs(errors) do
      local pos = err.col
      local msg = err.msg
      table.insert(out, "syntax error: " .. msg .. " (at index " .. pos .. ")")
    end
    print(table.concat(out, "\n"))
  end
  io.write("Result = ")
  return result  
end

print(eval "90-70-(5)+3")
-- Syntactic errors found: 0
-- Result = 18

print(eval "15+")
-- Syntactic errors found: 1
-- syntax error: expected a term after the operator (at index 3)
-- Result = 1015

print(eval "-2")
-- Syntactic errors found: 1
-- syntax error: expected an expression (at index 1)
-- Result = 998

print(eval "1+()+")
-- Syntactic errors found: 2
-- syntax error: expected an expression (at index 4)
-- syntax error: expected a term after the operator (at index 5)
-- Result = 2001

print(eval "1+(")
-- Syntactic errors found: 2
-- syntax error: expected an expression (at index 3)
-- syntax error: missing a closing ')' after the expression (at index 3)
-- Result = 1001

print(eval "3)")
-- Syntactic errors found: 1
-- syntax error: extra characters found after the expression (at index 2)
-- Result = 3
```

#### Error Recovery

By using labeled ordered choice or the recovery operator, when a label
is thrown, the parser may record the error and still continue parsing
to find more errors. We can even record the error right away without
actually throwing a label (relying on the regular PEG failure instead).
Below we rewrite the arithmetic expression example and modify
the `expect` function to use the recovery operator for error recovery:

```lua
local lpeg = require"lpeglabel"

local R, S, P, V = lpeg.R, lpeg.S, lpeg.P, lpeg.V
local C, Cc, Ct, Cmt, Carg = lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.Cmt, lpeg.Carg
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

local function expect(patt, labname, recpatt)
  local i = labelindex(labname)
  local function recorderror(input, pos, errors)
    table.insert(errors, {i, pos})
    return true
  end
	if not recpatt then recpatt = P"" end
  return Rec(patt, Cmt(Carg(1), recorderror) * recpatt)
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
  Exp = Ct(V"Term" * (C(op) * V"Operand")^0) / compute;
  Operand = expect(V"Term", "ExpTerm", Cc(0));
  Term = num + V"Group";
  Group = "(" *  V"InnerExp" * expect(")", "MisClose");
  InnerExp = expect(V"Exp", "ExpExp", (P(1) - ")")^0 * Cc(0));
}

g = expect(g, "NoExp", P(1)^0) * expect(-P(1), "Extra")

local function eval(input)
  local errors = {}
  local result, label, suffix = g:match(input, 1, errors)
  if #errors == 0 then
    return result
  else
    local out = {}
    for i, err in ipairs(errors) do
      local pos = err[2]
      local msg = labels[err[1]][2]
      table.insert(out, "syntax error: " .. msg .. " (at index " .. pos .. ")")
    end
    return nil, table.concat(out, "\n")
  end
end

print(eval "98-76*(54/32)")
--> 37.125

print(eval "-1+(1-(1*2))/2")
--> syntax error: no expression found (at index 1)

print(eval "(1+1-1*(2/2+)-():")
--> syntax error: expected a term after the operator (at index 13)
--> syntax error: expected an expression after the parenthesis (at index 16)
--> syntax error: missing a closing ')' after the expression (at index 17)
--> syntax error: extra characters found after the expression (at index 17)
```
