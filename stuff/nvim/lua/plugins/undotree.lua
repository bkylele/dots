vim.pack.add({
    'https://github.com/mbbill/undotree',
})

vim.keymap.set('n', '<leader>u', '<cmd>UndotreeShow<cr><cmd>UndotreeFocus<cr>', { desc = 'Open and focus Undotree' })
