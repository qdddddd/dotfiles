function Exists(file)
    -- Check if a file or directory exists in this path
    local ok, _, code = os.rename(file, file)
    if not ok then
        if code == 13 then
            -- Permission denied, but it exists
            return true
        end
    end
    return ok
end

function IsDir(path)
    -- Check if a directory exists in this path
    return Exists(path .. "/") -- "/" works on both Unix and Windows
end

local BUNDLE_DIR = os.getenv("HOME") .. "/.vim/bundle/"
local map = vim.api.nvim_set_keymap
local set_hl = function(name, fg, bg)
    local settings = {}
    if fg then settings.foreground = fg end
    if bg then settings.background = bg end
    vim.api.nvim_set_hl(0, name, settings)
end
local set_hl_link = function(name, linkto) vim.api.nvim_set_hl(0, name, { link = linkto, default = false }) end
local get_hl = function(name) return vim.api.nvim_get_hl_by_name(name, true) end

--- Configure LSP ---
require 'lspconfig'.csharp_ls.setup {
    cmd = { 'csharp-ls', '--loglevel', 'log' },
    filetypes = { "cs" },
    init_options = {
        AutomaticWorkspaceInit = true
    },
    root_dir = function(_, _)
        return vim.fs.dirname(
            vim.fs.find(
                function(name)
                    return name:match('.*%.sln$')
                end,
                { upward = true, limit = math.huge, type = 'file' }
            )[1]
        )
    end,
    single_file_support = true,
}

vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', { clear = true }),
    pattern = "*.cs",
    callback = function(args)
        vim.api.nvim_del_augroup_by_id(vim.api.nvim_create_augroup('coc_user_defined', { clear = true }))
        vim.cmd([[ CocDisable ]])

        -- Keymappings
        local opts = { buffer = args.buf }
        vim.keymap.set('n', '<leader>ho', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<leader>fo', function() vim.lsp.buf.format { async = true } end, opts)
        vim.keymap.set('n', '<leader>fi', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '<leader>dl', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', '<leader>re', vim.lsp.buf.references, opts)
        vim.keymap.set('n', '<leader>im', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>da', vim.diagnostic.setloclist, { noremap = true, silent = true })
        vim.keymap.set(
            'n', '<C-j>',
            function() if vim.fn.ListVisible() == 0 then vim.diagnostic.goto_next() else vim.cmd('cnext') end end,
            { noremap = true, silent = true }
        )
        vim.keymap.set(
            'n', '<C-k>',
            function() if vim.fn.ListVisible() == 0 then vim.diagnostic.goto_prev() else vim.cmd('cprevious') end end,
            { noremap = true, silent = true }
        )

        -- Diagnostics
        local signs = {
            { name = "DiagnosticSignError", text = "✗", severity = vim.diagnostic.severity.ERROR },
            { name = "DiagnosticSignWarn",  text = "▲", severity = vim.diagnostic.severity.WARN },
            { name = "DiagnosticSignHint",  text = "◇", severity = vim.diagnostic.severity.HINT },
            { name = "DiagnosticSignInfo",  text = "●", severity = vim.diagnostic.severity.INFO },
        }

        for _, sign in ipairs(signs) do
            vim.fn.sign_define(sign.name, { text = sign.text, texthl = sign.name, numhl = sign.name })
        end

        local function sign_mappings(name)
            local ret = {}
            for _, sign in ipairs(signs) do
                ret[sign.severity] = sign[name]
            end
            return ret
        end

        vim.diagnostic.config({
            virtual_text = false,
            signs = {
                text = sign_mappings("text"),
                numhl = sign_mappings("name"),
            },
            underline = true,
            update_in_insert = false,
            severity_sort = true,
            float = {
                scope = "line",
                focusable = true,
                source = "always",
                border = nil,
                header = "",
                prefix = "",
                max_width = 90,
                wrap = true
            },
        })

        set_hl_link("NormalFloat", "Fmenu")
        set_hl("DiagnosticError", get_hl("GruvboxRed").foreground, nil)
        set_hl("DiagnosticWarn", get_hl("GruvboxYellowSign").foreground, nil)
        set_hl("DiagnosticHint", get_hl("GruvboxYellowSign").foreground, nil)
        set_hl("DiagnosticInfo", get_hl("GruvboxAquaSign").foreground, nil)
        set_hl("FloatBorder", get_hl("VertSplit").foreground, get_hl("Fmenu").background)
        set_hl_link("@lsp.type.namespace", "GruvboxAqua")
        set_hl_link("DiagnosticFloatingError", "DiagnosticError")
        set_hl_link("DiagnosticFloatingWarn", "DiagnosticWarn")
        set_hl_link("DiagnosticFloatingHint", "DiagnosticHint")
        set_hl_link("DiagnosticFloatingInfo", "DiagnosticInfo")

        -- Signatures
        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
            vim.lsp.handlers.signature_help, {
                border = nil,
                max_width = 90,
                focusable = false,
            }
        )
        vim.api.nvim_create_autocmd({ "CursorHoldI" }, {
            group = vim.api.nvim_create_augroup("CsLspSignature", {}),
            pattern = "*.cs",
            callback = function(_) vim.lsp.buf.signature_help() end
        })

        -- Completion
        vim.g['deoplete#lsp#handler_enabled'] = true
        vim.g['deoplete#lsp#use_icons_for_candidates'] = true
        vim.fn['deoplete#custom#option']({
            num_processes = -1,
        })
        vim.fn['deoplete#custom#source']('_', {
            min_pattern_length = 1,
            smart_case = true,
            show_docstring = 1,
        })
        vim.fn['deoplete#custom#source']('lsp', {
            show_docstring = 1,
        })
        vim.fn['deoplete#enable']()
        vim.fn['deoplete#lsp#enable']()
        local o = { noremap = true, silent = true, expr = true }
        map('i', '<CR>', 'pumvisible() ? deoplete#close_popup() : "\\<CR>"', o)
        map('i', '<C-d>', 'pumvisible() ? "\\<PageDown>" : "\\<C-d>"', o)
        map('i', '<C-u>', 'pumvisible() ? "\\<PageUp>" : "\\<C-u>"', o)
        map('i', '<C-space>', 'deoplete#manual_complete()', o)
    end
})

vim.api.nvim_create_autocmd({ "FileType" }, {
    group = vim.api.nvim_create_augroup("CsLspHighlight", {}),
    pattern = "cs",
    callback = function(_)
        set_hl_link("csStorage", "GruvboxRed")
        set_hl_link("csClass", "GruvboxRed")
        set_hl_link("csType", "GruvboxRed")
        set_hl_link("csAccessModifier", "GruvboxRed")
        set_hl_link("csInterpolationFormat", "String")
        set_hl_link("Structure", "GruvboxYellow")
    end
})

--- Configure plugs ---
if Exists(BUNDLE_DIR .. "indent-blankline.nvim") then
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
end

if Exists(BUNDLE_DIR .. "bufferline.nvim") then
    vim.opt.termguicolors = true
    require('bufferline').setup {
        options = {
            numbers = function(opts) return string.format('%s', opts.raise(opts.ordinal)) end,
            show_buffer_close_icons = false,
            show_close_icon = false,
            show_buffer_icons = false,
            show_tab_indicators = false,
            enforce_regular_tabs = false,
            diagnostics = false,
            modified_icon = "●",
            indicator = {
                icon = "",
                style = "icon"
            },
            diagnostics_indicator = "",
            separator_style = { '|', '|' },
            tab_size = 1,
        }
    }

    local opts = { noremap = true, silent = true }
    map('n', '<leader>1', '<Cmd>BufferLineGoToBuffer 1<CR>', opts)
    map('n', '<leader>2', '<Cmd>BufferLineGoToBuffer 2<CR>', opts)
    map('n', '<leader>3', '<Cmd>BufferLineGoToBuffer 3<CR>', opts)
    map('n', '<leader>4', '<Cmd>BufferLineGoToBuffer 4<CR>', opts)
    map('n', '<leader>5', '<Cmd>BufferLineGoToBuffer 5<CR>', opts)
    map('n', '<leader>6', '<Cmd>BufferLineGoToBuffer 6<CR>', opts)
    map('n', '<leader>7', '<Cmd>BufferLineGoToBuffer 7<CR>', opts)
    map('n', '<leader>8', '<Cmd>BufferLineGoToBuffer 8<CR>', opts)
    map('n', '<leader>9', '<Cmd>BufferLineGoToBuffer 9<CR>', opts)
    map('n', '<leader><space>e', '<Cmd>BufferLinePick><CR>', opts)

    set_hl("BufferLineFill", "#3c3836", "#fbf1c7")
    set_hl_link("BufferLineBufferSelected", "lualine_c_visual")
    set_hl_link("BufferLinePickSelected", "lualine_a_visual")
    set_hl_link("BufferLineModifiedSelected", "lualine_c_visual")
    set_hl_link("BufferLineNumbersSelected", "lualine_c_visual")
    set_hl("BufferLineBackground", "#a89984", "#ebdbb2")
    set_hl("BufferLinePick", "#9d0006", "#ebdbb2")
    set_hl_link("BufferLineSeparator", "BufferLineBackground")
    set_hl_link("BufferLineNumbers", "BufferLineBackground")
    set_hl("BufferLineModified", "#076678", "#ebdbb2")
    set_hl("BufferLineBufferVisible", "#7c6f64", "#d5c4a1")
    set_hl("BufferLinePickVisible", "#9d0006", "#d5c4a1")
    set_hl("BufferLineModifiedVisible", "#076678", "#d5c4a1")
    set_hl("BufferLineNumbersVisible", "#076678", "#d5c4a1")
    set_hl("BufferLineIndicatorVisible", "#076678", "#d5c4a1")
end

if Exists(BUNDLE_DIR .. "nvim-treesitter") then
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

    set_hl_link("TSFuncBuiltin", "GruvboxAqua")
end

if Exists(BUNDLE_DIR .. "nvim-tree.lua") then
    local width_perc = 0.2
    local original_width = math.floor(vim.o.columns * width_perc)

    function NvimTreeToggleWidth()
        local max = vim.fn.MaxLineLength()
        local new = (max == vim.fn.winwidth(0)) and original_width or max
        vim.cmd('NvimTreeResize ' .. new)
    end

    set_hl_link("NvimTreeFolderIcon", "GruvboxBlue")
    set_hl_link("NvimTreeFolderName", "NvimTreeFolderIcon")
    set_hl_link("NvimTreeEmptyFolderName", "NvimTreeFolderName")
    vim.api.nvim_set_hl(0, "NvimTreeRootFolder", { bold = true, underline = true, ctermfg = 24, fg = "#076678" })
    set_hl_link("NvimTreeOpenedFolderName", "GruvboxBlueBold")
    set_hl_link("NvimTreeOpenedFile", "GruvboxGreen")
    set_hl_link("NvimTreeSymlink", "GruvboxAqua")
    set_hl_link("NvimTreeExecFile", "GruvboxYellow")
    vim.api.nvim_set_hl(0, "NvimTreeSpecialFile", {
        ctermfg = 237,
        ctermbg = 229,
        fg = "#3c3836",
        bg = "#fbf1c7",
        underline = true
    })
    map("n", "<leader>e", "<Cmd>NvimTreeFindFileToggle<CR>", { noremap = true, silent = true })

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

if Exists(BUNDLE_DIR .. "lualine.nvim") then
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
    map('n', '<leader>1', '<Cmd>LualineBuffersJump 1<CR>', opts)
    map('n', '<leader>2', '<Cmd>LualineBuffersJump 2<CR>', opts)
    map('n', '<leader>3', '<Cmd>LualineBuffersJump 3<CR>', opts)
    map('n', '<leader>4', '<Cmd>LualineBuffersJump 4<CR>', opts)
    map('n', '<leader>5', '<Cmd>LualineBuffersJump 5<CR>', opts)
    map('n', '<leader>6', '<Cmd>LualineBuffersJump 6<CR>', opts)
    map('n', '<leader>7', '<Cmd>LualineBuffersJump 7<CR>', opts)
    map('n', '<leader>8', '<Cmd>LualineBuffersJump 8<CR>', opts)
    map('n', '<leader>9', '<Cmd>LualineBuffersJump 9<CR>', opts)
end
