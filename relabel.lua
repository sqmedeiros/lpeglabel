-- $Id: re.lua,v 1.44 2013/03/26 20:11:40 roberto Exp $

-- imported functions and modules
local tonumber, type, print, error, ipairs = tonumber, type, print, error, ipairs
local setmetatable = setmetatable
local unpack, tinsert, concat = table.unpack or unpack, table.insert, table.concat
local rep = string.rep
local m = require"lpeglabel"

-- 'm' will be used to parse expressions, and 'mm' will be used to
-- create expressions; that is, 're' runs on 'm', creating patterns
-- on 'mm'
local mm = m

-- pattern's metatable
local mt = getmetatable(mm.P(0))



-- No more global accesses after this point
local version = _VERSION
if version == "Lua 5.2" then _ENV = nil end


local any = m.P(1)
local dummy = mm.P(false)


local errinfo = {
  {"NoPatt", "no pattern found"},
  {"ExtraChars", "unexpected characters after the pattern"},

  {"ExpPatt1", "expected a pattern after '/' or the label(s)"},

  {"ExpPatt2", "expected a pattern after '&'"},
  {"ExpPatt3", "expected a pattern after '!'"},

  {"ExpPatt4", "expected a pattern after '('"},
  {"ExpPatt5", "expected a pattern after ':'"},
  {"ExpPatt6", "expected a pattern after '{~'"},
  {"ExpPatt7", "expected a pattern after '{|'"},

  {"ExpPatt8", "expected a pattern after '<-'"},

  {"ExpPattOrClose", "expected a pattern or closing '}' after '{'"},

  {"ExpNum", "expected a number after '^', '+' or '-' (no space)"},
  {"ExpCap", "expected a string, number, '{}' or name after '->'"},

  {"ExpName1", "expected the name of a rule after '=>'"},
  {"ExpName2", "expected the name of a rule after '=' (no space)"},
  {"ExpName3", "expected the name of a rule after '<' (no space)"},

  {"ExpLab1", "expected at least one label after '{'"},
  {"ExpLab2", "expected a label after the comma"},

  {"ExpNameOrLab", "expected a name or label after '%' (no space)"},

  {"ExpItem", "expected at least one item after '[' or '^'"},

  {"MisClose1", "missing closing ')'"},
  {"MisClose2", "missing closing ':}'"},
  {"MisClose3", "missing closing '~}'"},
  {"MisClose4", "missing closing '|}'"},
  {"MisClose5", "missing closing '}'"},  -- for the captures

  {"MisClose6", "missing closing '>'"},
  {"MisClose7", "missing closing '}'"},  -- for the labels

  {"MisClose8", "missing closing ']'"},

  {"MisTerm1", "missing terminating single quote"},
  {"MisTerm2", "missing terminating double quote"},
}

local errmsgs = {}
local labels = {}

for i, err in ipairs(errinfo) do
  errmsgs[i] = err[2]
  labels[err[1]] = i
end

local errfound = {}

local function expect(pattern, labelname)
  local label = labels[labelname]
  local record = function (input, pos)
    tinsert(errfound, {label, pos})
    return true
  end
  return pattern + m.Cmt("", record) * m.T(label)
end

local ignore = m.Cmt(any, function (input, pos)
  return errfound[#errfound][2], dummy
end)

local function adderror(message)
  tinsert(errfound, {message})
end

-- Pre-defined names
local Predef = { nl = m.P"\n" }
local tlabels = {}


local mem
local fmem
local gmem


local function updatelocale ()
  mm.locale(Predef)
  Predef.a = Predef.alpha
  Predef.c = Predef.cntrl
  Predef.d = Predef.digit
  Predef.g = Predef.graph
  Predef.l = Predef.lower
  Predef.p = Predef.punct
  Predef.s = Predef.space
  Predef.u = Predef.upper
  Predef.w = Predef.alnum
  Predef.x = Predef.xdigit
  Predef.A = any - Predef.a
  Predef.C = any - Predef.c
  Predef.D = any - Predef.d
  Predef.G = any - Predef.g
  Predef.L = any - Predef.l
  Predef.P = any - Predef.p
  Predef.S = any - Predef.s
  Predef.U = any - Predef.u
  Predef.W = any - Predef.w
  Predef.X = any - Predef.x
  mem = {}    -- restart memoization
  fmem = {}
  gmem = {}
  local mt = {__mode = "v"}
  setmetatable(mem, mt)
  setmetatable(fmem, mt)
  setmetatable(gmem, mt)
end


updatelocale()



local I = m.P(function (s,i) print(i, s:sub(1, i-1)); return i end)


local function getdef (id, defs)
  local c = defs and defs[id]
  if not c then
    adderror("undefined name: " .. id)
    return nil
  end
  return c
end


local function mult (p, n)
  local np = mm.P(true)
  while n >= 1 do
    if n%2 >= 1 then np = np * p end
    p = p * p
    n = n/2
  end
  return np
end

local function equalcap (s, i, c)
  if type(c) ~= "string" then return nil end
  local e = #c + i
  if s:sub(i, e - 1) == c then return e else return nil end
end


local S = (Predef.space + "--" * (any - Predef.nl)^0)^0

local name = m.C(m.R("AZ", "az", "__") * m.R("AZ", "az", "__", "09")^0)

local arrow = S * "<-"

-- a defined name only have meaning in a given environment
local Def = name * m.Carg(1)

local num = m.C(m.R"09"^1) * S / tonumber

local String = "'" * m.C((any - "'" - m.P"\n")^0) * expect("'", "MisTerm1")
             + '"' * m.C((any - '"' - m.P"\n")^0) * expect('"', "MisTerm2")


local defined = "%" * Def / function (c,Defs)
  local cat =  Defs and Defs[c] or Predef[c]
  if not cat then
    adderror ("name '" .. c .. "' undefined")
    return dummy
  end
  return cat
end

local Range = m.Cs(any * (m.P"-"/"") * (any - "]")) / mm.R

local item = defined + Range + m.C(any - m.P"\n")

local Class =
    "["
  * (m.C(m.P"^"^-1))    -- optional complement symbol
  * m.Cf(expect(item, "ExpItem") * (item - "]")^0, mt.__add)
    / function (c, p) return c == "^" and any - p or p end
  * expect("]", "MisClose8")

local function adddef (t, k, exp)
  if t[k] then
    adderror("'"..k.."' already defined as a rule")
  else
    t[k] = exp
  end
  return t
end

local function firstdef (n, r) return adddef({n}, n, r) end


local function NT (n, b)
  if not b then
    adderror("rule '"..n.."' used outside a grammar")
    return dummy
  else return mm.V(n)
  end
end

local function labchoice (...)
  local t = { ... }
  local n = #t
  local p = t[1]
  local i = 2
  while i + 1 <= n do
    p = t[i] and mm.Lc(p, t[i+1], unpack(t[i])) or mt.__add(p, t[i+1])
    i = i + 2
  end

  return p
end

local function labify(labelnames)
  for i, l in ipairs(labelnames) do
    labelnames[i] = labels[l]
  end
  return labelnames
end

local labelset1 = labify {
  "ExpPatt2", "ExpPatt3",
  "ExpNum", "ExpCap", "ExpName1",
  "MisTerm1", "MisTerm2"
}

local labelset2 = labify {
  "MisClose1", "MisClose2", "MisClose3", "MisClose4", "MisClose5",
  "MisClose7", "MisClose8"
}

local exp = m.P{ "Exp",
  Exp = S * ( m.V"Grammar"
            + (m.V"SeqLC" * (S * "/" * (m.Ct(m.V"Labels") + m.Cc(nil))
                             * m.Lc(expect(S * m.V"SeqLC", "ExpPatt1"),
                                      m.V"SkipToSlash", labels["ExpPatt1"])
                            )^0
              ) / labchoice);
  Labels = m.P"{" * expect(S * m.V"Label", "ExpLab1")
           * (S * "," * expect(S * m.V"Label", "ExpLab2"))^0
           * expect(S * "}", "MisClose7");
  SkipToSlash = (-m.P"/" * m.V"Stuff")^0 * m.Cc(dummy);
  Stuff = m.V"Group" + any;
  Group = "(" * (-m.P")" * m.V"Stuff")^0 * ")"
        + "{" * (-m.P"}" * m.V"Stuff")^0 * "}";
  SeqLC = m.Lc(m.V"Seq", m.V"SkipToSlash", unpack(labelset1));
  Seq = m.Cf(m.Cc(m.P"") * m.V"Prefix" * (S * m.V"Prefix")^0, mt.__mul);
  Prefix = "&" * expect(S * m.V"Prefix", "ExpPatt2") / mt.__len
         + "!" * expect(S * m.V"Prefix", "ExpPatt3") / mt.__unm
         + m.V"Suffix";
  Suffix = m.Cf(m.V"PrimaryLC" *
          ( S * ( m.P"+" * m.Cc(1, mt.__pow)
                + m.P"*" * m.Cc(0, mt.__pow)
                + m.P"?" * m.Cc(-1, mt.__pow)
                + "^" * expect( m.Cg(num * m.Cc(mult))
                              + m.Cg(m.C(m.S"+-" * m.R"09"^1) * m.Cc(mt.__pow)
                              ),
                          "ExpNum")
                + "->" * expect(S * ( m.Cg((String + num) * m.Cc(mt.__div))
                                    + m.P"{}" * m.Cc(nil, m.Ct)
                                    + m.Cg(Def / getdef * m.Cc(mt.__div))
                                    ),
                           "ExpCap")
                + "=>" * expect(S * m.Cg(Def / getdef * m.Cc(m.Cmt)),
                           "ExpName1")
                )
          )^0, function (a,b,f) return f(a,b) end );
  PrimaryLC = m.Lc(m.V"Primary", ignore, unpack(labelset2));
  Primary = "(" * expect(m.V"Exp", "ExpPatt4") * expect(S * ")", "MisClose1")
          + String / mm.P
          + Class
          + defined
          + "%" * expect(m.V"Labels", "ExpNameOrLab") / mm.T
          + "{:" * (name * ":" + m.Cc(nil)) * expect(m.V"Exp", "ExpPatt5")
            * expect(S * ":}", "MisClose2")
            / function (n, p) return mm.Cg(p, n) end
          + "=" * expect(name, "ExpName2")
            / function (n) return mm.Cmt(mm.Cb(n), equalcap) end
          + m.P"{}" / mm.Cp
          + "{~" * expect(m.V"Exp", "ExpPatt6")
            * expect(S * "~}", "MisClose3") / mm.Cs
          + "{|" * expect(m.V"Exp", "ExpPatt7")
            * expect(S * "|}", "MisClose4") / mm.Ct
          + "{" * expect(m.V"Exp", "ExpPattOrClose")
            * expect(S * "}", "MisClose5") / mm.C
          + m.P"." * m.Cc(any)
          + (name * -arrow + "<" * expect(name, "ExpName3")
             * expect(">", "MisClose6")) * m.Cb("G") / NT;
  Label = num + name / function (f) return tlabels[f] end;
  Definition = name * arrow * expect(m.V"Exp", "ExpPatt8");
  Grammar = m.Cg(m.Cc(true), "G")
            * m.Cf(m.V"Definition" / firstdef * (S * m.Cg(m.V"Definition"))^0,
                adddef) / mm.P;
}

local pattern = S * m.Cg(m.Cc(false), "G") * expect(exp, "NoPatt") / mm.P
                * S * expect(-any, "ExtraChars")

local function lineno (s, i)
  if i == 1 then return 1, 1 end
  local rest, num = s:sub(1,i):gsub("[^\n]*\n", "")
  local r = #rest
  return 1 + num, r ~= 0 and r or 1
end

local function compile (p, defs)
  if mm.type(p) == "pattern" then return p end   -- already compiled
  p = p .. " " -- for better reporting of column numbers in errors when at EOF
  local cp, label, suffix = pattern:match(p, 1, defs)
  if #errfound > 0 then
    local lines = {}
    for line in p:gmatch("[^\r\n]+") do tinsert(lines, line) end
    local errors = {}
    for i, err in ipairs(errfound) do
      if #err == 1 then
        tinsert(errors, err[1])
      else
        local line, col = lineno(p, err[2])
        tinsert(errors, "L" .. line .. ":C" .. col .. ": " .. errmsgs[err[1]])
        tinsert(errors, lines[line])
        tinsert(errors, rep(" ", col-1) .. "^")
      end
    end
    errfound = {}
    error(concat(errors, "\n"))
  end
  return cp
end

local function match (s, p, i)
  local cp = mem[p]
  if not cp then
    cp = compile(p)
    mem[p] = cp
  end
  return cp:match(s, i or 1)
end

local function find (s, p, i)
  local cp = fmem[p]
  if not cp then
    cp = compile(p) / 0
    cp = mm.P{ mm.Cp() * cp * mm.Cp() + 1 * mm.V(1) }
    fmem[p] = cp
  end
  local i, e = cp:match(s, i or 1)
  if i then return i, e - 1
  else return i
  end
end

local function gsub (s, p, rep)
  local g = gmem[p] or {}   -- ensure gmem[p] is not collected while here
  gmem[p] = g
  local cp = g[rep]
  if not cp then
    cp = compile(p)
    cp = mm.Cs((cp / rep + 1)^0)
    g[rep] = cp
  end
  return cp:match(s)
end

local function setlabels (t)
  tlabels = t
end

-- exported names
local re = {
  compile = compile,
  match = match,
  find = find,
  gsub = gsub,
  updatelocale = updatelocale,
  setlabels = setlabels
}

if version == "Lua 5.1" then _G.re = re end

return re
