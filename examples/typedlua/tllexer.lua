local tllexer = {}

local lpeg = require "lpeglabel"
lpeg.locale(lpeg)

local tlerror = require "tlerror"

function tllexer.try (pat, label)
  return pat + lpeg.T(tlerror.labels[label])
end

local function setffp (s, i, t, n)
  if not t.ffp or i > t.ffp then
    t.ffp = i
    t.list = {}
    t.list[n] = true
    t.expected = "'" .. n .. "'"
  elseif i == t.ffp then
    if not t.list[n] then
      t.list[n] = true
      t.expected = "'" .. n .. "', " .. t.expected
    end
  end
  return false
end

local function updateffp (name)
  return lpeg.Cmt(lpeg.Carg(1) * lpeg.Cc(name), setffp)
end

tllexer.Shebang = lpeg.P("#") * (lpeg.P(1) - lpeg.P("\n"))^0 * lpeg.P("\n")

local Space = lpeg.space^1

local Equals = lpeg.P("=")^0
local Open = "[" * lpeg.Cg(Equals, "init") * "[" * lpeg.P("\n")^-1
local Close = "]" * lpeg.C(Equals) * "]"
local CloseEQ = lpeg.Cmt(Close * lpeg.Cb("init"),
                         function (s, i, a, b) return a == b end)

local LongString = Open * (lpeg.P(1) - CloseEQ)^0 * tllexer.try(Close, "LongString") /
                   function (s, o) return s end

local LongStringCm1 = Open * (lpeg.P(1) - CloseEQ)^0 * Close /
                   function (s, o) return s end

local Comment =	lpeg.Rec(lpeg.P"--" * #Open * (LongStringCm1 / function() return end + lpeg.T(tlerror.labels["LongString"])),
                lpeg.T(tlerror.labels["LongComment"]), tlerror.labels["LongString"]) +
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

function tllexer.token (pat, name)
  return pat * tllexer.Skip + updateffp(name) * lpeg.P(false)
end

function tllexer.symb (str)
  return tllexer.token(lpeg.P(str), str)
end

function tllexer.kw (str)
  return tllexer.token(lpeg.P(str) * -idRest, str)
end

local Hex = (lpeg.P("0x") + lpeg.P("0X")) * tllexer.try(lpeg.xdigit^1, "Number")
local Expo = lpeg.S("eE") * lpeg.S("+-")^-1 * tllexer.try(lpeg.digit^1, "Number")
local Float = (((lpeg.digit^1 * lpeg.P(".") * lpeg.digit^0 * tllexer.try(-lpeg.P("."), "Number")) +
              (lpeg.P(".") * lpeg.digit^1)) * Expo^-1) +
              (lpeg.digit^1 * Expo)
local Int = lpeg.digit^1

tllexer.Number = Hex + Float + Int

local ShortString = lpeg.P('"') *
                    ((lpeg.P('\\') * lpeg.P(1)) + (lpeg.P(1) - lpeg.P('"')))^0 *
                    tllexer.try(lpeg.P('"'), "String") +
                    lpeg.P("'") *
                    ((lpeg.P("\\") * lpeg.P(1)) + (lpeg.P(1) - lpeg.P("'")))^0 *
                    tllexer.try(lpeg.P("'"), "String")

tllexer.String = LongString + ShortString

-- for error reporting
tllexer.OneWord = tllexer.Name +
                  tllexer.Number +
                  tllexer.String +
                  tllexer.Reserved +
                  lpeg.P("...") +
                  lpeg.P(1)

return tllexer
