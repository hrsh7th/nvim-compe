local Compat = require'compe.utils.compat'

local VimBridge =  {}

local complete_callbacks = {}
local complete_aborts = {}
local documentation_callbacks = {}
local documentation_aborts = {}

--- clear
function VimBridge.clear()
  complete_callbacks = {}
  complete_aborts = {}
  documentation_callbacks = {}
  documentation_aborts = {}
end

--- complete_on_callback
function VimBridge.complete_on_callback(id, result)
  id = Compat.safe(id)
  result = Compat.safe(result)

  if complete_callbacks[id] ~= nil then
    complete_callbacks[id](result)
    complete_callbacks[id] = nil
  end
end

--- complete_on_abort
function VimBridge.complete_on_abort(id)
  id = Compat.safe(id)
  if complete_aborts[id] ~= nil then
    complete_aborts[id]()
    complete_aborts[id] = nil
  end
end

--- documentation_on_callback
function VimBridge.documentation_on_callback(id, document)
  id = Compat.safe(id)
  if documentation_callbacks[id] ~= nil then
    documentation_callbacks[id](document)
    documentation_callbacks[id] = nil
  end
end

--- documentation_on_abort
function VimBridge.documentation_on_abort(id)
  id = Compat.safe(id)
  if documentation_aborts[id] ~= nil then
    documentation_aborts[id]()
    documentation_aborts[id] = nil
  end
end

--- new
function VimBridge.new(id)
  local self = setmetatable({}, { __index = VimBridge })
  self.id = id
  return self
end

--- get_metadata
function VimBridge.get_metadata(self)
  return Compat.safe(vim.call('compe#source#vim_bridge#get_metadata', self.id))
end

--- datermine
function VimBridge.datermine(self, context)
  return Compat.safe(vim.call('compe#source#vim_bridge#datermine', self.id, context))
end

--- complete
function VimBridge.complete(self, args)
  complete_callbacks[self.id] = args.callback
  complete_aborts[self.id] = args.abort
  args.callback = nil
  args.abort = nil
  return Compat.safe(vim.call('compe#source#vim_bridge#complete', self.id, args))
end

--- documentation
function VimBridge.documentation(self, args)
  documentation_callbacks[self.id] = args.callback
  documentation_aborts[self.id] = args.abort
  args.callback = nil
  args.abort = nil
  return Compat.safe(vim.call('compe#source#vim_bridge#documentation', self.id, args))
end

return VimBridge

