--- Check if a file or directory exists in this path
function Exists(file)
    local ok, err, code = os.rename(file, file)
    if not ok then
        if code == 13 then
            -- Permission denied, but it exists
            return true
        end
    end
    return ok, err
end

--- Check if a directory exists in this path
function IsDir(path)
    -- "/" works on both Unix and Windows
    return Exists(path.."/")
end

-- lspinstall {
if IsDir('~/.vim/bundle/nvim-lspinstall') then
    local function setup_servers()
        require'lspinstall'.setup()
        local servers = require'lspinstall'.installed_servers()
        for _, server in pairs(servers) do
            require'lspconfig'[server].setup{}
        end
    end

    setup_servers()

    -- Automatically reload after `:LspInstall <server>` so we don't have to restart neovim
    require'lspinstall'.post_install_hook = function ()
        setup_servers() -- reload installed servers
        vim.cmd("bufdo e") -- this triggers the FileType autocmd that starts the server
    end
end
-- }

-- lspconfig {
if IsDir('~/.vim/bundle/nvim-lspconfig') then
    vim.cmd('packadd nvim-lspconfig')
    local pid = vim.fn.getpid()
    require'lspconfig'.omnisharp.setup {
        cmd = { "/home/qdu/.local/share/nvim/lspinstall/csharp/omnisharp/run", "--languageserver", "--hostPID", tostring(pid) },
        filetypes = {"cs", "vb"};
        root_dir = util.root_pattern("*.csproj", "*.sln");
        init_options = { };
    }
end
-- }
