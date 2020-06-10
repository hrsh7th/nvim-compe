local Completion = require'compe.completion'
local Debug = require'compe.debug'
local Source = require'compe.completion.source'
local VimBridge = require'compe.completion.source.vim_bridge'

local Compe = {}

--- new
function Compe:new()
  local this = setmetatable({}, { __index = self })
  this.completion = Completion:new()
  return this
end

--- register_lua_source
function Compe:register_lua_source(id, source)
  self.completion:register_source(id, Source:new(id, source))
end

--- registera_vim_source
function Compe:register_vim_source(id)
  self.completion:register_source(id, Source:new(id, VimBridge:new(id)))
end

--- unregister_source
function Compe:unregister_source(id)
  self.completion:unregister_source(id)
end


--- on_insert_char_pre
function Compe:on_insert_char_pre()
  if vim.g.compe_enabled then
    local status, value = pcall(function() self.completion:on_insert_char_pre() end)
    if not(status) then
      Debug:log(value)
    end
  end
end

--- on_text_changed
function Compe:on_text_changed()
  if vim.g.compe_enabled then
    local status, value = pcall(function() self.completion:on_text_changed() end)
    if not(status) then
      Debug:log(value)
    end
  end
end

--- Compe:complete()
function Compe:complete()
  if vim.g.compe_enabled then
    local status, value = pcall(function() self.completion:complete() end)
    if not(status) then
      Debug:log(value)
    end
  end
end

--- clear
function Compe:clear()
  if vim.g.compe_enabled then
    local status, value = pcall(function() self.completion:clear() end)
    if not(status) then
      Debug:log(value)
    end
  end
end

return Compe:new()

