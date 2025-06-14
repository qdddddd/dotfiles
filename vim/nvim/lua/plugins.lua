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
    vim.keymap.set('n', '<leader>sl', ':SessionList<CR>', { noremap = true, silent = true })
    vim.keymap.set('n', '<leader>ss', ':SessionSave<CR>', { noremap = true, silent = true })
    vim.keymap.set('n', '<leader>sc', ':SessionClose<CR>', { noremap = true, silent = true })
end

if ExistsBundle("vim-startify") then
    local version_string = vim.api.nvim_exec('version', true)
    local ver = version_string:match('NVIM v([0-9%.]+)') or 'unknown'
    ver = 'v' .. ver

    vim.g.startify_custom_header = {
        '                                                                         ',
        '                                                                         ',
        '       ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗                ',
        '       ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║                ',
        '       ██╔██╗ ██║█████╗  ██║   ██║ ██║ ██║ ██║██╔████╔██║                ',
        '       ██║╚██╗██║██╔══╝  ██║   ██║ ██║ ██║ ██║██║╚██╔╝██║                ',
        '       ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║                ',
        '       ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝  ' .. ver .. ' ',
        '                                                                         ',
        '                                                                         ',
    }
    vim.g.startify_session_dir = vim.fn.expand("~/.vim/sessions")
    vim.g.startify_files_number = 6
    vim.g.startify_list_order = {
        { '   MRU files in the current directory:' },
        'dir',
        { '   MRU files:' },
        'files',
        { '   Sessions:' },
        'sessions',
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
    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'startify',
        callback = function()
            vim.keymap.set('n', '<F2>', '<Nop>', { buffer = true })
            vim.opt_local.wrap = false
        end,
    })
end

if ExistsBundle("vim-tmux-navigator") then
    vim.g.tmux_navigator_no_mappings = 1
    vim.g.tmux_navigator_disable_when_zoomed = 1
    vim.keymap.set('n', '˙', ':TmuxNavigateLeft<CR>', { silent = true })
    vim.keymap.set('n', '∆', ':TmuxNavigateDown<CR>', { silent = true })
    vim.keymap.set('n', '˚', ':TmuxNavigateUp<CR>', { silent = true })
    vim.keymap.set('n', '¬', ':TmuxNavigateRight<CR>', { silent = true })
    vim.keymap.set('n', '«', ':TmuxNavigatePrevious<CR>', { silent = true })
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
    require 'nvim-treesitter.configs'.setup {
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

if ExistsBundle("nvim-tree.lua") then
    local width_perc = 0.2
    local original_width = math.floor(vim.o.columns * width_perc)

    function NvimTreeToggleWidth()
        local max = vim.fn.MaxLineLength()
        local new = (max == vim.fn.winwidth(0)) and original_width or max
        vim.cmd('NvimTreeResize ' .. new)
    end

    Map("n", "<leader>e", "<Cmd>NvimTreeFindFileToggle<CR>", { noremap = true, silent = true })

    vim.cmd([[ au! BufEnter NvimTree_* nnoremap <silent> <buffer> w :lua NvimTreeToggleWidth()<CR> ]])

    local function on_attach(bufnr)
        local api = require 'nvim-tree.api'

        local function opts(desc)
            return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        vim.keymap.set('n', '.', api.tree.toggle_hidden_filter, opts('Toggle Dotfiles'))
        vim.keymap.set('n', '<BS>', api.node.navigate.parent_close, opts('Close Directory'))
        vim.keymap.set('n', '<C-j>', api.node.navigate.sibling.next, opts('Next Sibling'))
        vim.keymap.set('n', '<C-k>', api.node.navigate.sibling.prev, opts('Previous Sibling'))
        vim.keymap.set('n', '<Tab>', api.node.open.preview, opts('Open Preview'))
        vim.keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
        vim.keymap.set('n', 'D', api.fs.trash, opts('Trash'))
        vim.keymap.set('n', 'f', api.live_filter.start, opts('Filter'))
        vim.keymap.set('n', 'F', api.live_filter.clear, opts('Clean Filter'))
        vim.keymap.set('n', 'i', api.tree.toggle_gitignore_filter, opts('Toggle Git Ignore'))
        vim.keymap.set('n', 'P', api.node.navigate.parent, opts('Parent Directory'))
        vim.keymap.set('n', 'R', api.tree.reload, opts('Refresh'))
        vim.keymap.set('n', 'S', api.tree.search_node, opts('Search'))
        vim.keymap.set('n', 'W', api.tree.collapse_all, opts('Collapse'))
        vim.keymap.set('n', 'a', api.fs.create, opts('Create'))
        vim.keymap.set('n', 'd', api.fs.remove, opts('Delete'))
        vim.keymap.set('n', 'Y', api.fs.copy.absolute_path, opts('Copy Absolute Path'))
        vim.keymap.set('n', 'h', api.tree.change_root_to_parent, opts('Up'))
        vim.keymap.set('n', '<leader>ho', api.node.show_info_popup, opts('Info'))
        vim.keymap.set('n', 'm', api.fs.cut, opts('Cut'))
        vim.keymap.set('n', 'p', api.fs.paste, opts('Paste'))
        vim.keymap.set('n', 'q', api.tree.close, opts('Close'))
        vim.keymap.set('n', 'r', api.fs.rename, opts('Rename'))
        vim.keymap.set('n', 's', api.node.open.horizontal, opts('Open: Horizontal Split'))
        vim.keymap.set('n', 'v', api.node.open.vertical, opts('Open: Vertical Split'))
        vim.keymap.set('n', 'y', api.fs.copy.node, opts('Copy'))
        vim.keymap.set('n', 'l', api.tree.change_root_to_node, opts('CD'))
        vim.keymap.set('n', '<2-RightMouse>', api.tree.change_root_to_node, opts('CD'))
        vim.keymap.set('n', '<CR>', api.node.open.edit, opts('Open'))
        vim.keymap.set('n', 'o', api.node.open.edit, opts('Open'))
        vim.keymap.set('n', '<2-LeftMouse>', api.node.open.edit, opts('Open'))
        vim.keymap.set('n', 'O', api.node.open.no_window_picker, opts('Open: No Window Picker'))
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
            TelescopePrompt = 'Telescope',
            dashboard = 'Dashboard',
            packer = 'Packer',
            fzf = 'FZF',
            alpha = 'Alpha',
            NvimTree = 'E',
            startify = 'Startify',
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
            theme = gb
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

    local opts = { noremap = true, silent = true }
    Map('n', '<leader>1', '<Cmd>LualineBuffersJump 1<CR>', opts)
    Map('n', '<leader>2', '<Cmd>LualineBuffersJump 2<CR>', opts)
    Map('n', '<leader>3', '<Cmd>LualineBuffersJump 3<CR>', opts)
    Map('n', '<leader>4', '<Cmd>LualineBuffersJump 4<CR>', opts)
    Map('n', '<leader>5', '<Cmd>LualineBuffersJump 5<CR>', opts)
    Map('n', '<leader>6', '<Cmd>LualineBuffersJump 6<CR>', opts)
    Map('n', '<leader>7', '<Cmd>LualineBuffersJump 7<CR>', opts)
    Map('n', '<leader>8', '<Cmd>LualineBuffersJump 8<CR>', opts)
    Map('n', '<leader>9', '<Cmd>LualineBuffersJump 9<CR>', opts)
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

    local coc_augrp = vim.api.nvim_create_augroup("coc_user_defined", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = coc_augrp,
        pattern = "*",
        callback = function()
            vim.fn["deoplete#disable"]()
            coc_key_mappings()
        end
    })
    vim.api.nvim_create_autocmd("CursorHold", {
        group = coc_augrp,
        pattern = "*.cs",
        command = "silent call CocActionAsync('highlight')",
    })
    vim.api.nvim_create_autocmd("FileType", {
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
    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("litecorrect", { clear = true }),
        pattern = { "markdown", "mkd", "tex" },
        callback = function()
            vim.cmd("call litecorrect#init()")
        end
    })
end

if ExistsBundle("nerdcommenter") then
    vim.g.NERDCustomDelimiters = { razor = { left = '@* ', right = ' *@' } }
    vim.g.NERDDefaultAlign = 'none'
end

if ExistsBundle("copilot.vim") then
    vim.g.copilot_no_tab_map = true
    local opts = { silent = true, expr = true, script = true }
    Keymap("i", "<C-F>", 'copilot#Accept("\\<CR>")', opts)
    Keymap("i", "<C-J>", "copilot#Next()", opts)
    Keymap("i", "<C-K>", "copilot#Previous()", opts)
    SetHl("CopilotSuggestion", "#fa8072", nil)
end

if ExistsBundle("vim-slime") then
    vim.g.slime_target = "tmux"
    vim.g.slime_cell_delimiter = "^\\s*##"
    vim.g.slime_default_config = {
        socket_name = vim.fn.get(vim.fn.split(vim.fn.getenv("TMUX"), ","), 0),
        target_pane = ":.2"
    }
    vim.g.slime_dont_ask_default = 0
    vim.g.slime_bracketed_paste = 1
    vim.g.slime_no_mappings = 1

    -- Slime key mappings
    local opts = { silent = true }
    vim.keymap.set("v", "<C-j><C-e>", "<Plug>SlimeRegionSend", opts)
    vim.keymap.set("n", "<C-j><C-r>", "<Plug>SlimeParagraphSend", opts)
    vim.keymap.set("n", "<C-j><C-e>", "<Plug>SlimeCellsSend", opts)
    vim.keymap.set("n", "<C-j><C-S-e>", "<Plug>SlimeCellsSendAndGoToNext", opts)
    vim.keymap.set("n", "<C-j><C-j>", "<Plug>SlimeCellsNext", opts)
    vim.keymap.set("n", "<C-k><C-k>", "<Plug>SlimeCellsPrev", opts)
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
