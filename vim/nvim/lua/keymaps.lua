vim.g.mapleader = " "

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
vim.keymap.set("n", "<C-j>", function()
    return list_visible() > 0 and ":cnext<CR>" or "<C-j>"
end, { expr = true, noremap = true })

vim.keymap.set("n", "<C-k>", function()
    return list_visible() > 0 and ":cprevious<CR>" or "<C-k>"
end, { expr = true, noremap = true })

vim.keymap.set("n", "q", function()
    return list_visible() > 0 and ":cclose<CR>" or "q"
end, { expr = true, noremap = true })

-- Wrapped line movement
vim.keymap.set("n", "j", "gj", { noremap = true })
vim.keymap.set("n", "k", "gk", { noremap = true })
vim.keymap.set("n", "$", "g$", { noremap = true })
vim.keymap.set("n", "0", "g0", { noremap = true })
vim.keymap.set("n", "^", "g^", { noremap = true })

-- Command mode navigation
vim.keymap.set("c", "<C-n>", "<Down>")
vim.keymap.set("c", "<C-p>", "<Up>")
vim.keymap.set("c", "<C-b>", "<Left>")
vim.keymap.set("c", "<C-f>", "<Right>")
vim.keymap.set("c", "<C-a>", "<Home>")

-- Yank to end of line
vim.keymap.set("n", "Y", "y$", { noremap = true })

-- Visual shifting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Use repeat in visual mode
vim.keymap.set("v", ".", ":normal .<CR>", { noremap = true })

-- Sudo write
vim.cmd([[cnoreabbrev w!! w !sudo tee % >/dev/null]])

-- Python table helpers
vim.keymap.set("n", ",,c", ":python ReformatTable()<CR>", { noremap = true })
vim.keymap.set("n", ",,f", ":python ReflowTable()<CR>", { noremap = true })

-- Save & delete buffer
vim.keymap.set("n", "<leader>w", ":w<CR>")
vim.keymap.set("n", "<leader>x", ":bd<CR>")

-- Terminal commands
vim.api.nvim_create_user_command("Vter", "vert ter zsh", {})
vim.api.nvim_create_user_command("Ter", "ter zsh", {})

-- Clear highlight
vim.keymap.set("n", "'", ":let @/=''<CR>", { silent = true })
vim.keymap.set("n", [[\]], ":let @/=''<CR>", { silent = true })

-- Redo
vim.keymap.set("n", "U", ":redo<CR>")

-- Switch between header and source files
vim.keymap.set("n", "<leader>ch", ":e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>")
vim.keymap.set("n", "<leader>cu", ":e %:p:s,.cuh$,.X123X,:s,.cu$,.cuh,:s,.X123X$,.cu,<CR>")

-- Insert mode navigation
vim.keymap.set("i", "<C-h>", "<Left>")
vim.keymap.set("i", "<C-l>", "<Right>")

-- Clear and redraw screen
vim.keymap.set("n", "<C-l>",
    [[<Cmd>nohlsearch<CR><Cmd>diffupdate<CR><Cmd>syntax sync fromstart<CR><Cmd>set relativenumber<Bar>set number<Bar>set cursorline<Bar>set signcolumn=yes<CR>]],
    { silent = true })

-- Copy over ssh
vim.keymap.set("v", "sy", ":w !sshcopy<CR><CR>", { silent = true })

-- Exit terminal
vim.keymap.set("t", "<leader><Esc>", "<C-\\><C-n>")

-- Cycle buffers
vim.keymap.set("n", "<A-->", "[b", { silent = true })
vim.keymap.set("n", "<A-=>", "]b", { silent = true })
vim.keymap.set("n", "–", "[b", { silent = true })
vim.keymap.set("n", "≠", "]b", { silent = true })

-- Open file in new tab
vim.keymap.set("n", "<leader>t", ":tabnew <C-R>=expand('%:p')<CR><CR>", { silent = true })

-- Jump to tab n with `tn`
for i = 1, 9 do
    vim.keymap.set("n", "t" .. i, ":tabnext " .. i .. "<CR>", { silent = true })
end

-- Cycle tabs
vim.keymap.set("n", "tj", ":tabprevious<CR>", { silent = true })
vim.keymap.set("n", "tk", ":tabnext<CR>", { silent = true })

-- Popup menu navigation
local opts = { expr = true, silent = true }
vim.keymap.set("i", "<CR>", function() return vim.fn.pumvisible() == 1 and "<C-y>" or "<C-g>u<CR>" end, opts)
vim.keymap.set("i", "<Down>", function() return vim.fn.pumvisible() == 1 and "<C-n>" or "<Down>" end, opts)
vim.keymap.set("i", "<Up>", function() return vim.fn.pumvisible() == 1 and "<C-p>" or "<Up>" end, opts)
vim.keymap.set("i", "<C-d>", function() return vim.fn.pumvisible() == 1 and "<PageDown><C-p><C-n>" or "<C-d>" end, opts)
vim.keymap.set("i", "<C-u>", function() return vim.fn.pumvisible() == 1 and "<PageUp><C-p><C-n>" or "<C-u>" end, opts)
