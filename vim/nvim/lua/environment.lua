require("utils")

local fn = vim.fn
local opt = vim.opt

-- Terminal and environment
if not fn.has("gui") then
    if LINUX() then
        opt.t_u7 = ""
    end
end

-- General settings
vim.cmd("filetype plugin indent on")
opt.mouse = "a"
opt.mousehide = true
opt.guioptions = ""
vim.scriptencoding = "utf-8"
opt.encoding = "utf-8"

if fn.has("clipboard") == 1 then
    if fn.has("unnamedplus") == 1 then
        opt.clipboard = "unnamed,unnamedplus"
    else
        opt.clipboard = "unnamed"
    end
end

opt.shortmess:append("cfilmnrxoOtT")
opt.viewoptions = { "folds", "options", "cursor", "unix", "slash" }
opt.virtualedit = "onemore"
opt.history = 1000
opt.spell = false
opt.hidden = true
opt.iskeyword:remove({ ".", "#", "-" })

-- Git commit cursor reset
Au("FileType", {
    pattern = "gitcommit",
    callback = function()
        Au("BufEnter", {
            pattern = "COMMIT_EDITMSG",
            command = "call setpos('.', [0, 1, 1, 0])"
        })
    end
})

-- Persistent undo and backup dirs
if fn.has("persistent_undo") == 1 then
    opt.undofile = true
    opt.undolevels = 1000
    opt.undoreload = 10000
end

-- Initialize directories
local function initialize_directories()
    local dir_list = {
        backup = "backupdir",
        views = "viewdir",
        swap = "directory"
    }

    if fn.has("persistent_undo") == 1 then
        dir_list["undo/nvim"] = "undodir"
    end

    local common_dir = HOME .. "/.vim/tempfiles/"

    for dirname, settingname in pairs(dir_list) do
        local directory = common_dir .. dirname .. "/"
        if fn.exists("*mkdir") == 1 and fn.isdirectory(directory) == 0 then
            fn.mkdir(directory, "p")
        end
        if fn.isdirectory(directory) == 0 then
            vim.notify("Warning: Unable to create directory: " .. directory, vim.log.levels.WARN)
        else
            directory = directory:gsub(" ", "\\ ")
            opt[settingname] = directory
        end
    end
end

initialize_directories()

-- Editor UI options
opt.autoindent = true
opt.backspace = { "indent", "eol", "start" }
opt.breakindent = true
opt.comments = { "sl:/*", "mb:*", "elx:*/" }
opt.cursorline = true
opt.equalalways = true
opt.expandtab = true
opt.foldenable = true
opt.hlsearch = true
opt.ignorecase = true
opt.incsearch = true
opt.linespace = 0
opt.list = true
opt.listchars = { tab = "›\\ ", trail = "•", extends = "#", nbsp = "." }
opt.bomb = false
opt.joinspaces = false
opt.readonly = false
opt.showmode = false
opt.number = true
opt.relativenumber = true
opt.scrolljump = 0
opt.scrolloff = 3
opt.shiftwidth = 4
opt.showmatch = true
opt.smartcase = true
opt.softtabstop = 4
opt.splitbelow = true
opt.splitright = true
opt.tabpagemax = 15
opt.tabstop = 4
opt.textwidth = 120
opt.updatetime = 300
opt.whichwrap = "b,s,h,l,<,>,[,]"
opt.wildmenu = true
opt.wildmode = "longest:full,full"
opt.winminheight = 0
opt.wrap = true

-- Filetype overrides
Au({ "BufRead", "BufNewFile" }, {
    pattern = "*.html.twig",
    command = "set ft=html.twig"
})
Au({ "BufRead", "BufNewFile" }, {
    pattern = "*.coffee",
    command = "set ft=coffee"
})
Au({ "BufRead", "BufNewFile" }, {
    pattern = "*.rst",
    command = "set ft=rst"
})
Au({ "BufRead", "BufNewFile" }, {
    pattern = "*.tex",
    command = "set ft=tex"
})
Au("FileType", {
    pattern = "json",
    command = "set ft=jsonc"
})

-- Crontab
if vim.env.VIM_CRONTAB == 'true' then
    opt.backup = false
    opt.writebackup = false
end

-- Wild ignore
opt.wildignore:append({
    ".git", ".hg", ".svn",
    "*.aux", "*.out", "*.toc",
    "*.o", "*.obj", "*.exe", "*.dll", "*.manifest", "*.rbc", "*.class",
    "*.ai", "*.bmp", "*.gif", "*.ico", "*.jpg", "*.jpeg", "*.png", "*.psd", "*.webp",
    "*.avi", "*.divx", "*.mp4", "*.webm", "*.mov", "*.m2ts", "*.mkv", "*.vob", "*.mpg", "*.mpeg",
    "*.mp3", "*.oga", "*.ogg", "*.wav", "*.flac", "*.m4a", "*.mov",
    "*.eot", "*.otf", "*.ttf", "*.woff",
    "*.doc", "*.pdf", "*.cbr", "*.cbz",
    "*.zip", "*.tar.gz", "*.tar.bz2", "*.rar", "*.tar.xz", "*.kgb",
    "*.swp", ".lock", ".DS_Store", "._*"
})

-- Fix esc delay
if not fn.has("gui_running") == 1 then
    opt.ttimeoutlen = 0
    opt.timeoutlen = 500

    local fast_escape = AuGrp("FastEscape")

    Au("InsertEnter", {
        group = fast_escape,
        pattern = "*",
        callback = function()
            opt.timeoutlen = 0
        end,
    })

    Au("InsertLeave", {
        group = fast_escape,
        pattern = "*",
        callback = function()
            opt.timeoutlen = 500
        end,
    })
end

-- Auto-write
vim.o.autowrite = true
Au({ "BufEnter", "BufNewFile" }, {
    pattern = { "*.vim", "*vimrc*" },
    command = "nmap <leader>s :w <bar> so % <CR>",
})

-- Completion
vim.o.completeopt = "menu,noinsert,longest,preview"
-- Close preview window when completion menu closes
Au({ "CompleteDone", "CursorMovedI", "InsertLeave" }, {
    callback = function()
        if fn.pumvisible() == 0 then
            pcall(fn.pclose)
        end
    end,
})
