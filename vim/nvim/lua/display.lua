require("utils")
vim.o.background = "light"
local menu_bg = "#f3e5bc"

require("gruvbox").setup({
    terminal_colors = true,
    invert_selection = false,
    overrides = {
        GruvboxGreenSign = { fg = "#79740e", bg = "bg" },
        GruvboxRedSign = { fg = "#9d0006", bg = "bg" },
        GruvboxAquaSign = { fg = "#427b58", bg = "bg" },
        GruvboxYellowSign = { fg = "#b57614", bg = "bg" },
        SignColumn = { bg = "bg" },
        -- floating window
        Fmenu = { fg = "#32302f", bg = menu_bg },
        FmenuThumb = { fg = menu_bg, bg = "#8a95a7" },
        FmenuSbar = { link = "PmenuSbar", default = true },
        -- coc
        CocErrorFloat = { fg = "#9d0006", bg = menu_bg },
        CocWarningFloat = { fg = "#b57614", bg = menu_bg },
        CocInfoFloat = { fg = "#427b58", bg = menu_bg },
        CocWarningSign = { link = "GruvboxYellowSign" },
        CocInfoSign = { link = "GruvboxAquaSign" },
        CocHintSign = { link = "GruvboxYellowSign" },
        CocInlayHintType = { link = "GruvboxBg4" },
        CocSemNamespace = { link = "GruvboxAqua" },
        CocSemClass = { link = "GruvboxYellow" },
        CocSemStruct = { link = "CocSemClass" },
        CocSemEvent = { link = "GruvboxAqua" },
        CocFloating = { link = "Fmenu" },
        CocHintFloat = { link = "CocWarningFloat" },
        CocMenuSel = { fg = "#f3e5bc", bg = "#076678" },
        -- NvimTree
        NvimTreeFolderIcon = { link = "GruvboxBlue" },
        NvimTreeFolderName = { link = "NvimTreeFolderIcon" },
        NvimTreeEmptyFolderName = { link = "NvimTreeFolderName" },
        NvimTreeRootFolder = { bold = true, underline = true, fg = "#076678" },
        NvimTreeOpenedFolderName = { link = "GruvboxBlueBold" },
        NvimTreeOpenedFile = { link = "GruvboxGreen" },
        NvimTreeSymlink = { link = "GruvboxAqua" },
        NvimTreeExecFile = { link = "GruvboxYellow" },
        NvimTreeSpecialFile = { fg = "#3c3836", bg = "#fbf1c7", underline = true },
        -- lsp
        Function = { link = "GruvboxBlueBold" },
        Identifier = { link = "GruvboxFg2" },
    }
})

vim.cmd.colorscheme("gruvbox")
vim.cmd("syntax on")
vim.cmd("hi! clear Operator")
vim.opt.conceallevel = 1
vim.opt.guicursor = "a:hor20"

-- Fzf floating window style
vim.g.fzf_layout = {
    window = {
        width = 1,
        height = 0.4,
        relative = true,
        yoffset = 1
    }
}

-- Strip trailing whitespace before saving
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function()
        local pos = vim.api.nvim_win_get_cursor(0)
        vim.cmd([[%s/\s\+$//e]])
        vim.api.nvim_win_set_cursor(0, pos)
    end,
})

-- Always color column 99999 to disable until triggered
vim.api.nvim_create_autocmd("BufWinEnter", {
    pattern = "*",
    command = "set colorcolumn=99999",
})

-- Show column marker if longest line exceeds limit
vim.api.nvim_create_augroup("TriggerColorColumn", { clear = true })
vim.api.nvim_create_autocmd(
    { "BufWinEnter", "BufRead", "TextChanged", "TextChangedI" },
    {
        pattern = "*.cs",
        group = "TriggerColorColumn",
        callback = function()
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local max_len = 0
            for _, line in ipairs(lines) do
                max_len = math.max(max_len, #line)
            end
            local len_limit = 120
            if max_len > len_limit then
                vim.opt.colorcolumn = tostring(len_limit + 1)
            else
                vim.opt.colorcolumn = "99999"
            end
        end
    }
)
