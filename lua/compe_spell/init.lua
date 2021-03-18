local compe = require("compe")
local Source = {}

function Source.new()
  return setmetatable({}, { __index = Source })
end

function Source.get_metadata(_)
  return {
    priority = 90;
    dup = 0;
    menu = '[Spell]';
  }
end

function Source.determine(_, context)
  if vim.wo.spell == 0 then
    return {}
  end
  return compe.helper.determine(context)
end

function Source.complete(_, context)
  context.callback({
    items = vim.fn.spellsuggest(context.input),
    incomplete = true
  })
end

return Source.new()

