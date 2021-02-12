local Compat = require'compe.utils.compat'

local VimBridge =  {}

local complete_callbacks = {}
local complete_aborts = {}
local resolve_callbacks = {}
local documentation_callbacks = {}
local documentation_aborts = {}

--- clear
function VimBridge.clear()
  complete_callbacks = {}
  complete_aborts = {}
  resolve_callbacks = {}
  documentation_callbacks = {}
  documentation_aborts = {}
end

--- complete_on_callback
function VimBridge.complete_on_callback(id, result)
  if complete_callbacks[id] ~= nil then
    complete_callbacks[id](result)
    complete_callbacks[id] = nil
  end
end

--- complete_on_abort
function VimBridge.complete_on_abort(id)
  if complete_aborts[id] ~= nil then
    complete_aborts[id]()
    complete_aborts[id] = nil
  end
end

--- resolve_on_callback
function VimBridge.resolve_on_callback(id, completed_item)
  if resolve_callbacks[id] ~= nil then
    resolve_callbacks[id](completed_item)
    resolve_callbacks[id] = nil
  end
end

--- documentation_on_callback
function VimBridge.documentation_on_callback(id, document)
  if documentation_callbacks[id] ~= nil then
    documentation_callbacks[id](document)
    documentation_callbacks[id] = nil
  end
end

--- documentation_on_abort
function VimBridge.documentation_on_abort(id)
  if documentation_aborts[id] ~= nil then
    documentation_aborts[id]()
    documentation_aborts[id] = nil
  end
end

--- get_metadata
local M = {}
M.get_metadata = function(self)
  return Compat.safe(vim.call('compe#source#vim_bridge#get_metadata', self.id))
end

--- determine
M.determine = function(self, context)
  return Compat.safe(vim.call('compe#source#vim_bridge#determine', self.id, context))
end

--- complete
M.complete = function(self, args)
  complete_callbacks[self.id] = args.callback
  complete_aborts[self.id] = args.abort
  args.callback = nil
  args.abort = nil
  return vim.call('compe#source#vim_bridge#complete', self.id, args)
end

--- resolve
M.resolve = function(self, args)
  resolve_callbacks[self.id] = args.callback
  args.callback = nil
  return Compat.safe(vim.call('compe#source#vim_bridge#resolve', self.id, args))
end

--- confirm
M.confirm = function(self, args)
  vim.call('compe#source#vim_bridge#confirm', self.id, args)
end

--- documentation
M.documentation = function(self, args)
  documentation_callbacks[self.id] = args.callback
  documentation_aborts[self.id] = args.abort
  args.callback = nil
  args.abort = nil
  return vim.call('compe#source#vim_bridge#documentation', self.id, args)
end

--- new
function VimBridge.new(id, methods)
  local self = setmetatable({}, { __index = VimBridge })
  self.id = id
  for _, method in ipairs(methods) do
    self[method] = M[method]
  end
  return self
end

return VimBridge

