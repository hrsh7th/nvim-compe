local Pattern = require'compe.pattern'
local protocol = require'vim.lsp.protocol'
local util = require'vim.lsp.util'

local Source = {}

function Source.new(client)
  local self = setmetatable({}, { __index = Source })
  self.client = client
  return self
end

function Source.get_metadata(self)
  return {
    priority = 1000;
    dup = 0;
    menu = '[LSP]';
  }
end

function Source.documentation(self, args)
  local completion_item = self:get_paths(args, { 'completed_item', 'user_data', 'nvim', 'lsp', 'completion_item' })
  if not completion_item then
    return args.abort()
  end

  --- send `completionItem/resolve` if supported.
  local has_resolve = self:get_paths(self.client.server_capabilities, { 'completionProvider', 'resolveProvider' })
  if has_resolve then
    self.client.request('completionItem/resolve', completion_item, function(err, _, result)
      if err or not result then
        return args.abort()
      end
      local document = self:create_document(args.context.filetype, result)
      if #document > 0 then
        args.callback(document)
      else
        args.abort()
      end
    end)

  --- use current completion_item
  else
    local document = self:create_document(args.context.filetype, completion_item)
    if #document > 0 then
      args.callback(document)
    else
      args.abort()
    end
  end
end

--- create_document
function Source.create_document(self, filetype, completion_item)
  local document = {}
  if completion_item.detail then
    table.insert(document, '```' .. filetype)
    table.insert(document, completion_item.detail)
    table.insert(document, '```')
  end
  if completion_item.documentation then
    if completion_item.detail then
      table.insert(document, ' ')
    end
    for _, line in ipairs(util.convert_input_to_markdown_lines(completion_item.documentation)) do
      table.insert(document, line)
    end
  end
  return document
end

function Source.datermine(self, context)
  local trigger_chars = self:get_paths(self.client.server_capabilities, { 'completionProvider', 'triggerCharacters' }) or {}
  if vim.tbl_contains(trigger_chars, context.before_char) and context.before_char ~= ' ' then
    return {
      keyword_pattern_offset = Pattern:get_keyword_pattern_offset(context);
      trigger_character_offset = context.col;
    }
  end

  return {
    keyword_pattern_offset = Pattern:get_keyword_pattern_offset(context)
  }
end

function Source.complete(self, args)
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

function Source.convert(_, result)
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

function Source.get_paths(self, root, paths)
  local c = root
  for _, path in ipairs(paths) do
    c = c[path]
    if not c then
      return nil
    end
  end
  return c
end

return Source
