local Debug = require'compe.utils.debug'
local Async = require'compe.utils.async'
local Cache = require'compe.utils.cache'
local String = require'compe.utils.string'
local Config = require'compe.config'
local Context = require'compe.context'
local Matcher = require'compe.matcher'
local VimBridge = require'compe.vim_bridge'

local Completion = {}

Completion._get_sources_cache_key = 0
Completion._sources = {}
Completion._context = Context.new({})
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
end

--- close
Completion.close = function()
  VimBridge.clear()

  for _, source in ipairs(Completion.get_sources()) do
    source:clear()
  end

  Completion._show(0, {})
  Completion._context = Context.new({})
end

--- confirm
Completion.confirm = function()
  local completed_item = Completion._selected_item

  if completed_item and completed_item.abbr then
    Completion._history[completed_item.abbr] = Completion._history[completed_item.abbr] or 0
    Completion._history[completed_item.abbr] = Completion._history[completed_item.abbr] + 1
  end

  if completed_item then
    for _, source in ipairs(Completion.get_sources()) do
      if source.id == completed_item.source_id then
        source:confirm(completed_item)
        break
      end
    end
  end

  Completion.close()
end

--- select
Completion.select = function(index)
  if index == -1 then
    return
  end

  local completed_item = Completion._current_items[(index == -2 and 0 or index) + 1]
  if completed_item then
    Completion._selected_item = completed_item

    for _, source in ipairs(Completion.get_sources()) do
      if source.id == completed_item.source_id then
        source:documentation(completed_item)
        break
      end
    end
  end
end

--- complete
Completion.complete = function(manual)
  if Completion:_should_ignore() then
    return
  end

  local context = Context.new({ manual = manual })

  -- Check the new context should be completed.
  if not Completion._context:should_complete(context) then
    return
  end

  local is_completing = (0 < Completion._current_offset and Completion._current_offset <= context.col)

  -- Restore pum if closed it automatically (backspace or invalid chars).
  local should_restore_pum = false
  should_restore_pum = should_restore_pum or Completion._context:maybe_backspace(context)
  should_restore_pum = should_restore_pum or vim.tbl_contains({ '-' }, context.before_char)
  if is_completing and vim.call('pumvisible') == 0 and should_restore_pum then
    Completion._show(Completion._current_offset, Completion._current_items)
  end

  if Config.get().autocomplete or (manual or is_completing) then
    local should_trigger = is_completing or not Completion._context:maybe_backspace(context)
    if should_trigger then
      if not Completion._trigger(context) then
        Completion._display(context)
      end
    end
  end

  -- If triggered, the `_display` will be called for each trigger callback.
  Completion._context = context
end

--- _trigger
Completion._trigger = function(context)
  if Completion:_should_ignore() then
    return false
  end

  local trigger = false
  for _, source in ipairs(Completion.get_sources()) do
    local status, value = pcall(function()
      trigger = source:trigger(context, function()
          Completion._display(Context.new({}))
      end)
    end)
    if not status then
      Debug.log(value)
    end
  end
  return trigger
end

--- _display
Completion._display = function(context)
  local sources = {}

  -- Check for processing source.
  Async.throttle('display:processing', 0, function() end)
  for _, source in ipairs(Completion.get_sources()) do
    if source.status == 'processing' then
      local processing_timeout = Config.get().source_timeout - source:get_processing_time()
      if processing_timeout > 0 then
        Async.throttle('display:processing', processing_timeout, function()
          Completion._display(context)
        end)
        return
      end
    else
      table.insert(sources, source)
    end
  end

  if #sources == 0 then
    return
  end

  local timeout = (vim.call('pumvisible') == 0 or context.manual) and 0 or Config.get().throttle_time
  Async.throttle('display:filter', timeout, function()
    -- Gather items and determine start_offset
    local start_offset = 0
    local items = {}
    local items_uniq = {}
    for _, source in ipairs(sources) do
      local source_start_offset = source:get_start_offset()
      if source_start_offset > 0 then
        local source_items = source:get_filtered_items(context)
        if #source_items > 0 then
          start_offset = (start_offset == 0 or start_offset > source_start_offset) and source_start_offset or start_offset

          -- Fix start_offset gap.
          local gap = string.sub(context.before_line, start_offset, source_start_offset - 1)
          for _, item in ipairs(source_items) do
            if items_uniq[item.original_word] == nil or item.original_dup ~= true then
              items_uniq[item.original_word] = true
              item.word = gap .. item.original_word
              item.abbr = string.rep(' ', #gap) .. item.original_abbr
              item.kind = item.original_kind or ''
              item.menu = item.original_menu or ''

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
  end)
end

--- _show
Completion._show = function(start_offset, items)
  Async.fast_schedule(function()
    Completion._current_offset = start_offset
    Completion._current_items = items
    Completion._selected_item = nil

    if not (vim.call('pumvisible') == 0 and #items == 0) then
      local should_preselect = false
      if items[1] then
        should_preselect = should_preselect or (Config.get().preselect == 'enable' and items[1].preselect)
        should_preselect = should_preselect or (Config.get().preselect == 'always')
      end

      local completeopt = vim.o.completeopt
      if should_preselect then
        vim.cmd('set completeopt=menu,menuone,noinsert')
      else
        vim.cmd('set completeopt=menu,menuone,noselect')
      end
      vim.call('complete', math.max(1, start_offset), items) -- start_offset=0 should close pum with `complete(1, [])`
      vim.cmd('set completeopt=' .. completeopt)
    end

    -- close documentation if needed.
    if start_offset == 0 or #items == 0 then
      vim.call('compe#documentation#close')
    end
  end)
end

--- _should_ignore
Completion._should_ignore = function()
  local should_ignore = false
  should_ignore = should_ignore or vim.call('compe#_is_selected_manually')
  should_ignore = should_ignore or string.sub(vim.call('mode'), 1, 1) ~= 'i'
  should_ignore = should_ignore or vim.call('getbufvar', '%', '&buftype') == 'prompt'
  return should_ignore
end

return Completion

