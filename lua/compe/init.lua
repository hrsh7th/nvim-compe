local Debug = require'compe.utils.debug'
local Callback = require'compe.utils.callback'
local api = vim.api
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

do
  local function replace(keys)
    return vim.api.nvim_replace_termcodes(keys, true, true, true)
  end

  local function feedkeys(keys)
    api.nvim_feedkeys(replace(keys), 'n', true)
  end

  local input = api.nvim_input

  local function mode() return api.nvim_get_mode()['mode'] end

  -- use with expr mapping
  compe.confirm = function(keys)
    if vim.fn.pumvisible() == 0 then return replace(keys) end

    local mode_correct = mode():match('i') ~= nil

    if mode_correct
      and vim.fn.complete_info({'selected'})['selected'] == -1
      and Config.get().preselect == 'confirm'
      then
        feedkeys("<Down>") -- selected the next one
    end

    local function run()
      vim.fn.luaeval('require"compe"._confirm_pre()')
      input('<Plug>(compe-confirm)')
    end

    -- we have to check this first because calling complete_info again will cause it to screw up
    if Config.get().preselect == 'confirm' then
      run()
    elseif mode_correct and vim.fn.complete_info({'selected'})['selected'] ~= -1 then
      run()
    else
      return replace(keys)
    end

    return replace('<Ignore>')
  end
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
compe._confirm_pre = enable(function()
  Completion.confirm_pre({
    index = vim.call('complete_info', {'selected' }).selected or -1;
  })
end)

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
compe._on_insert_enter = enable(suppress(function()
  Completion.enter_insert()
end))

--- _on_insert_leave
compe._on_insert_leave = enable(suppress(function()
  Completion.leave_insert()
end))

--- _on_text_changed
compe._on_text_changed = enable(suppress(function()
  Completion.complete({})
end))

--- _on_complete_changed
compe._on_complete_changed = enable(suppress(function()
  Completion.select({
    index = vim.call('complete_info', {'selected' }).selected or -1;
    manual = vim.call('compe#_is_selected_manually');
    documentation = true;
  })
end))

--- _on_callback
compe._on_callback = function(id, ...)
  Callback.call(id, ...)
end

return compe

