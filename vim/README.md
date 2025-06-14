# Vim and NeoVim Configs

NeoVim config files whose structure referencing [spf13](https://github.com/spf13/spf13-vim).

`nvim` contains NeoVim specific configs, sourcing `init.lua` as the basics, loading
modules in the following order:

```text
rc/vimrc.bundles
lua/environment.lua
lua/display.lua
lua/keymaps.lua
lua/lsp.lua
lua/plugins.lua
```

Plugin settings should go in `nvim/lua/plugins.lua`.
