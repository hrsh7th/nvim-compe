local compe = require'compe'

local Source = {}

Source.get_metadata = function(_)
  return {
    priority = 50,
    dup = 1,
    menu = '[Calc]'
  }
end

Source.determine = function(_, context)
  return compe.helper.determine(context, {
    keyword_pattern = [[\d\+\%(\.\d\+\)\?\%(\s\+\|\d\+\%(\.\d\+\)\?\|+\|\-\|/\|\*\|%\|\^\|(\|)\)\+$]]
  })
end

Source.complete = function(self, args)
  -- Ignore if input has no math operators.
  if string.match(args.input, '^[%s%d%.]*$') ~= nil then
    return args.abort()
  end

  -- Ignore if failed to interpret to Lua.
  local m = load(('return (%s)'):format(args.input))
  if type(m) ~= 'function' then
    return args.abort()
  end
  local status, value = pcall(function()
    return m()
  end)

  -- Ignore if return values is not number.
  if not status or type(value) ~= 'number' then
    return args.abort()
  end

  args.callback({
    items = { {
      word = '' .. value,
      abbr = self:_trim(args.input),
      filter_text = args.input,
    }, {
      word = self:_trim(args.input) .. ' = ' .. value,
      abbr = self:_trim(args.input) .. ' = ' .. value,
      filter_text = args.input,
    } },
    incomplete = true,
  })
end

Source._trim = function(_, text)
  text = string.gsub(text, '^%s*', '')
  text = string.gsub(text, '%s*$', '')
  return text
end

return Source

