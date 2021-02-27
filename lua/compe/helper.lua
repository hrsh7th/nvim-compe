local Pattern = require'compe.pattern'
local Character = require'compe.utils.character'

local Helper = {}

--- determine
Helper.determine = function(context, option)
  option = option or {}

  local trigger_character_offset = 0
  if option.trigger_characters and context.before_char ~= ' ' then
    if vim.tbl_contains(option.trigger_characters, context.before_char) then
      trigger_character_offset = context.col
    end
  end

  local keyword_pattern_offset = 0
  if option.keyword_pattern then
    keyword_pattern_offset = Pattern.get_pattern_offset(context.before_line, option.keyword_pattern)
  else
    keyword_pattern_offset = Pattern.get_keyword_offset(context)
  end

  return {
    keyword_pattern_offset = keyword_pattern_offset;
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
Helper.convert_lsp = function(args)
  local keyword_pattern_offset = args.keyword_pattern_offset
  local context = args.context
  local request = args.request
  local response = args.response

  local complete_items = {}
  for _, completion_item in pairs(vim.tbl_islist(response or {}) and response or response.items or {}) do
    local word = ''
    local abbr = ''
    if completion_item.insertTextFormat == 2 then
      word = completion_item.label
      abbr = completion_item.label

      local text = word
      if completion_item.textEdit ~= nil then
        text = completion_item.textEdit.newText or text
      elseif completion_item.insertText ~= nil then
        text = completion_item.insertText or text
      end
      if word ~= text then
        abbr = abbr .. '~'
      end
      word = text
    else
      word = completion_item.insertText or completion_item.label
      abbr = completion_item.label
    end

    -- Fix for leading_word
    local suggest_offset = args.keyword_pattern_offset
    local word_char = string.byte(word, 1)
    for idx = #context.before_line, 1, -1 do
      local line_char = string.byte(context.before_line, idx)
      if Character.is_white(line_char) then
        break
      end
      if Character.match(word_char, line_char) then
        if string.find(word, string.sub(context.before_line, idx, -1), 1, true) == 1 then
          suggest_offset = idx
          keyword_pattern_offset = math.min(idx, keyword_pattern_offset)
          break
        end
      end
    end

    table.insert(complete_items, {
      word = string.match(word, '[^%s=%(%$]+') or '';
      abbr = string.gsub(string.gsub(abbr, '^%s*', ''), '%s*$', '');
      kind = vim.lsp.protocol.CompletionItemKind[completion_item.kind] or nil;
      user_data = {
        compe = {
          request_position = request.position;
          completion_item = completion_item;
        };
      };
      filter_text = completion_item.filterText or nil;
      sort_text = completion_item.sortText or nil;
      preselect = completion_item.preselect or false;
      suggest_offset = suggest_offset;
    })
  end

  return {
    items = complete_items,
    incomplete = response.isIncomplete or false,
    keyword_pattern_offset = keyword_pattern_offset;
  }
end

return Helper

