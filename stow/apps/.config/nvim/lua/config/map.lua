vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

vim.cmd('cabbrev W update')
vim.cmd('cabbrev w update')

vim.keymap.set('n', '<c-c>', '<esc>')
vim.keymap.set('t', '<c-[>', '<c-\\><c-n>')
vim.keymap.set('i', 'jk', '<esc>')

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

vim.keymap.set('i', '<c-s-j>'   , '<c-o><cmd>.move+1<cr>')
vim.keymap.set('i', '<c-s-k>'   , '<c-o><cmd>.move-2<cr>')
vim.keymap.set('v', '<c-j>'     , ':move\'>+1<cr>gv')
vim.keymap.set('v', '<c-k>'     , ':move\'<-2<cr>gv')

vim.keymap.set('n', 'gyy'       , 'yygcc', { remap = true })
vim.keymap.set('v', 'gy'        , 'ygvgc', { remap = true })

vim.keymap.set('n', '<leader>pv', '<cmd>Ex<cr>')
vim.keymap.set('n', '<leader>pf', ':find **/**<left>',                { desc = 'Find file' })
vim.keymap.set('n', '<leader>pp', ':grep "" %<left><left><left>',     { desc = 'Grep in current file' })
vim.keymap.set('n', '<leader>ps', ':grep -r "" .<left><left><left>',  { desc = 'Grep in project' })
vim.keymap.set('v', '<leader>s' , ':s/',                              { desc = 'Start substitue on current selection'})
vim.keymap.set('v', '<leader>n' , ':norm ',                           { desc = 'Start norm on current selection'})



-- `]q`/`[q` move in quickfix, using `]`/`[` to repeat; any other
-- key restores whatever `]`/`[` mapped to before.
local repeat_active, repeat_running = false, false
local repeat_actions, saved_maps

-- save any pre-existing buffer-local `[`/`]` maps we're about to overwrite
local function save_bracket_maps()
    saved_maps = {}
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(0, 'n')) do
        if map.lhs == '[' or map.lhs == ']' then
            saved_maps[#saved_maps + 1] = map
            vim.keymap.del('n', map.lhs, { buffer = true })
        end
    end
end

local function stop_repeat()
    if not repeat_active then return end
    repeat_active = false
    pcall(vim.keymap.del, 'n', '[')
    pcall(vim.keymap.del, 'n', ']')
    for _, map in ipairs(saved_maps) do
        vim.fn.mapset('n', false, map)
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
    save_bracket_maps()
    repeat_actions, repeat_active = { previous, next }, true

    vim.keymap.set('n', '[', function() run_repeat(repeat_actions[1]) end, { nowait = true, silent = true })
    vim.keymap.set('n', ']', function() run_repeat(repeat_actions[2]) end, { nowait = true, silent = true })
    run_repeat(initial)
end

local function repeatable(suffix, label, previous, next)
    vim.keymap.set('n', '[' .. suffix, function() start_repeat(previous, next, previous) end,
        { desc = label .. ': previous' })
    vim.keymap.set('n', ']' .. suffix, function() start_repeat(previous, next, next) end,
        { desc = label .. ': next' })
end

vim.on_key(function(_, typed)
    if repeat_active and not repeat_running and typed ~= '[' and typed ~= ']' then stop_repeat() end
end, vim.api.nvim_create_namespace('bracket-repeat'))

repeatable('q', 'Quickfix',
    -- :cnext falls back on :cfirst to emulate wrapping, same for :cprev
    function() if not pcall(vim.cmd.cprevious) then vim.cmd.clast() end end,
    function() if not pcall(vim.cmd.cnext) then vim.cmd.cfirst() end end)
repeatable('d', 'Diagnostic',
    function() vim.diagnostic.jump({ count = -1 }) end,
    function() vim.diagnostic.jump({ count = 1 }) end)
