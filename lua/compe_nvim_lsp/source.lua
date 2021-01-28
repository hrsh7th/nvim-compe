local compe = require'compe'
local protocol = require'vim.lsp.protocol'
local util = require'vim.lsp.util'

local Source = {}

function Source.new(client, filetype)
  local self = setmetatable({}, { __index = Source })
  self.client = client
  self.filetype = filetype
  return self
end

function Source.get_metadata(self)
  return {
    priority = 1000;
    dup = 0;
    menu = '[LSP]';
    filetypes = { self.filetype };
  }
end

function Source.datermine(self, context)
  return compe.helper.datermine(context, {
    trigger_characters = self:_get_paths(self.client.server_capabilities, { 'completionProvider', 'triggerCharacters' }) or {};
  })
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
      items = self:_convert(result);
      incomplete = result.isIncomplete or false;
    })
  end)
end

function Source.documentation(self, args)
  local completion_item = self:_get_paths(args, { 'completed_item', 'user_data', 'nvim', 'lsp', 'completion_item' })
  if not completion_item then
    return args.abort()
  end

  --- send `completionItem/resolve` if supported.
  local has_resolve = self:_get_paths(self.client.server_capabilities, { 'completionProvider', 'resolveProvider' })
  if has_resolve then
    self.client.request('completionItem/resolve', completion_item, function(err, _, result)
      if err or not result then
        return args.abort()
      end
      local document = self:_create_document(args.context.filetype, result)
      if #document > 0 then
        args.callback(document)
      else
        args.abort()
      end
    end)

  --- use current completion_item
  else
    local document = self:_create_document(args.context.filetype, completion_item)
    if #document > 0 then
      args.callback(document)
    else
      args.abort()
    end
  end
end

function Source.confirm(self, args)
  local edits = self:_get_paths(args, { 'completed_item', 'user_data', 'nvim', 'lsp', 'completion_item', 'additionalTextEdits' })
  if edits then
    vim.lsp.util.apply_text_edits(edits, 0)
  end
end

--- create_document
function Source._create_document(self, filetype, completion_item)
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

function Source._convert(_, result)
  local completion_items = vim.tbl_islist(result or {}) and result or result.items or {}

  local complete_items = {}
  for _, completion_item in pairs(completion_items) do
    local label = completion_item.label
    local insert_text = completion_item.insertText or label

    local word = ''
    local abbr = ''
    if completion_item.insertTextFormat == 2 then
      word = label
      abbr = label

      local text = word
      if completion_item.textEdit ~= nil then
        text = completion_item.textEdit.newText or text
      elseif completion_item.insertText ~= nil then
        text = completion_item.insertText or text
      end
      if word ~= text then
        abbr = abbr .. '~'
      end
      word = string.match(text, '[^%s=%(%$"\']+')
    else
      word = insert_text
      abbr = label
    end
    word = string.gsub(word, '^%s*|%s*$', '')

    table.insert(complete_items, {
      word = word;
      abbr = abbr;
      preselect = completion_item.preselect or false;
      kind = protocol.CompletionItemKind[completion_item.kind] or nil;
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

function Source._get_paths(self, root, paths)
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
