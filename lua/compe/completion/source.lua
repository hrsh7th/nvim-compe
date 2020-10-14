local Debug = require'compe.debug'
local Context = require'compe.completion.context'
local Source =  {}

--- new
function Source:new(id, source)
  local this = setmetatable({}, { __index = self })
  this.id = id
  this.source = source
  this.context = Context:new(0, {})
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
    self:clear()
    self:log('no_completion', context, state)
    return
  end

  -- Force trigger conditions
  local force = false
  force = force or context.manual
  force = force or state.trigger_character_offset > 0
  force = force or self.incomplete and (vim.loop.now() - self.context.time) > vim.g.compe_incomplete_delay

  local is_same_offset = self.context.lnum == context.lnum and self.keyword_pattern_offset == state.keyword_pattern_offset
  local is_less_input = #(context:get_input(state.keyword_pattern_offset)) < vim.g.compe_min_length

  if force == false then
    -- Ignore when condition does not changed
    if is_same_offset then
      self:log('same_offset', context, state)
      return
    end

    -- Ignore when enough length of input
    if is_less_input then
      self:log('less_input', context, state)
      return
    end
  end

  -- Completion request.
  self.status = is_same_offset and self.status or 'processing'
  self.items = is_same_offset and self.items or {}
  self.keyword_pattern_offset = state.keyword_pattern_offset
  self.trigger_character_offset = state.trigger_character_offset
  self.context = context

  -- Completion
  self:log('completion', context, state)
  self.source:complete({
    context = self.context;
    keyword_pattern_offset = self.keyword_pattern_offset;
    trigger_character_offset = self.trigger_character_offset;
    incomplete = self.incomplete;
    callback = function(result)
      if context ~= self.context then
        Debug:log('> completed skip: ' .. self.id .. ': ' .. #result.items)
        return
      end

      self.status = 'completed'

      if #result.items == 0 then
        Debug:log('> completed empty: ' .. self.id .. ': ' .. #result.items)
        self.status = 'completed'
      end
      Debug:log('> completed: ' .. self.id .. ': ' .. #result.items .. ', sec: ' .. vim.loop.now() - self.context.time)

      self.incomplete = result.incomplete or false
      self.items = self:normalize_items(context, result.items or {})
      callback()
    end;
    abort = function()
      Debug:log('> completed abort: ' .. self.id)
      self.incomplete = false
      self.items = {}
      self.status = 'waiting'
      callback()
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

--- is_triggered_by_character
function Source:is_triggered_by_character()
  return self.trigger_character_offset > 0
end

--- get_items
function Source:get_items()
  return self.items or {}
end

-- log
function Source:log(label, context, state)
  local force_type = ''
  if context.manual then
    force_type = 'manual'
  elseif state.trigger_character_offset > 0 then
    force_type = 'trigger'
  elseif self.incomplete then
    force_type = 'incomplete'
  end
  Debug:log(string.format('<%s>	%s	k: %d	t: %d, f: %s',
      label,
      self.id,
      self.keyword_pattern_offset,
      self.trigger_character_offset,
      force_type
    ))
end

--- normalize_items
-- This method add special attributes for each items.
-- * priority
-- * asis
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

    local word = self:trim_word(before, after, item.word)

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

    -- required properties
    item.dup = metadata.dup ~= nil and metadata.dup or 1
    item.menu = metadata.menu ~= nil and metadata.menu or item.menu
    item.equal = 1
    item.empty = 1

    -- special properties
    item.priority = metadata.priority or 0
    item.asis = string.find(item.abbr, item.word, 1, true) == 1

    table.insert(normalized, item)
  end
  return normalized
end

-- trim_word
function Source:trim_word(before, after, word)
  local word_len = #word

  if before ~= nil then
    for prefix_overlap = word_len, 1, -1 do
      if string.sub(before, #before - prefix_overlap + 1) == string.sub(word, 1, prefix_overlap) then
        word = string.sub(word, prefix_overlap + 1)
        break
      end
    end
  end

  if after ~= nil then
    for postfix_overlap = word_len, 1, -1 do
      local word_index = word_len - postfix_overlap + 1
      if string.sub(after, 1, postfix_overlap) == string.sub(word, word_index) then
        word = string.sub(word, 1, word_index - 1)
        break
      end
    end
  end

  return word
end

return Source

