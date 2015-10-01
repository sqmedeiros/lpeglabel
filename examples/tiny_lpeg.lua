local lpeg = require "lpeglabel"
local ast = require "tiny_ast"

lpeg.locale(lpeg)

local function token (pat)
  return pat * lpeg.V"Skip"
end

local function symb (str)
  return token(lpeg.P(str))
end

local function kw(str)
  return token(lpeg.P(str) * -lpeg.V"idRest")
end

local function taggedCap(tag, pat)
  return lpeg.Ct(lpeg.Cg(lpeg.Cc(tag), "tag") * pat)
end

local function binaryop (e1, op, e2)
  if not op then return e1 end
  return { tag = op, [1] = e1, [2] = e2 }
end

local function chainl1(pat, sep)
  return lpeg.Cf(pat * lpeg.Cg(sep * pat)^0, binaryop)
end

local G = lpeg.P { lpeg.V"Tiny",
  -- parser
  Tiny = lpeg.V"Skip" * lpeg.V"CmdSeq" * -1;
  CmdSeq = taggedCap("Seq", lpeg.V"Cmd" * symb(";") * (lpeg.V"Cmd" * symb(";"))^0);
  Cmd = lpeg.V"IfCmd" + lpeg.V"RepeatCmd" + lpeg.V"AssignCmd" +
        lpeg.V"ReadCmd" + lpeg.V"WriteCmd";
  IfCmd = taggedCap("If", kw("if") * lpeg.V"Exp" * kw("then") * lpeg.V"CmdSeq" *
                             (kw("else") * lpeg.V"CmdSeq")^-1 * kw("end"));
  RepeatCmd = taggedCap("Repeat", kw("repeat") * lpeg.V"CmdSeq" *
                                     kw("until") * lpeg.V"Exp");
  AssignCmd = taggedCap("Assign", lpeg.V"Id" * symb(":=") * lpeg.V"Exp");
  ReadCmd = taggedCap("Read", kw("read") * lpeg.V"Id");
  WriteCmd = taggedCap("Write", kw("write") * lpeg.V"Exp");
  Exp = lpeg.V"SimpleExp" * (lpeg.V"RelOp" * lpeg.V"SimpleExp")^-1 / binaryop;
  SimpleExp = chainl1(lpeg.V"Term", lpeg.V"AddOp");
  Term = chainl1(lpeg.V"Factor", lpeg.V"MulOp");
  Factor = symb("(") * lpeg.V"Exp" * symb(")") +
           taggedCap("Number", token(lpeg.V"Number")) +
           lpeg.V("Id");
  Id = taggedCap("Id", token(lpeg.V"Name"));
  -- lexer
  Space = lpeg.space^1;
  Skip = lpeg.V"Space"^0;
  idStart = lpeg.alpha + lpeg.P"_";
  idRest = lpeg.alnum + lpeg.P"_";
  Keywords = lpeg.P"if" + "then" + "else" + "end" +
             "repeat" + "until" + "read" + "write";
  Reserved = lpeg.V"Keywords" * -lpeg.V"idRest";
  Identifier = lpeg.V"idStart" * lpeg.V"idRest"^0;
  Name = -lpeg.V"Reserved" * lpeg.C(lpeg.V"Identifier") * -lpeg.V"idRest";
  Number = lpeg.C(lpeg.digit^1) / tonumber;
  RelOp = symb("<") / "Lt" +
          symb("=") / "Eq";
  AddOp = symb("+") / "Add" +
          symb("-") / "Sub";
  MulOp = symb("*") / "Mul" +
          symb("/") / "Div";
}

local function getcontents(filename)
  file = assert(io.open(filename, "r"))
  contents = file:read("*a")
  file:close()
  return contents
end

if #arg ~= 1 then
  print ("Usage: lua tiny_lpeg.lua <file>")
  os.exit(1)
end

local input = getcontents(arg[1])
local t, l, r = lpeg.match(G, input)

local function printt(t, i)
  io.write (string.format (string.rep(" ", i) .. "{tag = %s,\n", t.tag))
  for k,v in ipairs(t) do
    if type (v) == "table" then
      printt(v, i+2)
    else
      io.write (string.format (string.rep(" ", i+2) .. tostring(v) .. "\n"))
    end
  end
  io.write (string.format (string.rep(" ", i) .. "}\n"))
end

if t then
  print(ast.__tostring(t))
else

end

os.exit(0)
