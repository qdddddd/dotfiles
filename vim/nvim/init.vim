" Nvim specific settings

" Migrate from vim
set runtimepath^=~/.vim
let &packpath = &runtimepath
source ~/.vim/vimrc
luafile ~/.config/nvim/plugs.lua

set guicursor="n-v-c-sm:hor20,i-ci-ve:hor20,r-cr-o:hor20"
hi! clear Operator

" Fzf floating window style
let g:fzf_layout = { 'window': { 'width': 0.5, 'height': 0.3, 'highlight': 'GruvboxRedSign'}}
