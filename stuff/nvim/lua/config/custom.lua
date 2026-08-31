-- if vim.fn.executable 'fd' == 1 then
--     -- to be accessible by viml, func needs to be global with '_G'
--     function _G.fdFindFiles(arg, _cmdcomplete)
--         return vim.fn.systemlist('fd --full-path ' .. arg)
--     end
--     vim.o.findfunc = 'v:lua.fdFindFiles'
-- end


vim.g.filetype_pl = 'prolog'

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


-- vim.api.nvim_create_user_command('Git', function(opts)
--   local filetype = vim.bo.filetype
--   local bufname = vim.fn.bufname('%')
--
--   if filetype == 'fugitive' and bufname:match('^fugitive://') then
--     vim.cmd('bd!')
--   end
--
--   local args = opts.args or ''
--   if args == '' then
--     vim.cmd('Git')
--   else
--     args = args:gsub("'", "\\'")
--     vim.cmd("Git " .. args)
--   end
-- end, { nargs = '*', complete = 'shellcmd' })
