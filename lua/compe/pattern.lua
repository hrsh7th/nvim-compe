local Config = require'compe.config'

local Pattern = {}

Pattern._filetypes = {}
Pattern._regexes = {}

--- set
Pattern.set_filetype_config = function(filetype, config)
  Pattern._filetypes[filetype] = config
end

--- get_default_pattern
Pattern.get_default_pattern = function()
  return Config.get().default_pattern
end

--- get_keyword_pattern
Pattern.get_keyword_pattern = function(filetype)
  if Pattern._filetypes[filetype] and Pattern._filetypes[filetype].keyword_pattern then
    return Pattern._filetypes[filetype].keyword_pattern
  end
  return Pattern.get_default_pattern()
end

--- get_keyword_offset
Pattern.get_keyword_offset = function(context)
  local keyword_pattern = Pattern.get_keyword_pattern(context.filetype) .. '$'
  local default_pattern = Pattern.get_default_pattern() .. '$'

  local s1, s2
  if keyword_pattern == default_pattern then
    s1 = Pattern.get_pattern_offset(context.before_line, keyword_pattern)
    s2 = s1
  else
    s1 = Pattern.get_pattern_offset(context.before_line, keyword_pattern)
    s2 = Pattern.get_pattern_offset(context.before_line, default_pattern)
  end

  if s2 == 0 then
    return s1
  end
  if s1 == 0 then
    return s2
  end
  return math.min(s1, s2)
end

--- get_pattern_offset
Pattern.get_pattern_offset = function(before_line, pattern)
  local regex = Pattern.regex(pattern)
  local s = regex:match_str(before_line)
  if s == nil then
    return 0
  end
  return s + 1
end


--- regex
Pattern.regex = function(pattern)
  if not Pattern._regexes[pattern] then
    Pattern._regexes[pattern] = vim.regex(pattern)
  end
  return Pattern._regexes[pattern]
end

return Pattern

