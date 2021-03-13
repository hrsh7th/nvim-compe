local Compat = require'compe.utils.compat'
local Callback = require'compe.utils.callback'

local Methods = {}

Methods.get_metadata = function(self)
  return Compat.safe(vim.call('compe#vim_bridge#get_metadata', self.id))
end

--- determine
Methods.determine = function(self, context)
  return Compat.safe(vim.call('compe#vim_bridge#determine', self.id, context))
end

--- complete
Methods.complete = function(self, args)
  args.callback = Callback.set(args.callback)
  args.abort = Callback.set(args.abort)
  return vim.call('compe#vim_bridge#complete', self.id, args)
end

--- resolve
Methods.resolve = function(self, args)
  args.callback = Callback.set(args.callback)
  return vim.call('compe#vim_bridge#resolve', self.id, args)
end

--- confirm
Methods.confirm = function(self, args)
  vim.call('compe#vim_bridge#confirm', self.id, args)
end

--- documentation
Methods.documentation = function(self, args)
  args.callback = Callback.set(args.callback)
  args.abort = Callback.set(args.abort)
  return vim.call('compe#vim_bridge#documentation', self.id, args)
end

local VimBridge =  {}

--- new
VimBridge.new = function(id, methods)
  local self = setmetatable({}, { __index = VimBridge })
  self.id = id
  for _, method in ipairs(methods) do
    self[method] = Methods[method]
  end
  return self
end

return VimBridge

