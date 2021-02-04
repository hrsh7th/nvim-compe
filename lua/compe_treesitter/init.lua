local ts_exists = pcall(require, "nvim-treesitter")
local ts_locals = require('nvim-treesitter.locals')
local parsers = require('nvim-treesitter.parsers')
local ts_utils = require('nvim-treesitter.ts_utils')
local compe = require('compe')

local Source = {}

function Source.new()
  return setmetatable({}, { __index = Source })
end

function Source.get_metadata(_)
  return {
    priority = 100;
    dup = true;
    menu = '[Treesitter]';
  }
end

function Source.determine(_, context)
  if not ts_exists then
    error("You need to install nvim-treesitter!")
    return {}
  end

  if not parsers.has_parser() then return {} end

  return compe.helper.determine(context)
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

function Source.complete(self, context)
  local complete_items = {}

  local at_point = ts_utils.get_node_at_cursor()
  local line_current = vim.api.nvim_win_get_cursor(0)[1]

  for name, definitions in ipairs(ts_locals.get_definitions(0)) do
    local matches = self:_prepare_match(definitions, name)

    for _, match in ipairs(matches) do
      local node = match.node
      local node_scope = self:_get_smallest_context(node)
      local start_line_node, _, _= node:start()
      local node_text = ts_utils.get_node_text(node, 0)[1]

      if node_text
        and (not node_scope or ts_utils.is_parent(node_scope, at_point))
        and (start_line_node <= line_current) then
        table.insert(complete_items, {word = node_text, kind = match.kind})
      end
    end
  end

  context.callback({
    items = complete_items,
    incomplete = true
  })
end

return Source.new()

