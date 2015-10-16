
local errors = {}
local function new_error (label, msg)
  table.insert(errors, { label = label, msg = msg })
end

new_error("Number", "malformed <number>")
new_error("String", "malformed <string>")
new_error("LongString", "unfinished long string")
new_error("LongComment", "unfinished long comment")
new_error("MissingOP", "missing '('")
new_error("MissingCP", "missing ')'")
new_error("MissingCC", "missing '}'")
new_error("MissingCB", "missing ']'")
new_error("UnionType", "expecting <type> after '|'")
new_error("FunctionType", "expecting <type> after '->'")
new_error("MethodType", "expecting <type> after '=>'")
new_error("TupleType", "expecting <type> after ','")
new_error("Type", "expecting <type> after ':'")
new_error("TypeDecEnd", "missing 'end' in type declaration")
new_error("TypeAliasName", "expecting <name> after 'typealias'")
new_error("MissingEqTypeAlias", "missing '=' in 'typealias'")
new_error("DotIndex", "expecting <name> after '.'")
new_error("MethodName", "expecting <name> after ':'")
new_error("Then", "missing 'then'")
new_error("IfEnd", "missing 'end' to close if statement")
new_error("WhileDo", "missing 'do' in while statement")
new_error("WhileEnd", "missing 'end' to close while statement")
new_error("BlockEnd", "missing 'end' to close block")
new_error("ForDo", "missing 'do' in for statement")
new_error("ForEnd", "missing 'end' to close for statement")
new_error("Until", "missing 'until' in repeat statement")
new_error("FuncEnd", "missing 'end' to close function declaration")
new_error("ParList", "expecting '...'")
new_error("MethodCall", "expecting '(' for method call")
new_error("Label1", "expecting <name> after '::'")
new_error("Label2", "expecting '::' to close label declaration")
new_error("LocalAssign1", "expecting expression list after '='")
new_error("LocalAssign2", "invalid local declaration")
new_error("ForGen", "expecting 'in'")
new_error("LocalFunc", "expecting <name> in local function declaration")
new_error("RetStat", "invalid statement after 'return'")
new_error("ElseIf", "expecting <exp> after 'elseif'")
new_error("SubExpr_1", "malformed 'or' expression")
new_error("SubExpr_2", "malformed 'and' expression")
new_error("SubExpr_3", "malformed relational expression")
new_error("SubExpr_4", "malformed '|' expression")
new_error("SubExpr_5", "malformed '~' expression")
new_error("SubExpr_6", "malformed '&' expression")
new_error("SubExpr_7", "malformed shift expression")
new_error("SubExpr_8", "malformed '..' expression")
new_error("SubExpr_9", "malformed addition expression")
new_error("SubExpr_10", "malformed multiplication expression")
new_error("SubExpr_11", "malformed unary expression")
new_error("SubExpr_12", "malformed '^' expression")
new_error("Stat", "invalid statement")

local labels = {}
for k, v in ipairs(errors) do
  labels[v.label] = k
end

return {
  errors = errors,
  labels = labels,
}
