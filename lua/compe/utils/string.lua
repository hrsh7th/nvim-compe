local Character = require'compe.utils.character'

local String = {}

String.INVALID_CHARS = {}
String.INVALID_CHARS[string.byte(' ')] = true
String.INVALID_CHARS[string.byte('\t')] = true
String.INVALID_CHARS[string.byte('\n')] = true
String.INVALID_CHARS[string.byte('=')] = true
String.INVALID_CHARS[string.byte('$')] = true
String.INVALID_CHARS[string.byte('(')] = true
String.INVALID_CHARS[string.byte('"')] = true
String.INVALID_CHARS[string.byte("'")] = true

--- match_prefix
String.match_prefix = function(text, prefix)
  if #text < #prefix then
    return false
  end

  for i = 1, #prefix do
    if not Character.match(string.byte(text, i), string.byte(prefix, i)) then
      return false
    end
  end
  return true
end


--- omit
String.omit = function(text, width)
  if width == 0 then
    return ''
  end

  if not text then
    text = ''
  end
  if #text > width then
    return string.sub(text, 1, width + 1) .. '...'
  end
  return text
end

--- trim
String.trim = function(text)
  local s = 1
  for i = 1, #text do
    if not Character.is_white(string.byte(text, i)) then
      s = i
      break
    end
  end

  local e = #text
  for i = #text, 1, -1 do
    if not Character.is_white(string.byte(text, i)) then
      e = i
      break
    end
  end
  if s == 1 and e == #text then
    return text
  end
  return string.sub(text, s, e)
end

--- get_word
String.get_word = function(word, prefix)
  local s = 0
  if #prefix > 0 then
    local i = 1
    while i <= #word do
      local found = true
      for j = 1, #prefix do
        if not Character.match(string.byte(word, i + j - 1), string.byte(prefix, j)) then
          found = false
          break
        end
      end
      if found then
        s = i
        break
      end
      i = i + 1
    end
  end

  local e = s + 1
  while e <= #word do
    if s == 0 then
      if not String.INVALID_CHARS[string.byte(word, e)] then
        s = e
      end
    else
      if String.INVALID_CHARS[string.byte(word, e)] then
        e = e - 1
        break
      end
    end
    e = e + 1
  end

  if s == 1 and e >= #word then
    return word
  end

  if s ~= 0 then
    return string.sub(word, s, e)
  end
  return ''
end

--- make_byte_map
String.make_byte_map = function(word)
  local map = {}
  for i = 1, #word do
    map[string.byte(word, i)] = true
  end
  return map
end

return String

