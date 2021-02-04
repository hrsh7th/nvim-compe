local THROTTLE_TIME = 100
local SOURCE_TIMEOUT = 200
local INCOMPLETE_DELAY = 400

local Config = {}

Config._config = {}
Config._bufnrs = {}

--- setup
Config.setup = function(config, bufnr)
  if bufnr == nil then
    -- global config
    Config._config = Config._normalize(config)
  else
    -- buffer config
    for key, value in pairs(Config._config) do
      if config[key] == nil then
        config[key] = value
      end
    end

    bufnr = (bufnr == 0 and vim.api.nvim_get_current_buf()) or bufnr
    Config._bufnrs[bufnr] = Config._normalize(config)
  end
end

--- get
Config.get = function()
  return Config._bufnrs[vim.api.nvim_get_current_buf()] or Config._config
end

--- get_metadata
Config.get_metadata = function(source_name)
  return Config.get().source[source_name]
end

--- is_source_enabled
Config.is_source_enabled = function(source_name)
  local config = Config.get()
  return config.source[source_name] and not config.source[source_name].disabled
end

--- _normalize
Config._normalize = function(config)
  -- normalize options
  config.enabled = Config._bool(config.enabled, true)
  config.debug = Config._bool(config.debug, false)
  config.min_length = config.min_length or 1
  config.preselect = config.preselect or 'enable'
  config.throttle_time = config.throttle_time or THROTTLE_TIME
  config.source_timeout = config.source_timeout or SOURCE_TIMEOUT
  config.incomplete_delay = config.incomplete_delay or INCOMPLETE_DELAY
  config.allow_prefix_unmatch = Config._bool(config.allow_prefix_unmatch, false)
  config.max_abbr_width = config.max_abbr_width or 100
  config.max_kind_width = config.max_kind_width or 100
  config.max_menu_width = config.max_menu_width or 100
  config.autocomplete = Config._bool(config.autocomplete, true)

  -- normalize source metadata
  if config.source then
    for name, metadata in pairs(config.source) do
      if type(metadata) ~= 'table' then
        config.source[name] = { disabled = not Config._bool(metadata, false) }
      else
        config.source[name].disabled = Config._bool(config.source[name].disabled, false)
      end
    end
  else
    config.source = {}
  end

  return config
end

--- _bool
Config._bool = function(v, def)
  if v == nil then
    return def
  end
  return v == true or v == 1
end

return Config

