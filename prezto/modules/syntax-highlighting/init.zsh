#
# Integrates zsh-syntax-highlighting into Prezto.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Return if requirements are not found.
if ! zstyle -t ':prezto:module:syntax-highlighting' color; then
  return 1
fi

# Source module files.
source "${0:h}/external/fast-syntax-highlighting.plugin.zsh" || return 1

if zstyle -t ':prezto:module:syntax-highlighting' theme; then
    echo $theme
    fast-theme $theme
fi
