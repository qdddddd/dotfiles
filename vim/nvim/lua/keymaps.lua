require("utils")
vim.g.mapleader = " "
local opts = { silent = true }

-- Reload vim settings
vim.api.nvim_create_user_command("Reload", function()
    dofile(vim.fn.stdpath("config") .. "/init.lua")
end, {})

-- ListVisible equivalent: check if quickfix/loclist is open in current tab
local function list_visible()
    local visible = vim.fn.getwininfo()
    local tabnr = vim.fn.tabpagenr()

    local count = 0
    for _, info in ipairs(visible) do
        if info.tabnr == tabnr then
            if info.loclist and info.winid == vim.fn.getloclist(0, { winid = 1 }).winid then
                count = count + 1
            elseif not info.loclist and info.quickfix then
                count = count + 1
            end
        end
    end

    return count
end

-- Remap Ctrl-j/k and q conditionally
Keymap("n", "<C-j>", function() return list_visible() > 0 and ":cnext<CR>" or "<C-j>" end, { expr = true })
Keymap("n", "<C-k>", function() return list_visible() > 0 and ":cprevious<CR>" or "<C-k>" end, { expr = true })
Keymap("n", "q", function() return list_visible() > 0 and ":cclose<CR>" or "q" end, { expr = true })

-- Wrapped line movement
Keymap("n", "j", "gj")
Keymap("n", "k", "gk")
Keymap("n", "$", "g$")
Keymap("n", "0", "g0")
Keymap("n", "^", "g^")

-- Command mode navigation
Keymap("c", "<C-n>", "<Down>")
Keymap("c", "<C-p>", "<Up>")
Keymap("c", "<C-b>", "<Left>")
Keymap("c", "<C-f>", "<Right>")
Keymap("c", "<C-a>", "<Home>")

-- Yank to end of line
Keymap("n", "Y", "y$")

-- Visual shifting
Keymap("v", "<", "<gv")
Keymap("v", ">", ">gv")

-- Use repeat in visual mode
Keymap("v", ".", ":normal .<CR>")

-- Sudo write
vim.cmd([[cnoreabbrev w!! w !sudo tee % >/dev/null]])

-- Save & delete buffer
Keymap("n", "<leader>w", ":w<CR>")
Keymap("n", "<leader>x", ":bd<CR>")

-- Terminal commands
vim.api.nvim_create_user_command("Vter", "vert ter zsh", {})
vim.api.nvim_create_user_command("Ter", "ter zsh", {})

-- Clear highlight
Keymap("n", "'", ":let @/=''<CR>", opts)
Keymap("n", [[\]], ":let @/=''<CR>", opts)

-- Redo
Keymap("n", "U", ":redo<CR>")

-- Switch between header and source files
Keymap("n", "<leader>ch", ":e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>")
Keymap("n", "<leader>cu", ":e %:p:s,.cuh$,.X123X,:s,.cu$,.cuh,:s,.X123X$,.cu,<CR>")

-- Insert mode navigation
Keymap("i", "<C-h>", "<Left>")
Keymap("i", "<C-l>", "<Right>")

-- Exit terminal
Keymap("t", "<leader><Esc>", "<C-\\><C-n>")

-- Cycle buffers (<M--> and Unicode fallback for macOS Option key over SSH)
Keymap("n", "<M-->", ":bprevious<CR>")
Keymap("n", "<M-=>", ":bnext<CR>")
Keymap("n", "–", ":bprevious<CR>")
Keymap("n", "≠", ":bnext<CR>")

-- Open file in new tab
Keymap("n", "<leader>t", ":tabnew <C-R>=expand('%:p')<CR><CR>", opts)

-- Jump to tab n with `tn`
for i = 1, 9 do
    Keymap("n", "t" .. i, ":tabnext " .. i .. "<CR>", opts)
end

-- Cycle tabs
Keymap("n", "tj", ":tabprevious<CR>", opts)
Keymap("n", "tk", ":tabnext<CR>", opts)

-- Popup menu navigation
opts = { expr = true, silent = true }
Keymap("i", "<CR>", function() return vim.fn.pumvisible() == 1 and "<C-y>" or "<C-g>u<CR>" end, opts)
Keymap("i", "<Down>", function() return vim.fn.pumvisible() == 1 and "<C-n>" or "<Down>" end, opts)
Keymap("i", "<Up>", function() return vim.fn.pumvisible() == 1 and "<C-p>" or "<Up>" end, opts)
Keymap("i", "<C-d>", function() return vim.fn.pumvisible() == 1 and "<PageDown><C-p><C-n>" or "<C-d>" end, opts)
Keymap("i", "<C-u>", function() return vim.fn.pumvisible() == 1 and "<PageUp><C-p><C-n>" or "<C-u>" end, opts)
