local Pattern = {
  filetypes = {};
}

function Pattern:set(filetype, config)
  self.filetypes[filetype] = config
end

function Pattern:get_keyword_pattern(context)
  return self.filetypes[context.filetype] and self.filetypes[context.filetype].keyword_pattern or '\\h[[:alnum:]]*\\%(-[[:alnum:]]\\+\\)*'
end

function Pattern:get_keyword_pattern_offset(context)
  local regex = vim.regex(self:get_keyword_pattern(context) .. '$')
  local offset = regex:match_str(context.before_line)
  if offset == nil then
    return nil
  end
  return offset + 1
end

function Pattern:get_property_accessors(context)
  return self.filetypes[context.filetype] and self.filetypes[context.filetype].propery_accessors or {}
end

return Pattern

