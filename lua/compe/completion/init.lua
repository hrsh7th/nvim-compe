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
  self.items = {}
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

--- on_complete_changed
function Completion.on_complete_changed(self)
  if vim.call('compe#is_selected_manually') then
    local selected = vim.call('complete_info', { 'selected' }).selected or -1
    local completed_item = self.items[selected + 1]
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

--- on_complete_done
function Completion.on_complete_done(self)
  self:clear()
  vim.call('compe#documentation#close')
  if vim.call('compe#is_selected_manually') then
    local completed_item = vim.v.completed_item
    self:add_history(completed_item)
  end
end

--- on_text_changed
function Completion.on_text_changed(self)
  local context = Context.new({})
  if not self.context:should_auto_complete(context) then
    return
  end
  self.context = context

  Debug:log(' ')
  Debug:log('>>> on_text_changed <<<: ' .. context.before_line)

  self:trigger(context)
  self:display(context)
end

--- manual_complete
function Completion.manual_complete(self)
  local context = Context.new({
    manual = true;
  })

  Debug:log(' ')
  Debug:log('>>> manual_complete <<<: ' .. context.before_line)

  self:trigger(context)
  self:display(context)
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
  for _, source in ipairs(self.sources) do
    source:clear()
  end
  self.items = {}
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
  -- Remove processing timer when display method called.
  Async.throttle('display:processing', 0, function() end)

  if vim.call('compe#is_selected_manually') or string.sub(vim.fn.mode(), 1, 1) ~= 'i' or vim.fn.getbufvar('%', '&buftype') == 'prompt' then
    return
  end

  for _, source in ipairs(self.sources) do
    if source.status == 'processing' and (vim.loop.now() - source.context.time) < vim.g.compe_source_timeout then
      Async.throttle('display:processing', vim.g.compe_source_timeout, vim.schedule_wrap(function()
        self:display(context)
      end))
      return
    end
  end

  -- Datermine start_offset
  local start_offset = 0
  for _, source in ipairs(self.sources) do
    if source.status == 'processing' or source.status == 'completed' then
      local source_start_offset = source:get_start_offset()
      if type(source_start_offset) == 'number' then
        if start_offset == 0 or source_start_offset < start_offset then
          Debug:log('!!! start_offset !!!: ' .. source.id .. ', ' .. source_start_offset)
          start_offset = source_start_offset
        end
      end
    end
  end
  if start_offset == 0 then
    return
  end

  -- Gather items
  local use_trigger_character = false
  local words = {}
  local items = {}
  for _, source in ipairs(self.sources) do
    if source.status == 'completed' then
      local source_items = Matcher.match(context, source, self.history)
      if #source_items > 0 and (source.is_triggered_by_character or source.is_triggered_by_character == use_trigger_character) then
        use_trigger_character = use_trigger_character or source.is_triggered_by_character

        local gap = string.sub(context.before_line, start_offset, source:get_start_offset() - 1)
        for _, item in ipairs(source_items) do
          if words[item.original_word] == nil or item.dup ~= true then
            words[item.original_word] = true
            item.word = gap .. item.original_word
            item.abbr = string.rep(' ', #gap) .. item.original_abbr
            table.insert(items, item)
          end
        end
      end
    end
  end
  Debug:log('!!! filter !!!: ' .. context.before_line)

  -- Completion
  vim.schedule(function()
    local pumvisible = vim.fn.pumvisible()
    if (#items > 0 or pumvisible) then
      local completeopt = vim.fn.getbufvar('%', '&completeopt', '')
      vim.fn.setbufvar('%', 'completeopt', 'menu,menuone,noselect')
      vim.fn.complete(start_offset, items)
      vim.fn.setbufvar('%', 'completeopt', completeopt)
      self.items = items

      -- preselect
      if vim.fn.has('nvim') and pumvisible then
        (function()
          local item = items[1]
          if item == nil then
            return
          end

          if item.preselect == true or vim.g.compe_auto_preselect then
            vim.api.nvim_select_popupmenu_item(0, false, false, {})
          end
        end)()
      end
    end
  end)
end

return Completion

