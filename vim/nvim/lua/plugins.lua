require("utils")

local BUNDLE_DIR = HOME .. "/.vim/bundle/"

local function ExistsBundle(file)
    return Exists(BUNDLE_DIR .. file)
end

--- Configure plugs ---
if ExistsBundle("matchit.zip") then
    vim.b.match_ignorecase = 1
end

if ExistsBundle("vim-rooter") then
    vim.g.rooter_targets = 'Projects/,Course Work/,*'
    vim.g.rooter_patterns = { '.git/' }
    vim.g.rooter_change_directory_for_non_project_files = 'current'
    vim.g.rooter_silent_chdir = 1
    vim.g.rooter_resolve_links = 1
end

if ExistsBundle("sessionman.vim") then
    vim.o.sessionoptions = 'blank,buffers,curdir,folds,tabpages,winsize'
    Keymap('n', '<leader>sl', ':SessionList<CR>', { noremap = true, silent = true })
    Keymap('n', '<leader>ss', ':SessionSave<CR>', { noremap = true, silent = true })
    Keymap('n', '<leader>sc', ':SessionClose<CR>', { noremap = true, silent = true })
end

if ExistsBundle("vim-startify") then
    local version_string = vim.api.nvim_exec('version', true)
    local ver = version_string:match('NVIM v([0-9%.]+)') or 'unknown'
    ver = 'v' .. ver

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
        { '   Sessions:' },
        'sessions',
        { '   MRU files in the current directory:' },
        'dir',
        { '   MRU files:' },
        'files',
        { '   Bookmarks:' },
        'bookmarks',
    }
    vim.g.startify_bookmarks = {
        { i = '~/.config/nvim/init.lua' },
        { p = '~/.config/nvim/lua/plugins.lua' },
        { b = '~/.vim/vimrc.bundles' },
    }
    vim.g.startify_update_oldfiles = 1
    vim.g.startify_disable_at_vimenter = 0
    vim.g.startify_session_autoload = 1
    vim.g.startify_session_persistence = 1
    vim.g.startify_change_to_dir = 0
    vim.g.startify_skiplist = {
        'COMMIT_EDITMSG',
        vim.fn.escape(vim.fn.fnamemodify(vim.fn.resolve(vim.env.VIMRUNTIME), ':p'), '\\') .. 'doc',
        'bundle/.*/doc',
    }
    Au('FileType', {
        pattern = 'startify',
        callback = function()
            Keymap('n', '<F2>', '<Nop>', { buffer = true })
            vim.opt_local.wrap = false
        end,
    })
end

if ExistsBundle("vim-tmux-navigator") then
    vim.g.tmux_navigator_no_mappings = 1
    vim.g.tmux_navigator_disable_when_zoomed = 1
    Keymap('n', '˙', ':TmuxNavigateLeft<CR>', { silent = true })
    Keymap('n', '∆', ':TmuxNavigateDown<CR>', { silent = true })
    Keymap('n', '˚', ':TmuxNavigateUp<CR>', { silent = true })
    Keymap('n', '¬', ':TmuxNavigateRight<CR>', { silent = true })
    Keymap('n', '«', ':TmuxNavigatePrevious<CR>', { silent = true })
end

if ExistsBundle("indent-blankline.nvim") then
    require('ibl').update {
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
    }
    vim.g.indent_blankline_show_first_indent_level = false
    vim.g.indent_blankline_show_trailing_blankline_indent = false
end

if ExistsBundle("nvim-treesitter") then
    local ok, ts_configs = pcall(require, "nvim-treesitter.configs")
    if not ok then
        ok, ts_configs = pcall(require, "nvim-treesitter.config")
    end
    if ok then
        ts_configs.setup {
            ensure_installed = { "vim", "python" }, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
            ignore_install = {},                    -- List of parsers to ignore installing
            highlight = {
                enable = true,                      -- false will disable the whole extension
                disable = {},                       -- list of language that will be disabled
                additional_vim_regex_highlighting = false,
            },
            indent = {
                enable = true,
                disable = {},
            },
            incremental_selection = {
                enable = true,
                disable = {},
                keymaps = {
                    init_selection = "vv",
                    node_decremental = "vd",
                    node_incremental = "vn",
                    scope_incremental = "vs"
                },
            },
        }

        SetHlLink("TSFuncBuiltin", "GruvboxAqua")
    end
end

if ExistsBundle("nvim-tree.lua") then
    local width_perc = 0.2
    local original_width = math.floor(vim.o.columns * width_perc)

    Keymap("n", "<leader>e", "<Cmd>NvimTreeFindFileToggle<CR>", { silent = true })

    Au("BufEnter", {
        desc = "NvimTree: Toggle width on 'w' key",
        pattern = "NvimTree_*",
        callback = function(args)
            Keymap(
                'n',
                'w',
                function()
                    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                    local max_len = 0
                    for _, line in ipairs(lines) do
                        max_len = math.max(max_len, #line)
                    end
                    local new = (max_len == vim.fn.winwidth(0)) and original_width or max_len
                    vim.cmd('NvimTreeResize ' .. new)
                end,
                { buffer = args.buf }
            )
        end
    })

    local function on_attach(bufnr)
        local api = require 'nvim-tree.api'

        local function opts(desc)
            return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, silent = true, nowait = true }
        end

        Keymap('n', '.', api.tree.toggle_hidden_filter, opts('Toggle Dotfiles'))
        Keymap('n', '<BS>', api.node.navigate.parent_close, opts('Close Directory'))
        Keymap('n', '<C-j>', api.node.navigate.sibling.next, opts('Next Sibling'))
        Keymap('n', '<C-k>', api.node.navigate.sibling.prev, opts('Previous Sibling'))
        Keymap('n', '<Tab>', api.node.open.preview, opts('Open Preview'))
        Keymap('n', '?', api.tree.toggle_help, opts('Help'))
        Keymap('n', 'D', api.fs.trash, opts('Trash'))
        Keymap('n', 'f', api.live_filter.start, opts('Filter'))
        Keymap('n', 'F', api.live_filter.clear, opts('Clean Filter'))
        Keymap('n', 'i', api.tree.toggle_gitignore_filter, opts('Toggle Git Ignore'))
        Keymap('n', 'P', api.node.navigate.parent, opts('Parent Directory'))
        Keymap('n', 'R', api.tree.reload, opts('Refresh'))
        Keymap('n', 'S', api.tree.search_node, opts('Search'))
        Keymap('n', 'W', api.tree.collapse_all, opts('Collapse'))
        Keymap('n', 'a', api.fs.create, opts('Create'))
        Keymap('n', 'd', api.fs.remove, opts('Delete'))
        Keymap('n', 'Y', api.fs.copy.absolute_path, opts('Copy Absolute Path'))
        Keymap('n', 'h', api.tree.change_root_to_parent, opts('Up'))
        Keymap('n', '<leader>ho', api.node.show_info_popup, opts('Info'))
        Keymap('n', 'm', api.fs.cut, opts('Cut'))
        Keymap('n', 'p', api.fs.paste, opts('Paste'))
        Keymap('n', 'q', api.tree.close, opts('Close'))
        Keymap('n', 'r', api.fs.rename, opts('Rename'))
        Keymap('n', 's', api.node.open.horizontal, opts('Open: Horizontal Split'))
        Keymap('n', 'v', api.node.open.vertical, opts('Open: Vertical Split'))
        Keymap('n', 'y', api.fs.copy.node, opts('Copy'))
        Keymap('n', 'l', api.tree.change_root_to_node, opts('CD'))
        Keymap('n', '<2-RightMouse>', api.tree.change_root_to_node, opts('CD'))
        Keymap('n', '<CR>', api.node.open.edit, opts('Open'))
        Keymap('n', 'o', api.node.open.edit, opts('Open'))
        Keymap('n', '<2-LeftMouse>', api.node.open.edit, opts('Open'))
        Keymap('n', 'O', api.node.open.no_window_picker, opts('Open: No Window Picker'))
    end

    require 'nvim-tree'.setup {
        on_attach = on_attach,
        hijack_cursor = true,
        reload_on_bufenter = true,
        respect_buf_cwd = true,
        update_focused_file = {
            enable = true,
        },
        view = {
            width = original_width
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
                    folder_arrow = false
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
                        ignored = "◌"
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
                    }
                }
            },
        }
    }
end

if ExistsBundle("lualine.nvim") then
    local buffer_section = {
        'buffers',
        show_filename_only = false,
        icons_enabled = false,
        mode = 2,
        use_mode_colors = false,
        max_length = vim.o.columns - 6,
        buffers_color = {
            active = { fg = 'bg', bg = '#076678' },
            inactive = { fg = '#7c6f64' },
        },
        symbols = {
            modified = ' ●',
            alternate_file = '',
            directory = '',
        },
        separator = "|",
        padding = 1,
        filetype_names = {
            fzf = 'search',
            NvimTree = 'tree',
            startify = 'start.dev',
        },
        fmt = function(str)
            -- Displays buffers with unique names, or parent directory if duplicates exist --
            if str == '' then return '' end -- Handle unnamed buffers like [No Name]

            -- Count occurrences of each filename across all listed buffers
            local filename_counts = {}
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if vim.bo[bufnr].buflisted then
                    local buf_name = vim.api.nvim_buf_get_name(bufnr)
                    if buf_name ~= '' then
                        local filename = vim.fn.fnamemodify(buf_name, ':t')
                        filename_counts[filename] = (filename_counts[filename] or 0) + 1
                    end
                end
            end

            local filename = vim.fn.fnamemodify(str, ':t') -- of the current buffer being processed

            if filename_counts[filename] and filename_counts[filename] > 1 then
                -- It's a duplicate: show "parent_directory/filename"
                local dirname = vim.fn.fnamemodify(str, ':p:h:t')

                if dirname == '.' or dirname == '' then
                    -- Avoid showing './filename' for files in the cwd or '/' for root
                    return filename
                end
                return dirname .. '/' .. filename
            else
                -- It's unique: show just the filename
                return filename
            end
        end
    }

    local gb = require 'lualine.themes.gruvbox_light'

    require('lualine').setup {
        options = {
            --section_separators = { left = '', right = '' },
            --component_separators = { left = '|', right = '|' },
            section_separators = { left = '', right = '' },
            component_separators = { left = '', right = '' },
            always_show_tabline = true,
            globalstatus = false,
            disabled_filetypes = {
                statusline = { 'startify', 'defx' },
                winbar = { 'NvimTree', 'startify', 'defx', 'fugitive', 'fugitiveblame', 'help' },
            },
            theme = gb,
        },
        sections = {
            lualine_a = { 'mode' },
            lualine_b = { 'branch', 'diff' },
            lualine_c = { { 'filename', newfile_status = true, path = 1 } },
            lualine_x = { 'diagnostics', 'progress', 'location' },
            lualine_y = { 'filetype' },
            lualine_z = { 'lsp_status' },
        },
        inactive_sections = {
            lualine_a = {},
            lualine_b = { { 'filename', newfile_status = true, path = 3 } },
            lualine_c = { 'diagnostics' },
            lualine_x = {},
            lualine_y = {},
            lualine_z = {}
        },
        tabline = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = { buffer_section },
            lualine_z = { 'tabs' }
        },
        extensions = { 'nvim-tree', 'quickfix', 'fugitive', 'fzf' }
    }

    local opts = { silent = true }
    Keymap('n', '<leader>1', '<Cmd>LualineBuffersJump 1<CR>', opts)
    Keymap('n', '<leader>2', '<Cmd>LualineBuffersJump 2<CR>', opts)
    Keymap('n', '<leader>3', '<Cmd>LualineBuffersJump 3<CR>', opts)
    Keymap('n', '<leader>4', '<Cmd>LualineBuffersJump 4<CR>', opts)
    Keymap('n', '<leader>5', '<Cmd>LualineBuffersJump 5<CR>', opts)
    Keymap('n', '<leader>6', '<Cmd>LualineBuffersJump 6<CR>', opts)
    Keymap('n', '<leader>7', '<Cmd>LualineBuffersJump 7<CR>', opts)
    Keymap('n', '<leader>8', '<Cmd>LualineBuffersJump 8<CR>', opts)
    Keymap('n', '<leader>9', '<Cmd>LualineBuffersJump 9<CR>', opts)
end

if ExistsBundle("coc.nvim") then
    vim.g.coc_config_home = vim.fn.expand("~/.vim")
    vim.g.coc_global_extensions = { "coc-pairs", "coc-snippets", "coc-lists", "coc-json" }
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
        end
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
end

if vim.fn.executable("fzf") == 1 then
    vim.opt.rtp:append("~/.fzf")
    vim.g.fzf_colors = {
        fg      = { "fg", "Normal" },
        bg      = { "bg", "Normal" },
        hl      = { "fg", "Comment" },
        ["fg+"] = { "fg", "CursorLine", "CursorColumn", "Normal" },
        ["bg+"] = { "bg", "CursorLine", "CursorColumn" },
        ["hl+"] = { "fg", "Statement" },
        info    = { "fg", "PreProc" },
        border  = { "fg", "Ignore" },
        prompt  = { "fg", "Conditional" },
        pointer = { "fg", "Exception" },
        marker  = { "fg", "Keyword" },
        spinner = { "fg", "Label" },
        header  = { "fg", "Comment" },
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

if ExistsBundle("vim-cpp-enhanced-highlight") then
    vim.g.cpp_class_scope_highlight = 0
    vim.g.cpp_member_variable_highlight = 1
    vim.g.cpp_class_decl_highlight = 0
    vim.g.cpp_experimental_template_highlight = 1
    vim.g.cpp_concepts_highlight = 1
end

if ExistsBundle("ctrlsf.vim") then
    vim.g.ctrlsf_auto_focus = { at = "start" }
    vim.g.ctrlsf_position = 'bottom'
    vim.g.ctrlsf_winsize = '40%'
    vim.g.ctrlsf_confirm_save = 0

    Keymap("n", "SF", "<Plug>CtrlSFPrompt", {})
    Keymap("v", "SF", "<Plug>CtrlSFVwordExec", {})
end

if ExistsBundle("vim-litecorrect") then
    Au("FileType", {
        group = AuGrp("litecorrect"),
        pattern = { "markdown", "mkd", "tex" },
        command = "call litecorrect#init()"
    })
end

if ExistsBundle("nerdcommenter") then
    vim.g.NERDCustomDelimiters = { razor = { left = '@* ', right = ' *@' } }
    vim.g.NERDDefaultAlign = 'none'
end

if ExistsBundle("copilot.vim") then
    vim.g.copilot_no_tab_map = true
    local opts = { silent = true, expr = true, replace_keycodes = false }
    Keymap('i', '<C-f>', 'copilot#Accept("\\<CR>")', opts)
    Keymap("i", "<C-j>", "copilot#Next()", opts)
    Keymap("i", "<C-k>", "copilot#Previous()", opts)
    SetHl("CopilotSuggestion", "#fa8072", nil) -- salmon
end

if ExistsBundle("vim-slime") then
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
end

if ExistsBundle("rainbow_parentheses.vim") then
    vim.g["rainbow#pairs"] = { { '(', ')' }, { '[', ']' }, { '{', '}' }, { '<', '>' }, { '"', '"' }, { "'", "'" } }
end

if ExistsBundle("rainbow-delimiters.nvim") then
    require('rainbow-delimiters.setup').setup {
        strategy = {
            [''] = 'rainbow-delimiters.strategy.global',
        },
        query = {
            [''] = 'rainbow-delimiters',
        },
        priority = {
            [''] = 110,
        },
        highlight = {
            'RainbowDelimiterRed',
            'RainbowDelimiterYellow',
            'RainbowDelimiterBlue',
            'RainbowDelimiterOrange',
            'RainbowDelimiterGreen',
            'RainbowDelimiterViolet',
            'RainbowDelimiterCyan',
        },
    }
end
