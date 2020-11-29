local Debug = require'compe.debug'
local Async = require'compe.async'
local Context = require'compe.completion.context'
local Matcher = require'compe.completion.matcher'
local VimBridge = require'compe.completion.source.vim_bridge'

local Completion = {}

--- new
function Completion.new()
  local self = setmetatable({}, { __index = Completion })
  self.sources = {}
  self.context = Context.new({})
  self.current_offset = 0
  self.current_items = {}
  self.history = {}
  return self
end

--- register_source
function Completion.register_source(self, source)
  table.insert(self.sources, source)

  table.sort(self.sources, function(a, b)
    local a_meta = a:get_metadata()
    local b_meta = b:get_metadata()
    if a_meta.priority ~= b_meta.priority then
      return a_meta.priority > b_meta.priority
    end
  end)
end

--- unregister_source
function Completion.unregister_source(self, id)
  for i, source in ipairs(self.sources) do
    if id == source:get_id() then
      table.remove(self.sources, i)
      break
    end
  end
end

--- on_insert_leave
function Completion.on_insert_leave(self)
  self:clear()
  VimBridge.clear()
end

--- on_complete_done
function Completion.on_complete_done(self)
  local has_completed_item = vim.call('compe#has_completed_item')
  if has_completed_item then
    self:clear()
    self:add_history(vim.v.completed_item)
  end
end

--- on_complete_changed
function Completion.on_complete_changed(self)
  if vim.call('compe#is_selected_manually') then
    local selected = vim.call('complete_info', { 'selected' }).selected or -1
    selected = selected == -2 and 0 or selected

    local completed_item = self.current_items[selected + 1]
    if completed_item then
      for _, source in ipairs(self.sources) do
        if source.id == completed_item.source_id then
          source:documentation(vim.v.event, completed_item)
          break
        end
      end
    end
  end
end

--- on_text_changed
function Completion.on_text_changed(self)
  local context = Context.new({})
  if not self.context:should_auto_complete(context) then
    return
  end

  Debug:log('>>> on_text_changed <<<: ' .. context.before_line)
  if not self:trigger(context) then
    self:display(context)
  end
  self.context = context
  Debug:log(' ')
end

--- on_manual_complete
function Completion.on_manual_complete(self)
  local context = Context.new({
    manual = true;
  })

  Debug:log('>>> on_manual_complete <<<: ' .. context.before_line)
  if not self:trigger(context) then
    self:display(context)
  end
end

--- add_history
function Completion.add_history(self, completed_item)
  if completed_item and completed_item.abbr then
    self.history[completed_item.abbr] = self.history[completed_item.abbr] or 0
    self.history[completed_item.abbr] = self.history[completed_item.abbr] + 1
  end
end

--- clear
function Completion.clear(self)
  vim.call('compe#documentation#close')
  for _, source in ipairs(self.sources) do
    source:clear()
  end
  self.context = Context.new({})
end

--- trigger
function Completion.trigger(self, context)
  if vim.call('compe#is_selected_manually') then
    return
  end

  local trigger = false
  for _, source in ipairs(self.sources) do
    local status, value = pcall(function()
      trigger = source:trigger(context, function()
        self:display(Context.new({ manual = true } ))
      end) or trigger
    end)
    if not(status) then
      Debug:log(value)
    end
  end
  return trigger
end

--- display
function Completion.display(self, context)
  -- Remove throttle timers when display method called.
  Async.throttle('display:processing', 0, function() end)

  -- Check for unexpected state
  if self:should_ignore_display() then
    return
  end

  -- Check for waiting processing source.
  for _, source in ipairs(self.sources) do
    local should_wait_processing = true
    should_wait_processing = should_wait_processing and source.status == 'processing' -- source is processing
    should_wait_processing = should_wait_processing and (vim.loop.now() - source.context.time) < vim.g.compe_source_timeout -- processing timeout
    if should_wait_processing then
      -- Reserve to call display after timeout.
      Async.throttle('display:processing', vim.g.compe_source_timeout, Async.fast_schedule_wrap(function()
        self:display(context)
      end))

      -- The vim will hide pum when press backspace so we restore manually.
      if self.context:maybe_backspace(context) then
        if self.current_offset > 0 then
          self:complete(self.current_offset, self.current_items)
        end
      end
      return
    end
  end

  local timeout = vim.fn.pumvisible() == 1 and vim.g.compe_throttle_time or 0
  Async.throttle('display:filter', timeout, Async.fast_schedule_wrap(function()
    -- Check for unexpected state
    if self:should_ignore_display() then
      return
    end

    -- Gather items and datermine start_offset
    local use_trigger_character = false
    local start_offset = 0
    local items = {}
    local items_uniq = {}
    for _, source in ipairs(self.sources) do
      local source_start_offset = source:get_start_offset()
      if source_start_offset > 0 then
        -- Prefer prior source's trigger character
        if source.is_triggered_by_character or not use_trigger_character then
          if source.status == 'processing' then
            start_offset = (start_offset == 0 or start_offset > source_start_offset) and source_start_offset or start_offset
          elseif source.status == 'completed' then
            -- If source status is completed but it does not provide any items, it will be ignored (don't use start_offset, trigger character).
            local source_items = Matcher.match(context, source, self.history)
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

    -- All sources didn't trigger.
    -- Clear current completion state.
    if #items == 0 or start_offset <= 0 then
      self.current_offset = 0
      self.current_items = {}
      self:complete(1, {})
      return
    end

    Debug:log('!!! filter !!!: ' .. context.before_line)

    -- Completion
    if #items > 0 or vim.fn.pumvisible() == 1 then
      self:complete(start_offset, items)
      self.current_offset = start_offset
      self.current_items = items
    end
  end))
end

--- complete
function Completion.complete(self, start_offset, items)
  Async.fast_schedule(function()
    local completeopt = vim.o.completeopt
    vim.cmd('set completeopt=menu,menuone,noselect')
    vim.fn.complete(start_offset, items)
    vim.cmd('set completeopt=' .. completeopt)

    -- preselect
    if items[1] and items[1].preselect or vim.g.compe_auto_preselect then
      vim.api.nvim_select_popupmenu_item(0, false, false, {})
    end
  end)
end

--- should_ignore_display
function Completion.should_ignore_display(self)
  local should_ignore_display = false
  should_ignore_display = should_ignore_display or vim.call('compe#is_selected_manually')
  should_ignore_display = should_ignore_display or string.sub(vim.fn.mode(), 1, 1) ~= 'i'
  should_ignore_display = should_ignore_display or vim.fn.getbufvar('%', '&buftype') == 'prompt'
  return should_ignore_display
end

--- aiueo_aiueo
return Completion

