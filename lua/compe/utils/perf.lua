local Perf = {}

--- mark
Perf.mark = function(name, callback)
  return function(...)
    local x = os.clock()
    local result = callback(...)
    local elapsed = os.clock() - x
    vim.schedule(function()
      print(name, string.format('elapsed time: %.3f', elapsed))
    end)
    return result
  end
end

return Perf

