require("utils")
local uv = vim.uv or vim.loop

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

local fzf_dir = vim.fn.expand("~/.fzf")
local fzf_dep = {
    dir = fzf_dir,
    name = "fzf",
    cond = function()
        return uv.fs_stat(fzf_dir) ~= nil
    end,
}

local function glibc_lt_2_39()
    if vim.fn.executable("ldd") ~= 1 then
        return false
    end
    local out = vim.fn.system({ "ldd", "--version" })
    if vim.v.shell_error ~= 0 or type(out) ~= "string" then
        return false
    end
    local major, minor = out:match("GLIBC%s+(%d+)%.(%d+)")
    if not major then
        major, minor = out:match("(%d+)%.(%d+)")
    end
    major = tonumber(major)
    minor = tonumber(minor)
    if not major or not minor then
        return false
    end
    return major < 2 or (major == 2 and minor < 39)
end

local treesitter_legacy = glibc_lt_2_39()

require("lazy").setup({
    -- Colorscheme
    {
        "ellisonleao/gruvbox.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            vim.o.background = "light"
            local menu_bg = "#f3e5bc"

            require("gruvbox").setup({
                terminal_colors = true,
                invert_selection = false,
                overrides = {
                    GruvboxGreenSign = { fg = "#79740e", bg = "NONE" },
                    GruvboxRedSign = { fg = "#9d0006", bg = "NONE" },
                    GruvboxAquaSign = { fg = "#427b58", bg = "NONE" },
                    GruvboxYellowSign = { fg = "#b57614", bg = "NONE" },
                    SignColumn = { bg = "bg" },
                    CursorLineSign = { link = "CursorLine" },
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
                    CocSemFunction = { link = "GruvboxBlueBold" },
                    CocSemMethod = { link = "GruvboxBlueBold" },
                    Identifier = { link = "GruvboxFg2" },
                    -- Startify
                    StartifyHeader = { link = "GruvboxYellow" },
                    StartifySection = { link = "GruvboxYellow" },
                },
            })

            vim.cmd.colorscheme("gruvbox")
            vim.cmd("syntax on")
            vim.cmd("hi! clear Operator")
        end,
    },

    -- General
    { "mbbill/undotree" },
    { "mhinz/vim-signify" },
    { "rhysd/conflict-marker.vim" },
    { "terryma/vim-multiple-cursors" },
    { "tpope/vim-fugitive" },
    { "tpope/vim-repeat" },
    { "tpope/vim-surround" },
    {
        "adelarsq/vim-matchit",
        config = function()
            vim.b.match_ignorecase = 1
        end,
    },
    { "vim-scripts/restore_view.vim" },
    {
        "vim-scripts/sessionman.vim",
        config = function()
            vim.o.sessionoptions = "blank,buffers,curdir,folds,tabpages,winsize"
            Keymap("n", "<leader>sl", ":SessionList<CR>", { noremap = true, silent = true })
            Keymap("n", "<leader>ss", ":SessionSave<CR>", { noremap = true, silent = true })
            Keymap("n", "<leader>sc", ":SessionClose<CR>", { noremap = true, silent = true })
        end,
    },

    -- UI
    { "nvim-tree/nvim-web-devicons" },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local buffer_section = {
                "buffers",
                show_filename_only = false,
                icons_enabled = false,
                mode = 2,
                use_mode_colors = false,
                max_length = vim.o.columns - 6,
                buffers_color = {
                    active = { fg = "bg", bg = "#076678" },
                    inactive = { fg = "#7c6f64" },
                },
                symbols = {
                    modified = " ●",
                    alternate_file = "",
                    directory = "",
                },
                separator = "|",
                padding = 1,
                filetype_names = {
                    fzf = "search",
                    NvimTree = "tree",
                    startify = "start.dev",
                },
                fmt = function(str)
                    -- Displays buffers with unique names, or parent directory if duplicates exist --
                    if str == "" then return "" end -- Handle unnamed buffers like [No Name]

                    -- Count occurrences of each filename across all listed buffers
                    local filename_counts = {}
                    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.bo[bufnr].buflisted then
                            local buf_name = vim.api.nvim_buf_get_name(bufnr)
                            if buf_name ~= "" then
                                local filename = vim.fn.fnamemodify(buf_name, ":t")
                                filename_counts[filename] = (filename_counts[filename] or 0) + 1
                            end
                        end
                    end

                    local filename = vim.fn.fnamemodify(str, ":t") -- of the current buffer being processed

                    if filename_counts[filename] and filename_counts[filename] > 1 then
                        -- It's a duplicate: show "parent_directory/filename"
                        local dirname = vim.fn.fnamemodify(str, ":p:h:t")

                        if dirname == "." or dirname == "" then
                            -- Avoid showing './filename' for files in the cwd or '/' for root
                            return filename
                        end
                        return dirname .. "/" .. filename
                    else
                        -- It's unique: show just the filename
                        return filename
                    end
                end,
            }

            local gb = require("lualine.themes.gruvbox_light")

            require("lualine").setup({
                options = {
                    --section_separators = { left = '', right = '' },
                    --component_separators = { left = '|', right = '|' },
                    section_separators = { left = "", right = "" },
                    component_separators = { left = "", right = "" },
                    always_show_tabline = true,
                    globalstatus = false,
                    disabled_filetypes = {
                        statusline = { "startify", "defx" },
                        winbar = { "NvimTree", "startify", "defx", "fugitive", "fugitiveblame", "help" },
                    },
                    theme = gb,
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch", "diff" },
                    lualine_c = { { "filename", newfile_status = true, path = 1 } },
                    lualine_x = { "diagnostics", "progress", "location" },
                    lualine_y = { "filetype" },
                    lualine_z = { "lsp_status" },
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = { { "filename", newfile_status = true, path = 3 } },
                    lualine_c = { "diagnostics" },
                    lualine_x = {},
                    lualine_y = {},
                    lualine_z = {},
                },
                tabline = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = { buffer_section },
                    lualine_z = { "tabs" },
                },
                extensions = { "nvim-tree", "quickfix", "fugitive", "fzf" },
            })

            local opts = { silent = true }
            Keymap("n", "<leader>1", "<Cmd>LualineBuffersJump 1<CR>", opts)
            Keymap("n", "<leader>2", "<Cmd>LualineBuffersJump 2<CR>", opts)
            Keymap("n", "<leader>3", "<Cmd>LualineBuffersJump 3<CR>", opts)
            Keymap("n", "<leader>4", "<Cmd>LualineBuffersJump 4<CR>", opts)
            Keymap("n", "<leader>5", "<Cmd>LualineBuffersJump 5<CR>", opts)
            Keymap("n", "<leader>6", "<Cmd>LualineBuffersJump 6<CR>", opts)
            Keymap("n", "<leader>7", "<Cmd>LualineBuffersJump 7<CR>", opts)
            Keymap("n", "<leader>8", "<Cmd>LualineBuffersJump 8<CR>", opts)
            Keymap("n", "<leader>9", "<Cmd>LualineBuffersJump 9<CR>", opts)
        end,
    },

    -- File explorer
    {
        "junegunn/fzf.vim",
        dependencies = { fzf_dep },
        config = function()
            if vim.fn.executable("fzf") == 1 then
                vim.opt.rtp:append("~/.fzf")
                vim.g.fzf_colors = {
                    fg = { "fg", "Normal" },
                    bg = { "bg", "Normal" },
                    hl = { "fg", "Comment" },
                    ["fg+"] = { "fg", "CursorLine", "CursorColumn", "Normal" },
                    ["bg+"] = { "bg", "CursorLine", "CursorColumn" },
                    ["hl+"] = { "fg", "Statement" },
                    info = { "fg", "PreProc" },
                    border = { "fg", "Ignore" },
                    prompt = { "fg", "Conditional" },
                    pointer = { "fg", "Exception" },
                    marker = { "fg", "Keyword" },
                    spinner = { "fg", "Label" },
                    header = { "fg", "Comment" },
                }

                -- Define :Ag command
                vim.api.nvim_create_user_command("Ag", function(opts)
                    vim.fn["fzf#vim#ag"](
                        opts.args,
                        '--color-path "0;34" --color-line-number "0;35" --color-match "1;33"',
                        { options = { "--color", "hl:#9d0006,hl+:#9d0006" } },
                        opts.bang and 1 or 0
                    )
                end, { bang = true, nargs = "*" })

                local opts = { silent = true }
                Keymap("n", "<leader>f<space>", ":FZF<CR>", opts)
                Keymap("n", "<leader>r<space>", ":History<CR>", opts)
                Keymap("n", "<leader>ff", ":BTags<CR>", opts)
                Keymap("n", "<leader>l<space>", ":Lines<CR>", opts)

                -- `K` to grep word under cursor
                Keymap("n", "K", function()
                    vim.fn["fzf#vim#ag"](
                        vim.fn.expand("<cword>"),
                        '--color-path "0;34" --color-line-number "0;35" --color-match "1;33"',
                        { options = { "--color", "hl:#9d0006,hl+:#9d0006" } }
                    )
                end, opts)
            end
        end,
    },
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local width_perc = 0.2
            local original_width = math.floor(vim.o.columns * width_perc)

            Keymap("n", "<leader>e", "<Cmd>NvimTreeFindFileToggle<CR>", { silent = true })

            Au("BufEnter", {
                desc = "NvimTree: Toggle width on 'w' key",
                pattern = "NvimTree_*",
                callback = function(args)
                    Keymap(
                        "n",
                        "w",
                        function()
                            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                            local max_len = 0
                            for _, line in ipairs(lines) do
                                max_len = math.max(max_len, #line)
                            end
                            local new = (max_len == vim.fn.winwidth(0)) and original_width or max_len
                            vim.cmd("NvimTreeResize " .. new)
                        end,
                        { buffer = args.buf }
                    )
                end,
            })

            local function on_attach(bufnr)
                local api = require("nvim-tree.api")

                local function opts(desc)
                    return { desc = "nvim-tree: " .. desc, buffer = bufnr, silent = true, nowait = true }
                end

                Keymap("n", ".", api.tree.toggle_hidden_filter, opts("Toggle Dotfiles"))
                Keymap("n", "<BS>", api.node.navigate.parent_close, opts("Close Directory"))
                Keymap("n", "<C-j>", api.node.navigate.sibling.next, opts("Next Sibling"))
                Keymap("n", "<C-k>", api.node.navigate.sibling.prev, opts("Previous Sibling"))
                Keymap("n", "<Tab>", api.node.open.preview, opts("Open Preview"))
                Keymap("n", "?", api.tree.toggle_help, opts("Help"))
                Keymap("n", "D", api.fs.trash, opts("Trash"))
                Keymap("n", "f", api.live_filter.start, opts("Filter"))
                Keymap("n", "F", api.live_filter.clear, opts("Clean Filter"))
                Keymap("n", "i", api.tree.toggle_gitignore_filter, opts("Toggle Git Ignore"))
                Keymap("n", "P", api.node.navigate.parent, opts("Parent Directory"))
                Keymap("n", "R", api.tree.reload, opts("Refresh"))
                Keymap("n", "S", api.tree.search_node, opts("Search"))
                Keymap("n", "W", api.tree.collapse_all, opts("Collapse"))
                Keymap("n", "a", api.fs.create, opts("Create"))
                Keymap("n", "d", api.fs.remove, opts("Delete"))
                Keymap("n", "Y", api.fs.copy.absolute_path, opts("Copy Absolute Path"))
                Keymap("n", "h", api.tree.change_root_to_parent, opts("Up"))
                Keymap("n", "<leader>ho", api.node.show_info_popup, opts("Info"))
                Keymap("n", "m", api.fs.cut, opts("Cut"))
                Keymap("n", "p", api.fs.paste, opts("Paste"))
                Keymap("n", "q", api.tree.close, opts("Close"))
                Keymap("n", "r", api.fs.rename, opts("Rename"))
                Keymap("n", "s", api.node.open.horizontal, opts("Open: Horizontal Split"))
                Keymap("n", "v", api.node.open.vertical, opts("Open: Vertical Split"))
                Keymap("n", "y", api.fs.copy.node, opts("Copy"))
                Keymap("n", "l", api.tree.change_root_to_node, opts("CD"))
                Keymap("n", "<2-RightMouse>", api.tree.change_root_to_node, opts("CD"))
                Keymap("n", "<CR>", api.node.open.edit, opts("Open"))
                Keymap("n", "o", api.node.open.edit, opts("Open"))
                Keymap("n", "<2-LeftMouse>", api.node.open.edit, opts("Open"))
                Keymap("n", "O", api.node.open.no_window_picker, opts("Open: No Window Picker"))
            end

            require("nvim-tree").setup({
                on_attach = on_attach,
                hijack_cursor = true,
                reload_on_bufenter = true,
                respect_buf_cwd = true,
                update_focused_file = {
                    enable = true,
                },
                filters = {
                    git_ignored = false,
                },
                view = {
                    width = original_width,
                },
                renderer = {
                    highlight_opened_files = "all",
                    highlight_git = false,
                    group_empty = true,
                    indent_markers = {
                        enable = true,
                        icons = {
                            corner = "└ ",
                            edge = "│ ",
                            none = "  ",
                        },
                    },
                    icons = {
                        git_placement = "after",
                        show = {
                            git = true,
                            file = true,
                            folder = true,
                            folder_arrow = false,
                        },
                        glyphs = {
                            default = "",
                            symlink = "",
                            git = {
                                unstaged = "✗",
                                staged = "✓",
                                unmerged = "",
                                renamed = "➜",
                                untracked = "★",
                                deleted = "",
                                ignored = "◌",
                            },
                            folder = {
                                arrow_open = "",
                                arrow_closed = "",
                                default = "",
                                open = "",
                                empty = "",
                                empty_open = "",
                                symlink = "",
                                symlink_open = "",
                            },
                        },
                    },
                },
            })
        end,
    },

    -- Writing
    {
        "reedes/vim-litecorrect",
        config = function()
            Au("FileType", {
                group = AuGrp("litecorrect"),
                pattern = { "markdown", "mkd", "tex" },
                command = "call litecorrect#init()",
            })
        end,
    },
    { "reedes/vim-textobj-quote" },
    { "reedes/vim-textobj-sentence" },

    -- General programming
    {
        "scrooloose/nerdcommenter",
        config = function()
            vim.g.NERDCustomDelimiters = { razor = { left = "@* ", right = " *@" } }
            vim.g.NERDDefaultAlign = "none"
        end,
    },
    { "godlygeek/tabular" },
    {
        "HiPhish/rainbow-delimiters.nvim",
        config = function()
            require("rainbow-delimiters.setup").setup({
                strategy = {
                    [""] = "rainbow-delimiters.strategy.global",
                },
                query = {
                    [""] = "rainbow-delimiters",
                },
                priority = {
                    [""] = 110,
                },
                highlight = {
                    "RainbowDelimiterRed",
                    "RainbowDelimiterYellow",
                    "RainbowDelimiterBlue",
                    "RainbowDelimiterOrange",
                    "RainbowDelimiterGreen",
                    "RainbowDelimiterViolet",
                    "RainbowDelimiterCyan",
                },
            })
        end,
    },
    {
        "majutsushi/tagbar",
        cond = function()
            return vim.fn.executable("ctags") == 1
        end,
    },
    {
        "octol/vim-cpp-enhanced-highlight",
        config = function()
            vim.g.cpp_class_scope_highlight = 0
            vim.g.cpp_member_variable_highlight = 1
            vim.g.cpp_class_decl_highlight = 0
            vim.g.cpp_experimental_template_highlight = 1
            vim.g.cpp_concepts_highlight = 1
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        branch = treesitter_legacy and "master" or "main",
        build = function()
            if treesitter_legacy then
                vim.cmd(":TSUpdate")
                return
            end

            vim.fn.system({
                "npm",
                "install",
                "-g",
                "tree-sitter-cli",
            })
        end,
        config = function()
            local ensure_langs = { "vim", "python", "c_sharp" }
            local ensure_fts = { "vim", "python", "cs" }

            if not treesitter_legacy then
                local ts = require("nvim-treesitter")
                ts.setup({
                    install_dir = vim.fn.stdpath("data") .. "/site",
                })

                local group = AuGrp("TreesitterMain")
                Au("FileType", {
                    group = group,
                    pattern = "*",
                    callback = function(args)
                        if not Contains(ensure_fts, args.match) then
                            return
                        end
                        local lang = vim.treesitter.language.get_lang(args.match)
                        if not lang then
                            return
                        end
                        ts.install({ lang })
                        pcall(vim.treesitter.start, args.buf, lang)
                        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end,
                })

                local function set_ts_links()
                    SetHlLink("@function.builtin", "GruvboxAqua")
                end
                set_ts_links()
                Au("ColorScheme", {
                    group = group,
                    callback = set_ts_links,
                })
                return
            end

            local ok, configs = pcall(require, "nvim-treesitter.configs")
            if not ok then
                return
            end
            configs.setup({
                ensure_installed = ensure_langs,
                ignore_install = {},
                auto_install = true,
                highlight = {
                    enable = true,
                    disable = function(lang, _)
                        return not Contains(ensure_langs, lang)
                    end,
                    additional_vim_regex_highlighting = true,
                },
                indent = {
                    enable = true,
                    disable = function(lang, _)
                        return not Contains(ensure_langs, lang)
                    end,
                },
                incremental_selection = {
                    enable = true,
                    disable = {},
                    keymaps = {
                        init_selection = "vv",
                        node_decremental = "vd",
                        node_incremental = "vn",
                        scope_incremental = "vs",
                    },
                },
            })

            local function set_ts_links()
                SetHlLink("TSFuncBuiltin", "GruvboxAqua")
            end
            set_ts_links()
            Au("ColorScheme", {
                group = AuGrp("TSHighlight"),
                callback = set_ts_links,
            })
        end,
    },
    { "nvim-lua/plenary.nvim" },
    {
        "zbirenbaum/copilot.lua",
        config = function()
            local copilot_opts = {
                panel = { enabled = false },
                suggestion = {
                    enabled = true,
                    auto_trigger = true,
                    keymap = {
                        accept = "<C-f>",
                        next = "<C-j>",
                        prev = "<C-k>",
                    },
                },
                filetypes = {
                    gitcommit = vim.g.codex_commit_enabled and false or true,
                    ["."] = true,
                },
            }
            require("copilot").setup(copilot_opts)
            local ok_suggestion, suggestion = pcall(require, "copilot.suggestion")
            if ok_suggestion then
                Keymap("i", "<C-u>", function()
                    if suggestion.is_visible() then
                        suggestion.dismiss()
                        if vim.fn.pumvisible() == 1 then
                            return "<C-e>"
                        end
                        return ""
                    end
                    if vim.fn.pumvisible() == 1 then
                        return "<PageUp><C-p><C-n>"
                    end
                    return "<C-u>"
                end, { expr = true, silent = true })
            end
            SetHl("CopilotSuggestion", "#fa8072", nil) -- salmon
        end,
    },
    {
        "NickvanDyke/opencode.nvim",
        dependencies = {
            ---@module 'snacks'
            { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
        },
        config = function()
            ---@type opencode.Opts
            vim.g.opencode_opts = {}

            -- Required for `opts.events.reload`.
            vim.o.autoread = true

            Keymap({ "n", "x" }, "<C-a>",
                function() require("opencode").ask("@this: ", { submit = true }) end,
                { desc = "Ask opencode…" })
            Keymap({ "n", "x" }, "<leader>o<space>", function() require("opencode").select() end,
                { desc = "Execute opencode action…" })
            Keymap({ "n", "t" }, "<C-/>", function() require("opencode").toggle() end,
                { desc = "Toggle opencode" })
            Keymap({ "n", "x" }, "go", function() return require("opencode").operator("@this ") end,
                { desc = "Add range to opencode", expr = true })
        end,
    },
    {
        "jpalardy/vim-slime",
        config = function()
            vim.g.slime_cell_delimiter = "^\\s*##"
            --vim.g.slime_target = "tmux"
            --vim.g.slime_default_config = { socket_name = "default", target_pane = "{last}" }
            vim.g.slime_target = "kitty"
            local sockets = vim.fn.glob("/tmp/kitty-*.sock", true, true)
            if #sockets > 0 then
                local handle = sockets[1]
                vim.g.slime_default_config = { window_id = 0, listen_on = "unix:" .. handle }
            end

            vim.g.slime_dont_ask_default = 0
            vim.g.slime_bracketed_paste = 1
            vim.g.slime_no_mappings = 1

            -- Slime key mappings
            local opts = { silent = true }
            Keymap("v", "<C-j><C-e>", "<Plug>SlimeRegionSend", opts)
            Keymap("n", "<C-j><C-r>", "<Plug>SlimeParagraphSend", opts)
            Keymap("n", "<C-j><C-e>", "<Plug>SlimeCellsSend", opts)
            Keymap("n", "<C-j><C-S-e>", "<Plug>SlimeCellsSendAndGoToNext", opts)
            Keymap("n", "<C-j><C-j>", "<Plug>SlimeCellsNext", opts)
            Keymap("n", "<C-k><C-k>", "<Plug>SlimeCellsPrev", opts)
        end,
    },
    { "klafyvel/vim-slime-cells" },

    -- LSP and extensions
    {
        "neoclide/coc.nvim",
        branch = "release",
        config = function()
            vim.g.coc_global_extensions = { "coc-pairs", "coc-snippets", "coc-lists", "coc-json", "coc-pyright" }
            vim.opt.signcolumn = "yes"

            function ShowDocumentation()
                if vim.tbl_contains({ "vim", "help" }, vim.bo.filetype) then
                    vim.cmd("h " .. vim.fn.expand("<cword>"))
                else
                    vim.fn.CocAction("doHover")
                end
            end

            local function coc_key_mappings()
                local opts = { silent = true, expr = true }
                Keymap("i", "<CR>", "coc#pum#visible() ? coc#pum#confirm() : \"\\<C-g>u\\<CR>\"", opts)
                Keymap("i", "<Tab>", "coc#pum#visible() ? coc#pum#next(1) : \"\\<Tab>\"", opts)
                Keymap("i", "<S-Tab>", "coc#pum#visible() ? coc#pum#prev(1) : \"\\<S-Tab>\"", opts)
                Keymap("i", "<Down>", "coc#pum#visible() ? coc#pum#next(0) : \"\\<Down>\"", opts)
                Keymap("i", "<Up>", "coc#pum#visible() ? coc#pum#prev(0) : \"\\<Up>\"", opts)

                local nmap_opts = { silent = true }
                Keymap("n", "<leader>dl", "<Plug>(coc-definition)", nmap_opts)
                Keymap("n", "<leader>re", "<Plug>(coc-references)", nmap_opts)
                Keymap("n", "<leader>fi", "<Plug>(coc-fix-current)", nmap_opts)
                Keymap("x", "<leader>fo", "<Plug>(coc-format-selected)", nmap_opts)
                Keymap("n", "<leader>dd", "<Plug>(coc-diagnostic-info)", nmap_opts)
                Keymap("n", "<leader>im", "<Plug>(coc-implementation)", nmap_opts)
                Keymap("n", "<C-j>", "<Plug>(coc-diagnostic-next)", nmap_opts)
                Keymap("n", "<C-k>", "<Plug>(coc-diagnostic-prev)", nmap_opts)
                Keymap("n", "<leader>rn", "<Plug>(coc-rename)", nmap_opts)
                Keymap("n", "<leader>ra", "<Plug>(coc-refactor)", nmap_opts)
                Keymap("n", "<leader>fo", ":call CocAction('format')<CR>", nmap_opts)
                Keymap("n", "<leader>rs", ":CocRestart<CR><CR>", nmap_opts)
                Keymap("n", "<leader>ho", ShowDocumentation, nmap_opts)
                Keymap("n", "<leader>da", ":<C-u>CocList diagnostics<CR>", nmap_opts)
                Keymap("n", "<leader>b<space>", ":CocList buffers<CR>", nmap_opts)
            end

            local coc_augrp = AuGrp("coc_user_defined")
            Au("FileType", {
                group = coc_augrp,
                pattern = "*",
                callback = function()
                    vim.fn["deoplete#disable"]()
                    coc_key_mappings()
                end,
            })
            Au("CursorHold", {
                group = coc_augrp,
                pattern = "*.cs",
                command = "silent call CocActionAsync('highlight')",
            })
            Au("FileType", {
                group = coc_augrp,
                pattern = "tex",
                callback = function()
                    vim.b.coc_pairs = { { "$", "$" } }
                end,
            })
        end,
    },
    {
        "honza/vim-snippets",
        config = function()
            local support = vim.api.nvim_get_runtime_file("snippets/support_functions.vim", false)
            if #support > 0 then
                vim.cmd("source " .. support[1])
            end
        end,
    },
    { "SirVer/ultisnips" },
    { "neovim/nvim-lspconfig" },
    {
        "Shougo/deoplete.nvim",
        build = ":UpdateRemotePlugins",
    },
    { "deoplete-plugins/deoplete-lsp" },

    -- Misc
    { "Konfekt/FastFold" },
    {
        "lukas-reineke/indent-blankline.nvim",
        config = function()
            require("ibl").update({
                enabled = true,
                indent = { char = "│" },
                exclude = {
                    filetypes = { "defx", "NvimTree", "startify" },
                    buftypes = { "help", "terminal", "nofile", "quickfix", "prompt" },
                },
                scope = {
                    enabled = true,
                    show_start = false,
                    show_end = false,
                },
            })
            vim.g.indent_blankline_show_first_indent_level = false
            vim.g.indent_blankline_show_trailing_blankline_indent = false
        end,
    },
    {
        "airblade/vim-rooter",
        config = function()
            vim.g.rooter_targets = "Projects/,Course Work/,*"
            vim.g.rooter_patterns = { ".git/" }
            vim.g.rooter_change_directory_for_non_project_files = "current"
            vim.g.rooter_silent_chdir = 1
            vim.g.rooter_resolve_links = 1
        end,
    },
    {
        "christoomey/vim-tmux-navigator",
        config = function()
            vim.g.tmux_navigator_no_mappings = 1
            vim.g.tmux_navigator_disable_when_zoomed = 1
            Keymap("n", "˙", ":TmuxNavigateLeft<CR>", { silent = true })
            Keymap("n", "∆", ":TmuxNavigateDown<CR>", { silent = true })
            Keymap("n", "˚", ":TmuxNavigateUp<CR>", { silent = true })
            Keymap("n", "¬", ":TmuxNavigateRight<CR>", { silent = true })
            Keymap("n", "«", ":TmuxNavigatePrevious<CR>", { silent = true })
        end,
    },
    {
        "mhinz/vim-startify",
        config = function()
            local version_string = vim.api.nvim_exec("version", true)
            local ver = version_string:match("NVIM v([0-9%.]+)") or "unknown"
            ver = "v" .. ver

            vim.g.startify_custom_header = {
                [[                                                                         ]],
                [[                                                                         ]],
                [[       ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗                ]],
                [[       ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║                ]],
                [[       ██╔██╗ ██║█████╗  ██║   ██║ ██║ ██║ ██║██╔████╔██║                ]],
                [[       ██║╚██╗██║██╔══╝  ██║   ██║ ██║ ██║ ██║██║╚██╔╝██║                ]],
                [[       ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║                ]],
                [[       ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝  ]] ..
                ver,
                [[                                                                         ]],
                [[                                                                         ]],
            }
            vim.g.startify_session_dir = vim.fn.expand("~/.vim/sessions")
            vim.g.startify_files_number = 6
            vim.g.startify_list_order = {
                { "   Sessions:" },
                "sessions",
                { "   MRU files in the current directory:" },
                "dir",
                { "   MRU files:" },
                "files",
                { "   Bookmarks:" },
                "bookmarks",
            }
            vim.g.startify_bookmarks = {
                { i = "~/.config/nvim/init.lua" },
                { p = "~/.config/nvim/lua/plugins.lua" },
                { b = "~/.vim/vimrc.bundles" },
            }
            vim.g.startify_update_oldfiles = 1
            vim.g.startify_disable_at_vimenter = 0
            vim.g.startify_session_autoload = 1
            vim.g.startify_session_persistence = 1
            vim.g.startify_change_to_dir = 0
            vim.g.startify_skiplist = {
                "COMMIT_EDITMSG",
                vim.fn.escape(vim.fn.fnamemodify(vim.fn.resolve(vim.env.VIMRUNTIME), ":p"), "\\") .. "doc",
                "bundle/.*/doc",
            }
            Au("FileType", {
                pattern = "startify",
                callback = function()
                    Keymap("n", "<F2>", "<Nop>", { buffer = true })
                    vim.opt_local.wrap = false
                end,
            })
        end,
    },
    { "spf13/vim-preview" },
    { "tpope/vim-markdown" },
    {
        "dyng/ctrlsf.vim",
        config = function()
            vim.g.ctrlsf_auto_focus = { at = "start" }
            vim.g.ctrlsf_position = "bottom"
            vim.g.ctrlsf_winsize = "40%"
            vim.g.ctrlsf_confirm_save = 0

            Keymap("n", "SF", "<Plug>CtrlSFPrompt", {})
            Keymap("v", "SF", "<Plug>CtrlSFVwordExec", {})
        end,
    },
}, {
    defaults = { lazy = false },
})
