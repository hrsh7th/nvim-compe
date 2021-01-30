local THROTTLE_TIME = 80
local SOURCE_TIMEOUT = 200
local INCOMPLETE_DELAY = 400

local Config = {}

Config._config = {
  enabled = true;
}

Config.setup = function(config)
  -- normalize options
  config.enabled = Config._true(config.enabled) or true
  config.debug = Config._true(config.debug)
  config.min_length = config.min_length or 1
  config.preselect = config.preselect or 'enable'
  config.throttle_time = config.throttle_time or THROTTLE_TIME
  config.source_timeout = config.source_timeout or SOURCE_TIMEOUT
  config.incomplete_delay = config.incomplete_delay or INCOMPLETE_DELAY
  config.allow_prefix_unmatch = Config._true(config.allow_prefix_unmatch)
  if config.autocomplete == nil then
    config.autocomplete = true
  else
    config.autocomplete = Config._true(config.autocomplete)
  end

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

Config.get = function()
  return Config._config
end

Config.get_metadata = function(source_name)
  return Config._config.source[source_name]
end

Config.is_source_enabled = function(source_name)
  return Config._config.source[source_name] and not Config._config.source[source_name].disabled
end

Config._true = function(v)
  return v == true or v == 1
end

return Config

