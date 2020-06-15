local Debug = require'compe.debug'
local Source =  {}

--- new
function Source:new(id, source)
  local this = setmetatable({}, { __index = self })
  this.id = id
  this.source = source
  this.context = {}
  this:clear()
  return this
end

-- clear
function Source:clear()
  self.status = 'waiting'
  self.items = {}
  self.keyword_pattern_offset = 0
  self.trigger_character_offset = 0
  self.incomplete = false
end

-- trigger
function Source:trigger(context, callback)
  self.context = context

  -- Normalize trigger offsets
  local state = self.source:datermine(context)
  state.trigger_character_offset = state.trigger_character_offset == nil and 0 or state.trigger_character_offset
  state.keyword_pattern_offset = state.keyword_pattern_offset == nil and 0 or state.keyword_pattern_offset
  state.keyword_pattern_offset = state.keyword_pattern_offset == 0 and state.trigger_character_offset or state.keyword_pattern_offset

  -- Fix for manual completion
  if context.manual then
    state.keyword_pattern_offset = state.keyword_pattern_offset ~= 0 and state.keyword_pattern_offset or context.col
    self:clear()
  end

  -- Does not match any patterns
  if state.keyword_pattern_offset == 0 and state.trigger_character_offset == 0 then
    Debug:log('<no completion> ' .. self.id .. '@ keyword_pattern_offset: ' .. self.keyword_pattern_offset .. ', trigger_character_offset: ' .. self.trigger_character_offset)
    self:clear()
    return false
  end

  -- Force trigger conditions
  local force = false
  force = force or context.manual
  force = force or state.trigger_character_offset > 0
  force = force or self.incomplete

  local is_same_offset = self.context.lnum == context.lnum and self.keyword_pattern_offset == state.keyword_pattern_offset
  local is_less_input = #context:get_input(state.keyword_pattern_offset) < vim.g.compe_min_length

  if force == false then
    -- Ignore when condition does not changed
    if is_same_offset then
      Debug:log('<ignore condition> ' .. self.id .. '@ keyword_pattern_offset: ' .. self.keyword_pattern_offset .. ', trigger_character_offset: ' .. self.trigger_character_offset)
      return
    end

    -- Ignore when enough length of input
    if is_less_input then
      Debug:log('<ignore min_length> ' .. self.id .. '@ keyword_pattern_offset: ' .. self.keyword_pattern_offset .. ', trigger_character_offset: ' .. self.trigger_character_offset)
      return
    end
  end

  -- Completion request.
  self.status = is_same_offset and self.status or 'processing'
  self.items = is_same_offset and self.items or {}
  self.keyword_pattern_offset = state.keyword_pattern_offset
  self.trigger_character_offset = state.trigger_character_offset

  -- Completion
  Debug:log('<completion> ' .. self.id .. '@ keyword_pattern_offset: ' .. self.keyword_pattern_offset .. ', trigger_character_offset: ' .. self.trigger_character_offset)
  self.source:complete({
    context = self.context;
    keyword_pattern_offset = self.keyword_pattern_offset;
    trigger_character_offset = self.trigger_character_offset;
    incomplete = self.incomplete;
    callback = function(result)
      Debug:log('> completed: ' .. self.id .. ': ' .. #result.items)

      self.incomplete = result.incomplete or false
      self.items = self:normalize_items(context, result.items or {})
      self.status = 'completed'
      callback()
    end;
    abort = function()
      self.incomplete = false
      self.items = {}
      self.status = 'waiting'
    end;
  })
  return true
end

--- get_id
function Source:get_id()
  return self.id
end

--- get_metadata
function Source:get_metadata()
  return vim.tbl_extend('keep', self.source:get_metadata(), {
    sort = true;
    priority = 0;
  })
end

--- get_status
function Source:get_status()
  return self.status
end

--- get_start_offset
function Source:get_start_offset()
  return self.keyword_pattern_offset
end

--- get_items
function Source:get_items()
  return self.items or {}
end

--- normalize_items
function Source:normalize_items(context, items)
  local start_offset = self:get_start_offset()
  local metadata = self:get_metadata()
  local normalized = {}

  local _, _, before = string.find(string.sub(context.before_line, 1, start_offset - 1), '([^%s]*)$')
  local _, _, after = string.find(context.after_line, '^([^%s]*)')

  for _, item in pairs(items) do
    -- string to completed_item
    if type(item) == 'string' then
      item = {
        word = item;
        abbr = item;
      }
    end

    local word = item.word

    -- fix complete overlap for prefix
    if before ~= nil then
      if string.find(word, before, 1, true) == 1 then
        word = string.sub(word,  #before + 1, #word)
      end
    end

    -- fix complete overlap for postfix
    if after ~= nil then
      local _, after_e = string.find(word, after, 1, true)
      if after_e == #word then
        word = string.sub(word, 1, #word - #after)
      end
    end

    if word ~= item.word then
      Debug:log(vim.inspect({
        before = before;
        after = after;
        fixed_word = word;
        item_word = item.word;
      }))
    end

    item.word = word

    -- add abbr if does not exists
    if item.abbr == nil then
      item.abbr = item.word
    end

    for key, value in pairs(self.source:get_item_metadata(item)) do
      item[key] = value
    end

    -- required properties
    item.dup = 1
    item.equal = 1
    item.empty = 1

    -- special properties
    item.priority = metadata.priority or 0
    item.score = 0

    table.insert(normalized, item)
  end
  return normalized
end

return Source

