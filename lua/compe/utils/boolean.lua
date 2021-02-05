local Boolean = {}

--- get
Boolean.get = function(v, def)
  if v == nil then
    return def
  end
  return v == true or v == 1
end

return Boolean

