local compe = require("compe")
local Source = {}

function Source.new()
  return setmetatable({}, { __index = Source })
end

function Source.get_metadata(_)
  return {
    priority = 90;
    menu = '[Tag]';
  }
end

function Source.determine(_, context)
  return compe.helper.determine(context)
end

function Source.complete(_, context)
  local _, items = pcall(function()
    return vim.fn.getcompletion(context.input, "tag")
  end)
  if type(items) ~= 'table' then
    return context.abort()
  end

  context.callback({
    items = items or {},
    incomplete = true
  })
end

function Source.documentation(_, context)
  local document = {}

  local tags = vim.fn.taglist(context.completed_item.word)
  for i, tag in ipairs(tags) do
    if 10 < i then
      table.insert(document, ('...and %d more'):format(#tags - 10))
      break
    end
    local doc =  tag.filename .. ' [' .. tag.kind .. ']'
        local doc =  '# ' .. tag.filename .. ' [' .. tag.kind .. ']'
    if #tag.cmd >= 5 and tag.signature == nil then
        doc = doc .. '\n  __' .. tag.cmd:sub(3, -3):gsub('%s+', ' ') .. '__'
    end
    if tag.access ~= nil then
        doc = doc .. '\n  ' .. tag.access
    end
    if tag.implementation ~= nil then
        doc = doc .. '\n  impl: _' .. tag.implementation .. '_'
    end
    if tag.inherits ~= nil then
        doc = doc .. '\n  ' .. tag.inherits
    end
    if tag.signature ~= nil then
        doc = doc .. '\n  sign: _' .. tag.name .. tag.signature .. '_'
    end
    if tag.scope ~= nil then
        doc = doc .. '\n  ' .. tag.scope
    end
    if tag.struct ~= nil then
        doc = doc .. '\n  in ' .. tag.struct
    end
    if tag.class ~= nil then
        doc = doc .. '\n  in ' .. tag.class
    end
    if tag.enum ~= nil then
        doc = doc .. '\n  in ' .. tag.enum
    end
    table.insert(document, doc)

  end

  context.callback(document)
end

return Source.new()

