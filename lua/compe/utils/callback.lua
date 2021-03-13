local Callback = {}

Callback._id = 0
Callback._callbacks = {}

--- set
Callback.set = function(callback)
  Callback._id = Callback._id + 1
  Callback._callbacks[Callback._id] = callback
  return Callback._id
end

--- call
Callback.call = function(id, ...)
  if Callback._callbacks[id] then
    Callback._callbacks[id](...)
    Callback._callbacks[id] = nil
  end
end

--- clear
Callback.clear = function()
  Callback._id = 0
  Callback._callbacks = {}
end

return Callback

