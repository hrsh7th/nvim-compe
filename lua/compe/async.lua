local debounce_timers = {}
local throttle_timers = {}

local function debounce(id, timeout, callback)
  if debounce_timers[id] ~= nil then
    debounce_timers[id]:stop()
    debounce_timers[id]:close()
  end
  debounce_timers[id] = vim.loop.new_timer()
  debounce_timers[id]:start(timeout, 0, vim.schedule_wrap(callback))
end

local function throttle(id, timeout, callback)
  if throttle_timers[id] ~= nil then
    return
  end
  throttle_timers[id] = vim.loop.new_timer()
  throttle_timers[id]:start(timeout, 0, function()
    throttle_timers[id] = nil
    vim.schedule(callback)
  end)
end

return {
  debounce = debounce;
  throttle = throttle;
}

