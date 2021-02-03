local Cache = {}

Cache._cache = {}

Cache.get = function(id, key)
  local cache = Cache._cache[id]
  if cache then
    if cache.key == key then
      return cache.value
    end
  end
  return nil
end

Cache.set = function(id, key, value)
  Cache._cache[id] = {
    key = key,
    value = value,
  }
end

Cache.ensure = function(id, key, callback)
  local value = Cache.get(id, key)
  if value ~= nil then
    return value
  end
  local value = callback()
  Cache.set(id, key, value)
  return value
end

return Cache

