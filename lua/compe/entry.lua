local Entry = {}

--- Create entry
Entry.new = function(source, item)
  local entry

  -- Convert string or Vim's complete-item to LSP's CompletionItem.
  if type(item) == 'string' then
    entry = {
      source = source,
      resolved = false,
      lsp_item = {
        label = item,
      };
    }
  elseif item.word ~= nil then
    entry = {
      source = source,
      resolved = false,
      lsp_item = {
        label = item.abbr or item.word,
        insertText = item.word,
        filterText = item.filter_text or nil, -- backward compatibility.
        sortText = item.sort_text or nil, -- backward compatibility.
        preselect = item.preselect or false,  -- backward compatibility.
      },
    }
  else
    entry = {
      source = source,
      resolved = false,
      lsp_item = item
    }
  end

  -- Analyze word/abbr.
  local word = ''
  local abbr = ''
  if entry.lsp_item.insertTextFormat == 2 then
    local text = entry.lsp_item.label
    if entry.lsp_item.textEdit ~= nil then
      text = entry.lsp_item.textEdit.newText or text
    elseif entry.lsp_item.insertText ~= nil then
      text = entry.lsp_item.insertText or text
    end
    if word ~= text then
      abbr = entry.lsp_item.label .. '~'
    end
    word = string.match(text, '[^%s=%(%$"\']+')
  else
    word = entry.lsp_item.insertText or entry.lsp_item.label
    abbr = entry.lsp_item.label
  end

  -- Create Vim's complete-item properties.
  local metadata = source:get_metadata()
  entry.vim_item = {}
  entry.vim_item._word = string.gsub(word, '^%s*|%s*$', '')
  entry.vim_item._abbr = abbr
  entry.vim_item._dup = metadata.dup or 1
  entry.vim_item.menu = metadata.menu or ''
  entry.vim_item.empty = 1
  entry.vim_item.equal = 1
  entry.vim_item.dup = 1

  return setmetatable(entry, { __index = Entry })
end

Entry.fix = function(self, context, start_offset)
  local gap = string.sub(context.before_line, start_offset, self.source:get_start_offset() - 1)
  self.vim_item.word = gap .. self.vim_item._word
  self.vim_item.abbr = string.rep(' ', #gap) .. self.vim_item._abbr
end

return Entry

