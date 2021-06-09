# Vim and NeoVim Configs

Vim config files whose structure referencing [spf13](https://github.com/spf13/spf13-vim).
Supports both Vim and NeoVim.

`rc` contains vimrcs and `nvim` contains NeoVim specific configs, sourcing `rc/vimrc` as the basics.
NeoVim plugin settings written in Lua should go in `nvim/plugs.lua`. The load order is as follows:

```text
rc/vimrc.bundles
rc/vimrc
nvim/plugs.lua
nvim/init.vim
```

Anything needs to be sourced before `rc/vimrc.bundles` should be written at the beginning of the "Load bundles config" block in `rc/vimrc`.
