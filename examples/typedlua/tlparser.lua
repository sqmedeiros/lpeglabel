local tlparser = {}

local lpeg = require "lpeglabel"
lpeg.locale(lpeg)

local tllexer = require "tllexer"

local function chainl1 (pat, sep)
  return pat * (sep * pat)^0
end

local G = lpeg.P { "TypedLua";
  TypedLua = tllexer.Shebang^-1 * tllexer.Skip * lpeg.V("Chunk") * -1;
  -- type language
  Type = lpeg.V("NilableType");
  NilableType = lpeg.V("UnionType") * tllexer.symb("?")^-1;
  UnionType = lpeg.V("PrimaryType") * (tllexer.symb("|") * lpeg.V("PrimaryType"))^0;
  PrimaryType = lpeg.V("LiteralType") +
                lpeg.V("BaseType") +
                lpeg.V("NilType") +
                lpeg.V("ValueType") +
                lpeg.V("AnyType") +
                lpeg.V("SelfType") +
                lpeg.V("FunctionType") +
                lpeg.V("TableType") +
                lpeg.V("VariableType");
  LiteralType = tllexer.token("false") +
                tllexer.token("true") +
                tllexer.token(tllexer.Number) +
                tllexer.token(tllexer.String);
  BaseType = tllexer.token("boolean") +
             tllexer.token("number") +
             tllexer.token("string") +
             tllexer.token("integer");
  NilType = tllexer.token("nil");
  ValueType = tllexer.token("value");
  AnyType = tllexer.token("any");
  SelfType = tllexer.token("self");
  FunctionType = lpeg.V("InputType") * tllexer.symb("->") * lpeg.V("NilableTuple");
  MethodType = lpeg.V("InputType") * tllexer.symb("=>") * lpeg.V("NilableTuple");
  InputType = tllexer.symb("(") * lpeg.V("TupleType")^-1 * tllexer.symb(")");
  NilableTuple = lpeg.V("UnionlistType") * tllexer.symb("?")^-1;
  UnionlistType = lpeg.V("OutputType") * (tllexer.symb("|") * lpeg.V("OutputType"))^0;
  OutputType = tllexer.symb("(") * lpeg.V("TupleType")^-1 * tllexer.symb(")");
  TupleType = lpeg.V("Type") * (tllexer.symb(",") * lpeg.V("Type"))^0 * tllexer.symb("*")^-1;
  TableType = tllexer.symb("{") * lpeg.V("TableTypeBody")^-1 * tllexer.symb("}");
  TableTypeBody = lpeg.V("RecordType") +
                  lpeg.V("HashType") +
                  lpeg.V("ArrayType");
  RecordType = lpeg.V("RecordField") * (tllexer.symb(",") * lpeg.V("RecordField"))^0 *
               (tllexer.symb(",") * (lpeg.V("HashType") + lpeg.V("ArrayType")))^-1;
  RecordField = tllexer.kw("const")^-1 *
                lpeg.V("LiteralType") * tllexer.symb(":") * lpeg.V("Type");
  HashType = lpeg.V("KeyType") * tllexer.symb(":") * lpeg.V("FieldType");
  ArrayType = lpeg.V("FieldType");
  KeyType = lpeg.V("BaseType") + lpeg.V("ValueType") + lpeg.V("AnyType");
  FieldType = lpeg.V("Type");
  VariableType = tllexer.token(tllexer.Name);
  RetType = lpeg.V("NilableTuple") +
            lpeg.V("Type");
  Id = tllexer.token(tllexer.Name);
  TypeDecId = (tllexer.kw("const") * lpeg.V("Id")) +
              lpeg.V("Id");
  IdList = lpeg.V("TypeDecId") * (tllexer.symb(",") * lpeg.V("TypeDecId"))^0;
  IdDec = lpeg.V("IdList") * tllexer.symb(":") *
          (lpeg.V("Type") + lpeg.V("MethodType"));
  IdDecList = (lpeg.V("IdDec")^1)^-1;
  TypeDec = tllexer.token(tllexer.Name) * lpeg.V("IdDecList") * tllexer.kw("end");
  Interface = tllexer.kw("interface") * lpeg.V("TypeDec") +
              tllexer.kw("typealias") * tllexer.token(tllexer.Name) * tllexer.symb("=") * lpeg.V("Type");
  -- parser
  Chunk = lpeg.V("Block");
  StatList = (tllexer.symb(";") + lpeg.V("Stat"))^0;
  Var = lpeg.V("Id");
  TypedId = tllexer.token(tllexer.Name) * (tllexer.symb(":") * lpeg.V("Type"))^-1;
  FunctionDef = tllexer.kw("function") * lpeg.V("FuncBody");
  FieldSep = tllexer.symb(",") + tllexer.symb(";");
  Field = ((tllexer.symb("[") * lpeg.V("Expr") * tllexer.symb("]")) +
          (tllexer.token(tllexer.Name))) *
          tllexer.symb("=") * lpeg.V("Expr") +
          lpeg.V("Expr");
  TField = (tllexer.kw("const") * lpeg.V("Field")) +
           lpeg.V("Field");
  FieldList = (lpeg.V("TField") * (lpeg.V("FieldSep") * lpeg.V("TField"))^0 *
              lpeg.V("FieldSep")^-1)^-1;
  Constructor = tllexer.symb("{") * lpeg.V("FieldList") * tllexer.symb("}");
  NameList = lpeg.V("TypedId") * (tllexer.symb(",") * lpeg.V("TypedId"))^0;
  ExpList = lpeg.V("Expr") * (tllexer.symb(",") * lpeg.V("Expr"))^0;
  FuncArgs = tllexer.symb("(") *
             (lpeg.V("Expr") * (tllexer.symb(",") * lpeg.V("Expr"))^0)^-1 *
             tllexer.symb(")") +
             lpeg.V("Constructor") +
             tllexer.token(tllexer.String);
  OrOp = tllexer.kw("or");
  AndOp = tllexer.kw("and");
  RelOp = tllexer.symb("~=") +
          tllexer.symb("==") +
          tllexer.symb("<=") +
          tllexer.symb(">=") +
          tllexer.symb("<") +
          tllexer.symb(">");
  BOrOp = tllexer.symb("|");
  BXorOp = tllexer.symb("~");
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
  SubExpr_1 = chainl1(lpeg.V("SubExpr_2"), lpeg.V("OrOp"));
  SubExpr_2 = chainl1(lpeg.V("SubExpr_3"), lpeg.V("AndOp"));
  SubExpr_3 = chainl1(lpeg.V("SubExpr_4"), lpeg.V("RelOp"));
  SubExpr_4 = chainl1(lpeg.V("SubExpr_5"), lpeg.V("BOrOp"));
  SubExpr_5 = chainl1(lpeg.V("SubExpr_6"), lpeg.V("BXorOp"));
  SubExpr_6 = chainl1(lpeg.V("SubExpr_7"), lpeg.V("BAndOp"));
  SubExpr_7 = chainl1(lpeg.V("SubExpr_8"), lpeg.V("ShiftOp"));
  SubExpr_8 = lpeg.V("SubExpr_9") * lpeg.V("ConOp") * lpeg.V("SubExpr_8") +
              lpeg.V("SubExpr_9");
  SubExpr_9 = chainl1(lpeg.V("SubExpr_10"), lpeg.V("AddOp"));
  SubExpr_10 = chainl1(lpeg.V("SubExpr_11"), lpeg.V("MulOp"));
  SubExpr_11 = lpeg.V("UnOp") * lpeg.V("SubExpr_11") +
               lpeg.V("SubExpr_12");
  SubExpr_12 = lpeg.V("SimpleExp") * (lpeg.V("PowOp") * lpeg.V("SubExpr_11"))^-1;
  SimpleExp = tllexer.token(tllexer.Number) +
              tllexer.token(tllexer.String) +
              tllexer.kw("nil") +
              tllexer.kw("false") +
              tllexer.kw("true") +
              tllexer.symb("...") +
              lpeg.V("FunctionDef") +
              lpeg.V("Constructor") +
              lpeg.V("SuffixedExp");
  SuffixedExp = lpeg.V("PrimaryExp") * (
                (tllexer.symb(".") * tllexer.token(tllexer.Name)) / "index" +
                (tllexer.symb("[") * lpeg.V("Expr") * tllexer.symb("]")) / "index" +
                (tllexer.symb(":") * tllexer.token(tllexer.Name) * lpeg.V("FuncArgs")) / "call" +
                lpeg.V("FuncArgs") / "call")^0 / function (...) local l = {...}; return l[#l] end;
  PrimaryExp = lpeg.V("Var") / "var" +
               tllexer.symb("(") * lpeg.V("Expr") * tllexer.symb(")");
  Block = lpeg.V("StatList") * lpeg.V("RetStat")^-1;
  IfStat = tllexer.kw("if") * lpeg.V("Expr") * tllexer.kw("then") * lpeg.V("Block") *
           (tllexer.kw("elseif") * lpeg.V("Expr") * tllexer.kw("then") * lpeg.V("Block"))^0 *
           (tllexer.kw("else") * lpeg.V("Block"))^-1 *
           tllexer.kw("end");
  WhileStat = tllexer.kw("while") * lpeg.V("Expr") *
              tllexer.kw("do") * lpeg.V("Block") * tllexer.kw("end");
  DoStat = tllexer.kw("do") * lpeg.V("Block") * tllexer.kw("end");
  ForBody = tllexer.kw("do") * lpeg.V("Block");
  ForNum = lpeg.V("Id") * tllexer.symb("=") * lpeg.V("Expr") * tllexer.symb(",") *
           lpeg.V("Expr") * (tllexer.symb(",") * lpeg.V("Expr"))^-1 *
           lpeg.V("ForBody");
  ForGen = lpeg.V("NameList") * tllexer.kw("in") *
           lpeg.V("ExpList") * lpeg.V("ForBody");
  ForStat = tllexer.kw("for") * (lpeg.V("ForNum") + lpeg.V("ForGen")) * tllexer.kw("end");
  RepeatStat = tllexer.kw("repeat") * lpeg.V("Block") *
               tllexer.kw("until") * lpeg.V("Expr");
  FuncName = lpeg.V("Id") * (tllexer.symb(".") *
             (tllexer.token(tllexer.Name)))^0 *
             (tllexer.symb(":") * (tllexer.token(tllexer.Name)))^-1;
  ParList = lpeg.V("NameList") * (tllexer.symb(",") * lpeg.V("TypedVarArg"))^-1 +
            lpeg.V("TypedVarArg");
  TypedVarArg = tllexer.symb("...") * (tllexer.symb(":") * lpeg.V("Type"))^-1;
  FuncBody = tllexer.symb("(") * lpeg.V("ParList")^-1 * tllexer.symb(")") *
             (tllexer.symb(":") * lpeg.V("RetType"))^-1 *
             lpeg.V("Block") * tllexer.kw("end");
  FuncStat = tllexer.kw("const")^-1 *
             tllexer.kw("function") * lpeg.V("FuncName") * lpeg.V("FuncBody");
  LocalFunc = tllexer.kw("function") *
              lpeg.V("Id") * lpeg.V("FuncBody");
  LocalAssign = lpeg.V("NameList") *
                ((tllexer.symb("=") * lpeg.V("ExpList")))^-1;
  LocalStat = tllexer.kw("local") *
              (lpeg.V("LocalTypeDec") + lpeg.V("LocalFunc") + lpeg.V("LocalAssign"));
  LabelStat = tllexer.symb("::") * tllexer.token(tllexer.Name) * tllexer.symb("::");
  BreakStat = tllexer.kw("break");
  GoToStat = tllexer.kw("goto") * tllexer.token(tllexer.Name);
  RetStat = tllexer.kw("return") *
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

function tlparser.parse (subject, filename, strict, integer)
  local errorinfo = {}
  lpeg.setmaxstack(1000)
  local ast, label, _ = lpeg.match(G, subject, nil, errorinfo, strict, integer)
  if not ast then
    return nil
  else
    return true
  end
end

return tlparser
