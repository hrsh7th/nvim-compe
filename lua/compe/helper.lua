local Pattern = require'compe.pattern'

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
    keyword_pattern = option.keyword_pattern or Pattern.get_keyword_pattern(context.filetype),
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

return Helper

