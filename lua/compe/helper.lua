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

return Helper

