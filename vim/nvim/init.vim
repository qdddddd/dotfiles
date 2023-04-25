" vim: set sw=4 ts=4 sts=4 et foldmarker={,} foldlevel=0 foldmethod=marker:
" Nvim specific settings

if exists('g:vscode')
    " THEME CHANGER
    function! SetCursorLineNrColorInsert(mode)
        " Insert mode: blue
        if a:mode == "i"
            call VSCodeNotify('nvim-theme.insert')

        " Replace mode: red
        elseif a:mode == "r"
            call VSCodeNotify('nvim-theme.replace')
        endif
    endfunction

    augroup CursorLineNrColorSwap
        autocmd!
        autocmd ModeChanged *:[vV\x16]* call VSCodeNotify('nvim-theme.visual')
        autocmd ModeChanged *:[R]* call VSCodeNotify('nvim-theme.replace')
        autocmd InsertEnter * call SetCursorLineNrColorInsert(v:insertmode)
        autocmd InsertLeave * call VSCodeNotify('nvim-theme.normal')
        autocmd CursorHold * call VSCodeNotify('nvim-theme.normal')
    augroup END

    set guicursor=n-v-c:block-Cursor
    set guicursor+=i:hor20
else
    " Migrate from vim
    set runtimepath^=~/.vim
    let &packpath = &runtimepath
    source ~/.vim/vimrc

    hi! clear Operator

    " Fzf floating window style
    let g:fzf_layout = { 'window': { 'width': 0.6, 'height': 0.3, 'highlight': 'GruvboxRedSign'}}

    " Reload vim settings
    command! Reload source ~/.config/nvim/init.vim

    " Color the column marking the lengthLimit when
    " the longest line in the file exceeds the limit
    au! BufWinEnter set colorcolumn=99999
    augroup TriggerColorColumn
        au!
        au BufWinEnter,BufRead,TextChanged,TextChangedI *.cs call ShowColumnAtLimit(120)
    augroup END

    function! ShowColumnAtLimit(len_limit)
        let max_len = max(map(getline(1,'$'), 'len(v:val)'))

        if max_len > a:len_limit
            exe "set colorcolumn=" . (a:len_limit + 1)
        else
            set colorcolumn=99999
        endif
    endfunction

    " Plugin Settings
    luafile ~/.config/nvim/plugs.lua

    " indent_blankline
    if isdirectory(expand("~/.vim/bundle/indent-blankline.nvim"))
        let g:indent_blankline_show_first_indent_level = v:false
        let g:indent_blankline_show_trailing_blankline_indent = v:false
    endif
end
