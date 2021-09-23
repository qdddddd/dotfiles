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
            separator_style = {'|', '|'}
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
            au VimEnter * hi! BufferLineFill guifg=#3c3836 guibg=#fbf1c7

            au VimEnter * hi! link BufferLineBufferSelected airline_a
            au VimEnter * hi! link BufferLinePickSelected airline_a_red
            au VimEnter * hi! link BufferLineModifiedSelected airline_a

            au VimEnter * hi! BufferLineBackground guifg=#a89984 guibg=#ebdbb2
            au VimEnter * hi! BufferLinePick guifg=#9d0006 guibg=#ebdbb2
            au VimEnter * hi! link BufferLineSeparator BufferLineBackground
            au VimEnter * hi! BufferLineModified guifg=#076678 guibg=#ebdbb2

            au VimEnter * hi! BufferLineBufferVisible guifg=#7c6f64 guibg=#d5c4a1
            au VimEnter * hi! BufferLinePickVisible guifg=#9d0006 guibg=#d5c4a1
            au VimEnter * hi! BufferLineModifiedVisible guifg=#076678 guibg=#d5c4a1
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
