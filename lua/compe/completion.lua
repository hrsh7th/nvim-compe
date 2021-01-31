local Debug = require'compe.utils.debug'
local Async = require'compe.utils.async'
local Cache = require'compe.utils.cache'
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
  return Cache.readthrough('Completion.get_sources', Completion._get_sources_cache_key, function()
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

  -- Restore pum if vim close it automatically (backspace or invalid chars).
  local is_completing = (0 < Completion._current_offset and Completion._current_offset <= context.col)
  if is_completing and vim.call('pumvisible') == 0 then
    Completion._show(Completion._current_offset, Completion._current_items)
  end

  if Config.get().autocomplete or (manual or is_completing) then
    local should_trigger = is_completing or not Completion._context:maybe_backspace(context)
    if should_trigger then
      Completion._trigger(context)
      Completion._display(context)
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
      trigger = source:trigger(context, (function(source)
        return function()
          Completion._display(Context.new({}))
        end
      end)(source)) or trigger
    end)
    if not status then
      Debug.log(value)
    end
  end
  return trigger
end

--- _display
Completion._display = function(context)
  Async.throttle('display:processing', -1, function() end)

  -- Check for processing source.
  for _, source in ipairs(Completion.get_sources()) do
    local should_wait_processing = true
    should_wait_processing = should_wait_processing and source.status == 'processing' -- source is processing
    should_wait_processing = should_wait_processing and source:get_processing_time() < Config.get().source_timeout -- processing timeout
    if should_wait_processing then
      local timeout = Config.get().source_timeout - source:get_processing_time()
      Async.throttle('display:processing', math.max(1, timeout), function()
        if source.status == 'processing' then
          Completion._display(Context.new({}))
        end
      end)
      return
    end
  end

  local timeout = (vim.call('pumvisible') == 0 or context.manual) and -1 or Config.get().throttle_time
  Async.throttle('display:filter', timeout, function()
    if Completion:_should_ignore() then
      return
    end

    -- Gather items and determine start_offset
    local use_trigger_character = false
    local start_offset = 0
    local items = {}
    local items_uniq = {}
    for _, source in ipairs(Completion.get_sources()) do
      local source_start_offset = source:get_start_offset()
      if source_start_offset > 0 then
        -- Prefer prior source's trigger character
        if source.is_triggered_by_character or not use_trigger_character then
          -- If source status is completed but it does not provide any items, it will be ignored (don't use start_offset, trigger character).
          local source_items = Matcher.match(context, source)
          if #source_items > 0 then
            start_offset = (start_offset == 0 or start_offset > source_start_offset) and source_start_offset or start_offset
            use_trigger_character = use_trigger_character or source.is_triggered_by_character

            -- Fix start_offset gap.
            local gap = string.sub(context.before_line, start_offset, source_start_offset - 1)
            for _, item in ipairs(source_items) do
              if items_uniq[item.original_word] == nil or item.original_dup ~= true then
                items_uniq[item.original_word] = true
                item.word = gap .. item.original_word
                item.abbr = string.rep(' ', #gap) .. item.original_abbr
                table.insert(items, item)
              end
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
  end)
end

--- _show
Completion._show = function(start_offset, items)
  vim.schedule(function()
    if not (vim.call('pumvisible') == 0 and #items == 0) then
      local completeopt = vim.o.completeopt
      vim.cmd('set completeopt=menu,menuone,noselect')
      vim.call('complete', math.max(1, start_offset), items) -- start_offset=0 should close pum with `complete(1, [])`
      vim.cmd('set completeopt=' .. completeopt)
    end
    Completion._current_offset = start_offset
    Completion._current_items = items
    Completion._selected_item = nil

    -- close documentation if needed.
    if start_offset == 0 or #items == 0 then
      vim.call('compe#documentation#close')
    end

    -- preselect
    if items[1] then
      local should_preselect = false
      should_preselect = should_preselect or (Config.get().preselect == 'enable' and items[1].preselect)
      should_preselect = should_preselect or (Config.get().preselect == 'always')
      if should_preselect then
        vim.api.nvim_select_popupmenu_item(0, false, false, {})
      end
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

