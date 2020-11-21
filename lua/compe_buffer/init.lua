return (function()
  if vim.g.compe_no_warnings ~= 1 and vim.g.compe_user_warned ~= 1 then 
    print([[warning: your current method of configuring "nvim-compe" will be depercated soon please checkout the "readme" to learn more. to skip warning, add let g:nvim_compe_silent = 1 to your config ]])
  vim.g.compe_user_warned = 1

  end
  return require'compe.builtin.buffer'
end)()
