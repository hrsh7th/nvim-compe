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

Source.complete = function(self, args)
  -- Lazy load data if not present.
  if (not(Source._items)) then
    Source._items = require('compe_emoji.data')
  end

  args.callback({
    items = self._items,
    incomplete = true,
  })
end

return Source
