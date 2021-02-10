local Pattern = require'compe.pattern'
local Character = require'compe.utils.character'

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
Helper.convert_lsp = function(args)
  local context = args.context
  local request = args.request
  local response = args.response

  local completion_items = vim.tbl_islist(response or {}) and response or response.items or {}

  local offset = context.col
  local complete_items = {}
  for _, completion_item in pairs(completion_items) do
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
      -- `func`($0)
      -- `class`="$0"
      -- `variable`$0
      word = string.match(text, '[^%s=%(%$]+')
    else
      word = completion_item.insertText or completion_item.label
      abbr = completion_item.label
    end
    word = string.gsub(string.gsub(word, '^%s*', ''), '%s*$', '')
    abbr = string.gsub(string.gsub(abbr, '^%s*', ''), '%s*$', '')

    -- determine item offset.
    local fixed = false
    if not fixed and completion_item.textEdit then
      -- overlapped textEdit
      for idx = completion_item.textEdit.range.start.character + 1, #context.before_line do
        -- TODO: Add references to location of the same logic in VSCode.
        if not Character.is_white(string.byte(context.before_line, idx)) then
          if string.find(word, string.sub(context.before_line, idx, -1), 1, true) == 1 then
            offset = math.min(offset, idx)
            fixed = true
            break
          end
        end
      end
    end
    if not fixed and request.context and request.context.triggerKind == 2 then
      -- overlapped trigger character
      -- TODO: This is_alnum checking is reasonable or not (This needed by sumneko_lua)
      if not Character.is_alnum(string.byte(context.before_char, 1)) then
        if string.byte(context.before_char, 1) == string.byte(word, 1) then
          offset = math.min(offset, context.col - 1)
          fixed = true
        end
      end
    end

    table.insert(complete_items, {
      word = word;
      abbr = abbr;
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
    })
  end

  return {
    items = complete_items,
    incomplete = response.incomplete or false,
    offset = context.col ~= offset and offset or nil,
  }
end

return Helper

