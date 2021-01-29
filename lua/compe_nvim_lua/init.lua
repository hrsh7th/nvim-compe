local compe = require'compe'
local Source = {}

function Source.new()
  local self = setmetatable({}, { __index = Source })
  self.regex = vim.regex('\\%(\\.\\|\\w\\)\\+$')
  return self
end

function Source.get_metadata(self)
  return {
    priority = 100;
    dup = 0;
    menu = '[Lua]';
    filetypes = {'lua'}
  }
end

function Source.determine(self, context)
  return compe.helper.determine(context, {
    trigger_characters = { '.' };
  })
end

function Source.complete(self, args)
  local s, e = self.regex:match_str(args.context.before_line)
  if not s then
    return args.abort()
  end

  local prefix = args.context.before_line
  prefix = string.sub(prefix, s + 1)
  prefix = string.gsub(prefix, '[^.]*$', '')

  args.callback({
    items = self:collect(vim.split(prefix, '.', true)),
  })
end

function Source.collect(self, paths)
  local target = _G
  local target_keys = vim.tbl_keys(_G)
  for i, path in ipairs(paths) do
    if vim.tbl_contains(target_keys, path) and type(target[path]) == 'table' then
      target = target[path]
      target_keys = vim.tbl_keys(target)
    elseif path ~= '' then
      return {}
    end
  end

  local candidates = {}
  for _, key in ipairs(target_keys) do
    if string.match(key, '^%a[%a_]*$') then
      table.insert(candidates, {
        word = '' .. key;
        kind = type(target[key]);
      })
    end
  end
  for _, key in ipairs(target_keys) do
    if not string.match(key, '^%a[%a_]*$') then
      table.insert(candidates, {
        word = '' .. key;
        kind = type(target[key]);
      })
    end
  end

  return candidates
end

return Source.new()

