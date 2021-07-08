local compe = require("compe")
local Source = {}
local luasnip = require "luasnip"
local util = require "vim.lsp.util"

function Source.new()
  return setmetatable({}, {__index = Source})
end

function Source.get_metadata(_)
  return {
    priority = 10,
    -- keep Snippets with same trigger but different filetype.
    dup = true,
    menu = "[LuaSnip]"
  }
end

function Source.determine(_, context)
  return compe.helper.determine(context)
end

function Source.documentation(self, args)
  local item = args.completed_item
  local snip = luasnip.snippets[item.kind][item.user_data.ft_indx]
  local header = (snip.name or "") .. " - `[" .. args.context.filetype .. "]`\n"

  -- table is flattened in convert_input_to_markdown_lines().
  local documentation = {header .. string.rep("=", string.len(header) - 3), "", (snip.dscr or "")}
  args.callback(util.convert_input_to_markdown_lines(documentation))
end

function Source.complete(_, context)
  local items = {}

  local filetypes = vim.split(vim.bo.filetype, ".", true)
  filetypes[#filetypes + 1] = "all"
  for i = 1, #filetypes do
    local ft_table = luasnip.snippets[filetypes[i]]
    if ft_table then
      for j, snip in ipairs(ft_table) do
        items[#items + 1] = {
          word = snip.trigger,
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

  context.callback(
    {
      items = items
    }
  )
end

function Source.confirm(_, context)
  local item = context.completed_item
  local snip = luasnip.snippets[item.kind][item.user_data.ft_indx]:copy()
  snip:trigger_expand(Luasnip_current_nodes[vim.api.nvim_get_current_buf()])
end

return Source.new()
