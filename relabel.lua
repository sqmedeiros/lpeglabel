-- $Id: re.lua,v 1.44 2013/03/26 20:11:40 roberto Exp $

-- imported functions and modules
local tonumber, type, print, error, ipairs = tonumber, type, print, error, ipairs
local setmetatable = setmetatable
local unpack = table.unpack or unpack
local tinsert = table.insert
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

local errors

local function throw(label)
  local record = function (input, pos)
    tinsert(errors, {label, pos})
    return true
  end
  return m.Cmt("", record) * m.T(label)
end

local ignore = m.Cmt(any, function (input, pos)
  return errors[#errors][2], mm.P""
end)

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
  if not c then error("undefined name: " .. id) end
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

local name = m.R("AZ", "az", "__") * m.R("AZ", "az", "__", "09")^0

local arrow = S * "<-"

local seq_follow = m.P"/" + ")" + "}" + ":}" + "~}" + "|}" + (name * arrow) + -1

name = m.C(name)


-- a defined name only have meaning in a given environment
local Def = name * m.Carg(1)

local num = m.C(m.R"09"^1) * S / tonumber

local String = "'" * m.C((any - "'")^0) * ("'" + throw(31)) +
               '"' * m.C((any - '"')^0) * ('"' + throw(30))


local defined = "%" * Def / function (c,Defs)
  local cat =  Defs and Defs[c] or Predef[c]
  if not cat then error ("name '" .. c .. "' undefined") end
  return cat
end

local Range = m.Cs(any * (m.P"-"/"") * (any - "]")) / mm.R

local item = defined + Range + m.C(any)

local Class =
    "["
  * (m.C(m.P"^"^-1))    -- optional complement symbol
  * m.Cf((item + throw(24)) * (item - "]")^0, mt.__add) /
                          function (c, p) return c == "^" and any - p or p end
  * ("]" + throw(25))

local function adddef (t, k, exp)
  if t[k] then
    error("'"..k.."' already defined as a rule")
  else
    t[k] = exp
  end
  return t
end

local function firstdef (n, r) return adddef({n}, n, r) end


local function NT (n, b)
  if not b then
    error("rule '"..n.."' used outside a grammar")
  else return mm.V(n)
  end
end

local function labchoice (...)
	local t = { ... }
	local n = #t
	local p = t[1] 
	local i = 2
	while i + 1 <= n do
		p = mm.Lc(p, t[i+1], unpack(t[i]))
		i = i + 2	
	end

	return p
end


local exp = m.P{ "Exp",
  Exp = S * ( m.V"Grammar"
            + (m.V"Seq") * ("/" * m.V"Labels" * S * (m.V"Seq" + throw(3)))^1 / labchoice
            + m.Cf(m.V"Seq" * ("/" * S * m.Lc(m.V"Seq" + throw(4), (-m.P"/" * any)^0, 4, 5, 6, 7, 8, 9, 10))^0, mt.__add) );
	Labels = m.Ct(m.P"{" * S * (m.V"Label" + throw(27)) * (S * "," * S * (m.V"Label" + throw(28)))^0 * S * ("}" + throw(29)));
  Seq = m.Cf(m.Cc(m.P"") * m.V"Prefix"^1 , mt.__mul);
  Prefix = "&" * S * (m.V"Prefix" + throw(5)) / mt.__len
         + "!" * S * (m.V"Prefix" + throw(6)) / mt.__unm
         + m.V"Suffix";
  Suffix = m.Cf(m.V"PrimaryLC" * S *
          ( ( m.P"+" * m.Cc(1, mt.__pow)
            + m.P"*" * m.Cc(0, mt.__pow)
            + m.P"?" * m.Cc(-1, mt.__pow)
            + "^" * ( m.Cg(num * m.Cc(mult))
                    + m.Cg(m.C(m.S"+-" * m.R"09"^1) * m.Cc(mt.__pow))
                    + throw(7)
                    )
            + "->" * S * ( m.Cg((String + num) * m.Cc(mt.__div))
                         + m.P"{" * (m.P"}" + throw(8)) * m.Cc(nil, m.Ct)
                         + m.Cg(Def / getdef * m.Cc(mt.__div))
                         + throw(9)
                         )
            + "=>" * S * (m.Cg(Def / getdef * m.Cc(m.Cmt)) + throw(10))
            ) * S
          )^0, function (a,b,f) return f(a,b) end );
  PrimaryLC = m.Lc(m.V"Primary", ignore, 12, 15, 18, 20, 25, 29, 33);
  Primary = "(" * (m.V"Exp" + throw(11)) * (")" + throw(12))
            + String / mm.P
            + Class
            + defined
            + "%{" * S * (m.V"Label" + throw(27)) * (S * "," * S * (m.V"Label" + throw(28)))^0 * S * ("}" + throw(29)) / mm.T
            + ("%" * throw(13))
            + "{:" * (name * ":" + m.Cc(nil)) * (m.V"Exp" + throw(14)) * (":}" + throw(15)) /
                     function (n, p) return mm.Cg(p, n) end
            + "=" * (name / function (n) return mm.Cmt(mm.Cb(n), equalcap) end + throw(16))
            + m.P"{}" / mm.Cp
            + "{~" * (m.V"Exp" + throw(17)) * ("~}" + throw(18)) / mm.Cs
            + "{|" * (m.V"Exp" + throw(32)) * ("|}" + throw(33)) / mm.Ct
            + "{" * (m.V"Exp" + throw(19)) * ("}" + throw(20)) / mm.C
            + m.P"." * m.Cc(any)
            + (name * -arrow + "<" * (name + throw(21)) * (">" + throw(22))) * m.Cb("G") / NT;
	Label = num + name / function (f) return tlabels[f] end;
  Definition = name * arrow * (m.V"Exp" + throw(23));
  Grammar = m.Cg(m.Cc(true), "G") *
            m.Cf(m.V"Definition" / firstdef * m.Cg(m.V"Definition")^0,
              adddef) / mm.P
}

local pattern = S * m.Cg(m.Cc(false), "G") * (exp + throw(1)) / mm.P * (-any + throw(2))

local function lineno (s, i)
  if i == 1 then return 1, 1 end
  local rest, num = s:sub(1,i):gsub("[^\n]*\n", "")
  local r = #rest
  return 1 + num, r ~= 0 and r or 1
end

local errorMessages = {
  "No pattern found",
  "Unexpected characters after the pattern",
  "Expected a pattern after labels",
  "Expected a pattern after `/`",
  "Expected a pattern after `&`",
  "Expected a pattern after `!`",
  "Expected a valid number after `^`",
  "Expected `}` right after `{`",
  "Expected a string, number, `{}` or name after `->`",
  "Expected a name after `=>`",
  "Expected a pattern after `(`",
  "Missing the closing `)` after pattern",
  "Expected a name or labels right after `%` (without any space)",
  "Expected a pattern after `{:` or `:`",
  "Missing the closing `:}` after pattern",
  "Expected a name after `=` (without any space)",
  "Expected a pattern after `{~`",
  "Missing the closing `~}` after pattern",
  "Expected a pattern or closing `}` after `{`",
  "Missing the closing `}` after pattern",
  "Expected a name right after `<`",
  "Missing the closing `>` after the name",
  "Expected a pattern after `<-`",
  "Expected at least one item after `[` or `^`",
  "Missing the closing `]` after the items",
  "Expected an item after the `-` (except `]`)",
  "Expected at least one label after the `{`",
  "Expected a label after the comma",
  "Missing closing `}` after the labels",
  "Missing closing double quote in string",
  "Missing closing single quote in string",
  "Expected a pattern after `{|`",
  "Missing the closing `|}` after pattern",
}

local function compile (p, defs)
  if mm.type(p) == "pattern" then return p end   -- already compiled
  errors = {}
  local cp, label, suffix = pattern:match(p, 1, defs)
  if #errors > 0 then
    local errmsg = ""
    for i, err in ipairs(errors) do
      local line, col = lineno(p, err[2])
      errmsg = errmsg .. "Line" .. line .. ", Col " .. col .. ": " .. errorMessages[err[1]] .. "\n"
    end
    error(errmsg, 3)
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
