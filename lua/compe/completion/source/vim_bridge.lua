local VimBridge =  {}

local complete_callbacks = {}
local complete_aborts = {}

--- on_callback
function VimBridge.on_callback(id, result)
  if complete_callbacks[id] ~= nil then
    complete_callbacks[id](result)
    complete_callbacks[id] = nil
  end
end

--- on_abort
function VimBridge.on_abort(id)
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

--- get_source_metadata
function VimBridge:get_source_metadata()
  return vim.api.nvim_call_function('compe#source#vim_bridge#get_source_metadata', { self.id })
end

--- get_item_metadata
function VimBridge:get_item_metadata(item)
  return vim.api.nvim_call_function('compe#source#vim_bridge#get_item_metadata', { self.id, item })
end

--- new
function VimBridge:datermine(context)
  return vim.api.nvim_call_function('compe#source#vim_bridge#datermine', { self.id, context })
end

--- new
function VimBridge:complete(args)
  complete_callbacks[self.id] = args.callback
  complete_aborts[self.id] = args.abort
  args.callback = nil
  args.abort = nil
  return vim.api.nvim_call_function('compe#source#vim_bridge#complete', { self.id, args })
end

return VimBridge

