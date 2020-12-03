local Config = {}

Config._config = {
  enabled = true;
  debug = false;
  min_length = 1;
  auto_preselect = false;
  throttle_time = 200;
  source_timeout = 200;
  incomplete_delay = 400;
  source = vim.empty_dict();
}

Config.get = function()
  return Config._config
end

Config.get_metadata = function(name)
  return Config._config.source[name]
end

Config.set = function(config)
  -- normalize options
  config.enabled = config.enabled or true
  config.debug = config.debug or false
  config.min_length = config.min_length or 1
  config.auto_preselect = config.auto_preselect or false
  config.throttle_time = config.throttle_time or 120
  config.source_timeout = config.source_timeout or 200
  config.incomplete_delay = config.incomplete_delay or 400

  -- normalize source metadata
  for name, metadata in pairs(config.source) do
    if type(metadata) ~= 'table' then
      if metadata == 1 or metadata == true then
        config.source[name] = { disabled = false }
      else
        config.source[name] = { disabled = true }
      end
    else
      config.source[name].disabled = config.source[name].disabled or false
    end
  end

  Config._config = config
end

Config.is_source_enabled = function(name)
  return Config._config.source[name] and not Config._config.source[name].disabled
end

return Config

