local re = require 'relabel'

function testerror(repatt, msg)
  msg = msg:match("^%s*(.-)%s*$") -- trim
  local ok, err = pcall(function () re.compile(repatt) end)
  assert(not ok)
  if msg:match("^[^\n]*\n(.-)$") then
    -- expecting a syntax error
    err = err:match("^[^\n]*\n(.-)$") -- remove first line (filename)
    err = err:gsub("[ \t]*\n", "\n") -- remove trailing spaces
    -- if err ~= msg then
    --   print(#err, #msg)
    --   print('--')
    --   print(err)
    --   print('--')
    --   print(msg)
    --   print('--')
    -- end
    assert(err == msg)
  else
    -- expecting a non-syntax error
    assert(err:match(msg))
  end
end

-- testing NoPatt

testerror([[~]], [[
L1:C1: no pattern found
~
^
]])

testerror([[???]], [[
L1:C1: no pattern found
???
^
]])

-- testing ExtraChars

testerror([['p'~]], [[
L1:C4: unexpected characters after the pattern
'p'~
   ^
]])

testerror([['p'?$?]], [[
L1:C5: unexpected characters after the pattern
'p'?$?
    ^
]])

-- testing ExpPatt1

testerror([['p' /{1}]], [[
L1:C9: expected a pattern after '/' or the label(s)
'p' /{1}
        ^
]])

testerror([['p' /{1} /{2} 'q']], [[
L1:C9: expected a pattern after '/' or the label(s)
'p' /{1} /{2} 'q'
        ^
]])

testerror([['p' /]], [[
L1:C6: expected a pattern after '/' or the label(s)
'p' /
     ^
]])

testerror([['p' / / 'q']], [[
L1:C6: expected a pattern after '/' or the label(s)
'p' / / 'q'
     ^
]])

-- testing ExpPatt2

testerror([[&]], [[
L1:C2: expected a pattern after '&'
&
 ^
]])

testerror([[& / 'p']], [[
L1:C2: expected a pattern after '&'
& / 'p'
 ^
]])

testerror([['p' &]], [[
L1:C6: expected a pattern after '&'
'p' &
     ^
]])

testerror([['p' / & / 'q']], [[
L1:C8: expected a pattern after '&'
'p' / & / 'q'
       ^
]])

testerror([[&&]], [[
L1:C3: expected a pattern after '&'
&&
  ^
]])

testerror([[!&]], [[
L1:C3: expected a pattern after '&'
!&
  ^
]])

-- testing ExpPatt3

testerror([[!]], [[
L1:C2: expected a pattern after '!'
!
 ^
]])

testerror([[! / 'p']], [[
L1:C2: expected a pattern after '!'
! / 'p'
 ^
]])

testerror([['p' !]], [[
L1:C6: expected a pattern after '!'
'p' !
     ^
]])

testerror([['p' / ! / 'q']], [[
L1:C8: expected a pattern after '!'
'p' / ! / 'q'
       ^
]])

testerror([[!!]], [[
L1:C3: expected a pattern after '!'
!!
  ^
]])

testerror([[&!]], [[
L1:C3: expected a pattern after '!'
&!
  ^
]])

-- testing ExpPatt4

testerror([[()]], [[
L1:C2: expected a pattern after '('
()
 ^
]])

testerror([[($$$)]], [[
L1:C2: expected a pattern after '('
($$$)
 ^
]])

-- testing ExpPatt5

testerror([[{: *** :}]], [[
L1:C3: expected a pattern after ':'
{: *** :}
  ^
]])

testerror([[{:group: *** :}]], [[
L1:C9: expected a pattern after ':'
{:group: *** :}
        ^
]])

testerror([[x <- {:x:}]], [[
L1:C10: expected a pattern after ':'
x <- {:x:}
         ^
]])

-- testing ExpPatt6

testerror([[{~~}]], [[
L1:C3: expected a pattern after '{~'
{~~}
  ^
]])

testerror([[{ {~ } ~}]], [[
L1:C5: expected a pattern after '{~'
{ {~ } ~}
    ^
L1:C10: missing closing '}'
{ {~ } ~}
         ^
]])

testerror([[{~ ^_^ ~}]], [[
L1:C3: expected a pattern after '{~'
{~ ^_^ ~}
  ^
]])

-- testing ExpPatt7

testerror([[{||}]], [[
L1:C3: expected a pattern after '{|'
{||}
  ^
]])

testerror([[{|@|}]], [[
L1:C3: expected a pattern after '{|'
{|@|}
  ^
]])

-- testing ExpPatt8

testerror([[S <-]], [[
L1:C5: expected a pattern after '<-'
S <-
    ^
]])

testerror([[S <- 'p' T <-]], [[
L1:C14: expected a pattern after '<-'
S <- 'p' T <-
             ^
]])

-- testing ExpPattOrClose

testerror([[{0}]], [[
L1:C2: expected a pattern or closing '}' after '{'
{0}
 ^
]])

testerror([[{ :'p': }]], [[
L1:C2: expected a pattern or closing '}' after '{'
{ :'p': }
 ^
]])

-- testing ExpNum

testerror([['p' ^ n]], [[
L1:C6: expected a number after '^', '+' or '-' (no space)
'p' ^ n
     ^
]])

testerror([['p'^+(+1)]], [[
L1:C5: expected a number after '^', '+' or '-' (no space)
'p'^+(+1)
    ^
]])

testerror([['p'^-/'q']], [[
L1:C5: expected a number after '^', '+' or '-' (no space)
'p'^-/'q'
    ^
]])

-- testing ExpCap

testerror([['p' -> {]], [[
L1:C7: expected a string, number, '{}' or name after '->'
'p' -> {
      ^
]])

testerror([['p' -> {'q'}]], [[
L1:C7: expected a string, number, '{}' or name after '->'
'p' -> {'q'}
      ^
]])

testerror([['p' -> / 'q']], [[
L1:C7: expected a string, number, '{}' or name after '->'
'p' -> / 'q'
      ^
]])

testerror([['p' -> [0-9] ]], [[
L1:C7: expected a string, number, '{}' or name after '->'
'p' -> [0-9]
      ^
]])

-- testing ExpName1

testerror([['p' =>]], [[
L1:C7: expected the name of a rule after '=>'
'p' =>
      ^
]])

testerror([['p' => 'q']], [[
L1:C7: expected the name of a rule after '=>'
'p' => 'q'
      ^
]])

-- testing ExpName2

testerror([['<' {:tag: [a-z]+ :} '>' '<' = '>']], [[
L1:C31: expected the name of a rule after '=' (no space)
'<' {:tag: [a-z]+ :} '>' '<' = '>'
                              ^
]])

testerror([['<' {:tag: [a-z]+ :} '>' '<' = tag '>']], [[
L1:C31: expected the name of a rule after '=' (no space)
'<' {:tag: [a-z]+ :} '>' '<' = tag '>'
                              ^
]])

-- testing ExpName3

testerror([[<>]], [[
L1:C2: expected the name of a rule after '<' (no space)
<>
 ^
]])

testerror([[<123>]], [[
L1:C2: expected the name of a rule after '<' (no space)
<123>
 ^
]])

testerror([[< hello >]], [[
L1:C2: expected the name of a rule after '<' (no space)
< hello >
 ^
]])

testerror([[<<S>>]], [[
L1:C2: expected the name of a rule after '<' (no space)
<<S>>
 ^
]])

-- testing ExpLab1

testerror([['p' /{} 'q']], [[
L1:C7: expected at least one label after '{'
'p' /{} 'q'
      ^
]])

testerror([[%{ 'label' }]], [[
L1:C3: expected at least one label after '{'
%{ 'label' }
  ^
]])

-- testing ExpLab2

testerror([['p' /{1,2,3,} 'q']], [[
L1:C13: expected a label after the comma
'p' /{1,2,3,} 'q'
            ^
]])

testerror([[%{ a,,b,,c }]], [[
L1:C6: expected a label after the comma
%{ a,,b,,c }
     ^
]])

-- testing ExpNameOrLab

testerror([[% s]], [[
L1:C2: expected a name or label after '%' (no space)
% s
 ^
]])

testerror([[% {1}]], [[
L1:C2: expected a name or label after '%' (no space)
% {1}
 ^
]])

-- testing ExpItem

testerror([[
"p" [
abc
] "q"  
]], [[
L1:C6: expected at least one item after '[' or '^'
"p" [
     ^
]])

-- testing MisClose1

testerror([[('p' ('q' / 'r')]], [[
L1:C17: missing closing ')'
('p' ('q' / 'r')
                ^
]])

-- testing MisClose2

-- two errors are reported due to the ignore strategy
testerror([[{: group: 'p' :}]], [[
L1:C9: missing closing ':}'
{: group: 'p' :}
        ^
L1:C9: unexpected characters after the pattern
{: group: 'p' :}
        ^
]])

testerror([[S <- {: 'p'  T <- 'q']], [[
L1:C12: missing closing ':}'
S <- {: 'p'  T <- 'q'
           ^
]])

-- testing MisClose3

testerror([['p' {~ ('q' 'r') / 's']], [[
L1:C23: missing closing '~}'
'p' {~ ('q' 'r') / 's'
                      ^
]])

-- testing MisClose4

-- two errors are reported due to the ignore strategy
testerror([['p' {| 'q' / 'r' }]], [[
L1:C17: missing closing '|}'
'p' {| 'q' / 'r' }
                ^
L1:C18: unexpected characters after the pattern
'p' {| 'q' / 'r' }
                 ^
]])

-- testing MisClose5

testerror([[{ 'p' ]], [[
L1:C6: missing closing '}'
{ 'p'
     ^
]])

-- testing MisClose6

testerror([[<patt]], [[
L1:C6: missing closing '>'
<patt
     ^
]])

testerror([[<insert your name here>]], [[
L1:C8: missing closing '>'
<insert your name here>
       ^
]])

-- testing MisClose7

testerror([['{' %{ a, b '}']], [[
L1:C12: missing closing '}'
'{' %{ a, b '}'
           ^
]])

-- testing MisClose8

testerror([[[]], [[
L1:C1: missing closing ']'
[
^
]])

testerror([[[^]], [[
L1:C1: missing closing ']'
[^
^
]])

testerror([[[] ]], [[
L1:C1: missing closing ']'
[]
^
]])

testerror([[[^] 	]], [[
L1:C1: missing closing ']'
[^]
^
]])

testerror([[[_-___-_|]], [[
L1:C1: missing closing ']'
[_-___-_|
^
]])

-- testing MisTerm1

testerror([['That is the question...]], [[
L1:C1: missing terminating single quote
'That is the question...
^
]])

-- testing MisTerm2

testerror([[Q <- "To be or not to be...]], [[
L1:C6: missing terminating double quote
Q <- "To be or not to be...
     ^
]])

-- testing error recovery, more complex grammars (multiline),
-- and pointer positions in error recovery

testerror([[&'p'/&/!/'p'^'q']], [[
L1:C7: expected a pattern after '&'
&'p'/&/!/'p'^'q'
      ^
L1:C9: expected a pattern after '!'
&'p'/&/!/'p'^'q'
        ^
L1:C14: expected a number after '^', '+' or '-' (no space)
&'p'/&/!/'p'^'q'
             ^
]])

testerror([[
  A <- 'a' (B 'b'
  B <- 'x' / !
  C <- 'c'
]], [[
L1:C18: missing closing ')'
  A <- 'a' (B 'b'
                 ^
L2:C15: expected a pattern after '!'
  B <- 'x' / !
              ^
]])

testerror([['a' / &@ ('c' / 'd')]], [[
L1:C8: expected a pattern after '&'
'a' / &@ ('c' / 'd')
       ^
]])

testerror([['x' / & / 'y']], [[
L1:C8: expected a pattern after '&'
'x' / & / 'y'
       ^
]])

testerror([[&/'p'/!/'q']], [[
L1:C2: expected a pattern after '&'
&/'p'/!/'q'
 ^
L1:C8: expected a pattern after '!'
&/'p'/!/'q'
       ^
]])

testerror([['p'//'q']], [[
L1:C5: expected a pattern after '/' or the label(s)
'p'//'q'
    ^
]])

testerror([[
  S <- 'forgot to close / T
  T <- 'T' & / 't'
]], [[
L1:C8: missing terminating single quote
  S <- 'forgot to close / T
       ^
L2:C13: expected a pattern after '&'
  T <- 'T' & / 't'
            ^
]])

testerror([[
  S <- [a-z / T
  T <- 'x' / & / 'y'
]], [[
L1:C8: missing closing ']'
  S <- [a-z / T
       ^
L2:C15: expected a pattern after '&'
  T <- 'x' / & / 'y'
              ^
]])

testerror([[
  S <- ('p' -- comment
]], [[
L1:C12: missing closing ')'
  S <- ('p' -- comment
           ^
]])

-- an unfortunate second error exists because we don't know
-- what's part of the quotation
testerror([[
  X <- ('p / Q (R
    / S))
  Q <- 'q'
  R <- 'r'
  S <- 's'
]], [[
L1:C9: missing terminating single quote
  X <- ('p / Q (R
        ^
L2:C9: unexpected characters after the pattern
    / S))
        ^
]])

testerror([[
  A <- 'A' /{'lab'} B / !

  B <- %{1, 2 3} 'b' / '6' & / 'B'

  C <- A^B
]], [[
L1:C14: expected at least one label after '{'
  A <- 'A' /{'lab'} B / !
             ^
L1:C26: expected a pattern after '!'
  A <- 'A' /{'lab'} B / !
                         ^
L3:C15: missing closing '}'
  B <- %{1, 2 3} 'b' / '6' & / 'B'
              ^
L3:C29: expected a pattern after '&'
  B <- %{1, 2 3} 'b' / '6' & / 'B'
                            ^
L5:C10: expected a number after '^', '+' or '-' (no space)
  C <- A^B
         ^
]])

testerror([['p'/{1/'q'/&]], [[
L1:C7: missing closing '}'
'p'/{1/'q'/&
      ^
L1:C13: expected a pattern after '&'
'p'/{1/'q'/&
            ^
]])

-- testing non-syntax errors

testerror([[
  A <- %nosuch %def
  A <- 'A again'
  A <- 'and again'
]], [[
name 'nosuch' undefined
]])

testerror([[names not in grammar]], [[
rule 'names' used outside a grammar
]])

testerror([[
  A <- %nosuch %def
  A <- 'A again'
  A <- 'and again'
]], [[
name 'nosuch' undefined
]])

-- the non-syntax error should not be reported
-- since there is a syntax error
testerror([[ A <- %nosuch ('error' ]], [[
L1:C23: missing closing ')'
 A <- %nosuch ('error'
                      ^
]])


print 'OK'
