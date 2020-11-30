local Debug = require'compe.debug'
local Compat = require'compe.compat'
local Completion = require'compe.completion'
local Source = require'compe.completion.source'
local Config = require'compe.config'
local VimBridge = require'compe.completion.source.vim_bridge'

local Compe = {}

--- setup
Compe.setup = function(config)
  Config.set(config)
end

--- new
function Compe.new()
  local self = setmetatable({}, { __index = Compe })
  self.completion = Completion.new()
  return self
end

--- register_source
function Compe.register_source(self, name, source)
  if not string.match(name, '^[%a_]+$') then
    error("the source's name must be [%a_]+")
  end
  local source = Source.new(name, source)
  self.completion:register_source(source)
  return source.id
end

--- register_vim_source
function Compe.register_vim_source(self, name, bridge_id)
  local source = Source.new(name, VimBridge.new(bridge_id))
  self.completion:register_source(source)
  return source.id
end

--- unregister_source
function Compe.unregister_source(self, id)
  self.completion:unregister_source(id)
end

--- on_complete_changed
function Compe.on_complete_changed(self)
  if Config.get().enabled then
    local status, value = pcall(function() self.completion:on_complete_changed() end)
    if not(status) then
      Debug.log(value)
    end
  end
end

--- on_complete_done
function Compe.on_complete_done(self)
  if Config.get().enabled then
    local status, value = pcall(function() self.completion:on_complete_done() end)
    if not(status) then
      Debug.log(value)
    end
  end
end

--- on_text_changed
function Compe.on_text_changed(self)
  if Config.get().enabled then
    local status, value = pcall(function() self.completion:on_text_changed() end)
    if not(status) then
      Debug.log(value)
    end
  end
end

--- on_insert_leave
function Compe.on_insert_leave(self)
  if Config.get().enabled then
    local status, value = pcall(function() self.completion:on_insert_leave() end)
    if not(status) then
      Debug.log(value)
    end
  end
end

--- on_manual_complete
function Compe.on_manual_complete(self)
  if Config.get().enabled then
    local status, value = pcall(function() self.completion:on_manual_complete() end)
    if not(status) then
      Debug.log(value)
    end
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
    Debug.log(value)
  end
end

return Compe.new()

