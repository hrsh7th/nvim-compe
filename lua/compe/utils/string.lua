local String = {}

String.trim = function(text, width)
  if width == 0 then
    return ''
  end

  text = text or ''
  if #text > width then
    return string.sub(text, 1, width + 1) .. '...'
  end
  return text
end

return String

