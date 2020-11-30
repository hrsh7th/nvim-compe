local Config = require'compe.config'

local Debug = {}

Debug.log = function(args)
  if Config.get().debug then
    if type(args) == 'string' then
      print(args)
    else
      print(vim.inspect(args))
    end
  end
end

return Debug

