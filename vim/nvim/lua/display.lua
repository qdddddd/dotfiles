require("utils")
vim.cmd("syntax on")
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
Au("BufWritePre", {
    pattern = "*",
    callback = function()
        local pos = vim.api.nvim_win_get_cursor(0)
        vim.cmd([[%s/\s\+$//e]])
        vim.api.nvim_win_set_cursor(0, pos)
    end,
})

-- Always color column 99999 to disable until triggered
Au("BufWinEnter", {
    pattern = "*",
    command = "set colorcolumn=99999",
})

-- Show column marker if longest line exceeds limit
Au(
    { "BufWinEnter", "BufRead", "TextChanged", "TextChangedI" },
    {
        pattern = "*.cs",
        group = AuGrp("TriggerColorColumn"),
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
