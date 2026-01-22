require("utils")

if vim.g.vscode then
    vim.opt.guicursor = {
        "n-v-c:block-Cursor",
        "i:hor20"
    }
else
    vim.opt.runtimepath:prepend(vim.fn.expand("~/.vim"))
    vim.opt.packpath = vim.opt.runtimepath:get()
    vim.g.codex_commit_enabled = vim.fn.executable("codex") == 1
    require("environment")
    require("gitcommit")
    require("display")
    require("keymaps")
    require("plugins")
    require("lsp")
end
