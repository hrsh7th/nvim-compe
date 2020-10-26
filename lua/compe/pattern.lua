local Pattern = {
  filetypes = {};
}

function Pattern:set(filetype, config)
  self.filetypes[filetype] = config
end

function Pattern:get_default_keyword_pattern()
  return '\\h\\w*\\%(-\\w\\+\\)*'
end

function Pattern:get_keyword_pattern(context)
  return self.filetypes[context.filetype] and self.filetypes[context.filetype].keyword_pattern or self.get_default_keyword_pattern()
end

function Pattern:get_keyword_pattern_offset(context)
  local context_regex = vim.regex(self:get_keyword_pattern(context) .. '$')
  local default_regex = vim.regex(self:get_default_keyword_pattern() .. '$')
  local s1 = context_regex:match_str(context.before_line)
  local s2 = default_regex:match_str(context.before_line)

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

function Pattern:get_property_accessors(context)
  return self.filetypes[context.filetype] and self.filetypes[context.filetype].propery_accessors or {}
end

return Pattern

