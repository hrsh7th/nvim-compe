local Cache = {}

Cache._readthrough = {}

Cache.readthrough = function(id, key, callback)
  local cache = Cache._readthrough[id]
  if cache and cache.key == key then
    return cache.result
  end
  Cache._readthrough[id] = {
    key = key;
    result = callback();
  }
  return Cache._readthrough[id].result
end

return Cache

