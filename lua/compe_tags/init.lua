local compe = require("compe")
local Source = {}

function Source.new()
  return setmetatable({}, { __index = Source })
end

function Source.get_metadata(self)
  return {
    priority = 90;
    menu = '[Tag]';
  }
end

function Source.determine(_, context)
  return compe.helper.determine(context)
end

function Source.complete(self, context)
--  here for reference:
--  this is an example of what is returned by this function in LSP
--     {
--       abbr = "get_contexts(carla_proj)",
--       filter_text = "get_contexts(carla_proj)",
--       kind = "Function",
--       preselect = false,
--       sort_text = "aget_contexts",
--       suggest_offset = 5,
--       user_data = {
--         compe = {
--           completion_item = {
--             detail = "asmd_resynth",
--             documentation = "get_contexts(carla_proj: Path) -> t.Dict[str, t.Optional[Path]]\n\nLoads contexts and Carla project files from the provided directory\n\nReturns a dictionary which maps context names t
-- o the corresponding carla\nproject file. The additional context 'orig' with project `None` is added.",
--             insertText = "get_contexts",
--             kind = 3,
--             label = "get_contexts(carla_proj)",
--             sortText = "aget_contexts"
--           },
--           request_position = <table 1>
--         }
--       },
--       word = "get_contexts"
--     }
  local _, items = pcall(function()
    return vim.fn.getcompletion(context.input, "tag")
  end)
  if type(items) ~= 'table' then
    return context.abort()
  end

  out = {}
  for k, v in ipairs(items) do
    local tags = vim.fn.taglist(v)
    local kind = '['
    local label = nil
    for i, tag in ipairs(tags) do
        kind = kind .. tag.kind
        if tag.signature ~= nil and #tags == 1 then
            label = tag.name .. tag.signature
        end
    end
    if label == nil and #tags > 1 then
        label = tags[1].name
        kind = nil
    else
        kind = kind .. ']'
    end
    table.insert(out, {
        abbr=label,
        word=v,
        filter_text=label,
        kind=kind,
        preselect=false,
        user_data={compe={completion_item={
            label=label, 
            detail=v,
            insertText=v,
        }}}
    })
  end

  context.callback({
    items = out or {},
    incomplete = false
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

