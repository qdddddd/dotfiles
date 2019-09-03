# Theme that heavily depends on
# https://github.com/blueyed/oh-my-zsh/blob/5228d6e/themes/blueyed.zsh-theme#L766-L789

function prompt_bernoulli_precmd {
    invisibles='%([BSUbfksu]|([FK]|){*})'
    PROMPT_L='%{%F{$COLOR}%}'${USER}'@'${HOST}' » %{%~%}'
    local lsize=${#${(S%%)PROMPT_L//$~invisibles/}}

    local pwdsize=${#${(%):-%~}}

    # Get Git repository information.
    vcs_info
    PROMPT_R=${vcs_info_msg_0_}
    local rsize=${#${(S%%)PROMPT_R//$~invisibles/}}

    # Define spaces in the middle
    local msize=$(($COLUMNS-$lsize-$pwdsize-2-$rsize))
    PROMPT_M=''
    if (($rsize > 0)); then
        PROMPT_M=${(r:$msize:: :)}
    fi

    if (($msize < 0)); then
        PROMPT_R=''
    fi

    #echo left=$lsize pwd=$pwdsize mid=${#PROMPT_M} right=$rsize columns=$COLUMNS
}

# Show remote ref name and marks of dirty, untracked, ahead-of, or behind.
# This also colors and adjusts ${hook_com[branch]}.
function +vi-git-st() {
    [[ $1 == 0 ]] || return 0 # do this only once for vcs_info_msg_0_.

    local -a gitstatus

    # Dirty
    local dirty
    if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
        dirty=$(parse_git_dirty)
    fi
    if [[ -n $dirty ]]; then
        gitstatus+=( "*" )
    fi

    # Untracked
    if [[ -n $(git ls-files --other --exclude-standard 2>/dev/null) ]]; then
        gitstatus+=( "=" )
    fi

    # Ahead
    if (( $(git_commits_ahead) )); then
        gitstatus+=( "ﰵ" )
    fi

    # Behind
    if (( $(git_commits_behind) )); then
        gitstatus+=( "ﰬ" )
    fi

    # Add gitstatus to branch
    if [[ -n $gitstatus ]]; then
        hook_com[branch]+=${(j::)gitstatus}
    fi

    return 0
}

function prompt_bernoulli_setup {
    setopt LOCAL_OPTIONS
    unsetopt XTRACE KSH_ARRAYS
    prompt_opts=(cr percent sp subst)

    # Assign colors.
    if [[ -n "$1" ]]; then
        COLOR="$1"
    else
        COLOR=66
    fi

    # Load required functions.
    autoload -Uz add-zsh-hook
    autoload -Uz vcs_info

    # Add hook for calling vcs-info before each command.
    add-zsh-hook precmd prompt_bernoulli_precmd

    # Set vcs-info parameters.
    # Must use Powerline font, for \uE0A0 to render.
    setopt promptsubst

    # Query/use custom command for `git`.
    zstyle -s ":vcs_info:git:*:-all-" "command" _git_cmd || _git_cmd=$(whence -p git)
    # Register vcs_info hooks.
    zstyle ':vcs_info:git*+set-message:*' hooks git-st

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:git:*' formats '%{%%B%} %b%{%%b%}'
    zstyle ':vcs_info:git:*' actionformats '%F{240}[%b|%a]%f'

    # Define prompts.
    PROMPT='%B${PROMPT_L} ${PROMPT_M} ${PROMPT_R}'
    PROMPT+=$'\n  %b%f'
}

prompt_bernoulli_setup "$@"

#PROMPT='%F{$COLOR}%n@%m » %1~ %f → '
