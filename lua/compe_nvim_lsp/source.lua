local compe = require'compe'
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
    dup = 1;
    menu = '[LSP]';
    filetypes = { self.filetype };
  }
end

--- determine
function Source.determine(self, context)
  return compe.helper.determine(context, {
    trigger_characters = self:_get_paths(self.client.server_capabilities, { 'completionProvider', 'triggerCharacters' }) or {};
  })
end

--- complete
function Source.complete(self, args)
  if vim.lsp.client_is_stopped(self.client.id) then
    return args.abort()
  end

  local request = vim.lsp.util.make_position_params()
  request.context = {}
  request.context.triggerKind = (args.trigger_character_offset > 0 and 2 or (args.incomplete and 3 or 1))
  if args.trigger_character_offset > 0 then
    request.context.triggerCharacter = args.context.before_char
  end

  self.client.request('textDocument/completion', request, function(err, _, response)
    if err or not response then
      return args.abort()
    end
    args.callback(compe.helper.convert_lsp({
      keyword_pattern_offset = args.keyword_pattern_offset,
      context = args.context,
      request = request,
      response = response,
    }))
  end)
end

--- resolve
function Source.resolve(self, args)
  local completion_item = self:_get_paths(args, { 'completed_item', 'user_data', 'compe', 'completion_item' })
  local has_resolve = self:_get_paths(self.client.server_capabilities, { 'completionProvider', 'resolveProvider' })
  if has_resolve and completion_item then
    self.client.request('completionItem/resolve', completion_item, function(err, _, result)
      if not err and result then
        args.completed_item.user_data.compe.completion_item = result
      end
      args.callback(args.completed_item)
    end)
  else
    args.callback(args.completed_item)
  end
end

--- confirm
function Source.confirm(self, args)
  local completed_item = args.completed_item
  local completion_item = self:_get_paths(completed_item, { 'user_data', 'compe', 'completion_item' })
  local request_position = self:_get_paths(completed_item, { 'user_data', 'compe', 'request_position' })
  if completion_item then
    vim.call('compe#confirmation#lsp', {
      completed_item = completed_item,
      completion_item = completion_item,
      request_position = request_position,
    })
  end
end

--- documentation
function Source.documentation(self, args)
  local completion_item = self:_get_paths(args, { 'completed_item', 'user_data', 'compe', 'completion_item' })
  if completion_item then
    local document = self:_create_document(args.context.filetype, completion_item)
    if #document > 0 then
      args.callback(document)
    else
      args.abort()
    end
  end
end

--- _create_document
function Source._create_document(self, filetype, completion_item)
  local document = {}
  if completion_item.detail and completion_item.detail ~= '' then
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

--- _get_paths
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
