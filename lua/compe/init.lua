--- compe public inteface module
--
-- This module wraps a number of functions from other modules into a a
-- convenient  public interface that can be used to access all nvim-compe main
-- functionaries
-- TODO: is it?.
--
-- Dependencies: `compe.completion`, `compe.debug`, `compe.completion.source`,
-- `compe.completion.source.vim_bridge`
-- @module compe

local completion = require'compe.completion'
local debug = require'compe.debug'
local source = require'compe.completion.source'
local vim_bridge = require'compe.completion.source.vim_bridge'

local compe = {}

--- sets compe-nvim public interface object.
-- @return - A new compe object.
compe.new = function()
  local self = setmetatable({}, { __index = compe })
  self.completion = completion.new()
  return self
end

--- registers a new lua source
-- passes params using new func from `source` to `completion` register_source
-- func.
-- @param id string representing the source name.
-- @param obj table representing nvim-compe source.
-- @function register_lua_source
compe.register_lua_source = function(self, id, obj)
  self.completion:register_source(source.new(id, obj))
end

--- registers a new vim source
-- passes params using new func from `source` and `vim_bridge` to `completion`
-- register_source func.
-- @param id string representing the source name.
-- @function register_vim_source
compe.register_vim_source = function(self, id)
  self.completion:register_source(source.new(id, vim_bridge.new(id)))
end

--- unregisters a vim or lua source
-- passes params using to `completion` unregister_source func.
-- @param id string representing the source name.
-- @function unregister_source
compe.unregister_source = function(self, id)
  self.completion:unregister_source(id)
end

--- wraps `completion:on_complete_changed`
-- ???
-- @param self
-- @function on_complete_changed
compe.on_complete_changed = function(self)
  local status, value = pcall(function() self.completion:on_complete_changed() end)
  if not(status) then
    debug:log(value)
  end
end

--- wraps `completion:on_complete_done`
-- ???
-- @param self
-- @function on_complete_done
compe.on_complete_done = function(self)
  local status, value = pcall(function() self.completion:on_complete_done() end)
  if not(status) then
    debug:log(value)
  end
end

--- wraps `completion:on_text_changed`
-- Event that triggers on text change ???
-- @param self
-- @function on_text_changed
compe.on_text_changed = function(self)
  local status, value = pcall(function() self.completion:on_text_changed() end)
  if not(status) then
    debug:log(value)
  end
end

--- wraps `completion:on_text_changed`
-- Event that triggers on insert leave ???
-- @param self
-- @function on_insert_leave
compe.on_insert_leave = function(self)
  local status, value = pcall(function() self.completion:on_insert_leave() end)
  if not(status) then
    debug:log(value)
  end
end

--- wraps `completion:on_manual_complete`
-- ???
-- @param self
-- @function on_manual_complete
compe.on_manual_complete = function(self)
  local status, value = pcall(function() self.completion:on_manual_complete() end)
  if not(status) then
    debug:log(value)
  end
end

--- wraps `completion:add_history`
-- ???
-- @param self
-- @function add_history
compe.add_history = function(self, word)
  self.completion:add_history(word)
end

--- wraps `completion:clear`
-- ???
-- @param self
-- @function clear
compe.clear = function(self)
  local status, value = pcall(function() self.completion:clear() end)
  if not(status) then
    debug:log(value)
  end
end

return compe.new()
