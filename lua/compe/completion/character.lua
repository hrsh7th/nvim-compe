local alpha = {}
string.gsub('abcdefghijklmnopqrstuvwxyz', '.', function(char)
  alpha[char] = string.byte(char)
  alpha[string.byte(char)] = char
end)

local ALPHA = {}
string.gsub('ABCDEFGHIJKLMNOPQRSTUVWXYZ', '.', function(char)
  ALPHA[char] = string.byte(char)
  ALPHA[string.byte(char)] = char
end)

local digit = {}
string.gsub('1234567890', '.', function(char)
  ALPHA[char] = string.byte(char)
  ALPHA[string.byte(char)] = char
end)

local Character = {}

Character.is_upper = function(char)
  return ALPHA[char] ~= nil
end

Character.is_alpha = function(char)
  return alpha[char] ~= nil or ALPHA[char] ~= nil
end

Character.is_alnum = function(char)
  return is_alpha(char) ~= nil or digit[char] ~= nil
end

Character.match = function(byte1, byte2)
  local diff = byte1 - byte2
  return diff == 0 or diff == 32 or diff == -32
end

return Character

