local Debug = require'compe.debug'
local Source =  {}

--- new
function Source:new(id, source)
  local this = setmetatable({}, { __index = self })
  this.id = id
  this.source = source
  this.context = {}

  this.status = 'waiting'
  this.keyword_pattern_offset = 0
  this.trigger_character_offset = 0

  this.incomplete = false
  this.items = {}
  return this
end

-- clear
function Source:clear()
  self.status = 'waiting'
  self.keyword_pattern_offset = 0
  self.trigger_character_offset = 0
end

-- trigger
function Source:trigger(context, callback)
  self.context = context

  -- Normalize trigger offsets
  local state = self.source:datermine(context)
  state.trigger_character_offset = state.trigger_character_offset == nil and 0 or state.trigger_character_offset
  state.keyword_pattern_offset = state.keyword_pattern_offset == nil and 0 or state.keyword_pattern_offset
  state.keyword_pattern_offset = state.keyword_pattern_offset == 0 and state.trigger_character_offset or state.keyword_pattern_offset

  -- Does not match any patterns
  if context.force ~= true and state.keyword_pattern_offset == 0 and state.trigger_character_offset == 0 then
    self.status = 'waiting'
    self.keyword_pattern_offset = 0
    self.trigger_character_offset = 0
    Debug:log('<clear> ' .. self.id .. '@ keyword_pattern_offset: ' .. self.keyword_pattern_offset .. ', trigger_character_offset: ' .. self.trigger_character_offset)
    return false
  end

  -- Force trigger conditions
  local force = false
  force = force or state.trigger_character_offset > 0
  force = force or context.force
  force = force or self.incomplete

  -- Fix for manual completion / trigger character completion
  if force and state.keyword_pattern_offset == 0 then
    state.keyword_pattern_offset = context.col
  end

  -- Check ignore conditions
  local ignore = false
  ignore = ignore or self.context.lnum == context.lnum and self.keyword_pattern_offset == state.keyword_pattern_offset
  ignore = ignore or #context:get_input(state.keyword_pattern_offset) < vim.g.compe_min_length
  if force == false and ignore then
    Debug:log('<ignore> ' .. self.id .. '@ keyword_pattern_offset: ' .. self.keyword_pattern_offset .. ', trigger_character_offset: ' .. self.trigger_character_offset)
    return self.status ~= 'waiting'
  end

  -- Update completion state
  self.status = force and self.status or 'processing'
  self.keyword_pattern_offset = state.keyword_pattern_offset
  self.trigger_character_offset = state.trigger_character_offset

  -- Completion
  Debug:log('<send> ' .. self.id .. '@ keyword_pattern_offset: ' .. self.keyword_pattern_offset .. ', trigger_character_offset: ' .. self.trigger_character_offset)
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
    item.score = 0

    table.insert(normalized, item)
  end
  return normalized
end

return Source

