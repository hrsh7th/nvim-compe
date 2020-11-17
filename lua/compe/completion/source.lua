local Debug = require'compe.debug'
local Async = require'compe.async'
local Context = require'compe.completion.context'
local Source =  {}

--- new
function Source.new(id, source)
  local self = setmetatable({}, { __index = Source })
  self.id = id
  self.source = source
  self.context = Context.new({})
  self:clear()
  return self
end

-- clear
function Source.clear(self)
  self.status = 'waiting'
  self.items = {}
  self.keyword_pattern_offset = 0
  self.trigger_character_offset = 0
  self.is_triggered_by_character = false
  self.incomplete = false
  self.documentation_id = 0
end

--- documentation
function Source.documentation(self, event, completed_item)
  self.documentation_id = self.documentation_id + 1

  local documentation_id = self.documentation_id
  if self.source.documentation then
    Async.next(function()
      self.source:documentation({
        completed_item = completed_item;
        callback = function(document)
          if self.documentation_id == documentation_id then
            vim.fn.call('compe#documentation#open', { event, document })
          end
        end
      })
    end)
  end
end

-- trigger
function Source.trigger(self, context, callback)
  local metadata = self:get_metadata()

  -- Check filetypes.
  if metadata.filetypes and #metadata.filetypes then
    if not vim.tbl_contains(metadata.filetypes or {}, context.filetype) then
      return self:clear()
    end
  end

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
  self.items = is_same_offset and self.items or {}
  self.is_triggered_by_character = is_same_offset and self.is_triggered_by_character or (state.trigger_character_offset > 0 and string.match(context.before_char, '%w+') == nil)
  self.status = 'processing'
  self.keyword_pattern_offset = state.keyword_pattern_offset
  self.trigger_character_offset = state.trigger_character_offset
  self.context = context

  -- Completion
  self:log('completion', context, state)
  self.source:complete({
    context = self.context;
    input = self.context:get_input(self.keyword_pattern_offset);
    keyword_pattern_offset = self.keyword_pattern_offset;
    trigger_character_offset = self.trigger_character_offset;
    incomplete = self.incomplete;
    callback = function(result)
      if context ~= self.context then
        Debug:log('> completed skip: ' .. self.id .. ': ' .. #result.items)
        return
      end

      Debug:log('> completed: ' .. self.id .. ': ' .. #result.items .. ', sec: ' .. vim.loop.now() - self.context.time)

      self.status = 'completed'
      self.items = self.incomplete and #result.items == 0 and self.items or self:normalize_items(context, result.items or {})
      self.incomplete = result.incomplete or false
      self.keyword_pattern_offset = result.keyword_pattern_offset or self.keyword_pattern_offset
      self.trigger_character_offset = result.trigger_character_offset or self.trigger_character_offset
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
function Source.get_id(self)
  return self.id
end

--- get_metadata
function Source.get_metadata(self)
  return vim.tbl_extend('keep', self.source:get_metadata(), {
    sort = true;
    priority = 0;
  })
end

--- get_status
function Source.get_status(self)
  return self.status
end

--- get_start_offset
function Source.get_start_offset(self)
  return self.keyword_pattern_offset
end

--- get_items
function Source.get_items(self)
  return self.items or {}
end

-- log
function Source.log(self, label, context, state)
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
function Source.normalize_items(self, _, items)
  local metadata = self:get_metadata()
  local normalized = {}

  for _, item in pairs(items) do
    -- string to completed_item
    if type(item) == 'string' then
      item = {
        word = item;
        abbr = item;
      }
    end

    -- create word/abbr
    item.word = item.word
    item.abbr = item.abbr or item.word

    -- required properties
    item.dup = metadata.dup ~= nil and metadata.dup or 1
    item.menu = metadata.menu ~= nil and metadata.menu or item.menu
    item.equal = 1
    item.empty = 1

    -- special properties
    item.priority = metadata.priority or 0
    item.asis = string.find(item.abbr, item.word, 1, true) == 1
    item.source_id = self.id

    -- restore original word/abbr
    item.original_word = item.word
    item.original_abbr = item.abbr

    table.insert(normalized, item)
  end
  return normalized
end

return Source

