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
  ALPHA[string.byte(char)] = true
end)

local Character = {}

Character.is_upper = function(byte)
  return ALPHA[byte]
end

Character.is_alpha = function(byte)
  return alpha[byte] or ALPHA[byte]
end

Character.is_alnum = function(byte)
  return is_alpha(byte) or digit[byte]
end

Character.match = function(byte1, byte2)
  local diff = byte1 - byte2
  return diff == 0 or diff == 32 or diff == -32
end

return Character

