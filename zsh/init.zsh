# Checks a boolean variable for "true".
# Case insensitive: "1", "y", "yes", "t", "true", "o", and "on".
function is-true {
    [[ -n "$1" && "$1" == (1|[Yy]([Ee][Ss]|)|[Tt]([Rr][Uu][Ee]|)|[Oo]([Nn]|)) ]]
}

# Return if requirements are not found.
if (( ! $+commands[git] )); then
    return 1
fi

setopt extended_glob
# Load functions
fpath=(${0:h}/functions $fpath)
for function in ${0:h}/functions/*; do
    autoload -Uz ${function##*/}
done
