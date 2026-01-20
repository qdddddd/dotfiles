require("utils")

if vim.g.vscode then
    vim.opt.guicursor = {
        "n-v-c:block-Cursor",
        "i:hor20"
    }
else
    vim.opt.runtimepath:prepend(vim.fn.expand("~/.vim"))
    vim.opt.packpath = vim.opt.runtimepath:get()
    if Exists(HOME .. "/.vim/vimrc.bundles") then
        vim.cmd("source ~/.vim/vimrc.bundles")
    end
    require("environment")
    require("gitcommit")
    require("display")
    require("keymaps")
    require("lsp")
    require("plugins")
end
