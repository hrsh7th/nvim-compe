local Pattern = require'compe.pattern'

local Helper = {}

--- determine
Helper.determine = function(context, option)
  local trigger_character_offset = 0
  if option and option.trigger_characters and context.before_char ~= ' ' then
    if vim.tbl_contains(option.trigger_characters, context.before_char) then
      trigger_character_offset = context.col
    end
  end

  local keyword_pattern_offset
  if option and option.keyword_pattern then
    keyword_pattern_offset = Pattern.get_pattern_offset(context.before_line, option.keyword_pattern)
  end

  return {
    keyword_pattern_offset = keyword_pattern_offset or Pattern.get_keyword_offset(context);
    trigger_character_offset = trigger_character_offset;
  }
end

--- get_keyword_pattern
Helper.get_keyword_pattern = function(filetype)
  return Pattern.get_keyword_pattern(filetype)
end

--- get_default_keyword_pattern
Helper.get_default_pattern = function()
  return Pattern.get_default_pattern()
end

--- convert_lsp
Helper.convert_lsp = function(request_position, response)
  local completion_items = vim.tbl_islist(response or {}) and response or response.items or {}

  local complete_items = {}
  for _, completion_item in pairs(completion_items) do
    local label = completion_item.label
    local insert_text = completion_item.insertText or label

    local word = ''
    local abbr = ''
    if completion_item.insertTextFormat == 2 then
      word = label
      abbr = label

      local text = word
      if completion_item.textEdit ~= nil then
        text = completion_item.textEdit.newText or text
      elseif completion_item.insertText ~= nil then
        text = completion_item.insertText or text
      end
      if word ~= text then
        abbr = abbr .. '~'
      end
      word = string.match(text, '[^%s=%(%$"\']+')
    else
      word = insert_text
      abbr = label
    end
    word = string.gsub(word, '^%s*|%s*$', '')

    table.insert(complete_items, {
      word = word;
      abbr = abbr;
      preselect = completion_item.preselect or false;
      kind = vim.lsp.protocol.CompletionItemKind[completion_item.kind] or nil;
      user_data = {
        compe = {
          request_position = request_position;
          completion_item = completion_item;
        };
      };
      filter_text = completion_item.filterText or nil;
      sort_text = completion_item.sortText or nil;
    })
  end
  return {
    items = complete_items,
    incomplete = response.incomplete or false,
  }
end

return Helper

