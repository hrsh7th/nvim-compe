local Cache = require'compe.utils.cache'
local Async = require'compe.utils.async'
local String = require'compe.utils.string'
local Boolean = require'compe.utils.boolean'
local Character = require'compe.utils.character'
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
  self.request_id = 0
  self.revision = 0
  self:clear()
  return self
end

-- clear
Source.clear = function(self)
  self.revision = self.revision + 1
  self.status = 'waiting'
  self.metadata = nil
  self.item_id = 0
  self.items = {}
  self.resolved_items = {}
  self.keyword_pattern_offset = 0
  self.trigger_character_offset = 0
  self.is_triggered_by_character = false
  self.context = Context.new_empty()
  self.request_id = self.request_id + 1
  self.request_time = vim.loop.now()
  self.request_state = {}
  self.incomplete = false
  return false
end

-- trigger
Source.trigger = function(self, context, callback)
  self.context = context

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
  local state = self.source:determine(context) or {}
  state.trigger_character_offset = state.trigger_character_offset == nil and 0 or state.trigger_character_offset
  state.keyword_pattern_offset = state.keyword_pattern_offset == nil and 0 or state.keyword_pattern_offset
  state.keyword_pattern_offset = state.keyword_pattern_offset == 0 and state.trigger_character_offset or state.keyword_pattern_offset

  -- Detect some trigger conditions.
  local count = #self:get_filtered_items(context)
  local short = (function()
    if self.status ~= 'waiting' and self.keyword_pattern_offset ~= 0 then
      return #context:get_input(self.keyword_pattern_offset) < Config.get().min_length
    end
    return #context:get_input(state.keyword_pattern_offset) < Config.get().min_length
  end)()
  local empty = (function()
    if context.is_trigger_character_only then
      return state.trigger_character_offset == 0
    end
    return state.keyword_pattern_offset == 0 and state.trigger_character_offset == 0
  end)()

  -- Detect completion trigger reason.
  local manual = context.manual
  local characters = state.trigger_character_offset > 0
  local incomplete = self.incomplete and not empty and self.status == 'completed'

  -- Clear current completion if all filter words removed.
  if self.status == 'completed' and not (manual or characters) then
    if context.col == self.keyword_pattern_offset then
      return self:clear()
    end
  end

  -- Handle is_trigger_character_only
  if not characters and context.is_trigger_character_only then
    return self:clear()
  end

  -- Handle completion reason.
  if not (manual or characters or incomplete) then
    -- Does not match.
    if empty and count == 0 then
      return self:clear()
    end

    -- Avoid short input.
    if short then
      return self:clear()
    end

    -- Stay completed or processing state.
    if self.status ~= 'waiting' then
      if count ~= 0 or self.request_state.keyword_pattern_offset == state.keyword_pattern_offset then
        return false
      end
    end
  end

  if manual then
    if state.keyword_pattern_offset == 0 then
      state.keyword_pattern_offset = context.col
    end
  end
  if characters then
    self.is_triggered_by_character = Character.is_symbol(string.byte(context.before_char))
  end

  local delay = (function()
    if incomplete then
      if not (manual or characters) then
        return Config.get().incomplete_delay - (vim.loop.now() - self.request_time)
      end
    end
    return -1
  end)()

  Async.debounce(self.id, delay, function()
    self.status = 'processing'
    self.request_id = self.request_id + 1
    self.request_time = vim.loop.now()
    self.request_state = state

    local request_id = self.request_id

    -- Completion
    self.source:complete({
      context = self.context;
      input = self.context:get_input(state.keyword_pattern_offset);
      keyword_pattern_offset = state.keyword_pattern_offset;
      trigger_character_offset = state.trigger_character_offset;
      incomplete = self.incomplete;
      callback = vim.schedule_wrap(function(result)
        if self.request_id ~= request_id then
          return
        end

        -- Continue current completion
        if count > 0 and #result.items == 0 then
          self.status = 'completed'
          return callback()
        end

        result = result or {}

        self.revision = self.revision + 1
        self.status = 'completed'
        self.incomplete = result.incomplete or false
        self.keyword_pattern_offset = result.keyword_pattern_offset or state.keyword_pattern_offset
        self.trigger_character_offset = state.trigger_character_offset
        self.items = self:_normalize_items(context, result.items or {})

        if #self.items == 0 then
          self:clear()
        end

        callback()
      end);
      abort = function()
        self:clear()
        vim.schedule(callback)
      end;
    })
  end)
  return true
end

--- resolve
Source.resolve = function(self, args)
  local callback = Async.guard('Source.resolve', args.callback)

  if self.resolved_items[args.completed_item.item_id] then
    return callback(self.resolved_items[args.completed_item.item_id])
  end

  if not self.source.resolve then
    self.resolved_items[args.completed_item.item_id] = args.completed_item
    return callback(self.resolved_items[args.completed_item.item_id])
  end

  self.source:resolve({
    completed_item = args.completed_item,
    callback = function(resolved_completed_item)
      self.resolved_items[args.completed_item.item_id] = resolved_completed_item or args.completed_item
      callback(self.resolved_items[args.completed_item.item_id])
    end;
  })
end

--- documentation
Source.documentation = function(self, completed_item)
  if self.source.documentation then
    self:resolve({
      completed_item = completed_item,
      callback = function(resolved_completed_item)
        self.source:documentation({
          completed_item = resolved_completed_item;
          context = Context.new({}, {});
          callback = Async.guard('Source.documentation#callback', vim.schedule_wrap(function(document)
            if document and #document ~= 0 then
              vim.call('compe#documentation#open', document)
            else
              vim.call('compe#documentation#close')
            end
          end));
          abort = Async.guard('Source.documentation#abort', vim.schedule_wrap(function()
            vim.call('compe#documentation#close')
          end));
        })
      end
    })
  else
    vim.call('compe#documentation#close')
  end
end

--- confirm
Source.confirm = function(self, completed_item)
  if self.source.confirm then
    local resolved = false
    self:resolve({
      completed_item = completed_item,
      callback = function(resolved_completed_item)
        self.source:confirm({
          completed_item = resolved_completed_item,
        })
        resolved = true
      end
    })
    vim.wait(Config.get().resolve_timeout, function() return resolved end, 1)
  end
end

--- get_metadata
Source.get_metadata = function(self)
  if not self.metadata then
    self.metadata = self.source:get_metadata()
  end

  local metadata = self.metadata
  for key, value in pairs(Config.get_metadata(self.name)) do
    metadata[key] = value
  end
  return metadata
end

--- get_filtered_items
Source.get_filtered_items = function(self, context)
  local start_offset = self:get_start_offset()
  if start_offset == 0 then
    return {}
  end

  local cache_group_key = table.concat({ 'source.get_filtered_items', self.id }, ':')

  local prev_items = (function()
    local prev_cache_key = {}
    table.insert(prev_cache_key, self.revision)
    table.insert(prev_cache_key, context.lnum)
    table.insert(prev_cache_key, start_offset)
    for i = context.col - 1, start_offset, -1 do
      prev_cache_key[4] = string.sub(context.before_line, start_offset, i)
      local prev_items = Cache.get(cache_group_key, table.concat(prev_cache_key, ':'))
      if prev_items then
        return prev_items
      end
    end
    return nil
  end)()

  local curr_cache_key = {}
  table.insert(curr_cache_key, self.revision)
  table.insert(curr_cache_key, context.lnum)
  table.insert(curr_cache_key, start_offset)
  table.insert(curr_cache_key, string.sub(context.before_line, start_offset))
  return Cache.ensure(cache_group_key, table.concat(curr_cache_key, ':'), function()
    if prev_items then
      return Matcher.match(context, self, prev_items)
    end
    return Matcher.match(context, self, self.items)
  end)
end

--- get_processing_time
Source.get_processing_time = function(self)
  if self.status == 'processing' then
    return vim.loop.now() - self.request_time
  end
  return Config.get().source_timeout + 1
end

--- get_start_offset
Source.get_start_offset = function(self)
  return self.keyword_pattern_offset or 0
end

--- is_completing
Source.is_completing = function(self, context)
  local is_completing = true
  is_completing = is_completing and self.context.bufnr == context.bufnr
  is_completing = is_completing and self.context.lnum == context.lnum
  is_completing = is_completing and (self.status == 'completed' or (self.incomplete and self.status == 'processing'))
  is_completing = is_completing and #self.items > 0
  return is_completing
end

--- _normalize_items
Source._normalize_items = function(self, _, items)
  local metadata = self:get_metadata()

  for i, item in ipairs(items) do
    self.item_id = self.item_id + 1

    local item_id = self.revision .. '.' .. self.item_id

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
    item.kind = item.kind or metadata.kind or nil
    item.menu = item.menu or metadata.menu or nil
    item.equal = 1
    item.empty = 1
    item.dup = 1

    -- special properties
    item.filter_text = item.filter_text or nil
    item.sort_text = item.sort_text or nil
    item.preselect = item.preselect or false

    -- internal properties
    item.item_id = item_id
    item.source_id = self.id
    item.priority = metadata.priority or 0
    item.sort = Boolean.get(metadata.sort, true)
    item.suggest_offset = item.suggest_offset or self.keyword_pattern_offset

    -- matcher related properties (will be overwrote)
    item.prefix = false
    item.score = 0
    item.fuzzy = false
    item.index = 0

    -- save original properties
    item.original_word = item.word
    item.original_abbr = item.abbr
    item.original_kind = item.kind
    item.original_menu = item.menu
    item.original_dup = Boolean.get(metadata.dup, true) and 1 or 0

    -- trim abbr/kind/menu
    item.abbr = String.omit(item.abbr, Config.get().max_abbr_width)
    item.kind = String.omit(item.kind, Config.get().max_kind_width)
    item.menu = String.omit(item.menu, Config.get().max_menu_width)

    items[i] = item
  end
  return items
end

return Source

