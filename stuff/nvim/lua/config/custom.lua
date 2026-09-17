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
      vim.keymap.set("n", "q", "<cmd>bd!<CR>", { buffer = true })
  end,
})
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  group = "custom_close_q",
  callback = function()
    local name = vim.api.nvim_buf_get_name(0)
    if name:match("^fugitive://") or name:match("^/tmp/") then
      vim.keymap.set("n", "q", "<cmd>bd!<CR>", { buffer = true })
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
