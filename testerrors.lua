local re = require 'relabel'

local npass, ntests = 0, 0

function testerror(repatt)
  ntests = ntests + 1
  local ok, err = pcall(function () re.compile(repatt) end)
  
  if ok then
    print("FAIL", ntests)
  else
    npass = npass + 1
    print("PASS", ntests, err)
  end
end

local patterns = {
  -- 1-5
  [[~]],
  [[???]],
  [['p'~]],
  [['p'?$?]],
  [['p' /{1}]],
  -- 6-10  
  [['p' /{1} /{2} 'q']],
  [['p' /]],
  [['p' / / 'q']],
  [[&]],
  [[& / 'p']],
  -- 11-15
  [['p' &]],
  [['p' / & / 'q']],
  [[&&]],
  [[!&]],
  [[!]],
  -- 16-20
  [[! / 'p']],
  [['p' !]],
  [['p' / ! / 'q']],
  [[!!]],
  [[&!]],
  -- 21-25
  [['p' ^ n]],
  [['p'^+(+1)]],
  [['p'^-/'q']],
  [['p' -> {]],
  [['p' -> {'q'}]],
  -- 26-30
  [['p' -> / 'q']],
  [['p' -> [0-9] ]],
  [['p' =>]],
  [['p' => 'q']],
  [[()]],
  -- 31-35
  [[($$$)]],
  [[('p' ('q' / 'r')]],
  [[% s]],
  [[% {1}]],
  [[{: *** :}]],
  -- 36-40
  [[{:group: *** :}]],
  [[{: group: 'p' :}]],
  [[S <- {: 'p'  T <- 'q']],
  [['<' {:tag: [a-z]+ :} '>' '<' = '>']],
  [['<' {:tag: [a-z]+ :} '>' '<' = tag '>']],
  -- 41-45
  [[{~~}]],
  [[{ {~ } ~}]],
  [[{~ ^_^ ~}]],
  [['p' {~ ('q' 'r') / 's']],
  [[{0}]],
  -- 46-50
  [[{ :'p': }]],
  [[{ 'p' ]],
  [[<>]],
  [[<123>]],
  [[< hello >]],
  -- 51-55
  [[<<S>>]],
  [[<patt]],
  [[<insert your name here>]],
  [[S <-]],
  [[S <- 'p' T <-]],
  -- 55-60
  [[[]],
  [[[^]],
  [[[] ]],
  [[[^] 	]],
  [[[_-___-_|]],
  -- 60-65
  [['p' /{} 'q']],
  [[%{ 'label' }]],
  [['p' /{1,2,3,} 'q']],
  [[%{ a,,b,,c }]],
  [['{' %{ a, b '}']],
  -- 65-70
  [[Q <- "To be or not to be...]],
  [['That is the question...]],
  [[{||}]],
  [[{|@|}]],
  [['p' {| 'q' / 'r' }]],
  -- 71-73
  [['a'/{1}'b'/'c']],
  [[x <- {:x:}]],
  [[&'p'/&/!/'p'^'q']],
  [[
    A <- 'a' (B 'b'
    B <- 'x' / !
    C <- 'c'
  ]]
}

for i, patt in ipairs(patterns) do
  testerror(patt)
end

print()
print("Tests passed: " .. npass .. "/" .. ntests)