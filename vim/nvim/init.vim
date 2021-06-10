" vim: set sw=4 ts=4 sts=4 et foldmarker={,} foldlevel=0 foldmethod=marker:
" Nvim specific settings

" Migrate from vim
set runtimepath^=~/.vim
let &packpath = &runtimepath
source ~/.vim/vimrc
luafile ~/.config/nvim/plugs.lua

" Set cursor style
set guicursor="n-v-c-sm:hor20,i-ci-ve:hor20,r-cr-o:hor20"
hi! clear Operator

" Fzf floating window style
let g:fzf_layout = { 'window': { 'width': 0.6, 'height': 0.3, 'highlight': 'GruvboxRedSign'}}

" Reload vim settings
command! Reload source ~/.config/nvim/init.vim

" Plugin Settings

" indent_blankline {
    if isdirectory(expand("~/.vim/bundle/indent-blankline.nvim"))
        let g:indent_blankline_indent_level = 20
        let g:indent_blankline_extra_indent_level = -1
    endif
" }
