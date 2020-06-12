local debounce_timers = {}

local function debounce(id, timeout, callback)
  if debounce_timers[id] ~= nil then
    debounce_timers[id]:close()
  end
  debounce_timers[id] = vim.loop.new_timer()
  debounce_timers[id]:start(timeout, 0, vim.schedule_wrap(callback))
end

return {
  debounce = debounce
}

