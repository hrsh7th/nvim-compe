local Compat = require'compe.compat'

local VimBridge =  {}

local complete_callbacks = {}
local complete_aborts = {}

--- on_callback
function VimBridge.on_callback(id, result)
  id = Compat.safe(id)
  result = Compat.safe(result)

  if complete_callbacks[id] ~= nil then
    complete_callbacks[id](result)
    complete_callbacks[id] = nil
  end
end

--- on_abort
function VimBridge.on_abort(id)
  id = Compat.safe(id)
  if complete_aborts[id] ~= nil then
    complete_aborts[id]()
    complete_aborts[id] = nil
  end
end

--- new
function VimBridge:new(id)
  local this = setmetatable({}, { __index = self })
  this.id = id
  return this
end

--- get_metadata
function VimBridge:get_metadata()
  return Compat.safe(vim.call('compe#source#vim_bridge#get_metadata', self.id))
end

--- new
function VimBridge:datermine(context)
  return Compat.safe(vim.call('compe#source#vim_bridge#datermine', self.id, context))
end

--- new
function VimBridge:complete(args)
  complete_callbacks[self.id] = args.callback
  complete_aborts[self.id] = args.abort
  args.callback = nil
  args.abort = nil
  return Compat.safe(vim.call('compe#source#vim_bridge#complete', self.id, args))
end

return VimBridge

