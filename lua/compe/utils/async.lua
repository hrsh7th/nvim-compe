local throttle_timer = {}
local debounce_timer = {}
local next_callback = {}

local function debounce(id, timeout, callback)
  if debounce_timer[id] then
    debounce_timer[id]:stop()
    debounce_timer[id]:close()
    debounce_timer[id] = nil
  end
  debounce_timer[id] = vim.loop.new_timer()
  debounce_timer[id]:start(timeout, 0, function()
    callback()
  end)
end

local function throttle(id, timeout, callback)
  if throttle_timer[id] then
    timeout = math.max(0, timeout - (vim.loop.now() - throttle_timer[id].now))
    throttle_timer[id].timer:stop()
    throttle_timer[id].timer:close()
    throttle_timer[id] = nil
  end
  throttle_timer[id] = {
    timer = vim.loop.new_timer();
    callback = callback;
    now = vim.loop.now();
  }
  throttle_timer[id].timer:start(timeout, 0, function()
    throttle_timer[id].callback()
    throttle_timer[id].timer:stop()
    throttle_timer[id].timer:close()
    throttle_timer[id] = nil
  end)
end

local function fast_schedule(callback)
  if not vim.in_fast_event() then
    callback()
  else
    vim.schedule(callback)
  end
end

local function fast_schedule_wrap(callback)
  return function()
    fast_schedule(callback)
  end
end

local function next(id, callback)
  next_callback[id] = callback
  fast_schedule(function()
    if next_callback[id] then
      next_callback[id]()
      next_callback[id] = nil
    end
  end)
end

return {
  throttle = throttle;
  debounce = debounce;
  next = next;
  fast_schedule = fast_schedule;
  fast_schedule_wrap = fast_schedule_wrap;
}
