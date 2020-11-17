local Completion = require'compe.completion'
local Debug = require'compe.debug'
local Source = require'compe.completion.source'
local VimBridge = require'compe.completion.source.vim_bridge'

local Compe = {}

--- new
function Compe.new()
  local self = setmetatable({}, { __index = Compe })
  self.completion = Completion.new()
  return self
end

--- register_lua_source
function Compe.register_lua_source(self, id, source)
  self.completion:register_source(Source.new(id, source))
end

--- register_vim_source
function Compe.register_vim_source(self, id)
  self.completion:register_source(Source.new(id, VimBridge.new(id)))
end

--- unregister_source
function Compe.unregister_source(self, id)
  self.completion:unregister_source(id)
end

--- on_complete_changed
function Compe.on_complete_changed(self)
  local status, value = pcall(function() self.completion:on_complete_changed() end)
  if not(status) then
    Debug:log(value)
  end
end

--- on_complete_done
function Compe.on_complete_done(self)
  local status, value = pcall(function() self.completion:on_complete_done() end)
  if not(status) then
    Debug:log(value)
  end
end

--- on_text_changed
function Compe.on_text_changed(self)
  local status, value = pcall(function() self.completion:on_text_changed() end)
  if not(status) then
    Debug:log(value)
  end
end

--- on_manual_complete
function Compe.on_manual_complete(self)
  local status, value = pcall(function() self.completion:on_manual_complete() end)
  if not(status) then
    Debug:log(value)
  end
end

-- add_history
function Compe.add_history(self, word)
  self.completion:add_history(word)
end

--- clear
function Compe.clear(self)
  local status, value = pcall(function() self.completion:clear() end)
  if not(status) then
    Debug:log(value)
  end
end

return Compe.new()

