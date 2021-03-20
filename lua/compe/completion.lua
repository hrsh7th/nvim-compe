local Async = require'compe.utils.async'
local Cache = require'compe.utils.cache'
local String = require'compe.utils.string'
local Callback = require'compe.utils.callback'
local Config = require'compe.config'
local Context = require'compe.context'
local Matcher = require'compe.matcher'

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
Completion._selected_manually = false
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

--- confirm_pre
Completion.confirm_pre = function(args)
  Completion.select({
    index = args.index,
    documentation = false,
  })
end

--- confirm
Completion.confirm = function()
  local completed_item = Completion._selected_item
  if completed_item then
    Completion._history[completed_item.abbr] = Completion._history[completed_item.abbr] or 0
    Completion._history[completed_item.abbr] = Completion._history[completed_item.abbr] + 1

    for _, source in ipairs(Completion.get_sources()) do
      if source.id == completed_item.source_id then
        source:confirm(completed_item)
        break
      end
    end
  end
  Completion.close()

  vim.cmd([[doautocmd <nomodeline> User CompeConfirmDone]])

  Completion.complete({ trigger_character_only = true })
end

--- select
Completion.select = function(args)
  local completed_item = Completion._current_items[(args.index == -2 and 0 or args.index) + 1]
  if completed_item then
    Completion._selected_item = completed_item
    Completion._selected_manually = args.manual or false

    if args.documentation and Config.get().documentation then
      for _, source in ipairs(Completion.get_sources()) do
        if source.id == completed_item.source_id then
          vim.schedule(Async.guard('documentation', function()
            source:documentation(completed_item)
          end))
          break
        end
      end
    end
  else
    vim.schedule(Async.guard('documentation', function()
      vim.call('compe#documentation#close')
    end))
  end
end

--- close
Completion.close = function()
  for _, source in ipairs(Completion.get_sources()) do
    source:clear()
  end

  vim.call('compe#documentation#close')
  Callback.clear()
  Completion._show(0, {})
  Completion._new_context({})
  Completion._current_items = {}
  Completion._current_offset = 0
  Completion._selected_item = nil
end

--- complete
Completion.complete = guard(function(option)
  local context = Completion._new_context(option)
  local is_manual_completing = context.is_completing and not Config.get().autocomplete
  local is_completing_backspace = context.is_completing and context:maybe_backspace()

  -- Restore
  if not Completion._selected_manually and context.is_completing and context.prev_context.is_completing and not context.pumvisible then
    Completion._show(Completion._current_offset, Completion._current_items)
  end

  -- Trigger
  local triggered = false
  if is_manual_completing or is_completing_backspace or context:should_auto_complete() then
    triggered = Completion._trigger(context)
  end

  -- Filter
  if not triggered then
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
        Completion._display(Completion._context)
      end)
    end) or trigger
  end
  return trigger
end

--- _display
Completion._display = guard(function(context)
  local timeout = context.pumvisible and Config.get().throttle_time or 0
  Async.throttle('Completion._display', timeout, Async.guard('Completion._display', guard(function()
    local context = Completion._context

    Async.debounce('Completion._display', 0, function() end)

    -- Check completing sources.
    local sources = {}
    local has_triggered_by_character = false
    for _, source in ipairs(Completion.get_sources()) do
      local timeout = Config.get().source_timeout - source:get_processing_time()
      if timeout > 0 then
        Async.debounce('Completion._display', timeout + 1, function()
          Completion._display(Completion._context)
        end)
        return
      end
      if source:is_completing(context) then
        has_triggered_by_character = has_triggered_by_character or source.is_triggered_by_character
        table.insert(sources, source)
      end
    end

    local start_offset = Completion._get_start_offset(context)
    local items = {}
    local items_uniq = {}
    for _, source in ipairs(sources) do
      if not has_triggered_by_character or source.is_triggered_by_character then
        local source_items = source:get_filtered_items(context)
        if #source_items > 0 and start_offset == source:get_start_offset() then
          for _, item in ipairs(source_items) do
            if items_uniq[item.original_word] == nil or item.original_dup == 1 then
              items_uniq[item.original_word] = true
              item.word = item.original_word
              item.abbr = item.original_abbr
              item.kind = item.original_kind or ''
              item.menu = item.original_menu or ''

              -- trim to specified width.
              item.abbr = String.omit(item.abbr, Config.get().max_abbr_width)
              item.kind = String.omit(item.kind, Config.get().max_kind_width)
              item.menu = String.omit(item.menu, Config.get().max_menu_width)
              table.insert(items, item)
            end
          end
        end
      end
    end

    --- Sort items
    table.sort(items, function(item1, item2)
      return Matcher.compare(item1, item2, Completion._history)
    end)

    if #items == 0 then
      Completion._show(0, {})
    else
      Completion._show(start_offset, items)
    end
  end)))
end)

--- _show
Completion._show = Async.guard('Completion._show', guard(function(start_offset, items)
  Completion._current_offset = start_offset
  Completion._current_items = items

  local should_preselect = false
  if items[1] then
    should_preselect = should_preselect or (Config.get().preselect == 'enable' and items[1].preselect)
    should_preselect = should_preselect or (Config.get().preselect == 'always')
  end

  local completeopt = vim.o.completeopt
  if should_preselect then
    vim.cmd('set completeopt=menuone,noinsert')
  else
    vim.cmd('set completeopt=menuone,noselect')
  end
  vim.call('complete', math.max(1, start_offset), items) -- start_offset=0 should close pum with `complete(1, [])`
  vim.cmd('set completeopt=' .. completeopt)

  if #items == 0 then
    vim.call('compe#documentation#close')
  end
end))

--- _new_context
Completion._new_context = function(option)
  local prev_context = vim.tbl_extend('keep', {}, Completion._context)
  prev_context.prev_context = nil
  Completion._context = Context.new(option, prev_context)

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

