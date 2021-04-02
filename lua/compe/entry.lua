local String = require'compe.utils.string'

local Entry = {}

Entry.create = function(context, trigger, response)
  response = response or {}

  if type(response.incomplete) == 'boolean' then
    -- Legacy format.
    response = {
      items = response.items,
      isIncomplete = response.incomplete,
    }
  elseif not response.items then
    -- LSP or Legacy format.
    response = {
      items = response,
      isIncomplete = false,
    }
  else
    --- LSP format with isIncomplete.
    response.isIncomplete = response.isIncomplete or false
  end

  for i, item in ipairs(response.items) do
    response.items[i] = Entry._convert(context, trigger, Entry._compat(item))
  end
  return response;
end

--- Convert any type item as LSP format.
Entry._compat = function(item)
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

-- Convert compe's entry
Entry._convert = function(context, trigger, item)
  local word = ''
  local abbr = ''
  if item.insertTextFormat == 2 then
    word = String.trim(item.label)
    abbr = String.trim(item.label) .. '~'
  else
    word = item.insertText or String.trim(item.label)
    abbr = String.trim(item.label)
  end

  local suggest_offset = trigger.keyword_pattern_offset
  if item.textEdit and item.textEdit.range then
    for idx = item.textEdit.range.start.character + 1, trigger.keyword_pattern_offset - 1 do
      if string.byte(context.before_line, idx) == string.byte(word, 1) then
        suggest_offset = idx
        break
      end
    end
  end

  return {
    vim = {
      word = word,
      abbr = abbr,
      kind = vim.lsp.protocol.CompletionItemKind[item.kind] or nil,
      empty = 1,
      equal = 1,
      dup = 1
    },
    lsp = item,
    suggest_offset = suggest_offset,
    request_offset = context.col,
  }
end

return Entry

