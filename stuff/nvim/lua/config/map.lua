vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

vim.keymap.set('n', '<c-c>', '<esc>')
vim.keymap.set('t', '<c-[>', '<c-\\><c-n>')

-- emacs style movement in insert mode
vim.keymap.set('i', '<c-n>', '<C-o>j')
vim.keymap.set('i', '<c-p>', '<C-o>k')
vim.keymap.set('i', '<c-a>', '<C-o>^')
vim.keymap.set('i', '<c-e>', '<C-o>$')
vim.keymap.set('i', '<c-f>', '<right>')
vim.keymap.set('i', '<c-b>', '<left>')
vim.keymap.set('i', '<m-f>', '<C-o>W')
vim.keymap.set('i', '<m-b>', '<C-o>B')
vim.keymap.set('i', '<c-d>', '<C-o>dl')
vim.keymap.set('i', '<m-d>', '<C-o>dW')

vim.keymap.set('c', '<c-a>', '<home>')
vim.keymap.set('c', '<c-e>', '<end>')
vim.keymap.set('c', '<c-b>', '<left>')
vim.keymap.set('c', '<m-f>', '<c-right>')
vim.keymap.set('c', '<m-b>', '<c-left>')
vim.keymap.set('c', '<c-d>', '<delete>')
vim.keymap.set('c', '<m-d>', '<c-right><c-w><delete>')

vim.keymap.set('n', '<c-d>', '<c-d>zz')
vim.keymap.set('n', '<c-u>', '<c-u>zz')

vim.keymap.set('n', 'gyy', 'yygcc', { remap = true })
vim.keymap.set('v', 'gy', 'ygvgc',  { remap = true })

vim.keymap.set('n', '<leader>pf', ':find<leader>',  { desc = 'Find file' })
vim.keymap.set('n', '<leader>ps', ':grep<leader>',  { desc = 'Grep' })
vim.keymap.set('v', '<leader>s', ':s/',             { desc = 'Start substitue on current selection' })

vim.keymap.set('n', '<leader>pv', '<cmd>Oil<cr>',                               { desc = 'Open Oil' })
vim.keymap.set('n', '<leader>u',  '<cmd>UndotreeShow | UndotreeFocus<cr>',      { desc = 'Open and focus Undotree' })
vim.keymap.set('n', '<c-w><c-g>', '<cmd>NoNeckPain<cr>',                        { desc = 'Toggle NoNeckPain' })
-- vim.keymap.set('n', '<leader>g',  '<cmd>G log --oneline --graph | G<cr>',       { desc = 'Open Git summary' })
vim.keymap.set('n', '<leader>g',  '<cmd>G<cr>',       { desc = 'Open Git summary' })

local ls = require('luasnip')
require('luasnip.loaders.from_snipmate').lazy_load()
vim.keymap.set({'i'}, '<tab>', function()
    if ls.expand_or_jumpable() then
        ls.expand_or_jump(1)
    else
        local key = vim.api.nvim_replace_termcodes('<tab>', true, false, true)
        vim.api.nvim_feedkeys(key, 'n', false)
    end
end, { silent = true, remap = true })
vim.keymap.set({'i', 's'}, '<s-tab>', function() ls.jump(-1) end, {silent = true})
vim.keymap.set({'i', 's'}, '<c-y>', function()
    if ls.choice_active() then
        ls.change_choice(1)
    end
end, {silent = true})
