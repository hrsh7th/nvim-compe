local debug = require'compe.debug'
local context = require'compe.completion.context'
local M = {
  sources = {},
  context = context.new({}),
  items = {},
  history = {}
}

--- registers a source
-- adds source to sources table and gets source metadata???
-- @param source table representing nvim-compe source.
-- @function register_source
M.register_source = function(self, source)
  table.insert(self.sources, source)

  table.sort(self.sources, function(a, b)
    local a_meta = a:get_metadata()
    local b_meta = b:get_metadata()
    if a_meta.priority ~= b_meta.priority then
      return a_meta.priority > b_meta.priority
    end
  end)
end

--- unregisters a source
-- drops a source from sources table.
-- @param id string representing the source name.
-- @function unregister_source
M.unregister_source = function(self, id)
  for i, source in ipairs(self.sources) do
    if id == source:get_id() then
      table.remove(self.sources, i)
      break
    end
  end
end

--- on leaving insert
-- internal private function.
-- receives vim's InsertLeave autocmd
-- @param self
-- @function on_insert_leave
M.on_insert_leave = function(self)
  self:clear()
  require'compe.completion.source.vim_bridge'.clear()
end

--- on complete change
-- internal private function.
-- @param self
-- @function on_complete_changed
M.on_complete_changed = function(self)
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

--- when complete done
-- internal private function.
-- @param self
-- @function on_complete_done
M.on_complete_done = function(self)
  self:clear()
  vim.call('compe#documentation#close')
  if vim.call('compe#is_selected_manually') then
    local completed_item = vim.v.completed_item
    self:add_history(completed_item)
  end
end

--- on text changed
--  internal private function.
--  triggers events on text change.
-- @param self
-- @function on_text_changed
M.on_text_changed = function(self)
  local c = context.new({})
  if not self.context:should_auto_complete(c) then
    return
  end
  self.context = c

  debug:log(' ')
  debug:log('>>> on_text_changed <<<: ' .. context.before_line)

  self:trigger(c)
  self:display(c)
end

--- manual_complete
-- Use to trigger completion manually.
-- @param self
-- @function manual_complete
M.manual_complete = function(self)
  local c = context.new({
    manual = true;
  })

  debug:log(' ')
  debug:log('>>> manual_complete <<<: ' .. context.before_line)

  self:trigger(c)
  self:display(c)
end

-- Adds items to compe-nvim's history.
-- Used for prioritizing items that are often selected by user.
-- @param self
-- @param completed_item item that has been confirmed
-- @function add_history
M.add_history = function(self, completed_item)
  if completed_item and completed_item.abbr then
    self.history[completed_item.abbr] = self.history[completed_item.abbr] or 0
    self.history[completed_item.abbr] = self.history[completed_item.abbr] + 1
  end
end

--- clears compe-nvim's items and context
-- public function that close nvim-compe menu.
-- @param self
-- @function clear
M.clear = function(self)
  for _, source in ipairs(self.sources) do
    source:clear()
  end
  self.items = {}
  self.context = context.new({})
end

--- trigger completion?
-- ???
-- @param self
-- @parm context ??
-- @function trigger
M.trigger = function(self, context)
  if vim.call('compe#is_selected_manually') then return end
  local trigger = false
  for _, source in ipairs(self.sources) do
    local status, value = pcall(function()
      trigger = source:trigger(context, function()
        self:display(context.new({ manual = true } ))
      end) or trigger
    end)
    if not(status) then
      debug:log(value)
    end
  end
  return trigger
end

--- display results
-- ???
-- @param self
-- @parm context ??
-- @function display
-- TODO(hrsh7th): refactor to a module of its own, like util/display.lua??
M.display = function(self, context)
  -- Remove processing timer when display method called.
  local async = require'compe.async'
  async.throttle('display:processing', 0, function() end)

  -- TODO(hrsh7th): this will get big, maybe new function should_display_menu?
  if vim.call('compe#is_selected_manually') or string.sub(vim.fn.mode(), 1, 1) ~= 'i' or vim.fn.getbufvar('%', '&buftype') == 'prompt' then
    return
  end

  for _, source in ipairs(self.sources) do
    if source.status == 'processing' and (vim.loop.now() - source.context.time) < vim.g.compe_source_timeout then
      async.throttle('display:processing', vim.g.compe_source_timeout, vim.schedule_wrap(function()
        self:display(context)
      end))
      return
    end
  end

  -- Datermine start_offset > disply.determine_offset(source, status, id)
  local start_offset = 0
  for _, source in ipairs(self.sources) do
    if source.status == 'processing' or source.status == 'completed' then
      local source_start_offset = source:get_start_offset()
      if type(source_start_offset) == 'number' then
        if start_offset == 0 or source_start_offset < start_offset then
          debug:log('!!! start_offset !!!: ' .. source.id .. ', ' .. source_start_offset)
          start_offset = source_start_offset
        end
      end
    end
  end
  if start_offset == 0 then
    return
  end

  -- Gather items >> display.collect_items(source, status, id)
  local use_trigger_character = false
  local words = {}
  local items = {}
  for _, source in ipairs(self.sources) do
    if source.status == 'completed' then
      local source_items = require'compe.completion.matcher'.match(context, source, self.history)
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
  debug:log('!!! filter !!!: ' .. context.before_line)

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

return setmetatable({}, { __index = M })
