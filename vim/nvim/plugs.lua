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
local set_hl = function(name, fg, bg) vim.api.nvim_set_hl(0, name, { foreground = fg, background = bg }) end
local set_hl_link = function(name, linkto) vim.api.nvim_set_hl(0, name, { link = linkto, default = false }) end
local get_hl = function(name) return vim.api.nvim_get_hl_by_name(name, true) end

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
    vim.g["airline#extensions#tabline#enabled"] = 0
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
    map('n', '<A-->', '<Cmd>BufferLineCyclePrev<CR>', opts)
    map('n', '<A-=>', '<Cmd>BufferLineCycleNext<CR>', opts)
    if vim.fn.OSX() then
        map('n', '–', '<Cmd>BufferLineCyclePrev<CR>', opts)
        map('n', '≠', '<Cmd>BufferLineCycleNext<CR>', opts)
    end

    set_hl("BufferLineFill", "#3c3836", "#fbf1c7")
    set_hl_link("BufferLineBufferSelected", "airline_a")
    set_hl_link("BufferLinePickSelected", "airline_a_red")
    set_hl_link("BufferLineModifiedSelected", "airline_a")
    set_hl_link("BufferLineNumbersSelected", "airline_a")
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

if Exists(BUNDLE_DIR .. "barbar.nvim") then
    vim.g["airline#extensions#tabline#enabled"] = 0
    require 'bufferline'.setup {
        icons = {
            buffer_index = true,
            buffer_number = false,
            filetype = {
                enabled = false
            },
            button = false,
            separator = { left = '|' },
            inactive = {
                separator = { left = '|' },
            },
        },
        clickable = true,
        maximum_padding = 0,
        no_name_title = nil
    }

    local opts = { noremap = true, silent = false }
    map('n', '<leader><space>e', '<Cmd>BufferPick<CR>', opts)
    map('n', '<leader>1', '<Cmd>BufferGoto 1<CR>', opts)
    map('n', '<leader>2', '<Cmd>BufferGoto 2<CR>', opts)
    map('n', '<leader>3', '<Cmd>BufferGoto 3<CR>', opts)
    map('n', '<leader>4', '<Cmd>BufferGoto 4<CR>', opts)
    map('n', '<leader>5', '<Cmd>BufferGoto 5<CR>', opts)
    map('n', '<leader>6', '<Cmd>BufferGoto 6<CR>', opts)
    map('n', '<leader>7', '<Cmd>BufferGoto 7<CR>', opts)
    map('n', '<leader>8', '<Cmd>BufferGoto 8<CR>', opts)
    map('n', '<leader>9', '<Cmd>BufferGoto 9<CR>', opts)
    map('n', '<leader>0', '<Cmd>BufferLast<CR>', opts)
    map('n', '<A-->', '<Cmd>BufferPrevious<CR>', opts)
    map('n', '<A-=>', '<Cmd>BufferNext<CR>', opts)
    if vim.fn.OSX() then
        map('n', '–', '<Cmd>BufferPrevious<CR>', opts)
        map('n', '≠', '<Cmd>BufferNext<CR>', opts)
    end

    set_hl_link("BufferCurrent", "airline_a")
    set_hl_link("BufferCurrentIndex", "BufferCurrent")
    set_hl_link("BufferCurrentSign", "BufferCurrent")
    set_hl_link("BufferCurrentMod", "BufferCurrent")
    set_hl_link("BufferVisible", "StatusLine")
    set_hl_link("BufferVisibleIndex", "BufferVisible")
    set_hl_link("BufferVisibleSign", "BufferInactive")
    set_hl("BufferVisibleMod", get_hl("Identifier").foreground, get_hl("TabLine").background)
    set_hl_link("BufferInactiveMod", "BufferVisibleMod")
end

if Exists(BUNDLE_DIR .. "nvim-treesitter") then
    require 'nvim-treesitter.configs'.setup {
        ensure_installed = { "vim", "python", "c_sharp" }, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
        ignore_install = {},                               -- List of parsers to ignore installing
        highlight = {
            enable = true,                                 -- false will disable the whole extension
            disable = {},                                  -- list of language that will be disabled
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
