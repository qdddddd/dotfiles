--- Check if a file or directory exists in this path
function Exists(file)
    local ok, _, code = os.rename(file, file)
    if not ok then
        if code == 13 then
            -- Permission denied, but it exists
            return true
        end
    end
    return ok
end

--- Check if a directory exists in this path
function IsDir(path)
    -- "/" works on both Unix and Windows
    return Exists(path.."/")
end

--- lualine
local HOME = os.getenv("HOME")
if Exists(HOME .. "/.vim/bundle/lualine.nvim/") then
    require'lualine'.setup {
        options = {
            icons_enabled = true,
            theme = 'gruvbox_light',
            component_separators = '',
            section_separators = '',
            disabled_filetypes = {}
        },
        sections = {
            lualine_a = {'mode'},
            lualine_b = {
                {
                    'diff',
                    colored = true, -- displays diff status in color if set to true
                    -- all colors are in format #rrggbb
                    color_added = nil, -- changes diff's added foreground color
                    color_modified = nil, -- changes diff's modified foreground color
                    color_removed = nil, -- changes diff's removed foreground color
                    symbols = {added = '+', modified = '~', removed = '-'} -- changes diff symbols
                },
                'branch'
            },
            lualine_c = {{'filename', path = 1}},
            lualine_x = {'fileformat'},
            lualine_y = {'filetype'},
            lualine_z = {
                'progress',
                "GetStatusLineInfo()",
                {
                    'diagnostics',
                    -- table of diagnostic sources, available sources:
                    -- nvim_lsp, coc, ale, vim_lsp
                    sources = {'coc', 'ale'},
                    -- displays diagnostics from defined severity
                    sections = {'error', 'warn', 'info', 'hint'},
                    -- all colors are in format #rrggbb
                    color_error = nil, -- changes diagnostic's error foreground color
                    color_warn = nil, -- changes diagnostic's warn foreground color
                    color_info = nil, -- Changes diagnostic's info foreground color
                    color_hint = nil, -- Changes diagnostic's hint foreground color
                    symbols = {error = 'E', warn = 'W', info = 'I', hint = 'H'}
                }
            }
        },
        inactive_sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = {'filename'},
            lualine_x = {'location'},
            lualine_y = {},
            lualine_z = {}
        },
        tabline = {},
        extensions = {'fugitive'}
    }
end

if Exists(HOME .. "/.vim/bundle/bufferline.nvim") then
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

if Exists(HOME .. "/.vim/bundle/nvim-treesitter") then
    require'nvim-treesitter.configs'.setup {
      ensure_installed = { "c_sharp" }, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
      ignore_install = { }, -- List of parsers to ignore installing
      highlight = {
        enable = true,              -- false will disable the whole extension
        disable = { "c" },  -- list of language that will be disabled
        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false,
      },
    }
end
