local Async = {}

Async._base_timer_id = 0
Async._timers = {}
Async._throttles = {}
Async._debounces = {}
Async._guards = {}

--- once
Async.once = function(callback)
  local once = false
  return function(...)
    if once then
      return
    end
    once = true
    callback(...)
  end
end

-- set_timeout
Async.set_timeout = function(callback, timeout)
  Async._base_timer_id = Async._base_timer_id + 1

  if timeout <= 0 then
    if vim.in_fast_event() then
      vim.schedule(callback)
    else
      callback()
    end
    return -1
  end

  local timer_id = Async._base_timer_id
  Async._timers[timer_id] = vim.loop.new_timer()
  Async._timers[timer_id]:start(timeout, 0, vim.schedule_wrap(function()
    Async.clear_timeout(timer_id)
    callback()
  end))
  return timer_id
end

-- clear_timeout
Async.clear_timeout = function(timer_id)
  if Async._timers[timer_id] then
    Async._timers[timer_id]:stop()
    Async._timers[timer_id]:close()
    Async._timers[timer_id] = nil
  end
end

--- throttle
Async.throttle = function(id, timeout, callback)
  Async._throttles[id] = Async._throttles[id] or {
    timer_id = -1;
    now = vim.loop.now();
  }

  local state = Async._throttles[id]
  Async.clear_timeout(state.timer_id)
  state.timer_id = Async.set_timeout(function()
    state.now = vim.loop.now()
    callback()
  end, math.max(0, timeout - (vim.loop.now() - state.now)))
end

--- debounce
Async.debounce = function(id, timeout, callback)
  Async.clear_timeout(Async._debounces[id])
  Async._debounces[id] = Async.set_timeout(function()
    callback()
  end, timeout)
end

--- guard
Async.guard = function(id, callback)
  Async._guards[id] = Async._guards[id] or 0
  Async._guards[id] = Async._guards[id] + 1

  local guard = Async._guards[id]
  return function(...)
    if Async._guards[id] ~= guard then
      return
    end
    callback(...)
  end
end

return Async

