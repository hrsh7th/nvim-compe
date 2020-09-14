local Debug = {}

function Debug:log(args)
  if vim.g.compe_debug then
    if type(args) == 'string' then
      print(args)
    else
      print(vim.inspect(args))
    end
  end
end

return Debug

