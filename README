<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <title>LPegLabLabel - Parsing Expression Grammars For Lua</title>
    <link rel="stylesheet"
          href="http://www.inf.puc-rio.br/~roberto/lpeg/doc.css"
          type="text/css"/>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
</head>
<body>

<div id="container">
	
<div id="product">
  <div id="product_logo">
    <a href="https://github.com/sqmedeiros/lpeglabel">
    <img alt="LPegLabel logo" src="lpeglabel-logo.gif" width="128"/></a>
    
  </div>
  <div id="product_name"><big><strong>LPegLabel</strong></big></div>
  <div id="product_description">
     Parsing Expression Grammars For Lua with Labels, version 0.1
  </div>
</div> <!-- id="product" -->

<div id="main">
	
<div id="navigation">
<h1>LPeg</h1>

<ul>
  <li><strong>Home</strong>
  <ul>
    <li><a href="#intro">Introduction</a></li>
    <li><a href="#func">Functions</a></li>
    <li><a href="#ex">Some Examples</a></li>
    <li><a href="#download">Download</a></li>
    <li><a href="#license">License</a></li>
  </ul>
  </li>
</ul>
</div> <!-- id="navigation" -->

<div id="content">


<h2><a name="intro">Introduction</a></h2>

<p>
<em>LPegLabel</em> is an extension of the
<a href="http://www.inf.puc-rio.br/~roberto/lpeg/">LPeg</a>
library that provides an implementation of Parsing Expression
Grammars (PEGs) with labeled failures. Labels can be
used to signal different kinds of erros and to
specify which alternative in a labeled ordered choice
should handle a given label. Labels can also be combined
with the standard patterns of LPeg.
</p>

<p>
This document describes the new functions available
in LpegLabel and presents some examples of usage.
In LPegLabel, the result of an unsuccessful matching
is a triple <code>nil, lab, sfail</code>, where <code>lab</code>
is the label associated with the failure, and
<code>sfail</code> is the suffix input where
the label was thrown.
</p>

<p>
Below there is a brief summary of the new functions
provided by LpegLabel:
</p>
<table border="1">
<tbody><tr><td><b>Function</b></td><td><b>Description</b></td></tr>
<tr><td><a href="#f-t"><code>lpeglabel.T (l)</code></a></td>
  <td>Throws label <code>l</code></td></tr>
<tr><td><a href="#f-lc"><code>lpeglabel.Lc (p1, p2, l<sub>1</sub>, ..., l<sub>n</sub>)</code></a></td>
  <td>Matches <code>p1</code> and tries to match <code>p2</code>
			if the matching of <code>p1</code> gives one of l<sub>1</sub>, ..., l<sub>n</sub> 
      </td></tr>
<tr><td><a href="#re-t"><code>%{l}</code></a></td>
  <td>Syntax of <em>relabel</em> module. Equivalent to <code>lpeg.T(l)</code>
      </td></tr>
<tr><td><a href="#re-lc"><code>p1 /{l<sub>1</sub>, ..., l<sub>n</sub>} p2</code></a></td>
  <td>Syntax of <em>relabel</em> module. Equivalent to <code>lpeg.Lc(p1, p2, l<sub>1</sub>, ..., l<sub>n</sub>)</code>
      </td></tr>
<tr><td><a href="#re-setl"><code>relabel.setlabels (tlabel)</code></a></td>
  <td>Allows to specicify a table with mnemonic labels. 
      </td></tr>
</tbody></table>

<p>
For a more detailed and formal discussion about
PEGs with labels please see
<a href="http://www.inf.puc-rio.br/~roberto/docs/sblp2013-1.pdf">
Exception Handling for Error Reporting in Parsing Expression Grammars</a>,
<a href="http://arxiv.org/abs/1405.6646">Error Reporting in Parsing Expression Grammars</a>,
and <a href="http://dx.doi.org/10.1145/2851613.2851750">
A parsing machine for parsing expression grammars with labeled failures</a>.
</p>

<!--
<p>
In case of an unsucessful matching, the <em>match</em> function returns
<code>nil</code> plus a list of labels. These labels may be used to build
a good error message.
</p>
-->

<h2><a name="func">Functions</a></h2>


<h3><a name="f-t"></a><code>lpeglabel.T(l)</code></h3>
<p>
Returns a pattern that throws the label <code>l</code>.
A label must be an integer between <code>0</code> and <code>63</code>.

The label <code>0</code> is equivalent to the regular failure of PEGs.


<h3><a name="f-lc"></a><code>lpeglabel.Lc(p1, p2, l<sub>1</sub>, ..., l<sub>n</sub>)</code></h3>
<p>
Returns a pattern equivalent to a <em>labeled ordered choice</em>.
If the matching of <code>p1</code> gives one of the labels <code>l<sub>1</sub>, ..., l<sub>n</sub></code>,
then the matching of <code>p2</code> is tried from the same position. Otherwise,
the result of the matching of <code>p1</code> is the pattern's result.
</p>

<p>
The labeled ordered choice <code>lpeg.Lc(p1, p2, 0)</code> is equivalent to the
regular ordered choice <code>p1 / p2</code>.
</p>

<p>
Although PEG's ordered choice is associative, the labeled ordered choice is not.
When using this function, the user should take care to build a left-associative
labeled ordered choice pattern.
</p>


<h3><a name="re-t"></a><code>%{l}</code></h3>
<p>
Syntax of <em>relabel</em> module. Equivalent to <code>lpeg.T(l)</code>.
</p>


<h3><a name="re-lc"></a><code>p1 /{l<sub>1</sub>, ..., l<sub>n</sub>} p2</code></h3>
<p>
Syntax of <em>relabel</em> module. Equivalent to <code>lpeg.Lc(p1, p2, l<sub>1</sub>, ..., l<sub>n</sub>)</code>.
</p>

<p>
The <code>/{}</code> operator is left-associative. 
</p>

<p>
A grammar can use both choice operators (<code>/</code> and <code>/{}</code>),
but a single choice can not mix them. That is, the parser
of <code>relabel</code> module will not recognize a pattern as
<code>p1 / p2 /{l<sub>1</sub>} p3</code>.
</p>


<h3><a name="re-setl"></a><code>relabel.setlabels (tlabel)</code></h3>

<p>Allows to specicify a table with labels. They keys of
<code>tlabel</code> must be integers between <code>0</code> and <code>63</code>,
and the associated values should be strings.
</p>



<h2><a name="ex">Some Examples</a></h2>

<h3>Throwing a label</h3>
<p>
The following example defines a grammar that matches
a list of identifiers separated by commas. A label
is thrown when there is an error matching an identifier
or a comma:
</p>
<pre class="example">
local m = require'lpeglabel'

local g = m.P{
  "S",
  S = m.V"Id" * m.V"List",
  List = -m.P(1) + ("," + m.T(2)) * m.V"Id" * m.V"List",
  Id = m.R'az'^1 + m.T(1),
}

function mymatch (g, s)
  local r, e = g:match(s)
  if not r then
    if e == 1 then
      return "Error: expecting an identifier"
    elseif e == 2 then
      return "Error: expecting ','"
    else
      return "Error"
    end
  end
  return r
end
	
print(mymatch(g, "a,b"))
print(mymatch(g, "a b"))
print(mymatch(g, ", b"))
</pre>
<p>
In this example we could think about writing rule <em>List</em> as follows:
<pre class="example">
List = m.P(("," + m.T(2)) * m.V"Id")^0
</pre>
but this would give us an expression that when matching
the end of input would result in a failure whose associated
label would be <em>2</em>.
</p>

<p>
In the previous example we could have also created a table
with the error messages to improve the readbility of the PEG.
Below we rewrite the grammar following this approach: 
</p>

<pre class="example">
local m = require'lpeglabel'

local errUndef = 0
local errId = 1
local errComma = 2

local terror = {
  [errUndef] = "Error",
  [errId] = "Error: expecting an identifier",
  [errComma] = "Error: expecting ','",
}

local g = m.P{
  "S",
  S = m.V"Id" * m.V"List",
  List = -m.P(1) + ("," + m.T(errComma)) * m.V"Id" * m.V"List",
  Id = m.R'az'^1 + m.T(errId),
}

function mymatch (g, s)
  local r, e = g:match(s)
  if not r then
    return terror[e]
  end
  return r
end
	
print(mymatch(g, "a,b"))
print(mymatch(g, "a b"))
print(mymatch(g, ", b"))
</pre>

<h3>Throwing a label using the <em>relabel</em> module</h3>

<p>
We can also rewrite the previous example using the <em>relabel</em> module
as follows:
</p>
<pre class="example">
local re = require 'relabel' 

local g = re.compile[[
  S    <- Id List
  List <- !.  /  (',' / %{2}) Id List
  Id   <- [a-z]  /  %{1}	
]]

function mymatch (g, s)
  local r, e = g:match(s)
  if not r then
    if e == 1 then
      return "Error: expecting an identifier"
    elseif e == 2 then
      return "Error: expecting ','"
    else
      return "Error"
    end
  end
  return r
end
	
print(mymatch(g, "a,b"))
print(mymatch(g, "a b"))
print(mymatch(g, ", b"))
</pre>

<p>
Another way to describe the previous example using the <em>relabel</em> module
is by using a table with the description of the errors (<em>terror</em>) and
another table that associates a name to a given label (<em>tlabels</em>):
</p>
<pre class="example">
local re = require 'relabel' 

local errUndef, errId, errComma = 0, 1, 2

local terror = {
  [errUndef] = "Error",
  [errId] = "Error: expecting an identifier",
  [errComma] = "Error: expecting ','",
}

local tlabels = { ["errUndef"] = errUndef,
                  ["errId"]    = errId, 
                  ["errComma"] = errComma }

re.setlabels(tlabels)

local g = re.compile[[
  S    <- Id List
  List <- !.  /  (',' / %{errComma}) Id List
  Id   <- [a-z]  /  %{errId}	
]]

function mymatch (g, s)
  local r, e = g:match(s)
  if not r then
    return terror[e]
  end
  return r
end
	
print(mymatch(g, "a,b"))
print(mymatch(g, "a b"))
print(mymatch(g, ", b"))
</pre>



<h3>Throwing and catching a label</h3>

<p>
When a label is thrown, the grammar itself can handle this label
by using the labeled ordered choice. Below we rewrite the example
of the list of identifiers to show this feature:
</p>
<pre class="example">
local m = require'lpeglabel'

local errUndef, errId, errComma = 0, 1, 2

local terror = {
  [errUndef] = "Error",
  [errId] = "Error: expecting an identifier",
  [errComma] = "Error: expecting ','",
}

g = m.P{
  "S",
  S = m.Lc(m.Lc(m.V"Id" * m.V"List", m.V"ErrId", errId),
           m.V"ErrComma", errComma),
  List = -m.P(1)  +  m.V"Comma" * m.V"Id" * m.V"List",
  Id = m.R'az'^1  +  m.T(errId),
  Comma = ","  +  m.T(errComma),
  ErrId = m.Cc(errId) / terror,
  ErrComma = m.Cc(errComma) / terror
}

print(g:match("a,b"))
print(g:match("a b"))
print(g:match(",b"))
</pre>

<p>
As was pointed out <a href="#f-lc">before</a>, the labeled ordered
choice is not associative, so we should impose a left-associative
order when using function <code>Lc</code>.
</p>
<p>
Below we use the <em>re</em> module to throw and catch labels.
As was pointed out <a href="#re-lc">before</a>, the <code>/{}</code>
operator is left-associative, so we do not need to manually impose
a left-associative order as we did in the previous example that
used <code>Lc</code>:
</p>
<pre class="example">
local re = require'relabel'

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
</pre>


<h3>Tiny Language</h3>
<p>
As a more complex example, below we have the grammar
for the Tiny language, as described in 
<a href="http://arxiv.org/abs/1405.6646">this</a> paper.
The example below can also show the line where the syntactic
error probably happened.
</p>
<pre class="example">
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
</pre>


<h2><a name="download"></a>Download</h2>

<p>LPegLabel 
<a href="https://github.com/sqmedeiros/lpeglabel/archive/master.zip">source code</a>.</p>


<h2><a name="license">License</a></h2>

<p>
The MIT License (MIT)
</p>
<p>
Copyright (c) 2014-2015 Sérgio Medeiros
</p>
<p>
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
</p>
<p>
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
</p>
<p>
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.




</p>

</div> <!-- id="content" -->

</div> <!-- id="main" -->

<div id="about">
</div> <!-- id="about" -->

</div> <!-- id="container" -->

</body>
</html> 

