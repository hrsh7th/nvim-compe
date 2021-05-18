local Lazy = {}

Lazy._sources = {

  calc = function()
    require'compe'.register_source('calc', require'compe_calc')
  end,

  omni = function()
    require'compe'.register_source('omni', require'compe_omni')
  end,

  path = function()
    require'compe'.register_source('path', require'compe_path')
  end,

  tags = function()
    require'compe'.register_source('tags', require'compe_tags')
  end,

  emoji = function()
    require'compe'.register_source('emoji', require'compe_emoji')
  end,

  spell = function()
    require'compe'.register_source('spell', require'compe_spell')
  end,

  vsnip = function()
    require'compe'.register_source('vsnip', require'compe_vsnip')
  end,

  buffer = function()
    require'compe'.register_source('buffer', require'compe_buffer')
  end,

  luasnip = function()
    if pcall(require, 'luasnip') then
      require'compe'.register_source('luasnip', require'compe_luasnip')
    end
  end,

  vim_lsc = function()
    if vim.g.loaded_lsc ~= nil then
      vim.fn['compe_vim_lsc#source#attach']()
    end
  end,

  vim_lsp = function()
    if vim.g.lsp_loaded ~= nil then
      vim.fn['compe_vim_lsp#source#attach']()
    end
  end,

  nvim_lsp = function()
    require'compe_nvim_lsp'.attach()
  end,

  nvim_lua = function()
    require'compe'.register_source('nvim_lua', require'compe_nvim_lua')
  end,

  ultisnips = function()
    if vim.g.did_plugin_ultisnips ~= nil then
      require'compe'.register_source('ultisnips', require'compe_ultisnips')
    end
  end,

  treesitter = function()
    if pcall(require, 'nvim-treesitter') then
      require'compe'.register_source('treesitter', require'compe_treesitter')
    end
  end,

  snippets_nvim = function()
    if pcall(require, 'snippets') then
      require'compe'.register_source('snippets_nvim', require'compe_snippets_nvim')
    end
  end,

}

Lazy._deferred = {}

local function _load(source_name)
  if Lazy._sources[source_name] ~= nil then
    Lazy._sources[source_name]()
    Lazy._sources[source_name] = nil
  end
end

Lazy.load_deferred = function()
  if Lazy._deferred ~= nil then
    for source_name, _ in pairs(Lazy._deferred) do
      _load(source_name)
    end
    Lazy._deferred = nil
  end
end

Lazy.load = function(source_name)
  if Lazy._deferred == nil then
    _load(source_name)
  else
    Lazy._deferred[source_name] = true
  end
end

return Lazy
