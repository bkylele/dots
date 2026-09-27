vim.o.guicursor = ''

vim.o.number = true
vim.o.relativenumber = true

vim.o.scrolloff = 8
vim.o.sidescrolloff = 8

vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.o.incsearch = true
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.undofile = true
vim.o.swapfile = false
vim.o.backup = false

vim.o.clipboard = 'unnamedplus'
vim.cmd('filetype plugin on')
vim.cmd('syntax on')
vim.cmd('set completeopt+=fuzzy')

vim.o.termguicolors = true
vim.o.conceallevel = 2
vim.o.winborder = 'double'

vim.cmd('colorscheme vim')

vim.cmd.packadd('nvim.difftool')
vim.cmd.packadd('nvim.tohtml')
-- :noh after 4 secs or on entering insert
vim.cmd.packadd('nohlsearch')
vim.cmd('let loaded_matchparen = 1')

-- see (:h ui2)
require('vim._core.ui2').enable({})

-- see (:h lspconfig-all)
vim.lsp.enable({
    'clangd',
    'rust_analyzer',
    'coq_lsp',
    'dafny',
})

-- jank from here on out

vim.g.filetype_pl = 'prolog'
vim.g.fugitive_summary_format = '%d %s'

vim.api.nvim_create_autocmd("FileType", {
  pattern = "nix",
  callback = function()
    vim.bo.formatprg = ", nixfmt - "
  end,
})

vim.api.nvim_create_augroup("custom_close_q", { clear = true })
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = "custom_close_q",
  pattern = { "help", "qf", "oil", "fugitive", "fugitiveblame" },
  callback = function()
      vim.keymap.set("n", "gq", "<cmd>bd!<CR>", { buffer = true })
  end,
})
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  group = "custom_close_q",
  callback = function()
    local name = vim.api.nvim_buf_get_name(0)
    if name:match("^fugitive://") or name:match("^/tmp/") then
      vim.keymap.set("n", "gq", "<cmd>bd!<CR>", { buffer = true })
    end
  end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = "markdown",
    callback = function()
        -- Enable spell checking
        vim.opt_local.spell = true
        vim.opt_local.spelllang = "en_us"

        -- Word wrapping and formatting
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true     -- Break lines at words, not in the middle of characters
        vim.opt_local.breakindent = true   -- Wrapped lines retain the indentation of the first line

        -- Visuals and UI
        vim.opt_local.conceallevel = 2     -- Hides markdown syntax markers (like ** or _) for cleaner reading
        vim.opt_local.colorcolumn = "0"    -- Disables the color column margin line if you have one globally set
        vim.opt_local.signcolumn = "yes"   -- Keeps the left margin open to prevent text shifting

        vim.keymap.set("v", "<leader>t", ":!column -t -s '|' -o '|'<cr>")
    end,
    group = vim.api.nvim_create_augroup("MarkdownSettings", { clear = true }),
})
