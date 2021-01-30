local Debug = require'compe.utils.debug'
local Pattern = require'compe.pattern'
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
      return callback(args)
    end)
    if not status then
      Debug.log(value)
    end
  end
end

--- enable
-- call function if enabled.
local enable = function(callback)
  return function(...)
    if Config.get().enabled then
      return callback(...)
    end
  end
end

local compe = {}

--- Public API

--- helper
compe.helper = Helper

--- setup
compe.setup = function(config)
  Pattern.set_filetype_config('vim', {
    keyword_pattern = [[\%(\h\%(\w\|#\)*\)]];
  })
  Pattern.set_filetype_config('php', {
    keyword_pattern = [[\%(\$\w*\|\h\w*\)]];
  })
  Pattern.set_filetype_config('html', {
    keyword_pattern = [[\%(/\h\?\w*\|\h\w*\)]];
  })
  Config.setup(config)
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
compe._complete = enable(function()
  Completion.complete(true)
  return ''
end)

--- _close
compe._close = enable(function()
  Completion.close()
  return ''
end)

--- _register_vim_source
compe._register_vim_source = function(name, bridge_id)
  local source = Source.new(name, VimBridge.new(bridge_id))
  Completion.register_source(source)
  return source.id
end

--- _on_insert_enter
compe._on_insert_enter = enable(suppress(function()
  Completion.enter_insert()
end))

--- _on_insert_leave
compe._on_insert_leave = enable(suppress(function()
  Completion.leave_insert()
end))

--- _on_text_changed
compe._on_text_changed = enable(suppress(function()
  Completion.complete(false)
end))

--- _on_complete_changed
compe._on_complete_changed = enable(suppress(function()
  Completion.select(vim.call('complete_info', {'selected' }).selected or -1)
end))

--- _on_complete_done
compe._on_complete_done = enable(suppress(function()
  if vim.call('compe#_has_completed_item') then
    Completion.confirm()
  end
end))

return compe

