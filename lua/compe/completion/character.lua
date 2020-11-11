local alpha = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
local digit = '1234567890'

local function is_upper(char)
  return string.lower(char) ~= char
end

local function is_alpha(char)
  return string.find(alpha, char, 1, true) ~= nil
end

local function is_alnum(char)
  return string.find(alpha .. digit, char, 1, true) ~= nil
end

return {
  is_upper = is_upper;
  is_alpha = is_alpha;
  is_alnum = is_alnum;
}

