local is_nvim = vim.fn.has('nvim')

local Compat = {}

function Compat.safe(data)
  if type(data) ~= 'table' then
    if is_nvim and data == vim.NIL then
      return nil
    end
    return data
  end

  local safe = {}
  for k, v in pairs(data) do
    safe[k] = Compat.safe(v)
  end
  return safe
end

return Compat
