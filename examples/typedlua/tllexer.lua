local tllexer = {}

local lpeg = require "lpeglabel"
lpeg.locale(lpeg)

local function setffp (s, i, t)
  if not t.ffp or i > t.ffp then
    t.ffp = i
  end
  return false
end

local function updateffp ()
  return lpeg.Cmt(lpeg.Carg(1), setffp)
end

tllexer.Shebang = lpeg.P("#") * (lpeg.P(1) - lpeg.P("\n"))^0 * lpeg.P("\n")

local Space = lpeg.space^1

local Equals = lpeg.P("=")^0
local Open = "[" * lpeg.Cg(Equals, "init") * "[" * lpeg.P("\n")^-1
local Close = "]" * lpeg.C(Equals) * "]"
local CloseEQ = lpeg.Cmt(Close * lpeg.Cb("init"),
                         function (s, i, a, b) return a == b end)

local LongString = Open * (lpeg.P(1) - CloseEQ)^0 * Close /
                   function (s, o) return s end

local Comment = lpeg.P("--") * LongString /
                function () return end +
                lpeg.P("--") * (lpeg.P(1) - lpeg.P("\n"))^0

tllexer.Skip = (Space + Comment)^0

local idStart = lpeg.alpha + lpeg.P("_")
local idRest = lpeg.alnum + lpeg.P("_")

local Keywords = lpeg.P("and") + "break" + "do" + "elseif" + "else" + "end" +
                 "false" + "for" + "function" + "goto" + "if" + "in" +
                 "local" + "nil" + "not" + "or" + "repeat" + "return" +
                 "then" + "true" + "until" + "while"

tllexer.Reserved = Keywords * -idRest

local Identifier = idStart * idRest^0

tllexer.Name = -tllexer.Reserved * Identifier * -idRest

function tllexer.token (pat)
  return pat * tllexer.Skip + updateffp() * lpeg.P(false)
end

function tllexer.symb (str)
  return tllexer.token(lpeg.P(str))
end

function tllexer.kw (str)
  return tllexer.token(lpeg.P(str) * -idRest)
end

local Hex = (lpeg.P("0x") + lpeg.P("0X")) * lpeg.xdigit^1
local Expo = lpeg.S("eE") * lpeg.S("+-")^-1 * lpeg.digit^1
local Float = (((lpeg.digit^1 * lpeg.P(".") * lpeg.digit^0) +
              (lpeg.P(".") * lpeg.digit^1)) * Expo^-1) +
              (lpeg.digit^1 * Expo)
local Int = lpeg.digit^1

tllexer.Number = Hex + Float + Int

local ShortString = lpeg.P('"') *
                    ((lpeg.P('\\') * lpeg.P(1)) + (lpeg.P(1) - lpeg.P('"')))^0 *
                    lpeg.P('"') +
                    lpeg.P("'") *
                    ((lpeg.P("\\") * lpeg.P(1)) + (lpeg.P(1) - lpeg.P("'")))^0 *
                    lpeg.P("'")

tllexer.String = LongString + ShortString

return tllexer
