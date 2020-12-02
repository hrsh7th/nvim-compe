local Debug = require'compe.utils.debug'
local Async = require'compe.utils.async'
local Cache = require'compe.utils.cache'
local Config = require'compe.config'
local Context = require'compe.context'
local Matcher = require'compe.matcher'
local VimBridge = require'compe.vim_bridge'

local Completion = {}

Completion._insert_id = 0
Completion._sources = {}
Completion._context = Context.new({})
Completion._current_offset = 0
Completion._current_items = {}
Completion._history = {}

--- register_source
Completion.register_source = function(source)
  Completion._sources[source.id] = source
end

--- unregister_source
Completion.unregister_source = function(id)
  Completion._sources[id] = nil
end

--- get_sources
Completion.get_sources = function()
  return Cache.readthrough('Completion.get_sources', Completion._insert_id, function()
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

--- start_insert
Completion.start_insert = function()
  Completion.close()
  Completion._insert_id = Completion._insert_id + 1
end

--- close
Completion.close = function()
  VimBridge.clear()

  for _, source in ipairs(Completion.get_sources()) do
    source:clear()
  end

  if vim.call('pumvisible') == 1 then
    Completion._show(1, {})
  end

  vim.call('compe#documentation#close')

  Completion._context = Context.new({})
end

--- confirm
Completion.confirm = function(completed_item)
  Completion.close()
  if completed_item and completed_item.abbr then
    Completion._history[completed_item.abbr] = Completion._history[completed_item.abbr] or 0
    Completion._history[completed_item.abbr] = Completion._history[completed_item.abbr] + 1
  end
end

--- select
Completion.select = function(index)
  if index == -1 then
    return
  end

  local completed_item = Completion._current_items[(index == -2 and 0 or index) + 1]
  if completed_item then
    for _, source in ipairs(Completion.get_sources()) do
      if source.id == completed_item.source_id then
        source:documentation(vim.v.event, completed_item)
        break
      end
    end
  end
end

--- complete
Completion.complete = function(manual)
  local timeout = (vim.call('pumvisible') == 1 and not manual) and Config.get().throttle_time or 0
  Async.throttle('complete', timeout, Async.fast_schedule_wrap(function()
    local context = Context.new({ manual = manual })
    if not Completion._context:should_complete(context) then
      return
    end

    if not Completion._trigger(context) then
      Completion._display(context)
    end
    Completion._context = context
  end))
end

--- _trigger
Completion._trigger = function(context)
  if vim.call('compe#_is_selected_manually') then
    return
  end

  local trigger = false
  for _, source in ipairs(Completion.get_sources()) do
    local status, value = pcall(function()
      trigger = source:trigger(context, function()
        Completion._display(Context.new({ manual = true } ))
      end) or trigger
    end)
    if not status then
      Debug.log(value)
    end
  end
  return trigger
end

--- _display
Completion._display = function(context)
  -- Remove throttle timers when display method called.
  Async.throttle('display:processing', 0, function() end)

  -- Check for unexpected state
  if Completion._should_ignore_display() then
    return
  end

  -- Check for waiting processing source.
  for _, source in ipairs(Completion.get_sources()) do
    local should_wait_processing = true
    should_wait_processing = should_wait_processing and source.status == 'processing' -- source is processing
    should_wait_processing = should_wait_processing and (vim.loop.now() - source.context.time) < Config.get().source_timeout -- processing timeout
    if should_wait_processing then
      -- Reserve to call display after timeout.
      Async.throttle('display:processing', Config.get().source_timeout, Async.fast_schedule_wrap(function()
        Completion._display(context)
      end))

      -- The vim will hide pum when press backspace so we restore manually.
      if Completion._context:maybe_backspace(context) then
        if Completion._current_offset > 0 then
          Async.fast_schedule(function()
            Completion._show(Completion._current_offset, Completion._current_items)
          end)
        end
      end
      return
    end
  end

  -- Gather items and datermine start_offset
  local use_trigger_character = false
  local start_offset = 0
  local items = {}
  local items_uniq = {}
  for _, source in ipairs(Completion.get_sources()) do
    local source_start_offset = source:get_start_offset()
    if source_start_offset > 0 then
      -- Prefer prior source's trigger character
      if source.is_triggered_by_character or not use_trigger_character then
        if source.status == 'processing' then
          start_offset = (start_offset == 0 or start_offset > source_start_offset) and source_start_offset or start_offset
        elseif source.status == 'completed' then
          -- If source status is completed but it does not provide any items, it will be ignored (don't use start_offset, trigger character).
          local source_items = Matcher.match(context, source, Completion._history)
          if #source_items > 0 then
            start_offset = (start_offset == 0 or start_offset > source_start_offset) and source_start_offset or start_offset
            use_trigger_character = use_trigger_character or source.is_triggered_by_character

            -- Fix start_offset gap.
            local gap = string.sub(context.before_line, start_offset, source_start_offset - 1)
            for _, item in ipairs(source_items) do
              if items_uniq[item.original_word] == nil or item.dup ~= true then
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
  end

  local pumvisible = vim.call('pumvisible') == 1

  -- All sources didn't trigger.
  -- Clear current completion state.
  if (#items == 0 or start_offset <= 0) and pumvisible then
    Completion._show(1, {})
    return
  end

  -- Completion
  if #items > 0 or pumvisible then
    Completion._show(start_offset, items)
  end
end

--- _show
Completion._show = function(start_offset, items)
  Async.next('_show', function()
    local completeopt = vim.o.completeopt
    vim.cmd('set completeopt=menu,menuone,noselect')
    vim.call('complete', start_offset, items)
    vim.cmd('set completeopt=' .. completeopt)

    Completion._current_offset = start_offset
    Completion._current_items = items

    -- preselect
    if items[1] and items[1].preselect or Config.get().auto_preselect then
      vim.api.nvim_select_popupmenu_item(0, false, false, {})
    end
  end)
end

--- _should_ignore_display
Completion._should_ignore_display = function()
  local should_ignore_display = false
  should_ignore_display = should_ignore_display or vim.call('compe#_is_selected_manually')
  should_ignore_display = should_ignore_display or string.sub(vim.call('mode'), 1, 1) ~= 'i'
  should_ignore_display = should_ignore_display or vim.call('getbufvar', '%', '&buftype') == 'prompt'
  return should_ignore_display
end

return Completion

