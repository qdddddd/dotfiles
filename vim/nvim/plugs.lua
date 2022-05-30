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
    return Exists(path.."/") -- "/" works on both Unix and Windows
end

local BUNDLE_DIR = os.getenv("HOME") .. "/.vim/bundle/"

--- Configure plugs ---

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
            modified_icon = "+",
            indicator_icon = "",
            separator_style = {'|', '|'},
            tab_size = 10,
        }
    }

    vim.cmd([[
        nnoremap <silent><leader>1 <Cmd>BufferLineGoToBuffer 1<CR>
        nnoremap <silent><leader>2 <Cmd>BufferLineGoToBuffer 2<CR>
        nnoremap <silent><leader>3 <Cmd>BufferLineGoToBuffer 3<CR>
        nnoremap <silent><leader>4 <Cmd>BufferLineGoToBuffer 4<CR>
        nnoremap <silent><leader>5 <Cmd>BufferLineGoToBuffer 5<CR>
        nnoremap <silent><leader>6 <Cmd>BufferLineGoToBuffer 6<CR>
        nnoremap <silent><leader>7 <Cmd>BufferLineGoToBuffer 7<CR>
        nnoremap <silent><leader>8 <Cmd>BufferLineGoToBuffer 8<CR>
        nnoremap <silent><leader>9 <Cmd>BufferLineGoToBuffer 9<CR>
        nnoremap <silent><leader><space>e :BufferLinePick<CR>
        nnoremap <silent> – :BufferLineCyclePrev<CR>
        nnoremap <silent> ≠ :BufferLineCycleNext<CR>
        if LINUX() || has('nvim')
            nnoremap <silent> <A--> :BufferLineCyclePrev<CR>
            nnoremap <silent> <A-=> :BufferLineCycleNext<CR>
        endif

        augroup bufferline_highlights
            au!
            au VimEnter * hi BufferLineFill guifg=#3c3836 guibg=#fbf1c7

            au VimEnter * hi! link BufferLineBufferSelected airline_a
            au VimEnter * hi! link BufferLinePickSelected airline_a_red
            au VimEnter * hi! link BufferLineModifiedSelected airline_a

            au VimEnter * hi BufferLineBackground guifg=#a89984 guibg=#ebdbb2
            au VimEnter * hi BufferLinePick guifg=#9d0006 guibg=#ebdbb2
            au VimEnter * hi! link BufferLineSeparator BufferLineBackground
            au VimEnter * hi BufferLineModified guifg=#076678 guibg=#ebdbb2

            au VimEnter * hi BufferLineBufferVisible guifg=#7c6f64 guibg=#d5c4a1
            au VimEnter * hi BufferLinePickVisible guifg=#9d0006 guibg=#d5c4a1
            au VimEnter * hi BufferLineModifiedVisible guifg=#076678 guibg=#d5c4a1
        augroup END
    ]])
end

if Exists(BUNDLE_DIR .. "nvim-treesitter") then
    require'nvim-treesitter.configs'.setup {
        ensure_installed = { "vim", "python", "c_sharp"  }, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
        ignore_install = { }, -- List of parsers to ignore installing
        highlight = {
            enable = true,  -- false will disable the whole extension
            disable = {},   -- list of language that will be disabled
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

    vim.cmd([[
        augroup treesitter_highlights
            au!
            au VimEnter * hi! link TSFuncBuiltin GruvboxAqua
        augroup END
    ]])
end

if Exists(BUNDLE_DIR .. "nvim-tree.lua") then
    local width_perc = 0.2
    local original_width = math.floor(vim.o.columns * width_perc)

    function NvimTreeToggleWidth()
        local max = vim.fn.MaxLineLength()
        local new = (max == vim.fn.winwidth(0)) and original_width or max
        vim.cmd('NvimTreeResize '..new)
    end

    vim.cmd([[
        nnoremap <silent> <leader>e :NvimTreeFindFileToggle<CR>
        augroup nvimtree_augroup
            au!
            au VimEnter * hi! link NvimTreeFolderIcon GruvboxBlue
            au VimEnter * hi! link NvimTreeFolderName NvimTreeFolderIcon
            au VimEnter * hi! link NvimTreeEmptyFolderName NvimTreeFolderName
            au VimEnter * hi! NvimTreeRootFolder cterm=bold,underline ctermfg=24 gui=bold,underline guifg=#076678
            au VimEnter * hi! link NvimTreeOpenedFolderName GruvboxBlueBold
            au VimEnter * hi! link NvimTreeOpenedFile GruvboxGreen
            au VimEnter * hi! link NvimTreeSymlink GruvboxAqua
            au VimEnter * hi! link NvimTreeExecFile GruvboxYellow
            au VimEnter * hi! NvimTreeSpecialFile ctermfg=237 ctermbg=229 guifg=#3c3836 guibg=#fbf1c7 gui=underline cterm=underline
            au BufEnter NvimTree_* nnoremap <silent> <buffer> w :lua NvimTreeToggleWidth()<CR>
        augroup END
    ]])

    require'nvim-tree'.setup {
        hijack_cursor = true,
        reload_on_bufenter = true,
        respect_buf_cwd = true,
        update_focused_file = {
            enable = true,
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
                    default= "",
                    symlink= "",
                    git= {
                        unstaged= "✗",
                        staged= "✓",
                        unmerged= "",
                        renamed= "➜",
                        untracked= "★",
                        deleted= "",
                        ignored= "◌"
                    },
                    folder= {
                        arrow_open= "",
                        arrow_closed= "",
                        default= "",
                        open= "",
                        empty= "",
                        empty_open= "",
                        symlink= "",
                        symlink_open= "",
                    }
                }
            },
        },
        view = {
            width = original_width,
            mappings = {
                custom_only = true,
                list = {
                    { key = ".",                            action = "toggle_dotfiles" },
                    { key = "<BS>",                         action = "close_node" },
                    { key = "<C-j>",                        action = "next_sibling" },
                    { key = "<C-k>",                        action = "prev_sibling" },
                    { key = "<C-o>",                        action = "system_open" },
                    { key = "<Tab>",                        action = "preview" },
                    { key = "?",                            action = "toggle_help" },
                    { key = "D",                            action = "trash" },
                    { key = "F",                            action = "clear_live_filter" },
                    { key = "i",                            action = "toggle_git_ignored" },
                    { key = "P",                            action = "parent_node" },
                    { key = "R",                            action = "refresh" },
                    { key = "S",                            action = "search_node" },
                    { key = "W",                            action = "collapse_all" },
                    { key = "a",                            action = "create" },
                    { key = "d",                            action = "remove" },
                    { key = "f",                            action = "live_filter" },
                    { key = "Y",                            action = "copy_absolute_path" },
                    { key = "h",                            action = "dir_up" },
                    { key = "<leader>ho",                   action = "toggle_file_info" },
                    { key = "m",                            action = "cut" },
                    { key = "p",                            action = "paste" },
                    { key = "q",                            action = "close" },
                    { key = "r",                            action = "rename" },
                    { key = "s",                            action = "split" },
                    { key = "v",                            action = "vsplit" },
                    { key = "y",                            action = "copy" },
                    { key = {"<2-RightMouse>", "l"},        action = "cd" },
                    { key = {"<CR>", "o", "<2-LeftMouse>"}, action = "edit" },
                    { key = {"O"},                          action = "edit_no_picker" },
                }
            },
        },
    }
end
