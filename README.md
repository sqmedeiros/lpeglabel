<p align="center"><img src="https://github.com/sqmedeiros/lpeglabel/raw/master/lpeglabel-logo.png" alt="LPegLabel" width="150px"></p>

## LPegLabel - Parsing Expression Grammars (with Labels) for Lua 

---

### Introduction

LPegLabel is a conservative extension of the
[LPeg](http://www.inf.puc-rio.br/~roberto/lpeg)
library that provides an implementation of Parsing
Expression Grammars (PEGs) with labeled failures. 
Labels can be used to signal different kinds of erros
and to specify which alternative in a labeled ordered
choice should handle a given label. Labels can also be
combined with the standard patterns of LPeg.

This document describes the new functions available
in LpegLabel and presents some examples of usage.
For a more detailed discussion about PEGs with labeled failures
please see [A Parsing Machine for Parsing Expression
Grammars with Labeled Failures](https://docs.google.com/viewer?a=v&pid=sites&srcid=ZGVmYXVsdGRvbWFpbnxzcW1lZGVpcm9zfGd4OjMzZmE3YzM0Y2E2MGM5Y2M).


In LPegLabel, the result of an unsuccessful matching
is a triple **nil, lab, sfail**, where **lab**
is the label associated with the failure, and
**sfail** is the suffix input being matched when
**lab** was thrown. Below there is a brief summary
of the new functions provided by LpegLabel: 

<table border="1">
<tbody><tr><td><b>Function</b></td><td><b>Description</b></td></tr>
<tr><td><a href="#f-t"><code>lpeglabel.T (l)</code></a></td>
  <td>Throws label <code>l</code></td></tr>
<tr><td><a href="#f-lc"><code>lpeglabel.Lc (p1, p2, l1, ..., ln)</code></a></td>
  <td>Matches <code>p1</code> and tries to match <code>p2</code>
			if the matching of <code>p1</code> gives one of l<sub>1</sub>, ..., l<sub>n</sub> 
      </td></tr>
<tr><td><a href="#re-t"><code>%{l}</code></a></td>
  <td>Syntax of <em>relabel</em> module. Equivalent to <code>lpeg.T(l)</code>
      </td></tr>
<tr><td><a href="#re-lc"><code>p1 /{l1, ..., ln} p2</code></a></td>
  <td>Syntax of <em>relabel</em> module. Equivalent to <code>lpeg.Lc(p1, p2, l1, ..., ln)</code>
      </td></tr>
<tr><td><a href="#re-setl"><code>relabel.setlabels (tlabel)</code></a></td>
  <td>Allows to specicify a table with mnemonic labels. 
      </td></tr>
</tbody></table>


### Functions


#### <a name="f-t"></a><code>lpeglabel.T(l)</code>


Returns a pattern that throws the label `l`.
A label must be an integer between 0 and 63.

The label 0 is equivalent to the regular failure of PEGs.


#### <a name="f-lc"></a><code>lpeglabel.Lc(p1, p2, l1, ..., ln)</code>#

Returns a pattern equivalent to a *labeled ordered choice*.
If the matching of `p1` gives one of the labels `l1, ..., ln`,
then the matching of `p2` is tried from the same position. Otherwise,
the result of the matching of `p1` is the pattern's result.

The labeled ordered choice `lpeg.Lc(p1, p2, 0)` is equivalent to the
regular ordered choice `p1 / p2`.

Although PEG's ordered choice is associative, the labeled ordered choice is not.
When using this function, the user should take care to build a left-associative
labeled ordered choice pattern.


#### <a name="re-t"></a><code>%{l}</code>

Syntax of *relabel* module. Equivalent to `lpeg.T(l)`.


#### <a name="re-lc"></a><code>p1 /{l1, ..., ln} p2</code>

Syntax of *relabel* module. Equivalent to `lpeg.Lc(p1, p2, l1, ..., ln)`.

The `/{}` operator is left-associative. 

A grammar can use both choice operators (`/` and `/{}`),
but a single choice can not mix them. That is, the parser of `relabel`
module will not recognize a pattern as `p1 / p2 /{l1} p3`.


#### <a name="re-setl"></a><code>relabel.setlabels (tlabel)</code>

Allows to specicify a table with labels. They keys of
`tlabel` must be integers between 0 and 63,
and the associated values should be strings.


### Examples

#### Throwing a label

The following example defines a grammar that matches
a list of identifiers separated by commas. A label
is thrown when there is an error matching an identifier
or a comma:

```lua
local m = require'lpeglabel'

local function calcline (s, i)
  if i == 1 then return 1, 1 end
  local rest, line = s:sub(1,i):gsub("[^\n]*\n", "")
  local col = #rest
  return 1 + line, col ~= 0 and col or 1
end

local g = m.P{
  "S",
  S = m.V"Id" * m.V"List",
  List = -m.P(1) + (m.V"Comma" + m.T(2)) * (m.V"Id" + m.T(1)) * m.V"List",
  Id = m.V"Sp" * m.R'az'^1,
  Comma = m.V"Sp" * ",",
  Sp = m.S" \n\t"^0,
}

function mymatch (g, s)
  local r, e, sfail = g:match(s)
  if not r then
    local line, col = calcline(s, #s - #sfail)
    local msg = "Error at line " .. line .. " (col " .. col .. ")"
    if e == 1 then
      return r, msg .. ": expecting an identifier before '" .. sfail .. "'"
    elseif e == 2 then
      return r, msg .. ": expecting ',' before '" .. sfail .. "'"
    else
      return r, msg
    end
  end
  return r
end
  
print(mymatch(g, "one,two"))              --> 8
print(mymatch(g, "one two"))              --> nil Error at line 1 (col 3): expecting ',' before ' two'
print(mymatch(g, "one,\n two,\nthree,"))  --> nil Error at line 3 (col 6): expecting an identifier before ''
```


#### Arithmetic Expressions

Here's an example of an LPegLabel grammar that make its own function called
'expect', which takes a pattern and a label as parameters and throws the label
if the pattern fails to be matched. This function can be extended later on to
record all errors encountered once error recovery is implemented.

```lua
local lpeg = require"lpeglabel"

local R, S, P, V, C, Ct, T = lpeg.R, lpeg.S, lpeg.P, lpeg.V, lpeg.C, lpeg.Ct, lpeg.T

local labels = {
  {"NoExp",     "no expression found"},
  {"Extra",     "extra characters found after the expression"},
  {"ExpTerm",   "expected a term after the operator"},
  {"ExpExp",    "expected an expression after the parenthesis"},
  {"MisClose",  "missing a closing ')' after the expression"},
}

local function expect(patt, labname)
  for i, elem in ipairs(labels) do
    if elem[1] == labname then
      return patt + T(i)
    end
  end

  error("could not find label: " .. labname)
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
  Exp = Ct(V"Term" * (C(op) * expect(V"Term", "ExpTerm"))^0) / compute;
  Term = num + V"Group";
  Group = "(" * expect(V"Exp", "ExpExp") * expect(")", "MisClose");
}

g = expect(g, "NoExp") * expect(-P(1), "Extra")

local function eval(input)
  local result, label, suffix = g:match(input)
  if result ~= nil then
    return result
  else
    local pos = input:len() - suffix:len() + 1
    local msg = labels[label][2]
    return nil, "syntax error: " .. msg .. " (at index " .. pos .. ")"
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
```

