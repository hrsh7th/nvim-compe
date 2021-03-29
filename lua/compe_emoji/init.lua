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
  local trigger = compe.helper.determine(context, {
    keyword_pattern = [[\%(\s\|^\)\zs:\w*$]],
  })
  if trigger then
    trigger.trigger_character_offset = trigger.keyword_pattern_offset
  end
  return trigger
end

Source.complete = function(self, args)
  -- Lazy load data if not present.
  if (not(Source._items)) then
    Source._items = require('compe_emoji.items')
  end

  args.callback({
    items = self._items,
    incomplete = true,
  })
end

return Source
