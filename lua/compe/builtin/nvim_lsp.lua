--- nvim_lsp source
--
-- This module defines nvim_lsp source functions and expose few function to
-- deal with it.
--
-- Dependencies: `vim.lsp.protocol`, `vim.lsp.util`, `compe`, `compe.pattern`,
--
-- @module builtin.nvim_lsp

local compe = require'compe'
local pattern = require'compe.pattern'
local protocol = require'vim.lsp.protocol'
local util = require'vim.lsp.util'
local lsp_sources = {}
local nvim_lsp = {}

--- get_paths
-- @returns ???
nvim_lsp.get_paths = function(self, root, paths)
  local c = root
  for _, path in ipairs(paths) do
    c = c[path]
    if not c then
      return nil
    end
  end
  return c
end

--- get_data (not used)
-- Not sure what to call it, can you suggest a better name??
-- @param self
-- @param cap: capabilities
-- @return table
nvim_lsp.check = function(self, cap)
-- used more then once, maybe good idea to use it
  self:check(self.client.server_capabilities, cap)
end

--- source metadata
-- @return a table { priority, dub, menu }
nvim_lsp.get_metadata = function(self)
  return {
    priority = 1000,
    dup = 0,
    menu = '[LSP]',
  }
end

--- source preview function.
-- @param self
-- @param args ???
-- @return markdown string
nvim_lsp.documentation = function(self, args)

  -- gets completion item from nvim_lsp
  local completion_item = self:get_paths(args, { 'completed_item', 'user_data', 'nvim', 'lsp', 'completion_item' })
  if not completion_item then
    return
  end

  --- function to check if item has documentation, if so convert it to markdown.
  local function documentation(completion_item)
    if completion_item.documentation then
      args.callback(util.convert_input_to_markdown_lines(completion_item.documentation))
    end
  end

  local has_resolve = self:get_paths(self.client.server_capabilities, { 'completionProvider', 'resolveProvider' })

  --- send `completionItem/resolve` if supported.
  if has_resolve then
    self.client.request('completionItem/resolve', completion_item, function(err, _, result)
      if err or not result then
        return
      end
      documentation(result)
    end)

  --- use current completion_item ??
  else
    documentation(completion_item)
  end
end

--- source determine function.
-- @param self
-- @param context table: ???
-- @return if .... it returns a table with `keyword_pattern_offset` ,
-- and `trigger_character_offset`, else `keyword_pattern_offset`.
function nvim_lsp.datermine(self, context)
  local trigger_chars = self:get_paths(self.client.server_capabilities, { 'completionProvider', 'triggerCharacters' }) or {}
  if vim.tbl_contains(trigger_chars, context.before_char) and context.before_char ~= ' ' then
    return {
      keyword_pattern_offset = pattern:get_keyword_pattern_offset(context);
      trigger_character_offset = context.col;
    }
  end

  return {
    keyword_pattern_offset = pattern:get_keyword_pattern_offset(context)
  }
end

--- ??
-- ??
-- @param result
-- @return table: completion items
function nvim_lsp.convert(_, result)
  local completion_items = vim.tbl_islist(result or {}) and result or result.items or {}

  local complete_items = {}
  for _, completion_item in pairs(completion_items) do
    local label = string.gsub(completion_item.label, "^%s*(.-)%s*$", "%1")
    local insert_text = completion_item.insertText and string.gsub(completion_item.insertText, "^%s*(.-)%s*$", "%1") or label

    local word = ''
    local abbr = ''
    if completion_item.insertTextFormat == 2 then
      word = label
      abbr = label

      local expandable = false
      if completion_item.textEdit ~= nil and completion_item.textEdit.newText ~= nil then
        expandable = word ~= completion_item.textEdit.newText
      elseif completion_item.insertText ~= nil then
        expandable = word ~= completion_item.insertText
      end

      if expandable then
        abbr = abbr .. '~'
      end
    else
      word = insert_text
      abbr = label
    end

    local kind = protocol.CompletionItemKind[completion_item.kind] or ''
    if type(completion_item.detail) == 'string' then
      local match = string.match(string.gsub(completion_item.detail, "^%s*(.-)%s*$", "%1"), '^[^\n]+')
      if match ~= nil then
        kind = match
      end
    end

    table.insert(complete_items, {
      word = word;
      abbr = abbr;
      preselect = completion_item.preselect or false,
      kind = kind;
      user_data = {
        nvim = {
          lsp = {
            completion_item = completion_item;
          };
        };
      };
      filter_text = completion_item.filterText or nil;
      sort_text = completion_item.sortText or nil;
    })
  end
  return complete_items
end

--- source compelete function.
-- triggers completion based on the item provided
-- @param self
-- @param args: ???
function nvim_lsp.complete(self, args)
  local params = vim.lsp.util.make_position_params()

  if vim.lsp.client_is_stopped(self.client.id) then
    return args.abort()
  end

  params.context = {
    triggerKind = (args.trigger_character_offset > 0 and 2 or (args.incomplete and 3 or 1))
  }

  if args.trigger_character_offset > 0 then
    params.context.triggerCharacter = args.context.before_char
  end

  self.client.request('textDocument/completion', params, function(err, _, result)
    if err or not result then return args.abort() end
    args.callback({
      items = self:convert(result);
      incomplete = result.incomplete or false;
    })
  end)
end

return {
register = function()
  -- unregister ?? why
  for source_id in pairs(lsp_sources) do
    compe:unregister_source(source_id)
  end
  -- for every client configured with nvim_lsp, register a source
  for id, client in pairs(vim.lsp.buf_get_clients(0)) do
    local source_id = 'nvim_lsp:' .. id
    lsp_sources[source_id] = setmetatable({client = client}, { __index = nvim_lsp })
    compe:register_lua_source(source_id, lsp_sources[source_id])
  end
end
}
