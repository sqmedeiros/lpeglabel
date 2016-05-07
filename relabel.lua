-- $Id: re.lua,v 1.44 2013/03/26 20:11:40 roberto Exp $

-- imported functions and modules
local tonumber, type, print, error = tonumber, type, print, error
local setmetatable = setmetatable
local unpack = table.unpack or unpack
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


local function patt_error (s, i)
  local msg = (#s < i + 20) and s:sub(i)
                             or s:sub(i,i+20) .. "..."
  msg = ("pattern error near '%s'"):format(msg)
  error(msg, 2)
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

local String = "'" * m.C((any - "'")^0) * ("'" + m.T(31)) +
               '"' * m.C((any - '"')^0) * ('"' + m.T(30))


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
  * m.Cf((item + m.T(24)) * (item - "]")^0, mt.__add) /
                          function (c, p) return c == "^" and any - p or p end
  * ("]" + m.T(25))

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
            + (m.V"Seq") * ("/" * m.V"Labels" * S * (m.V"Seq" + m.T(3)))^1 / labchoice
            + m.Cf(m.V"Seq" * ("/" * S * (m.V"Seq" + m.T(4)))^0, mt.__add) );
	Labels = m.Ct(m.P"{" * S * (m.V"Label" + m.T(27)) * (S * "," * S * (m.V"Label" + m.T(28)))^0 * S * ("}" + m.T(29)));
  Seq = m.Cf(m.Cc(m.P"") * m.V"Prefix"^1 , mt.__mul);
  Prefix = "&" * S * (m.V"Prefix" + m.T(5)) / mt.__len
         + "!" * S * (m.V"Prefix" + m.T(6)) / mt.__unm
         + m.V"Suffix";
  Suffix = m.Cf(m.V"Primary" * S *
          ( ( m.P"+" * m.Cc(1, mt.__pow)
            + m.P"*" * m.Cc(0, mt.__pow)
            + m.P"?" * m.Cc(-1, mt.__pow)
            + "^" * ( m.Cg(num * m.Cc(mult))
                    + m.Cg(m.C(m.S"+-" * m.R"09"^1) * m.Cc(mt.__pow))
                    + m.T(7)
                    )
            + "->" * S * ( m.Cg((String + num) * m.Cc(mt.__div))
                         + m.P"{" * (m.P"}" + m.T(8)) * m.Cc(nil, m.Ct)
                         + m.Cg(Def / getdef * m.Cc(mt.__div))
                         + m.T(9)
                         )
            + "=>" * S * (m.Cg(Def / getdef * m.Cc(m.Cmt)) + m.T(10))
            ) * S
          )^0, function (a,b,f) return f(a,b) end );
  Primary = "(" * (m.V"Exp" + m.T(11)) * (")" + m.T(12))
            + String / mm.P
            + Class
            + defined
            + "%{" * S * (m.V"Label" + m.T(27)) * (S * "," * S * (m.V"Label" + m.T(28)))^0 * S * ("}" + m.T(29)) / mm.T
            + ("%" * m.T(13))
            + "{:" * (name * ":" + m.Cc(nil)) * (m.V"Exp" + m.T(14)) * (":}" + m.T(15)) /
                     function (n, p) return mm.Cg(p, n) end
            + "=" * (name / function (n) return mm.Cmt(mm.Cb(n), equalcap) end + m.T(16))
            + m.P"{}" / mm.Cp
            + "{~" * (m.V"Exp" + m.T(17)) * ("~}" + m.T(18)) / mm.Cs
            + "{|" * (m.V"Exp" + m.T(32)) * ("|}" + m.T(33)) / mm.Ct
            + "{" * (m.V"Exp" + m.T(19)) * ("}" + m.T(20)) / mm.C
            + m.P"." * m.Cc(any)
            + (name * -arrow + "<" * (name + m.T(21)) * (">" + m.T(22))) * m.Cb("G") / NT;
	Label = num + name / function (f) return tlabels[f] end;
  Definition = name * arrow * (m.V"Exp" + m.T(23));
  Grammar = m.Cg(m.Cc(true), "G") *
            m.Cf(m.V"Definition" / firstdef * m.Cg(m.V"Definition")^0,
              adddef) / mm.P
}

local pattern = S * m.Cg(m.Cc(false), "G") * (exp + m.T(1)) / mm.P * (-any + m.T(2))

local function lineno (s, i)
  if i == 1 then return 1, 1 end
  local rest, num = s:sub(1,i):gsub("[^\n]*\n", "")
  local r = #rest
  return 1 + num, r ~= 0 and r or 1
end

local function compile (p, defs)
  if mm.type(p) == "pattern" then return p end   -- already compiled
  local cp, label, suffix = pattern:match(p, 1, defs)
  if not cp then
    local line, col = lineno(p, p:len() - suffix:len())
    error("incorrect pattern on line " .. line .. " col " .. col .. ": " .. label, 3)
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
