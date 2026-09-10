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

vim.keymap.set('c', '<c-a>'     , '<home>',                  { desc = 'emacs-style movement' }                )
vim.keymap.set('c', '<c-e>'     , '<end>',                   { desc = 'emacs-style movement' }                )
vim.keymap.set('c', '<c-b>'     , '<left>',                  { desc = 'emacs-style movement' }                )
vim.keymap.set('c', '<m-f>'     , '<c-right>',               { desc = 'emacs-style movement' }                )
vim.keymap.set('c', '<m-b>'     , '<c-left>',                { desc = 'emacs-style movement' }                )
vim.keymap.set('c', '<c-d>'     , '<delete>',                { desc = 'emacs-style movement' }                )
vim.keymap.set('c', '<m-d>'     , '<c-right><c-w><delete>',  { desc = 'emacs-style movement' }                )
vim.keymap.set('n', '<c-d>'     , '<c-d>zz',                 { desc = 'emacs-style movement' }                )
vim.keymap.set('n', '<c-u>'     , '<c-u>zz',                 { desc = 'emacs-style movement' }                )

vim.keymap.set('i', '<c-s-j>'   , '<c-o><cmd>.move+1<cr>'                                                     )
vim.keymap.set('i', '<c-s-k>'   , '<c-o><cmd>.move-2<cr>'                                                     )
vim.keymap.set('v', '<c-j>'     , ':move\'>+1<cr>gv'                                                     )
vim.keymap.set('v', '<c-k>'     , ':move\'<-2<cr>gv'                                                     )

vim.keymap.set('n', 'gyy'       , 'yygcc'                  , { remap = true }                                 )
vim.keymap.set('v', 'gy'        , 'ygvgc'                  , { remap = true }                                 )

vim.keymap.set('n', '<leader>pf', ':find<space>**/*'       , { desc = 'Find file' }                           )
vim.keymap.set('n', '<leader>ps', ':grep<space>""<left>'   , { desc = 'Grep' }                                )
vim.keymap.set('v', '<leader>s' , ':s/'                    , { desc = 'Start substitue on current selection' })
vim.keymap.set('v', '<leader>n' , ':norm<space>'           , { desc = 'Start norm on current selection' }     )


-- q] / q[ starts a repeat mode; [ and ] stay untouched otherwise.
local qf_repeat_active = false
local qf_repeat_running = false
local qf_repeat_ns = vim.api.nvim_create_namespace('quickfix-repeat')
local qf_repeat_group = vim.api.nvim_create_augroup('quickfix-repeat', { clear = true })
local qf_saved_maps = {}
local qf_saved_buffers = {}

local function is_bracket_map(map)
    local first = map.lhs:sub(1, 1)
    return first == '[' or first == ']'
end

local function map_opts(map)
    local opts = {
        desc = map.desc ~= '' and map.desc or nil,
        expr = map.expr == 1,
        nowait = map.nowait == 1,
        silent = map.silent == 1,
        remap = map.noremap == 0,
        replace_keycodes = map.replace_keycodes == 1,
    }
    if map.buffer and map.buffer > 0 then opts.buffer = map.buffer end
    return opts
end

local function delete_map(map)
    if map.buffer and map.buffer > 0 then
        vim.api.nvim_buf_del_keymap(map.buffer, 'n', map.lhs)
    else
        vim.keymap.del('n', map.lhs)
    end
end

local function save_buffer_maps(bufnr)
    if qf_saved_buffers[bufnr] then return end
    qf_saved_buffers[bufnr] = true

    for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, 'n')) do
        if is_bracket_map(map) then
            qf_saved_maps[#qf_saved_maps + 1] = map
            delete_map(map)
        end
    end
end

local function stop_qf_repeat()
    if not qf_repeat_active then return end

    qf_repeat_active = false
    pcall(vim.keymap.del, 'n', ']')
    pcall(vim.keymap.del, 'n', '[')
    for _, map in ipairs(qf_saved_maps) do
        if map.buffer == 0 or vim.api.nvim_buf_is_valid(map.buffer) then
            vim.keymap.set('n', map.lhs, map.callback or map.rhs, map_opts(map))
        end
    end
    qf_saved_maps = {}
    qf_saved_buffers = {}
end

local function run_qf_command(command)
    qf_repeat_running = true
    local ok, err = pcall(vim.cmd, command)
    qf_repeat_running = false
    if not ok then
        stop_qf_repeat()
        error(err)
    end
end

local function start_qf_repeat(command)
    qf_saved_maps = {}
    qf_saved_buffers = {}
    for _, map in ipairs(vim.api.nvim_get_keymap('n')) do
        if is_bracket_map(map) then
            qf_saved_maps[#qf_saved_maps + 1] = map
            delete_map(map)
        end
    end
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then save_buffer_maps(bufnr) end
    end

    qf_repeat_active = true
    vim.keymap.set('n', ']', function() run_qf_command('cnext') end,
        { desc = 'Quickfix: next', nowait = true, silent = true })
    vim.keymap.set('n', '[', function() run_qf_command('cprevious') end,
        { desc = 'Quickfix: previous', nowait = true, silent = true })
    run_qf_command(command)
end

vim.api.nvim_create_autocmd('BufEnter', {
    group = qf_repeat_group,
    callback = function(args)
        if qf_repeat_active then save_buffer_maps(args.buf) end
    end,
})

vim.on_key(function(_, typed)
    if qf_repeat_active and not qf_repeat_running and typed ~= '[' and typed ~= ']' then
        stop_qf_repeat()
    end
end, qf_repeat_ns)

vim.keymap.set('n', 'q]', function() start_qf_repeat('cnext') end,     { desc = 'Quickfix: next' })
vim.keymap.set('n', 'q[', function() start_qf_repeat('cprevious') end, { desc = 'Quickfix: previous' })
