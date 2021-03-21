local ts_locals = require'nvim-treesitter.locals'
local parsers = require'nvim-treesitter.parsers'
local ts_utils = require'nvim-treesitter.ts_utils'
local compe = require('compe')

local Source = {}

function Source.new()
  return setmetatable({}, { __index = Source })
end

function Source.get_metadata(_)
  return {
    priority = 100;
    dup = 0;
    menu = '[Treesitter]';
  }
end

function Source.determine(_, context)
  if not parsers.has_parser() then
    return {}
  end

  return compe.helper.determine(context)
end

function Source.complete(self, args)
  local complete_items = {}
  local complete_items_uniq = {}

  local at_point = ts_utils.get_node_at_cursor()
  for name, definitions in ipairs(ts_locals.get_definitions(0)) do
    local matches = self:_prepare_match(definitions, name)

    for _, match in ipairs(matches) do
      local node = match.node
      local text = ts_utils.get_node_text(node, 0)[1]
      if not complete_items_uniq[text] then
        local scope = self:_get_smallest_context(node)
        local start_line = node:start()

        local accept = true
        accept = accept and text
        accept = accept and (not scope or ts_utils.is_parent(scope, at_point))
        accept = accept and start_line <= (args.context.lnum - 1)
        if accept then
          complete_items_uniq[text] = true
          table.insert(complete_items, {
            word = text .. '',
            kind = match.kind .. ''
          })
        end
      end
    end
  end

  args.callback({
    items = complete_items,
  })
end

function Source._get_smallest_context(_, source)
  local scopes = ts_locals.get_scopes()
  local current = source

  while current ~= nil and not vim.tbl_contains(scopes, current) do
    current = current:parent()
  end

  return current or nil
end

function Source._prepare_match(self, match, kind)
  local matches = {}

  if match.node then
    table.insert(matches, { kind = kind or '', node = match.node })
  else
    for name, item in pairs(match) do
      vim.list_extend(matches, self:_prepare_match(item, name))
    end
  end

  return matches
end

return Source.new()

