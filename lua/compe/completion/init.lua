local Debug = require'compe.debug'
local Context = require'compe.completion.context'
local Matcher = require'compe.completion.matcher'

local Completion = {}

--- new
function Completion:new()
  local this = setmetatable({}, { __index = self })
  this.insert_char_pre = 0
  this.sources = {}
  this.context = Context:new(this.insert_char_pre - 1, {})
  return this
end

--- register_source
function Completion:register_source(source)
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
function Completion:unregister_source(id)
  for i, source in ipairs(self.sources) do
    if id == source:get_id() then
      table.remove(self.sources, i)
      break
    end
  end
end

--- on_insert_char_pre
function Completion:on_insert_char_pre()
  self.insert_char_pre = self.insert_char_pre + 1
end

--- on_text_changed
function Completion:on_text_changed()
  local context = Context:new(self.insert_char_pre, {})
  if self.context.changedtick == context.changedtick then
    return
  end

  Debug:log(' ')
  Debug:log('>>> on_text_changed <<<: ' .. context.before_line)

  self:trigger(context)
  self:display(context)
end

--- on_manual_complete
function Completion:on_manual_complete()
  local context = Context:new(self.insert_char_pre, {
    manual = true;
  })

  Debug:log(' ')
  Debug:log('>>> on_manual_complete <<<: ' .. context.before_line)

  self:trigger(context)
  self:display(context)
end

-- clear
function Completion:clear()
  for _, source in ipairs(self.sources) do
    source:clear()
  end
end

--- trigger
function Completion:trigger(context)
  if #vim.v.completed_item ~= 0 then
    return
  end

  local trigger = false
  for _, source in ipairs(self.sources) do
    local status, value = pcall(function()
      trigger = source:trigger(context, function()
        self:display(Context:new(self.insert_char_pre, { manual = true } ))
      end) or trigger
    end)
    if not(status) then
      Debug:log(value)
    end
  end
  return trigger
end

--- display
function Completion:display(context)
  if #vim.v.completed_item ~= 0 then
    return
  end

  for _, source in ipairs(self.sources) do
    if source.status == 'processing' and (vim.loop.now() - source.context.time) < vim.g.compe_source_timeout then
      return
    end
  end

  if self.context.changedtick == context.changedtick and context.manual ~= true then
    return
  end
  self.context = context

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

  -- Gather items
  local use_trigger_character = false
  local words = {}
  local items = {}
  for _, source in ipairs(self.sources) do
    if source.status == 'completed' then
      local is_triggered_by_character = source:is_triggered_by_character()
      local source_items = Matcher.match(context, source)
      if #source_items > 0 and (is_triggered_by_character or is_triggered_by_character == use_trigger_character) then
        use_trigger_character = is_triggered_by_character
        for _, item in ipairs(source_items) do
          if words[item.word] == nil or item.dup ~= true then
            words[item.word] = true
            table.insert(items, item)
          end
        end
      end
    end
  end
  Debug:log('!!! filter !!!: ' .. context.before_line)

  -- Completion
  vim.schedule(function()
    if #vim.v.completed_item ~= 0 then
      return
    end

    if #items > 0 and string.sub(vim.fn.mode(), 1, 1) == 'i' and vim.fn.getbufvar('%', '&buftype') ~= 'prompt' and start_offset > 0 then
      local completeopt = vim.fn.getbufvar('%', '&completeopt', '')
      vim.fn.setbufvar('%', 'completeopt', 'menu,menuone,noselect')
      vim.fn.complete(start_offset, items)
      vim.fn.setbufvar('%', 'completeopt', completeopt)

      -- preselect
      if vim.fn.has('nvim') and vim.fn.pumvisible() then
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

