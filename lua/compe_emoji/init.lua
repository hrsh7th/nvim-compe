local compe = require'compe'

local Source = {}

Source.get_metadata = function(_)
  return {
    priority = 80,
    dup = 1,
    menu = '[Emoji]'
  }
end

Source.determine = function(_, context)
  return compe.helper.determine(context, {
    keyword_pattern = [[\%(\s\|^\)\zs:\w*]]
  })
end

-- Load emoji data from auto-generated file:
Source._items = require('compe_emoji.data')

Source.complete = function(self, args)
  args.callback({
    items = self._items,
    incomplete = true,
  })
end

return Source
