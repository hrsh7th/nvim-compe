local Debug = require'compe.debug'
local Context = require'compe.completion.context'
local Matcher = require'compe.completion.matcher'

local Completion = {}

--- new
function Completion:new()
  local this = setmetatable({}, { __index = self })
  this.insert_char_pre = 0
  this.sources = {}
  this.context = Context:new(this.insert_char_pre - 1, false)
  return this
end

--- register_source
function Completion:register_source(id, source)
  self.sources[id] = source
end

--- unregister_source
function Completion:unregister_source(id)
  self.sources[id] = nil
end

--- complete
function Completion:complete()
  local context = Context:new(self.insert_char_pre, true)

  Debug:log(' ')
  Debug:log('>>> complete <<<: ' .. context.before_line)

  self:trigger(context)
  self:display(context)
end

--- on_insert_char_pre
function Completion:on_insert_char_pre()
  self.insert_char_pre = self.insert_char_pre + 1
end

--- on_text_changed
function Completion:on_text_changed()
  local context = Context:new(self.insert_char_pre, false)
  if self.context.changedtick == context.changedtick then
    return
  end

  Debug:log(' ')
  Debug:log('>>> on_text_changed <<<: ' .. context.before_line)

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
  if self.context.changedtick == context.changedtick and context.force ~= true then
    return
  end

  for _, source in pairs(self.sources) do
    local status, value = pcall(function()
      source:trigger(context, function()
        self:display(Context:new(self.insert_char_pre, true))
      end)
    end)
    if not(status) then
      Debug:log(value)
    end
  end
end

--- display
function Completion:display(context)
  if #vim.v.completed_item ~= 0 then
    return
  end
  if self.context.changedtick == context.changedtick and context.force ~= true then
    return
  end
  self.context = context

  -- Datermine start_offset
  local start_offset = 0
  for _, source in pairs(self.sources) do
    if source.status == 'processing' or source.status == 'completed' then
      local source_start_offset = source:get_start_offset()
      if type(source_start_offset) == 'number' then
        if start_offset == 0 or source_start_offset < start_offset then
          start_offset = source_start_offset
        end
      end
    end
  end

  -- Gather items
  local items = {}
  for _, source in pairs(self.sources) do
    if source.status == 'completed' then
      for _, item in pairs(source:get_items()) do
        table.insert(items, item)
      end
    end
  end

  -- Completion
  if string.sub(vim.fn.mode(), 1, 1) == 'i' and #items > 0 and start_offset > 0 then
    vim.fn.complete(start_offset, Matcher.match(context, start_offset, items))
  end
end

return Completion

