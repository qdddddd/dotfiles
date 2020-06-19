# Return if requirements are not found.
if (( ! $+commands[git] )); then
    return 1
fi

setopt extended_glob

# Checks a boolean variable for "true".
# Case insensitive: "1", "y", "yes", "t", "true", "o", and "on".
function is-true {
    [[ -n "$1" && "$1" == (1|[Yy]([Ee][Ss]|)|[Tt]([Rr][Uu][Ee]|)|[Oo]([Nn]|)) ]]
}

# Load functions
fpath=(${0:h}/functions $fpath)
for function in ${0:h}/functions/*; do
    autoload -Uz ${function##*/}
done

# git alias
_git_log_medium_format='%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B'
alias gpl='git pull'
alias gl='git log --topo-order --pretty=format:"${_git_log_medium_format}"'
alias glg='git log --topo-order --stat --pretty=format:"${_git_log_medium_format}"'
alias gst='git status -s'
