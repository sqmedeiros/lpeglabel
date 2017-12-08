local tlparser = {}

local lpeg = require "lpeglabel"
lpeg.locale(lpeg)

local tllexer = require "tllexer"
local tlerror = require "tlerror"

local function chainl1 (pat, sep, label)
  return pat * (sep * tllexer.try(pat, label))^0
end

local G = lpeg.P { "TypedLua";
  TypedLua = tllexer.Shebang^-1 * tllexer.Skip * lpeg.V("Chunk") * tllexer.try(-1, "Stat");
  -- type language
  Type = lpeg.V("NilableType");
  NilableType = lpeg.V("UnionType") * tllexer.symb("?")^-1;
  UnionType = lpeg.V("PrimaryType") * (tllexer.symb("|") * tllexer.try(lpeg.V("PrimaryType"), "UnionType"))^0;
  PrimaryType = lpeg.V("LiteralType") +
                lpeg.V("BaseType") +
                lpeg.V("NilType") +
                lpeg.V("ValueType") +
                lpeg.V("AnyType") +
                lpeg.V("SelfType") +
                lpeg.V("FunctionType") +
                lpeg.V("TableType") +
                lpeg.V("VariableType");
  LiteralType = tllexer.token("false", "false") +
                tllexer.token("true", "true") +
                tllexer.token(tllexer.Number, "Number") +
                tllexer.token(tllexer.String, "String");
  BaseType = tllexer.token("boolean", "boolean") +
             tllexer.token("number", "number") +
             tllexer.token("string", "string") +
             tllexer.token("integer", "integer");
  NilType = tllexer.token("nil", "nil");
  ValueType = tllexer.token("value", "value");
  AnyType = tllexer.token("any", "any");
  SelfType = tllexer.token("self", "self");
  FunctionType = lpeg.V("InputType") * tllexer.symb("->") * tllexer.try(lpeg.V("NilableTuple"), "FunctionType");
  MethodType = lpeg.V("InputType") * tllexer.symb("=>") * tllexer.try(lpeg.V("NilableTuple"), "MethodType");
  InputType = tllexer.symb("(") * lpeg.V("TupleType")^-1 * tllexer.try(tllexer.symb(")"), "MissingCP");
  NilableTuple = lpeg.V("UnionlistType") * tllexer.symb("?")^-1;
  UnionlistType = lpeg.V("OutputType") * (tllexer.symb("|") * tllexer.try(lpeg.V("OutputType"), "UnionType"))^0;
  OutputType = tllexer.symb("(") * lpeg.V("TupleType")^-1 * tllexer.try(tllexer.symb(")"), "MissingCP");
  TupleType = lpeg.V("Type") * (tllexer.symb(",") * tllexer.try(lpeg.V("Type"), "TupleType"))^0 * tllexer.symb("*")^-1;
  TableType = tllexer.symb("{") * lpeg.V("TableTypeBody")^-1 * tllexer.try(tllexer.symb("}"), "MissingCC");
  TableTypeBody = lpeg.V("RecordType") +
                  lpeg.V("HashType") +
                  lpeg.V("ArrayType");
  RecordType = lpeg.V("RecordField") * (tllexer.symb(",") * lpeg.V("RecordField"))^0 *
               (tllexer.symb(",") * (lpeg.V("HashType") + lpeg.V("ArrayType")))^-1;
  RecordField = tllexer.kw("const")^-1 *
                lpeg.V("LiteralType") * tllexer.symb(":") * tllexer.try(lpeg.V("Type"), "Type");
  HashType = lpeg.V("KeyType") * tllexer.symb(":") * tllexer.try(lpeg.V("FieldType"), "Type");
  ArrayType = lpeg.V("FieldType");
  KeyType = lpeg.V("BaseType") + lpeg.V("ValueType") + lpeg.V("AnyType");
  FieldType = lpeg.V("Type");
  VariableType = tllexer.token(tllexer.Name, "Name");
  RetType = lpeg.V("NilableTuple") +
            lpeg.V("Type");
  Id = tllexer.token(tllexer.Name, "Name");
  TypeDecId = (tllexer.kw("const") * lpeg.V("Id")) +
              lpeg.V("Id");
  IdList = lpeg.V("TypeDecId") * (tllexer.symb(",") * tllexer.try(lpeg.V("TypeDecId"), "TupleType"))^0;
  IdDec = lpeg.V("IdList") * tllexer.symb(":") * tllexer.try((lpeg.V("Type") + lpeg.V("MethodType")), "Type");
  IdDecList = (lpeg.V("IdDec")^1)^-1;
  TypeDec = tllexer.token(tllexer.Name, "Name") * lpeg.V("IdDecList") * tllexer.try(tllexer.kw("end"), "TypeDecEnd");
  Interface = tllexer.kw("interface") * lpeg.V("TypeDec") +
              tllexer.kw("typealias") *
                tllexer.try(tllexer.token(tllexer.Name, "Name"), "TypeAliasName") *
                tllexer.try(tllexer.symb("="), "MissingEqTypeAlias") * lpeg.V("Type");
  -- parser
  Chunk = lpeg.V("Block");
  StatList = (tllexer.symb(";") + lpeg.V("Stat"))^0;
  Var = lpeg.V("Id");
  TypedId = tllexer.token(tllexer.Name, "Name") * (tllexer.symb(":") * tllexer.try(lpeg.V("Type"), "Type"))^-1;
  FunctionDef = tllexer.kw("function") * lpeg.V("FuncBody");
  FieldSep = tllexer.symb(",") + tllexer.symb(";");
  Field = ((tllexer.symb("[") * lpeg.V("Expr") * tllexer.try(tllexer.symb("]"), "MissingCB")) +
          (tllexer.token(tllexer.Name, "Name"))) *
          tllexer.symb("=") * lpeg.V("Expr") +
          lpeg.V("Expr");
  TField = (tllexer.kw("const") * lpeg.V("Field")) +
           lpeg.V("Field");
  FieldList = (lpeg.V("TField") * (lpeg.V("FieldSep") * lpeg.V("TField"))^0 *
              lpeg.V("FieldSep")^-1)^-1;
  Constructor = tllexer.symb("{") * lpeg.V("FieldList") * tllexer.try(tllexer.symb("}"), "MissingCC");
  NameList = lpeg.V("TypedId") * (tllexer.symb(",") * lpeg.V("TypedId"))^0;
  ExpList = lpeg.V("Expr") * (tllexer.symb(",") * lpeg.V("Expr"))^0;
  FuncArgs = tllexer.symb("(") *
             (lpeg.V("Expr") * (tllexer.symb(",") * lpeg.V("Expr"))^0)^-1 *
             tllexer.try(tllexer.symb(")"), "MissingCP") +
             lpeg.V("Constructor") +
             tllexer.token(tllexer.String, "String");
  OrOp = tllexer.kw("or");
  AndOp = tllexer.kw("and");
  RelOp = tllexer.symb("~=") +
          tllexer.symb("==") +
          tllexer.symb("<=") +
          tllexer.symb(">=") +
          tllexer.symb("<") +
          tllexer.symb(">");
  BOrOp = tllexer.symb("|");
  BXorOp = tllexer.symb("~") * -lpeg.P("=");
  BAndOp = tllexer.symb("&");
  ShiftOp = tllexer.symb("<<") +
            tllexer.symb(">>");
  ConOp = tllexer.symb("..");
  AddOp = tllexer.symb("+") +
          tllexer.symb("-");
  MulOp = tllexer.symb("*") +
          tllexer.symb("//") +
          tllexer.symb("/") +
          tllexer.symb("%");
  UnOp = tllexer.kw("not") +
         tllexer.symb("-") +
         tllexer.symb("~") +
         tllexer.symb("#");
  PowOp = tllexer.symb("^");
  Expr = lpeg.V("SubExpr_1");
  SubExpr_1 = chainl1(lpeg.V("SubExpr_2"), lpeg.V("OrOp"), "SubExpr_1");
  SubExpr_2 = chainl1(lpeg.V("SubExpr_3"), lpeg.V("AndOp"), "SubExpr_2");
  SubExpr_3 = chainl1(lpeg.V("SubExpr_4"), lpeg.V("RelOp"), "SubExpr_3");
  SubExpr_4 = chainl1(lpeg.V("SubExpr_5"), lpeg.V("BOrOp"), "SubExpr_4");
  SubExpr_5 = chainl1(lpeg.V("SubExpr_6"), lpeg.V("BXorOp"), "SubExpr_5");
  SubExpr_6 = chainl1(lpeg.V("SubExpr_7"), lpeg.V("BAndOp"), "SubExpr_6");
  SubExpr_7 = chainl1(lpeg.V("SubExpr_8"), lpeg.V("ShiftOp"), "SubExpr_7");
  SubExpr_8 = lpeg.V("SubExpr_9") * lpeg.V("ConOp") * tllexer.try(lpeg.V("SubExpr_8"), "SubExpr_8") +
              lpeg.V("SubExpr_9");
  SubExpr_9 = chainl1(lpeg.V("SubExpr_10"), lpeg.V("AddOp"), "SubExpr_9");
  SubExpr_10 = chainl1(lpeg.V("SubExpr_11"), lpeg.V("MulOp"), "SubExpr_10");
  SubExpr_11 = lpeg.V("UnOp") * tllexer.try(lpeg.V("SubExpr_11"), "SubExpr_11") +
               lpeg.V("SubExpr_12");
  SubExpr_12 = lpeg.V("SimpleExp") * (lpeg.V("PowOp") * tllexer.try(lpeg.V("SubExpr_11"), "SubExpr_12"))^-1;
  SimpleExp = tllexer.token(tllexer.Number, "Number") +
              tllexer.token(tllexer.String, "String") +
              tllexer.kw("nil") +
              tllexer.kw("false") +
              tllexer.kw("true") +
              tllexer.symb("...") +
              lpeg.V("FunctionDef") +
              lpeg.V("Constructor") +
              lpeg.V("SuffixedExp");
  SuffixedExp = lpeg.V("PrimaryExp") * (
                (tllexer.symb(".") * tllexer.try(tllexer.token(tllexer.Name, "Name"), "DotIndex")) / "index" +
                (tllexer.symb("[") * lpeg.V("Expr") * tllexer.try(tllexer.symb("]"), "MissingCB")) / "index" +
                (tllexer.symb(":") * tllexer.try(tllexer.token(tllexer.Name, "Name"), "MethodName") * tllexer.try(lpeg.V("FuncArgs"), "MethodCall")) / "call" +
                lpeg.V("FuncArgs") / "call")^0 / function (...) local l = {...}; return l[#l] end;
  PrimaryExp = lpeg.V("Var") / "var" +
               tllexer.symb("(") * lpeg.V("Expr") * tllexer.try(tllexer.symb(")"), "MissingCP");
  Block = lpeg.V("StatList") * lpeg.V("RetStat")^-1;
  IfStat = tllexer.kw("if") * lpeg.V("Expr") * tllexer.try(tllexer.kw("then"), "Then") * lpeg.V("Block") *
           (tllexer.kw("elseif") * tllexer.try(lpeg.V("Expr"), "ElseIf") * tllexer.try(tllexer.kw("then"), "Then") * lpeg.V("Block"))^0 *
           (tllexer.kw("else") * lpeg.V("Block"))^-1 *
           tllexer.try(tllexer.kw("end"), "IfEnd");
  WhileStat = tllexer.kw("while") * lpeg.V("Expr") *
              tllexer.try(tllexer.kw("do"), "WhileDo") * lpeg.V("Block") * tllexer.try(tllexer.kw("end"), "WhileEnd");
  DoStat = tllexer.kw("do") * lpeg.V("Block") * tllexer.try(tllexer.kw("end"), "BlockEnd");
  ForBody = tllexer.try(tllexer.kw("do"), "ForDo") * lpeg.V("Block");
  ForNum = lpeg.V("Id") * tllexer.symb("=") * lpeg.V("Expr") * tllexer.symb(",") *
           lpeg.V("Expr") * (tllexer.symb(",") * lpeg.V("Expr"))^-1 *
           lpeg.V("ForBody");
  ForGen = lpeg.V("NameList") * tllexer.try(tllexer.kw("in"), "ForGen") *
           lpeg.V("ExpList") * lpeg.V("ForBody");
  ForStat = tllexer.kw("for") * (lpeg.V("ForNum") + lpeg.V("ForGen")) * tllexer.try(tllexer.kw("end"), "ForEnd");
  RepeatStat = tllexer.kw("repeat") * lpeg.V("Block") *
               tllexer.try(tllexer.kw("until"), "Until") * lpeg.V("Expr");
  FuncName = lpeg.V("Id") * (tllexer.symb(".") *
             (tllexer.token(tllexer.Name, "Name")))^0 *
             (tllexer.symb(":") * (tllexer.token(tllexer.Name, "Name")))^-1;
  ParList = lpeg.V("NameList") * (tllexer.symb(",") * tllexer.try(lpeg.V("TypedVarArg"), "ParList"))^-1 +
            lpeg.V("TypedVarArg");
  TypedVarArg = tllexer.symb("...") * (tllexer.symb(":") * tllexer.try(lpeg.V("Type"), "Type"))^-1;
  FuncBody = tllexer.try(tllexer.symb("("), "MissingOP") * lpeg.V("ParList")^-1 * tllexer.try(tllexer.symb(")"), "MissingCP") *
             (tllexer.symb(":") * tllexer.try(lpeg.V("RetType"), "Type"))^-1 *
             lpeg.V("Block") * tllexer.try(tllexer.kw("end"), "FuncEnd");
  FuncStat = tllexer.kw("const")^-1 *
             tllexer.kw("function") * lpeg.V("FuncName") * lpeg.V("FuncBody");
  LocalFunc = tllexer.kw("function") *
              tllexer.try(lpeg.V("Id"), "LocalFunc") * lpeg.V("FuncBody");
  LocalAssign = lpeg.V("NameList") * tllexer.symb("=") * tllexer.try(lpeg.V("ExpList"), "LocalAssign1") +
                lpeg.V("NameList") * (#(-tllexer.symb("=") * (lpeg.V("Stat") + -1)) * lpeg.P(true)) + lpeg.T(tlerror.labels["LocalAssign2"]);
  LocalStat = tllexer.kw("local") *
              (lpeg.V("LocalTypeDec") + lpeg.V("LocalFunc") + lpeg.V("LocalAssign"));
  LabelStat = tllexer.symb("::") * tllexer.try(tllexer.token(tllexer.Name, "Name"), "Label1") * tllexer.try(tllexer.symb("::"), "Label2");
  BreakStat = tllexer.kw("break");
  GoToStat = tllexer.kw("goto") * tllexer.token(tllexer.Name, "Name");
  RetStat = tllexer.kw("return") * tllexer.try(-lpeg.V("Stat"), "RetStat") *
            (lpeg.V("Expr") * (tllexer.symb(",") * lpeg.V("Expr"))^0)^-1 *
            tllexer.symb(";")^-1;
  TypeDecStat = lpeg.V("Interface");
  LocalTypeDec = lpeg.V("TypeDecStat");
  LVar = (tllexer.kw("const") * lpeg.V("SuffixedExp")) +
         lpeg.V("SuffixedExp");
  ExprStat = lpeg.Cmt(lpeg.V("LVar") * lpeg.V("Assignment"),
             function (s, i, ...)
               local l = {...}
               local i = 1
               while l[i] ~= "=" do
                 local se = l[i]
                 if se ~= "var" and se ~= "index" then return false end
                 i = i + 1
               end
               return true
             end) +
             lpeg.Cmt(lpeg.V("SuffixedExp"),
             function (s, i, se)
               if se ~= "call" then return false end
               return true
             end);
  Assignment = ((tllexer.symb(",") * lpeg.V("LVar"))^1)^-1 * (tllexer.symb("=") / "=") * lpeg.V("ExpList");
  Stat = lpeg.V("IfStat") + lpeg.V("WhileStat") + lpeg.V("DoStat") + lpeg.V("ForStat") +
         lpeg.V("RepeatStat") + lpeg.V("FuncStat") + lpeg.V("LocalStat") +
         lpeg.V("LabelStat") + lpeg.V("BreakStat") + lpeg.V("GoToStat") +
         lpeg.V("TypeDecStat") + lpeg.V("ExprStat");
}

local function lineno (s, i)
  if i == 1 then return 1, 1 end
  local rest, num = s:sub(1,i):gsub("[^\n]*\n", "")
  local r = #rest
  return 1 + num, r ~= 0 and r or 1
end

function tlparser.parse (subject, filename, strict, integer)
  local errorinfo = {}
  lpeg.setmaxstack(1000)
  local ast, label, pos = lpeg.match(G, subject, nil, errorinfo, strict, integer)
  if not ast then
    local line, col = lineno(subject, pos)
    local error_msg = string.format("%s:%d:%d: ", filename, line, col)
    if label ~= 0 then
      error_msg = error_msg .. tlerror.errors[label].msg
    else
      local u = lpeg.match(lpeg.C(tllexer.OneWord) + lpeg.Cc("EOF"), subject, errorinfo.ffp)
      error_msg = error_msg .. string.format("unexpected '%s', expecting %s", u, errorinfo.expected)
    end
    return nil, error_msg
  else
    return true
  end
end

return tlparser
