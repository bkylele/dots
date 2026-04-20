if vim.fn.executable 'fd' == 1 then
    -- to be accessible by viml, func needs to be global with '_G'
    function _G.fdFindFiles(arg, _cmdcomplete)
        return vim.fn.systemlist('fd --full-path ' .. arg)
    end
    vim.o.findfunc = 'v:lua.fdFindFiles'
end

vim.g.filetype_pl = 'prolog'

vim.api.nvim_create_autocmd("FileType", {
  pattern = "nix",
  callback = function()
    vim.bo.formatprg = ", nixfmt"
  end,
})
