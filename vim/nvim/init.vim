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
