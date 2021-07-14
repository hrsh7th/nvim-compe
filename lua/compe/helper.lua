local Pattern = require'compe.pattern'
local String = require'compe.utils.string'
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

--- set_text
Helper.set_text = function(bufnr, text_edits)
  vim.call('compe#helper#set_text', bufnr, text_edits)
end

--- convert_lsp
--
-- This method will convert LSP.CompletionItem.
--
-- Should check following servers.
--
-- - php: $| -> namespace\Class::$variable|
-- - clang: foo.| -> foo->prop|
-- - json: "repository|" -> "repository": {|}
-- - html: "</|>" -> "</div|>"
-- - rust: PathBuf::into_|os_string -> PathBuf::into_boxed_path|
-- - viml: let g:compe.| -> let g:compe.autocomplete|
-- - lua: require'compe|' -> require'compe.utils.character|'
--
Helper.convert_lsp = function(args)
  local keyword_pattern_offset = args.keyword_pattern_offset
  local context = args.context
  local request = args.request
  local response = args.response or {}

  local completion_items = response.items or response
  for i, completion_item in ipairs(completion_items) do
    local word = ''
    local abbr = ''
    local insert_text = completion_item.insertText ~= '' and completion_item.insertText and completion_item.insertText or nil
    if completion_item.insertTextFormat == 2 then
      word = completion_item.label
      abbr = completion_item.label

      local text = word
      if completion_item.textEdit ~= nil then
        text = completion_item.textEdit.newText or text
      elseif insert_text then
        text = insert_text or text
      end
      if word ~= text then
        abbr = abbr .. '~'
      end
      word = text
    else
      word = insert_text or completion_item.label
      abbr = completion_item.label
    end
    word = String.trim(word)
    abbr = String.trim(abbr)

    local suggest_offset = args.keyword_pattern_offset
    if completion_item.textEdit and completion_item.textEdit.range then
      for idx = completion_item.textEdit.range.start.character + 1, args.keyword_pattern_offset - 1 do
        if string.byte(context.before_line, idx) == string.byte(word, 1) then
          suggest_offset = idx
          keyword_pattern_offset = math.min(idx, keyword_pattern_offset)
          break
        end
      end
    else
      -- TODO: Add tests (compe specific implementation)
      local byte_map = String.make_byte_map(word)
      for idx = args.keyword_pattern_offset - 1, 1, -1 do
        local char = string.byte(context.before_line, idx)
        if Character.is_white(char) or not byte_map[char] then
          break
        end
        if Character.is_semantic_index(context.before_line, idx) then
          local match = true
          for i = 1, math.min(#word, args.keyword_pattern_offset - idx) do
            if string.byte(word, i) ~= string.byte(context.before_line, idx + i - 1) then
              match = false
              break
            end
          end
          if match then
            suggest_offset = idx
            keyword_pattern_offset = math.min(idx, keyword_pattern_offset)
          end
        end
      end
    end

    completion_items[i] = {
      word = word,
      abbr = abbr,
      kind = vim.lsp.protocol.CompletionItemKind[completion_item.kind] or nil;
      user_data = {
        compe = {
          request_position = request.position;
          completion_item = completion_item;
        };
      };
      filter_text = completion_item.filterText or abbr;
      sort_text = completion_item.sortText or abbr;
      preselect = completion_item.preselect or false;
      suggest_offset = suggest_offset;
    }
  end

  local leading = string.sub(context.before_line, keyword_pattern_offset, args.keyword_pattern_offset - 1)
  for _, completion_items in ipairs(completion_items) do
    completion_items.word = String.get_word(completion_items.word, leading)
  end

  return {
    items = completion_items,
    incomplete = response.isIncomplete or false,
    keyword_pattern_offset = keyword_pattern_offset;
  }
end

return Helper

