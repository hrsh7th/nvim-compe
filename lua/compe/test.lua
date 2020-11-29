local M1 = require'compe.completion.matcher_old'
local M2 = require'compe.completion.matcher_new'

local attempts = 100000

vim.g.result = ''

x = os.clock()
for j = 1, attempts do
    tmp = M1.score('nvimgetbufline', 'nvimgetbufline', 'nvim_g_et_b_uf_line')
end
elapsed = os.clock() - x
vim.g.result = vim.g.result .. string.format("matcher_old: elapsed time: %.3f", elapsed) .. "\n"

x = os.clock()
for j = 1, attempts do
    tmp = M2.score('nvimgetbufline', 'nvim_g_et_b_uf_line')
end
elapsed = os.clock() - x
vim.g.result = vim.g.result .. string.format("matcher_new: elapsed time: %.3f", elapsed) .. "\n"

print(vim.g.result)

