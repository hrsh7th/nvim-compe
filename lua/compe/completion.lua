local Async = require'compe.utils.async'
local Cache = require'compe.utils.cache'
local String = require'compe.utils.string'
local Config = require'compe.config'
local Context = require'compe.context'
local Matcher = require'compe.matcher'
local VimBridge = require'compe.vim_bridge'

--- guard
local guard = function(callback)
  return function(...)
    local invalid = false
    invalid = invalid or vim.call('compe#_is_selected_manually')
    invalid = invalid or vim.call('getbufvar', '%', '&buftype') == 'prompt'
    invalid = invalid or string.sub(vim.call('mode'), 1, 1) ~= 'i'
    if not invalid then
      callback(...)
    end
  end
end

local Completion = {}

Completion._get_sources_cache_key = 0
Completion._sources = {}
Completion._context = Context.new_empty()
Completion._current_offset = 0
Completion._current_items = {}
Completion._selected_item = nil
Completion._history = {}

--- register_source
Completion.register_source = function(source)
  Completion._sources[source.id] = source
  Completion._get_sources_cache_key = Completion._get_sources_cache_key + 1
end

--- unregister_source
Completion.unregister_source = function(id)
  Completion._sources[id] = nil
  Completion._get_sources_cache_key = Completion._get_sources_cache_key + 1
end

--- get_sources
Completion.get_sources = function()
  return Cache.ensure('Completion.get_sources', Completion._get_sources_cache_key, function()
    local sources = {}
    for _, source in pairs(Completion._sources) do
      if Config.is_source_enabled(source.name) then
        table.insert(sources, source)
      end
    end

    table.sort(sources, function(source1, source2)
      local meta1 = source1:get_metadata()
      local meta2 = source2:get_metadata()
      if meta1.priority ~= meta2.priority then
        return meta1.priority > meta2.priority
      end
    end)

    return sources
  end)
end

--- enter_insert
Completion.enter_insert = function()
  Completion.close()
  Completion._get_sources_cache_key = Completion._get_sources_cache_key + 1
end

--- leave_insert
Completion.leave_insert = function()
  Completion.close()
  Completion._get_sources_cache_key = Completion._get_sources_cache_key + 1
end

--- confirm
Completion.confirm = function()
  local completed_item = Completion._selected_item
  if completed_item then
    Completion._history[completed_item.abbr] = Completion._history[completed_item.abbr] or 0
    Completion._history[completed_item.abbr] = Completion._history[completed_item.abbr] + 1

    for _, source in ipairs(Completion.get_sources()) do
      if source.id == completed_item.source_id then
        source:confirm(completed_item, function()
          Completion.close()
          Completion.complete({ trigger_character_only = true })
        end)
        break
      end
    end
  else
    Completion.close()
  end
end

--- select
Completion.select = function(args)
  local completed_item = Completion._current_items[(args.index == -2 and 0 or args.index) + 1]
  if completed_item then
    Completion._selected_item = completed_item

    if args.documentation and Config.get().documentation then
      for _, source in ipairs(Completion.get_sources()) do
        if source.id == completed_item.source_id then
          source:documentation(completed_item)
          break
        end
      end
    end
  end
end

--- close
Completion.close = function()
  for _, source in ipairs(Completion.get_sources()) do
    source:clear()
  end

  VimBridge.clear()
  vim.call('compe#documentation#close')
  Completion._show(0, {}, Completion._context)
  Completion._current_items = {}
  Completion._current_offset = 0
  Completion._selected_item = nil
end

--- complete
Completion.complete = guard(function(option)
  local context = Completion._new_context(option)
  local is_manual_completing = context.is_completing and not Config.get().autocomplete
  local is_completing_backspace = context.is_completing and context:maybe_backspace()

  -- Trigger
  if is_manual_completing or is_completing_backspace or context:should_auto_complete() then
    Completion._trigger(context)
  end

  -- Restoreo
  if context.is_completing and context.prev_context.is_completing and not context.pumvisible and context.prev_context.pumvisible then
    Completion._show(Completion._current_offset, Completion._current_items, context)
  end

  -- Filter
  if context.is_completing then
    Completion._display(context)
  end
end)

--- _trigger
Completion._trigger = function(context)
  Async.debounce('Completion._trigger:callback', 0, function() end)

  local trigger = false
  for _, source in ipairs(Completion.get_sources()) do
    trigger = source:trigger(context, function()
      Async.debounce('Completion._trigger:callback', 10, function()
        Completion._display(Completion._new_context(context.option))
      end)
    end) or trigger
  end
  return trigger
end

--- _display
Completion._display = guard(function(context)
  Async.debounce('Completion._display', 0, function() end)

  -- Check completing sources.
  local sources = {}
  for _, source in ipairs(Completion.get_sources()) do
    local timeout = Config.get().source_timeout - source:get_processing_time()
    if timeout > 0 then
      Async.debounce('Completion._display', timeout + 1, function()
        Completion._display(Completion._new_context(context.option))
      end)
      return
    end
    if source:is_completing(context) then
      table.insert(sources, source)
    end
  end

  local start_offset = Completion._get_start_offset(context)
  local items = {}
  local items_uniq = {}
  for _, source in ipairs(sources) do
    local source_items = source:get_filtered_items(context)
    if #source_items > 0 and start_offset == source:get_start_offset() then
      for _, item in ipairs(source_items) do
        if items_uniq[item.original_word] == nil or item.original_dup == 1 then
          items_uniq[item.original_word] = true
          item.word = item.original_word
          item.abbr = item.original_abbr
          item.kind = item.original_kind or ''
          item.menu = item.original_menu or ''

          item.kind = Config.get().kind_mapping[item.kind] or item.kind
          -- trim to specified width.
          item.abbr = String.trim(item.abbr, Config.get().max_abbr_width)
          item.kind = String.trim(item.kind, Config.get().max_kind_width)
          item.menu = String.trim(item.menu, Config.get().max_menu_width)
          table.insert(items, item)
        end
      end
      if source.is_triggered_by_character then
        break
      end
    end
  end

  --- Sort items
  table.sort(items, function(item1, item2)
    return Matcher.compare(item1, item2, Completion._history)
  end)

  if #items == 0 then
    Completion._show(0, {}, context)
  else
    Completion._show(start_offset, items, context)
  end
end)

--- _show
Completion._show = function(start_offset, items, context)
  local curr_pumvisible = (Completion._current_offset ~= 0 and #Completion._current_items ~= 0)
  local next_pumvisible = (start_offset ~= 0 and #items ~= 0)
  local pummove = start_offset ~= Completion._current_offset
  local timeout = (function()
    if curr_pumvisible ~= next_pumvisible then
      return 0
    end
    if pummove then
      return 0
    end
    if context:maybe_backspace() then
      return 0
    end
    return Config.get().throttle_time
  end)()

  Completion._current_offset = start_offset
  Completion._current_items = items
  Async.throttle('Completion._show', timeout, Async.guard('Completion._show', guard(function()
    if curr_pumvisible then
      if not next_pumvisible then
        vim.call('compe#documentation#close')
      end
    end

    local should_preselect = false
    if items[1] then
      should_preselect = should_preselect or (Config.get().preselect == 'enable' and items[1].preselect)
      should_preselect = should_preselect or (Config.get().preselect == 'always')
    end

    local completeopt = vim.o.completeopt
    if context.option.completeopt then
      vim.cmd('set completeopt=' .. context.option.completeopt)
    elseif should_preselect then
      vim.cmd('set completeopt=menuone,noinsert')
    else
      vim.cmd('set completeopt=menuone,noselect')
    end
    vim.call('complete', math.max(1, start_offset), items) -- start_offset=0 should close pum with `complete(1, [])`
    vim.cmd('set completeopt=' .. completeopt)

    if curr_pumvisible and next_pumvisible and should_preselect then
      Completion.select({
        index = 0,
        documentation = true
      })
    end
  end)))
end

--- _new_context
Completion._new_context = function(option)
  Completion._context = Context.new(option, Completion._context)
  local context = Completion._context
  context.is_completing = Completion._is_completing(context)
  context.start_offset = Completion._get_start_offset(context)
  context.pumvisible = vim.call('pumvisible') == 1
  return context
end

--- _is_completing
Completion._is_completing = function(context)
  for _, source in ipairs(Completion.get_sources()) do
    if source:is_completing(context) then
      return true
    end
  end
  return false
end

--- _get_start_offset
Completion._get_start_offset = function(context)
  local start_offset = context.col + 1
  for _, source in ipairs(Completion.get_sources()) do
    if source:is_completing(context) then
      start_offset = math.min(start_offset, source:get_start_offset())
    end
  end
  return start_offset ~= context.col + 1 and start_offset or 0
end

return Completion
