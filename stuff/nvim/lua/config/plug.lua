vim.keymap.set('n', '<leader>pv', '<cmd>Oil<cr>',                               { desc = 'Open Oil' })
vim.keymap.set('n', '<leader>u',  '<cmd>UndotreeShow | UndotreeFocus<cr>',      { desc = 'Open and focus Undotree' })
vim.keymap.set('n', '<c-w><c-g>', '<cmd>NoNeckPain<cr>',                        { desc = 'Toggle NoNeckPain' })
vim.keymap.set('n', '<leader>g',  '<cmd>G<cr>',                                 { desc = 'Open Git summary' })

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

require("no-neck-pain").setup({
    buffers = {
        left = {
            scratchPad = {
                enabled = true,
                fileName = "notes",
                location = "~/dox/",
            },
            bo = {
                filetype = "md"
            },
        }
    },
})

require('oil').setup({
    columns = {
        'icon',
        'permissions',
        'size',
        'mtime',
    },

    skip_confirm_for_simple_edits = true,
    watch_for_changes = true,
    view_options = { show_hidden = true, },
})

require('lean').setup({ mappings = true })

vim.g.coqtail_noimap = 1
vim.api.nvim_create_autocmd("FileType", {
  pattern = "coq",
  callback = function()
      vim.keymap.set({'n', 'i'}, '<c-j>', '<cmd>RocqNext<cr>', { buffer = true })
      vim.keymap.set({'n', 'i'}, '<c-k>', '<cmd>RocqUndo<cr>', { buffer = true })
  end,
})
