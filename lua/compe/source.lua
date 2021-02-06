local Cache = require'compe.utils.cache'
local Async = require'compe.utils.async'
local Boolean = require'compe.utils.boolean'
local Config = require'compe.config'
local Matcher = require'compe.matcher'
local Context = require'compe.context'

local Source =  {}

Source.base_id = 0

--- new
function Source.new(name, source)
  Source.base_id = Source.base_id + 1

  local self = setmetatable({}, { __index = Source })
  self.id = Source.base_id
  self.name = name
  self.source = source
  self.context = Context.new({})
  self.revision = 0
  self:clear()
  return self
end

-- clear
function Source.clear(self)
  self.status = 'waiting'
  self.metadata = nil
  self.item_id = 0
  self.items = {}
  self.resolved_items = {}
  self.keyword_pattern_offset = 0
  self.trigger_character_offset = 0
  self.is_triggered_by_character = false
  self.incomplete = false
end

--- confirm
function Source.confirm(self, completed_item)
  if self.source.confirm then
    self:resolve({
      completed_item = completed_item,
      callback = function(completed_item)
        self.source:confirm({
          completed_item = completed_item,
        })
      end
    })
  end
end

--- resolve
function Source.resolve(self, args)
  if self.resolved_items[args.completed_item.item_id] then
    return args.callback(self.resolved_items[args.completed_item.item_id])
  end
  if self.source.resolve then
    self.source:resolve({
      completed_item = args.completed_item,
      callback = function(completed_item)
        self.resolved_items[args.completed_item.item_id] = completed_item or args.completed_item
        args.callback(self.resolved_items[args.completed_item.item_id])
      end;
    })
  else
    self.resolved_items[args.completed_item.item_id] = args.completed_item
    args.callback(self.resolved_items[args.completed_item.item_id])
  end
end

--- documentation
function Source.documentation(self, completed_item)
  if self.source.documentation then
    self:resolve({
      completed_item = completed_item,
      callback = function(completed_item)
        self.source:documentation({
          completed_item = completed_item;
          context = Context.new({});
          callback = Async.guard('Source.documentation#callback', Async.fast_schedule_wrap(function(document)
            if document and #document ~= 0 then
              vim.call('compe#documentation#open', document)
            else
              vim.call('compe#documentation#close')
            end
          end));
          abort = Async.guard('Source.documentation#abort', Async.fast_schedule_wrap(function()
            vim.call('compe#documentation#close')
          end));
        })
      end
    })
  else
    Async.fast_schedule(function()
      vim.call('compe#documentation#close')
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

  if metadata.ignored_filetypes and #metadata.ignored_filetypes then
    if vim.tbl_contains(metadata.ignored_filetypes or {}, context.filetype) then
      return self:clear()
    end
  end

  -- Normalize trigger offsets
  local state = self.source:determine(context)
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
    return
  end

  -- Force trigger conditions
  local force = false
  force = force or context.manual
  force = force or state.trigger_character_offset > 0
  force = force or self.incomplete and (vim.loop.now() - self.context.time) > Config.get().incomplete_delay

  local is_same_offset = self.context.lnum == context.lnum and self.keyword_pattern_offset == state.keyword_pattern_offset
  local is_less_input = #(context:get_input(state.keyword_pattern_offset)) < Config.get().min_length

  if force == false then
    -- Ignore when condition does not changed
    if is_same_offset then
      return
    end

    -- Ignore when enough length of input
    if is_less_input then
      return
    end
  end

  self.is_triggered_by_character = is_same_offset and self.is_triggered_by_character or (state.trigger_character_offset > 0 and not string.match(context.before_char, '%w+'))

  self.items = (is_same_offset and self.incomplete) and self.items or {}
  self.status = 'processing'
  self.keyword_pattern_offset = state.keyword_pattern_offset
  self.trigger_character_offset = state.trigger_character_offset
  self.context = context

  -- Completion
  self.source:complete({
    context = self.context;
    input = self.context:get_input(self.keyword_pattern_offset);
    keyword_pattern_offset = self.keyword_pattern_offset;
    trigger_character_offset = self.trigger_character_offset;
    incomplete = self.incomplete;
    callback = Async.fast_schedule_wrap(function(result)
      self.revision = self.revision + 1
      self.items = self.incomplete and #result.items == 0 and self.items or self:normalize_items(context, result.items or {})
      self.status = 'completed'
      self.incomplete = result.incomplete or false
      self.keyword_pattern_offset = result.keyword_pattern_offset or self.keyword_pattern_offset
      self.trigger_character_offset = result.trigger_character_offset or self.trigger_character_offset
      callback()
    end);
    abort = Async.fast_schedule_wrap(function()
      self.revision = self.revision + 1
      self.items = {}
      self.status = 'waiting'
      self.incomplete = false
      self.keyword_pattern_offset = 0
      self.trigger_character_offset = 0
      callback()
    end);
  })
  return true
end

--- get_metadata
function Source.get_metadata(self)
  if not self.metadata then
    self.metadata = self.source:get_metadata()
  end

  local metadata = self.metadata
  for key, value in pairs(Config.get_metadata(self.name)) do
    metadata[key] = value
  end
  return metadata
end

--- get_start_offset
function Source.get_start_offset(self)
  return self.keyword_pattern_offset or 0
end

--- get_filtered_items
function Source.get_filtered_items(self, context)
  local start_offset = self:get_start_offset()
  local input = context:get_input(start_offset)

  local cache_group_key = {}
  table.insert(cache_group_key, 'source.get_filtered_items')
  table.insert(cache_group_key, self.id)
  cache_group_key = table.concat(cache_group_key, ':')

  local curr_cache_key = {}
  table.insert(curr_cache_key, self.revision)
  table.insert(curr_cache_key, context.lnum)
  table.insert(curr_cache_key, start_offset)
  table.insert(curr_cache_key, input)
  curr_cache_key = table.concat(curr_cache_key, ':')

  local prev_items = (function()
    if #input == 0 or self.incomplete then
      return nil
    end

    local prev_cache_key = {}
    table.insert(prev_cache_key, self.revision)
    table.insert(prev_cache_key, context.lnum)
    table.insert(prev_cache_key, start_offset)
    for i = #input, 1, -1 do
      table.insert(prev_cache_key, input:sub(1, i))
      local prev_items = Cache.get(cache_group_key, table.concat(prev_cache_key, ':'))
      if prev_items then
        return prev_items
      end
      table.remove(prev_cache_key, #prev_cache_key)
    end
    return nil
  end)()

  return Cache.ensure(cache_group_key, curr_cache_key, function()
    if type(prev_items) == 'table' then
      return Matcher.match(input, prev_items)
    end
    return Matcher.match(input, self.items)
  end)
end

--- get_processing_time
function Source.get_processing_time(self)
  if self.status == 'processing' then
    return vim.loop.now() - self.context.time
  end
  return 0
end

--- normalize_items
function Source.normalize_items(self, _, items)
  local metadata = self:get_metadata()

  local normalized = {}
  for _, item in pairs(items) do
    self.item_id = self.item_id + 1

    -- string to completed_item
    if type(item) == 'string' then
      item = {
        word = item;
        abbr = item;
      }
    end

    -- complete-items properties.
    item.word = item.word
    item.abbr = item.abbr or item.word
    item.menu = metadata.menu == nil and item.menu or metadata.menu
    item.equal = 1
    item.empty = 1
    item.dup = 1

    -- Special properties
    item.item_id = self.item_id
    item.source_id = self.id
    item.priority = metadata.priority or 0
    item.sort = Boolean.get(metadata.sort, true)

    -- Matcher related properties (will be overwrote)
    item.index = 0
    item.score = 0
    item.fuzzy = false

    -- Restore original properties
    item.original_word = item.word
    item.original_abbr = item.abbr
    item.original_kind = item.kind
    item.original_menu = item.menu
    item.original_dup = Boolean.get(metadata.dup, true) and 1 or 0

    table.insert(normalized, item)
  end
  return normalized
end

return Source

