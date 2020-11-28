local alpha = {
  a = true,
  b = true,
  c = true,
  d = true,
  e = true,
  f = true,
  g = true,
  h = true,
  i = true,
  j = true,
  k = true,
  l = true,
  m = true,
  n = true,
  o = true,
  p = true,
  q = true,
  r = true,
  s = true,
  t = true,
  u = true,
  v = true,
  w = true,
  x = true,
  y = true,
  z = true,
}

local digit = {
  ['1'] = true,
  ['2'] = true,
  ['3'] = true,
  ['4'] = true,
  ['5'] = true,
  ['6'] = true,
  ['7'] = true,
  ['8'] = true,
  ['9'] = true,
  ['0'] = true,
}

local ALPHA = {
  A = true,
  B = true,
  C = true,
  D = true,
  E = true,
  F = true,
  G = true,
  H = true,
  I = true,
  J = true,
  K = true,
  L = true,
  M = true,
  N = true,
  O = true,
  P = true,
  Q = true,
  R = true,
  S = true,
  T = true,
  U = true,
  V = true,
  W = true,
  X = true,
  Y = true,
  Z = true,
}

local Character = {}

Character.is_upper = function(char)
  return ALPHA[char]
end

Character.is_alpha = function(char)
  return alpha[char] or ALPHA[char]
end

Character.is_alnum = function(char)
  return is_alpha(char) or digit[char]
end

return Character
