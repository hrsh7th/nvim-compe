local Debug = require'compe.utils.debug'
local Callback = require'compe.utils.callback'
local Completion = require'compe.completion'
local Source = require'compe.source'
local Config = require'compe.config'
local Helper = require'compe.helper'
local VimBridge = require'compe.vim_bridge'

--- suppress
-- suppress errors.
local suppress = function(callback)
  return function(...)
    local args = ...
    local status, value = pcall(function()
      return callback(args) or ''
    end)
    if not status then
      Debug.log(value)
    end
    return value
  end
end

--- enable
-- call function if enabled.
local enable = function(callback)
  return function(...)
    if Config.get().enabled then
      return callback(...) or ''
    end
  end
end

local idle = function(callback)
  return function(...)
    -- if vim.fn.getchar(1) ~= 0 then
    --   return
    -- end
    return callback(...) or ''
  end
end

local compe = {}

--- Public API

--- helper
compe.helper = Helper

--- setup
compe.setup = function(config, bufnr)
  Config.setup(config, bufnr)
end

--- register_source
compe.register_source = function(name, source)
  if not string.match(name, '^[%a_]+$') then
    error("the source's name must be [%a_]+")
  end
  local source = Source.new(name, source)
  Completion.register_source(source)
  return source.id
end

--- unregister_source
compe.unregister_source = function(id)
  Completion.unregister_source(id)
end

--- Private API

--- _complete
compe._complete = enable(function(option)
  Completion.complete(option)
  return ''
end)

--- _close
compe._close = enable(function()
  Completion.close()
  return ''
end)

--- _confirm_pre
compe._confirm_pre = enable(suppress(function(index)
  return Completion.confirm_pre(index)
end))

--- _confirm
compe._confirm = enable(suppress(function()
  Completion.confirm()
end))

--- _register_vim_source
compe._register_vim_source = function(name, bridge_id, methods)
  local source = Source.new(name, VimBridge.new(bridge_id, methods))
  Completion.register_source(source)
  return source.id
end

--- _on_insert_enter
compe._on_insert_enter = idle(enable(suppress(function()
  Completion.enter_insert()
end)))

--- _on_insert_leave
compe._on_insert_leave = idle(enable(suppress(function()
  Completion.leave_insert()
end)))

--- _on_text_changed
compe._on_text_changed = idle(enable(suppress(function()
  Completion.complete({})
end)))

--- _on_complete_changed
compe._on_complete_changed = idle(enable(suppress(function()
  Completion.select({
    index = vim.call('complete_info', {'selected' }).selected or -1;
    manual = vim.call('compe#_is_selected_manually');
    documentation = true;
  })
end)))

--- _on_callback
compe._on_callback = function(id, ...)
  Callback.call(id, ...)
end

return compe

