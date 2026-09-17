vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

vim.cmd('cabbrev W update')
vim.cmd('cabbrev w update')

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

vim.keymap.set('n', '<c-d>'     , '<c-d>zz')
vim.keymap.set('n', '<c-u>'     , '<c-u>zz')

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

-- Prefix+[ or ] starts a repeat mode; any other key restores the bracket maps.
local repeat_active, repeat_running = false, false
local repeat_actions, saved_maps, saved_buffers

local function suspend_bracket_maps(bufnr)
    local id = bufnr or 0
    if saved_buffers[id] then return end
    saved_buffers[id] = true

    local maps = bufnr and vim.api.nvim_buf_get_keymap(bufnr, 'n') or vim.api.nvim_get_keymap('n')
    for _, map in ipairs(maps) do
        local first = map.lhs:sub(1, 1)
        if first == '[' or first == ']' then
            saved_maps[#saved_maps + 1] = { bufnr = bufnr, map = map }
            vim.keymap.del('n', map.lhs, bufnr and { buffer = bufnr } or nil)
        end
    end
end

local function stop_repeat()
    if not repeat_active then return end
    repeat_active = false
    pcall(vim.keymap.del, 'n', ']')
    pcall(vim.keymap.del, 'n', '[')

    for _, saved in ipairs(saved_maps) do
        if not saved.bufnr or vim.api.nvim_buf_is_valid(saved.bufnr) then
            local restore = function() vim.fn.mapset('n', false, saved.map) end
            if saved.bufnr then vim.api.nvim_buf_call(saved.bufnr, restore) else restore() end
        end
    end
end

local function run_repeat(action)
    repeat_running = true
    local ok, err = pcall(action)
    repeat_running = false
    if not ok then
        stop_repeat()
        error(err)
    end
end

local function start_repeat(previous, next, initial)
    saved_maps, saved_buffers = {}, {}
    suspend_bracket_maps()
    suspend_bracket_maps(vim.api.nvim_get_current_buf())
    repeat_actions, repeat_active = { previous, next }, true

    vim.keymap.set('n', '[', function() run_repeat(repeat_actions[1]) end, { nowait = true, silent = true })
    vim.keymap.set('n', ']', function() run_repeat(repeat_actions[2]) end, { nowait = true, silent = true })
    run_repeat(initial)
end

local function repeatable(prefix, label, previous, next)
    vim.keymap.set('n', prefix .. '[', function() start_repeat(previous, next, previous) end,
        { desc = label .. ': previous' })
    vim.keymap.set('n', prefix .. ']', function() start_repeat(previous, next, next) end,
        { desc = label .. ': next' })
end

vim.api.nvim_create_autocmd('BufEnter', {
    group = vim.api.nvim_create_augroup('bracket-repeat', { clear = true }),
    callback = function(args)
        if repeat_active then suspend_bracket_maps(args.buf) end
    end,
})

vim.on_key(function(_, typed)
    if repeat_active and not repeat_running and typed ~= '[' and typed ~= ']' then stop_repeat() end
end, vim.api.nvim_create_namespace('bracket-repeat'))

repeatable('q', 'Quickfix',
    function() vim.cmd('cprevious') end,
    function() vim.cmd('cnext') end)
repeatable('d', 'Diagnostic',
    function() vim.diagnostic.jump({ count = -1 }) end,
    function() vim.diagnostic.jump({ count = 1 }) end)
