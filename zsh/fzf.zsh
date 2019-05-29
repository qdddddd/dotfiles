# Setup fzf
# ---------
if [[ ! "$PATH" == */usr/local/opt/fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/usr/local/opt/fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/usr/local/opt/fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/usr/local/opt/fzf/shell/key-bindings.zsh"

# Search for dot files
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'

# Gruvbox color
local dark0_hard='#1d2021'
local dark0='#282828'
local dark0_soft='#32302f'
local dark1='#3c3836'
local dark2='#504945'
local dark3='#665c54'
local dark4='#7c6f64'
local dark4_256='#7c6f64'
local gray_245='#928374'
local gray_244='#928374'
local light0_hard='#f9f5d7'
local light0='#fbf1c7'
local light0_soft='#f2e5bc'
local light1='#ebdbb2'
local light2='#d5c4a1'
local light3='#bdae93'
local light4='#a89984'
local light4_256='#a89984'
local bright_red='#fb4934'
local bright_green='#b8bb26'
local bright_yellow='#fabd2f'
local bright_blue='#83a598'
local bright_purple='#d3869b'
local bright_aqua='#8ec07c'
local bright_orange='#fe8019'
local neutral_red='#cc241d'
local neutral_green='#98971a'
local neutral_yellow='#d79921'
local neutral_blue='#458588'
local neutral_purple='#b16286'
local neutral_aqua='#689d6a'
local neutral_orange='#d65d0e'
local faded_red='#9d0006'
local faded_green='#79740e'
local faded_yellow='#b57614'
local faded_blue='#076678'
local faded_purple='#8f3f71'
local faded_aqua='#427b58'
local faded_orange='#af3a03'

export FZF_DEFAULT_OPTS="
    --color=bg+:$light1,spinner:$neutral_blue,hl:$faded_red
    --color=fg:$dark2,header:$faded_blue,info:$faded_blue,pointer:$faded_red
    --color=marker:$faded_red,fg+:$dark2,prompt:$dark1,hl+:$faded_red
    --preview 'cat {}'
    --height 40%
"
alias f='fzf --reverse'
