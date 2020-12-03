local throttle_timer = {}

local Async = {}

Async._base_timer_id = 0
Async._timers = {}

Async.set_timeout = function(callback, timeout)
  Async._base_timer_id = Async._base_timer_id + 1

  if timeout < 0 then
    vim.schedule(callback)
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

Async.clear_timeout = function(timer_id)
  if Async._timers[timer_id] then
    Async._timers[timer_id]:stop()
    Async._timers[timer_id]:close()
    Async._timers[timer_id] = nil
  end
end

Async.throttle = function(id, timeout, callback)
  throttle_timer[id] = throttle_timer[id] or {
    timer_id = -1;
    now = vim.loop.now();
  }

  local state = throttle_timer[id]
  Async.clear_timeout(state.timer_id)
  state.timer_id = Async.set_timeout(function()
    throttle_timer[id] = nil
    callback()
  end, timeout - (vim.loop.now() - state.now))
  state.now = vim.loop.now()
end

return Async

