local Pattern = {}

Pattern.filetypes = {}
Pattern.regexes = {}

Pattern.set = function(filetype, config)
  Pattern.filetypes[filetype] = config
end

Pattern.get_default_keyword_pattern = function()
  return '\\h\\w*\\%(-\\w*\\)*'
end

Pattern.get_keyword_pattern = function(context)
  return Pattern.get_keyword_pattern_by_filetype(context.filetype)
end

Pattern.get_keyword_pattern_by_filetype = function(filetype)
  return Pattern.filetypes[filetype] and Pattern.filetypes[filetype].keyword_pattern or Pattern.get_default_keyword_pattern()
end

Pattern.get_keyword_pattern_offset = function(context)
  local keyword_pattern = Pattern.get_keyword_pattern(context) .. '$'
  local default_pattern = Pattern.get_default_keyword_pattern() .. '$'

  local s1, s2
  if keyword_pattern == default_pattern then
    s1 = Pattern.regex(keyword_pattern):match_str(context.before_line)
    s2 = s1
  else
    s1 = Pattern.regex(keyword_pattern):match_str(context.before_line)
    s2 = Pattern.regex(default_pattern):match_str(context.before_line)
  end

  if s1 == nil and s2 == nil then
    return 0
  end
  if s2 == nil then
    return s1 + 1
  end
  if s1 == nil then
    return s2 + 1
  end
  return math.min(s1, s2) + 1
end

Pattern.regex = function(pattern)
  if not Pattern.regexes[pattern] then
    Pattern.regexes[pattern] = vim.regex(pattern)
  end
  return Pattern.regexes[pattern]
end

return Pattern

