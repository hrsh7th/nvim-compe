local THROTTLE_TIME = 40
local SOURCE_TIMEOUT = 100
local INCOMPLETE_DELAY = 200

local Config = {}

Config._config = {
  enabled = true;
}

Config.get = function()
  return Config._config
end

Config.get_metadata = function(name)
  return Config._config.source[name]
end

Config.set = function(config)
  -- normalize options
  config.enabled = Config._true(config.enabled)
  config.debug = Config._true(config.debug)
  config.min_length = config.min_length or 1
  config.preselect = config.preselect or 'enable'
  config.throttle_time = config.throttle_time or THROTTLE_TIME
  config.source_timeout = config.source_timeout or SOURCE_TIMEOUT
  config.incomplete_delay = config.incomplete_delay or INCOMPLETE_DELAY
  config.allow_prefix_unmatch = Config._true(config.allow_prefix_unmatch)

  -- normalize source metadata
  for name, metadata in pairs(config.source) do
    if type(metadata) ~= 'table' then
      config.source[name] = { disabled = not Config._true(metadata) }
    else
      config.source[name].disabled = config.source[name].disabled or false
    end
  end

  Config._config = config
end

Config.is_source_enabled = function(name)
  return Config._config.source[name] and not Config._config.source[name].disabled
end

Config._true = function(v)
  return v == true or v == 1
end

return Config

