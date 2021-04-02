local compe = require("compe")
local Source = {}
local luasnip_exists, luasnip = pcall(require, "luasnip")

function Source.new()
  return setmetatable({}, { __index = Source })
end

function Source.get_metadata(_)
  return {
    priority = 10;
    -- keep Snippets with same trigger but different filetype.
    dup = true;
    menu = '[Snippets]';
  }
end

function Source.determine(_, context)
  if not luasnip_exists then
    error("Cannot add source 'luasnip' without LuaSnip installed!")
    return {}
  end
  return compe.helper.determine(context)
end

function Source.documentation(self, context)
  local item = context.completed_item
  context.callback(luasnip.snippets[item.kind][item.user_data.ft_indx].dscr)
end

function Source.complete(_, context)
  local items = {}

  local filetypes = vim.split(vim.bo.filetype, ".", true)
  filetypes[#filetypes+1] = "all"
  for i = 1, #filetypes do
    local ft_table = luasnip.snippets[filetypes[i]]
    if ft_table then
      for j, snip in ipairs(ft_table) do
        items[#items+1] = {
          word = snip.name or snip.trigger,
          kind = filetypes[i],
          abbr = snip.trigger,
          user_data = {
            -- store index of snip in ft-table, no search when expanding.
            ft_indx = j
          }
        }
      end
    end
  end

  context.callback({
    items = items
  })
end

function Source.confirm(_, context)
  local item = context.completed_item
  local snip = luasnip.snippets[item.kind][item.user_data.ft_indx]:copy()
  snip:trigger_expand(Luasnip_current_nodes[vim.api.nvim_get_current_buf()])
end

return Source.new()
