-- Generates the emoji data Lua file using this as a source: https://raw.githubusercontent.com/iamcal/emoji-data/master/emoji.json

local Update = {}

Update._read = function(path)
  return vim.fn.json_decode(vim.fn.readfile(path))
end

Update._write = function(path, data)
  local h = io.open(path, 'w')
  h:write(data)
  io.close(h)
end

Update.to_string = function(chars)
  local nrs = {}
  for _, char in ipairs(chars) do
    table.insert(nrs, vim.fn.eval(([[char2nr("\U%s")]]):format(char)))
  end
  return vim.fn.list2str(nrs, true)
end

Update.to_item = function(emoji, short_name)
  short_name = ':' .. short_name .. ':'
  local word = emoji
  local abbr = emoji
  local kind = short_name
  local filter_text = short_name
  return ("{ word = '%s'; abbr = '%s'; kind = '%s'; filter_text = '%s' };\n"):format(word, abbr, kind, filter_text)
end

Update.update = function()
  local items = ''
  for _, emoji in ipairs(Update._read('./emoji.json')) do
    local char = Update.to_string(vim.split(emoji.unified, '-'))

    local valid = true
    valid = valid and vim.fn.strdisplaywidth(char) <= 2 -- Ignore invalid ligatures
    if valid then
      items = items .. Update.to_item(char, emoji.short_name)
    end
  end
  Update._write('./items.lua', ('return {\n%s}'):format(items))
end

return Update

