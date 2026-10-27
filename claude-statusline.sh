#!/usr/bin/env bash
# Claude Code status line, two lines:
#   1. the folder and git branch;
#   2. the model and usage meters (context, 5-hour and 7-day limits, Fable
#      weekly), which the ctx-usage mod used to draw above the prompt.
#
# A linked git worktree shows as "<repo path> ⎇<worktree>[/subdir]", its
# branch hidden when it only repeats the worktree name. Long locations are
# shortened to fit the pane width: parent dirs are abbreviated fish-style,
# the branch is cut in the middle, the path is reduced to one abbreviated
# parent plus its last segment, then the parent is dropped, then hard-cut.

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

# Pane width: tmux pane, else the controlling tty, else 80. Keep a small
# margin for Claude Code's status-line padding.
cols=""
[ -n "$TMUX_PANE" ] && cols=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_width}' 2>/dev/null)
[ -z "$cols" ] && cols=$(stty size 2>/dev/null </dev/tty | cut -d' ' -f2)
[[ "$cols" =~ ^[0-9]+$ ]] || cols=80
budget=$((cols - 4))

# The location is "$path$tail": for a linked worktree, path is the main
# repo and tail is " ⎇<worktree>[/subdir]"; otherwise path is the cwd.
# Shrinking only rewrites path, so same-named repos under different parents
# stay distinguishable until the last steps.
git_branch="" tail=""
path="$cwd"
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree &>/dev/null; then
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
               || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  { read -r git_dir; read -r common_dir; read -r top; } < <(
    git -C "$cwd" --no-optional-locks rev-parse --path-format=absolute \
      --git-dir --git-common-dir --show-toplevel 2>/dev/null)
  if [ -n "$top" ] && [ "$git_dir" != "$common_dir" ]; then
    # git reports physical paths; map them back onto the logical cwd so
    # symlinked dirs (e.g. ~/.local/tmp) keep the path the user typed.
    repo="${common_dir%/.git}"
    phys=$(cd "$cwd" 2>/dev/null && pwd -P)
    sub="${phys#"$top"}"
    top_log="${cwd%"$sub"}"
    if [[ "$top" == "$repo"/* ]]; then
      path="${top_log%"${top#"$repo"}"}"
    else
      path="$repo"
    fi
    wt=$(basename "$top")
    tail=" ⎇$wt$sub"
    [[ "$git_branch" == "$wt" || "$git_branch" == "worktree-$wt" ]] && git_branch=""
  fi
fi
# Not ${path/#$HOME/\~}: bash 3.2 (macOS) keeps the backslash.
case "$path" in "$HOME" | "$HOME"/*) path="~${path#"$HOME"}" ;; esac

fits() {
  local n=$((${#path} + ${#tail}))
  [ -n "$git_branch" ] && n=$((n + 1 + ${#git_branch}))
  [ "$n" -le "$budget" ]
}

# First character of a dir name, keeping a leading dot (.dotfiles -> .d).
abbrev() { [[ "$1" == .* ]] && printf '%s' "${1:0:2}" || printf '%s' "${1:0:1}"; }

# 1. Abbreviate every dir of path but the last,
#    e.g. ~/Documents/portfolios/tceef -> ~/D/p/tceef.
if ! fits && [[ "$path" == */* ]]; then
  IFS=/ read -ra parts <<<"$path"
  last=$((${#parts[@]} - 1))
  out=""
  for i in "${!parts[@]}"; do
    p="${parts[$i]}"
    if [ "$i" -lt "$last" ] && [ -n "$p" ] && [ "$p" != "~" ]; then
      p=$(abbrev "$p")
    fi
    out+="$p"
    [ "$i" -lt "$last" ] && out+="/"
  done
  path="$out"
fi

# 2. Cut the branch in the middle down to 24 chars.
if ! fits && [ "${#git_branch}" -gt 24 ]; then
  git_branch="${git_branch:0:11}…${git_branch: -12}"
fi

# 3. Keep the last segment and one abbreviated parent, e.g. p/pandas-ta.
if ! fits && [[ "$path" == */*/* ]]; then
  base="${path##*/}"
  parent="${path%/*}"
  parent="${parent##*/}"
  path="$parent/$base"
fi

# 4. Drop the parent: last segment only, or no repo at all for a worktree.
if ! fits; then
  if [ -n "$tail" ]; then
    path="" tail="${tail# }"
  else
    path="${path##*/}"
  fi
fi

place="$path$tail"

# 5. Hard-cut whatever is left, path first, then branch.
if ! fits; then
  room=$budget
  [ -n "$git_branch" ] && room=$((budget - 1 - ${#git_branch}))
  if [ "$room" -ge 8 ]; then
    place="${place:0:room-1}…"
  else
    git_branch=""
    [ "${#place}" -gt "$budget" ] && place="${place:0:budget-1}…"
  fi
fi


# ---- Line 2: model and usage meters (formerly the ctx-usage mod's banner) ----
# "opus-5.5 ctx:24% 2h30m:37% 3d3h:12% fbl:51%": the model and each key gray,
# each value green below 50%, yellow from 50%, red from 80%.

model=$(echo "$input" | jq -r '.model.display_name // .model.id // ""')
model="${model% (*context)}"
model="${model%\[*\]}"
model="${model// /-}"
model=$(printf '%s' "$model" | tr '[:upper:]' '[:lower:]')

now=$(date +%s)

# "2h30m" for the 5-hour window, "3d3h" for longer ones.
time_left() {
  local secs=$(( $2 - now ))
  [ "$secs" -gt 0 ] || return 0
  if [ "$1" = five_hour ]; then
    local h=$(( secs / 3600 )) m=$(( secs % 3600 / 60 ))
    [ "$h" -gt 0 ] && printf '%dh%dm' "$h" "$m" || printf '%dm' "$m"
  else
    local d=$(( secs / 86400 )) h=$(( secs % 86400 / 3600 ))
    [ "$d" -gt 0 ] && printf '%dd%dh' "$d" "$h" || printf '%dh' "$h"
  fi
}

# Weekly per-model (Fable) usage. The payload only carries five_hour and
# seven_day, so the per-model buckets come from a cached GET
# /api/oauth/usage refreshed by a detached background job; rendering never
# waits on the network. The cache sits in tmpfs and is shared with meterboard.
# The dir is built from UID, not XDG_RUNTIME_DIR: ssh logins here get that
# variable unexpanded from /etc/environment. macOS has no /run/user, so it
# falls back to the per-user $TMPDIR there.
if [ -d "/run/user/$UID" ]; then
  usage_dir="/run/user/$UID/claude-usage"
else
  usage_dir="${TMPDIR:-/tmp}/claude-usage-$UID"
fi
usage_cache="$usage_dir/usage-utilization.json"
usage_lock="$usage_dir/usage-utilization.lock"
usage_failures="$usage_dir/usage-utilization.failures" # failed refreshes in a row; mtime = last one
usage_creds="$HOME/.claude/.credentials.json"

# The OAuth access token: the credentials file (Linux), else the macOS
# Keychain item, where Claude Code keeps it there (the file may exist
# without a token). The Keychain is only readable from a GUI login session.
oauth_token() {
  local tok=
  [ -r "$usage_creds" ] && tok=$(jq -r '.claudeAiOauth.accessToken // empty' "$usage_creds" 2>/dev/null)
  if [ -z "$tok" ] && command -v security >/dev/null 2>&1; then
    tok=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
      | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
  fi
  printf '%s' "$tok"
}

# File mtime in epoch seconds (GNU stat, then BSD/macOS stat), 0 if missing.
mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }
usage_ttl=120          # refresh in the background once the cache is older than this
usage_backoff_max=1800 # longest wait between retries once refreshes keep failing
usage_max_age=21600    # stop displaying entirely rather than show a stale number

usage_cache_age() {
  if [ -f "$usage_cache" ]; then
    echo $(( $(date +%s) - $(mtime "$usage_cache") ))
  else
    echo 999999
  fi
}

# Due once the cache is stale and, after failures, once usage_ttl *
# 2^failures (capped) has passed since the last one. The job re-checks once
# it holds the lock, in case another refresh just finished.
usage_refresh_due() {
  local failures retry_wait
  [ "$(usage_cache_age)" -ge "$usage_ttl" ] || return 1
  [ -f "$usage_failures" ] || return 0
  failures=
  read -r failures 2>/dev/null < "$usage_failures"
  case "$failures" in [0-5]) ;; ''|*[!0-9]*) failures=1 ;; *) failures=5 ;; esac
  retry_wait=$(( usage_ttl << failures ))
  [ "$retry_wait" -gt "$usage_backoff_max" ] && retry_wait=$usage_backoff_max
  [ $(( $(date +%s) - $(mtime "$usage_failures") )) -ge "$retry_wait" ]
}

# Claude Code re-runs this script every refreshInterval seconds (settings
# statusLine) so the time-left counters move. Those timer runs get the same
# payload as the last run apart from elapsed-time fields, so a payload whose
# fingerprint matches the session's previous one is a timer tick: it redraws
# but does not fetch. Any real session update changes the fingerprint.
# shortcut: one tiny file per session in tmpfs, never pruned; cleared at reboot.
mkdir -p "$usage_dir" 2>/dev/null
sid=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null)
session_event=1
if [ -n "$sid" ]; then
  sig=$(echo "$input" | jq -cS 'del(.cost.total_duration_ms)' 2>/dev/null | cksum | cut -d' ' -f1)
  sig_file="$usage_dir/statusline-${sid//[^A-Za-z0-9-]/}.sig"
  last_sig=
  read -r last_sig 2>/dev/null < "$sig_file"
  [ "$sig" = "$last_sig" ] && session_event=0
  echo "$sig" > "$sig_file" 2>/dev/null
fi

cache_age=$(usage_cache_age)
if [ "$session_event" = 1 ] && [ "$cache_age" -ge "$usage_ttl" ] && { [ -r "$usage_creds" ] || command -v security >/dev/null 2>&1; } && command -v curl >/dev/null 2>&1 && usage_refresh_due; then
  if mkdir "$usage_lock" 2>/dev/null; then
    (
      trap 'rmdir "$usage_lock" 2>/dev/null' EXIT
      usage_refresh_due || exit 0
      tok=$(oauth_token)
      tmp="${usage_cache}.$$"
      if [ -n "$tok" ] \
         && curl -sf --max-time 8 "https://api.anthropic.com/api/oauth/usage" \
              -H "Authorization: Bearer $tok" \
              -H "Content-Type: application/json" -o "$tmp" 2>/dev/null \
         && jq -e '(.limits | type == "array") or has("five_hour")' "$tmp" >/dev/null 2>&1; then
        mv -f "$tmp" "$usage_cache"
        rm -f "$usage_failures"
      else
        rm -f "$tmp"
        failures=
        read -r failures 2>/dev/null < "$usage_failures"
        case "$failures" in ''|*[!0-9]*) failures=0 ;; esac
        echo $(( 10#$failures + 1 )) > "$usage_failures"
      fi
    ) </dev/null >/dev/null 2>&1 &
  else
    # Reclaim a lock left behind by a refresh that was killed.
    lock_mtime=$(mtime "$usage_lock")
    [ "$lock_mtime" -gt 0 ] || lock_mtime=$now
    lock_age=$(( now - lock_mtime ))
    [ "$lock_age" -gt 60 ] && rmdir "$usage_lock" 2>/dev/null
  fi
fi

fable_pct=""
if [ -f "$usage_cache" ] && [ "$cache_age" -lt "$usage_max_age" ]; then
  fable_pct=$(jq -r '
    [ .limits[]?
      | select(.kind == "weekly_scoped")
      | select(((.scope.model.display_name // "") | ascii_downcase) | startswith("fable"))
      | .percent | numbers ] | .[0] // empty' "$usage_cache" 2>/dev/null)
fi

# Meters as "key<TAB>pct" lines (key may be empty), in display order.
meters=$(echo "$input" | jq -r '
  (.context_window.used_percentage
     // (if .context_window.remaining_percentage then 100 - .context_window.remaining_percentage else empty end)
   | "ctx\t\(.)"),
  (.rate_limits.five_hour | select(.used_percentage != null) | "five_hour:\(.resets_at // 0)\t\(.used_percentage)"),
  (.rate_limits.seven_day | select(.used_percentage != null) | "seven_day:\(.resets_at // 0)\t\(.used_percentage)")
' 2>/dev/null)
[ -n "$fable_pct" ] && meters+=$'\n'"fbl"$'\t'"$fable_pct"

# Labels in #7c6f64, the theme's "inactive" colour that Claude Code uses for
# dimColor hints such as "(shift+tab to cycle)"; not the ANSI dim attribute,
# which kitty draws at dim_opacity 0.55 (~#928374 here, too faint).
gray=$'\033[38;2;124;111;100m'

# Each segment is drawn only while the line still fits the pane.
line2="" width2=0
add_seg() { # plain-text, ansi-text
  local need=${#1}
  [ "$width2" -gt 0 ] && need=$((need + 1))
  [ $((width2 + need)) -le "$budget" ] || return 1
  [ "$width2" -gt 0 ] && line2+=" "
  line2+="$2"
  width2=$((width2 + need))
}
[ -n "$model" ] && add_seg "$model" "$gray""$model"$'\033[0m'
while IFS=$'\t' read -r key pct; do
  [ -n "$pct" ] || continue
  p=$(printf '%.0f' "$pct" 2>/dev/null) || continue
  case "$key" in
    five_hour:*|seven_day:*) label=$(time_left "${key%%:*}" "${key#*:}") ;;
    *) label="$key" ;;
  esac
  if [ "$p" -ge 80 ]; then c=31; elif [ "$p" -ge 50 ]; then c=33; else c=32; fi
  if [ -n "$label" ]; then
    add_seg "$label:$p%" "$gray""$label:"$'\033[0m\033['"$c"m"$p%"$'\033[0m' || break
  else
    add_seg "$p%" $'\033['"$c"m"$p%"$'\033[0m' || break
  fi
done <<<"$meters"

printf "\033[34m%s\033[0m" "$place"
[ -n "$git_branch" ] && printf " \033[33m%s\033[0m" "$git_branch"
printf "\n"
[ -n "$line2" ] && printf "%s\n" "$line2"
