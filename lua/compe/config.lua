local THROTTLE_TIME = 80
local SOURCE_TIMEOUT = 200
local INCOMPLETE_DELAY = 400

local Config = {}

Config._config = {
  enabled = true;
}

Config._normalize = function(config)
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
  if config.source then
    for name, metadata in pairs(config.source) do
      if type(metadata) ~= 'table' then
        config.source[name] = { disabled = not Config._true(metadata) }
      else
        config.source[name].disabled = config.source[name].disabled or false
      end
    end
  else
    config.source = {}
  end

  return config
end

Config.setup = function(config, bufnr)
  if bufnr == nil then
    Config._config = Config._normalize(config)
  else
    local buf_config = Config._normalize(vim.deepcopy(Config._config))

    if config.enabled ~= nil then
      buf_config.enabled = Config._true(config.enabled)
    end
    if config.debug ~= nil then
      buf_config.debug = Config._true(config.debug)
    end
    if config.min_length ~= nil then
      buf_config.min_length = config.min_length or 1
    end
    if config.preselect ~= nil then
      buf_config.preselect = config.preselect or 'enable'
    end
    if config.throttle_time ~= nil then
      buf_config.throttle_time = config.throttle_time or THROTTLE_TIME
    end
    if config.source_timeout ~= nil then
      buf_config.source_timeout = config.source_timeout or SOURCE_TIMEOUT
    end
    if config.incomplete_delay ~= nil then
      buf_config.incomplete_delay = config.incomplete_delay or INCOMPLETE_DELAY
    end
    if config.allow_prefix_unmatch ~= nil then
      buf_config.allow_prefix_unmatch = Config._true(config.allow_prefix_unmatch)
    end

    if config.source ~= nil then
      buf_config.source = config.source
      for name, metadata in pairs(buf_config.source) do
        if type(metadata) ~= 'table' then
          buf_config.source[name] = { disabled = not Config._true(metadata) }
        else
          buf_config.source[name].disabled = buf_config.source[name].disabled or false
        end
      end
    end

    vim.api.nvim_buf_set_var(bufnr, 'compe_config', buf_config)
  end
end

Config.get = function()
  local ok, config = pcall(vim.api.nvim_buf_get_var, 0, 'compe_config')
  if ok then
    return config
  end
  return Config._config
end

Config.get_metadata = function(source_name)
  return Config.get().source[source_name]
end

Config.is_source_enabled = function(source_name)
  local config = Config.get()
  return config.source[source_name] and not config.source[source_name].disabled
end

Config._true = function(v)
  return v == true or v == 1
end

return Config

