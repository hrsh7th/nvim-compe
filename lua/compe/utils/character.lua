local alpha = {}
string.gsub('abcdefghijklmnopqrstuvwxyz', '.', function(char)
  alpha[string.byte(char)] = true
end)

local ALPHA = {}
string.gsub('ABCDEFGHIJKLMNOPQRSTUVWXYZ', '.', function(char)
  ALPHA[string.byte(char)] = true
end)

local digit = {}
string.gsub('1234567890', '.', function(char)
  digit[string.byte(char)] = true
end)

local white = {}
white[string.byte(' ')] = true
white[string.byte('\t')] = true

local Character = {}

Character.is_upper = function(byte)
  return ALPHA[byte]
end

Character.is_alpha = function(byte)
  return alpha[byte] or ALPHA[byte]
end

Character.is_digit = function(byte)
  return digit[byte]
end

Character.is_white = function(byte)
  return white[byte]
end

Character.is_symbol = function(byte)
  return not (Character.is_alnum(byte) or Character.is_white(byte))
end

Character.is_alnum = function(byte)
  return Character.is_alpha(byte) or Character.is_digit(byte)
end

Character.is_semantic_index = function(bytes, index)
  if index <= 1 then
    return true
  end
  if not Character.is_upper(bytes[index - 1]) and Character.is_upper(bytes[index]) then
    return true
  end
  if not Character.is_alpha(bytes[index - 1]) and Character.is_alpha(bytes[index]) then
    return true
  end
  return false
end

Character.get_next_semantic_index = function(bytes, current_index)
  for i = current_index + 1, #bytes do
    if Character.is_semantic_index(bytes, i) then
      return i
    end
  end
  return #bytes + 1
end

Character.match = function(byte1, byte2)
  if not Character.is_alpha(byte1) or not Character.is_alpha(byte2) then
    return byte1 == byte2
  end
  local diff = byte1 - byte2
  return diff == 0 or diff == 32 or diff == -32
end

return Character

