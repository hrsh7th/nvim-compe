local Time = {}

function Time:clock()
  return vim.fn.reltimefloat(vim.fn.reltime()) * 1000
end

return Time

