local seq2str

local function id2str (t)
  local tag = t.tag
  if tag == "Id" then
    return string.format("%s \"%s\"", tag, t[1])
  else
    error("invalid identifier: " .. tag)
  end
end

local function exp2str (t)
  local tag = t.tag
  if tag == "Number" then
    return string.format("%s %d", tag, t[1])
  elseif tag == "Id" then
    return id2str(t)
  elseif tag == "Lt" or
         tag == "Eq" or
         tag == "Add" or
         tag == "Sub" or
         tag == "Mul" or
         tag == "Div" then
    return string.format("%s (%s) (%s)", tag, exp2str(t[1]), exp2str(t[2]))
  else
    error("invalid expression: " .. tag)
  end
end

local function cmd2str (t)
  local tag = t.tag
  if tag == "If" then
    local str = string.format("%s (%s) %s ", tag, exp2str(t[1]), seq2str(t[2]))
    if not t[3] then
      return str
    else
      return str .. seq2str(t[3])
    end
  elseif tag == "Repeat" then
    return string.format("%s %s (%s)", tag, seq2str(t[1]), exp2str(t[2]))
  elseif tag == "Assign" then
    return string.format("%s (%s) (%s)", tag, id2str(t[1]), exp2str(t[2]))
  elseif tag == "Read" then
    return string.format("%s (%s)", tag, id2str(t[1]))
  elseif tag == "Write" then
    return string.format("%s (%s)", tag, exp2str(t[1]))
  else
    error("invalid command: " .. tag)
  end
end

seq2str = function (t)
  local tag = t.tag
  if tag == "Seq" then
    local tt = {}
    for i = 1, #t do
      tt[#tt + 1] = cmd2str(t[i])
    end
    return "[" .. table.concat(tt, ", ") .. "]"
  else
    error("invalid command sequence: " .. tag)
  end
end

return {
  __tostring = seq2str
}
