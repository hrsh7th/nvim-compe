local helper = require'compe.helper'

local Entry = {}

Entry.create = function(context, trigger, response)
  response = response or {}
  if not (response.items or response.isIncomplete ~= nil) then
    response = {
      items = response,
      isIncomplete = false,
    }
  end

  for i, item in ipairs(response.items) do
    response.items[i] = Entry._to_item(item)
  end

  return helper.convert_lsp({
    keyword_pattern_offset = trigger.keyword_pattern_offset,
    context = context,
    response = response
  })
end

--- Convert any type item as LSP format.
Entry._to_item = function(item)
  -- Handle string item.
  if type(item) == 'string' then
    return { label = item }
  end

  -- Handle legacy item.
  if item.word then
    return {
      label = item.abbr or item.word,
      insertText = item.word,
      filterText = item.filter_text,
      sortText = item.sort_text,
    }
  end

  return item
end

return Entry

