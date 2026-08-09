#!/usr/bin/env bash
set -euo pipefail

# Temporary hard-coded debug switch. Set to 1 to log each input payload.
DEBUG=1
LOG_DIR_PARENT="${AGENT_FORGE_DIR:-~/Downloads}"
DEBUG_LOG_DIR="$LOG_DIR_PARENT/logs"

# Originally: https://github.com/kcchien/claude-code-statusline
# modified for my needs

debug_log_input() {
  [[ "$DEBUG" == "1" ]] || return 0

  local ts log_file model_name model_slug
  ts=$(date +"%Y-%m-%dT%H:%M:%S%z")

  if command -v jq >/dev/null 2>&1; then
    model_name=$(printf '%s' "$1" | jq -r '.model.display_name // empty' 2>/dev/null || true)
  fi
  if [[ -n "${model_name:-}" ]]; then
    model_slug=$(printf '%s' "$model_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')
  fi
  model_slug="${model_slug:-unknown}"

  log_file="$DEBUG_LOG_DIR/statusline-${model_slug}-$(date +%Y-%m-%d).log"

  mkdir -p "$DEBUG_LOG_DIR" 2>/dev/null || return 0
  {
    printf '--- %s pid=%s ---\n' "$ts" "$$"
    printf '%s\n\n' "$1"
  } >> "$log_file" 2>/dev/null || true
}


# ═══════════════════════════════════════════════════════════════
# Environment detection
# ═══════════════════════════════════════════════════════════════

USE_ASCII="${CLAUDE_STATUSLINE_ASCII:-0}"
USE_NERDFONT="${CLAUDE_STATUSLINE_NERDFONT:-0}"
USE_TRUECOLOR=0
if [[ "${COLORTERM:-}" == "truecolor" || "${COLORTERM:-}" == "24bit" ]]; then
  USE_TRUECOLOR=1
fi

# ═══════════════════════════════════════════════════════════════
# Colors and symbols
# ═══════════════════════════════════════════════════════════════

RST='\033[0m'
CYAN='\033[36m'
BLUE='\033[34m'
DIM='\033[2m'
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
MAGENTA='\033[35m'

# A bit brighter than stock Solarized Dark secondary text (base0, #839496)
# so it stays legible against base03 rather than reading as barely-there.
if (( USE_TRUECOLOR )); then
  GRAY='\033[38;2;131;148;150m'
  SESSION_COLOR='\033[38;2;189;147;249m'
  FOLDER_COLOR='\033[38;2;255;121;198m'
else
  GRAY='\033[90m'
  SESSION_COLOR='\033[35m'
  FOLDER_COLOR='\033[35m'
fi

# Symbol set
if [[ "$USE_ASCII" == "1" ]]; then
  S_BRANCH=">"
  S_TIMER=""
  SEP=" | "
else
  if [[ "$USE_NERDFONT" == "1" ]]; then
    S_BRANCH=$'\xEF\x90\x98 '  # nf-oct-git_branch (U+F418)
    S_TIMER=$'\xEF\x80\x97'    # nf-fa-clock-o (U+F017)
  else
    S_BRANCH="⎇"
    S_TIMER="⏱"
  fi
  SEP=" │ "
fi

# ═══════════════════════════════════════════════════════════════
# Fallback output
# ═══════════════════════════════════════════════════════════════

fallback_prompt() {
  printf '%b' "${GRAY}${1:-─}${RST}"
  exit 0
}

command -v jq &>/dev/null || fallback_prompt "─ │ jq not found"

# ═══════════════════════════════════════════════════════════════
# Helpers: human-readable counts, reset countdowns, color scale
# ═══════════════════════════════════════════════════════════════

human_count() {
  awk -v n="${1:-0}" 'BEGIN {
    if (n >= 1000000) printf "%.0fm", n/1000000
    else if (n >= 1000) printf "%.0fk", n/1000
    else printf "%d", n
  }'
}

# Formats a unix timestamp as time-until: "Xd Yh" beyond a day, "Xh Ym" beyond
# an hour, "Xm Ys" under an hour, "now" if already past.
time_until() {
  local target_ts="${1:-}"
  [[ -z "$target_ts" ]] && return 0
  local now_ts
  now_ts=$(date +%s)
  awk -v target="$target_ts" -v now="$now_ts" 'BEGIN {
    diff = target - now
    if (diff <= 0) { print "now"; exit }
    if (diff >= 86400) {
      days = int(diff / 86400)
      hours = int((diff % 86400) / 3600)
      printf "%dd%dh", days, hours
    } else if (diff >= 3600) {
      hours = int(diff / 3600)
      mins = int((diff % 3600) / 60)
      printf "%dh%dm", hours, mins
    } else {
      mins = int(diff / 60)
      secs = int(diff % 60)
      printf "%dm%ds", mins, secs
    }
  }'
}

# Clamps a percentage (possibly fractional, e.g. "42.7") to an integer 0-100.
clamp_pct() {
  local pct="${1:-0}"
  pct="${pct%.*}"
  pct="${pct:-0}"
  if (( pct < 0 )); then pct=0; fi
  if (( pct > 100 )); then pct=100; fi
  printf '%s' "$pct"
}

# Severity color scale, not linear: grey (near-zero, ignore it) -> green ->
# blue (steady state, holds through the middle) -> yellow (getting warm) ->
# orange at 85 -> red at 90 -> a brighter, bold red at 95+.
tier_color() {
  local pct
  pct=$(clamp_pct "${1:-0}")
  if (( ! USE_TRUECOLOR )); then
    if (( pct >= 95 )); then printf '\033[1m%b' "$RED"
    elif (( pct >= 90 )); then printf '%b' "$RED"
    elif (( pct >= 65 )); then printf '%b' "$YELLOW"
    elif (( pct >= 40 )); then printf '%b' "$BLUE"
    elif (( pct >= 5 )); then printf '%b' "$GREEN"
    else printf '%b' "$GRAY"
    fi
    return
  fi
  if (( pct >= 95 )); then printf '\033[1m\033[38;2;255;69;69m'
  elif (( pct >= 90 )); then printf '\033[38;2;231;76;60m'
  elif (( pct >= 85 )); then printf '\033[38;2;230;126;34m'
  elif (( pct >= 65 )); then printf '\033[38;2;241;196;15m'
  elif (( pct >= 40 )); then printf '\033[38;2;38;139;210m'
  elif (( pct >= 5 )); then printf '\033[38;2;46;204;113m'
  else printf '\033[38;2;108;113;120m'
  fi
}

# Renders a 10-segment bar for a 0-100 percentage. Filled segments use the
# given color (so the whole pill can share one color); unfilled segments use
# a muted grey (Solarized base01) so the empty part stays visible on dark bg.
# No trailing reset — caller owns exactly one ${RST} at the end of the pill.
render_bar() {
  local pct color
  pct=$(clamp_pct "${1:-0}")
  color="${2:-}"
  local filled=$(( pct / 10 ))
  local bar="" i

  if [[ "$USE_ASCII" == "1" ]]; then
    for (( i=0; i<10; i++ )); do
      if (( i < filled )); then bar+="#"; else bar+="-"; fi
    done
    printf '%s' "$bar"
    return
  fi

  for (( i=0; i<10; i++ )); do
    if (( i < filled )); then
      bar+="${color}█"
    else
      bar+="\\033[38;2;88;110;117m░"
    fi
  done
  printf '%s' "$bar"
}

# Model pill color, gradient by pricing tier: Haiku -> Sonnet -> Opus -> Fable.
model_color() {
  local truecolor fallback bold=""
  case "$1" in
    *Haiku*)          truecolor='\033[38;2;100;149;237m'; fallback="$BLUE" ;;
    *Sonnet*)         truecolor='\033[38;2;80;200;140m';  fallback="$GREEN" ;;
    *Opus*)           truecolor='\033[38;2;230;150;60m';  fallback="$YELLOW" ;;
    *Fable*|*Mythos*) truecolor='\033[38;2;255;60;180m';  fallback="$MAGENTA"; bold='\033[1m' ;;
    *)                truecolor="$CYAN";                  fallback="$CYAN" ;;
  esac
  if (( USE_TRUECOLOR )); then
    printf '%b' "${bold}${truecolor}"
  else
    printf '%b' "${bold}${fallback}"
  fi
}

# Effort shorthand, clothing-size style: low->S, medium->M, high->L, xhigh->XL, max->XXL.
effort_shorthand() {
  case "$1" in
    low)    printf 'S' ;;
    medium) printf 'M' ;;
    high)   printf 'L' ;;
    xhigh)  printf 'XL' ;;
    max)    printf 'XXL' ;;
    *)      printf '%s' "$1" ;;
  esac
}

# Maps effort level onto the same 0-100 severity scale as tier_color, so a
# session accidentally left on max effort reads as loud/red.
effort_risk_pct() {
  case "$1" in
    low)    printf '0' ;;
    medium) printf '25' ;;
    high)   printf '55' ;;
    xhigh)  printf '80' ;;
    max)    printf '100' ;;
    *)      printf '40' ;;
  esac
}

# Truncates a session name to its first two words, splitting on space or
# dash (so "update claude config" -> "update claude…", "my-session-name"
# -> "my-session…"). Left whole if it never reaches a second delimiter.
trim_session() {
  local s="${1:-}"
  awk -v s="$s" 'BEGIN {
    n = 0
    out = ""
    len = length(s)
    for (i = 1; i <= len; i++) {
      c = substr(s, i, 1)
      if (c == " " || c == "-") {
        n++
        if (n == 2) { printf "%s…", out; exit }
      }
      out = out c
    }
    printf "%s", out
  }'
}

# ═══════════════════════════════════════════════════════════════
# Read JSON (single jq invocation)
# ═══════════════════════════════════════════════════════════════

input=$(cat)
debug_log_input "$input"

parsed=$(echo "$input" | jq -r '
  (.model.display_name // ""),
  (.context_window.used_percentage // 0 | tostring),
  (.workspace.current_dir // "." | split("/") | last),
  (.worktree.branch // ""),
  (.rate_limits.five_hour.used_percentage // -1 | tostring),
  (.rate_limits.seven_day.used_percentage // -1 | tostring),
  (.workspace.current_dir // "."),
  (.context_window.context_window_size // 0 | tostring),
  (.session_name // ""),
  (.effort.level // ""),
  (.workspace.repo.name // ""),
  (.rate_limits.five_hour.resets_at // "" | tostring),
  (.rate_limits.seven_day.resets_at // "" | tostring),
  (.context_window.total_input_tokens // 0 | tostring),
  (.context_window.total_output_tokens // 0 | tostring),
  "END"
' 2>/dev/null) || fallback_prompt "─ │ parse error"

{
  IFS= read -r model_name
  IFS= read -r ctx_pct
  IFS= read -r dir
  IFS= read -r branch
  IFS= read -r rate5h
  IFS= read -r rate7d
  IFS= read -r cwd_full
  IFS= read -r ctx_size
  IFS= read -r session_name
  IFS= read -r effort_level
  IFS= read -r repo_name
  IFS= read -r five_hour_resets_at
  IFS= read -r seven_day_resets_at
  IFS= read -r ctx_input_tokens
  IFS= read -r ctx_output_tokens
  IFS= read -r _sentinel
} <<< "$parsed"

# ═══════════════════════════════════════════════════════════════
# Model
# ═══════════════════════════════════════════════════════════════

model="${model_name:-─}"

# ═══════════════════════════════════════════════════════════════
# Context percentage
# ═══════════════════════════════════════════════════════════════

pct_int=$(clamp_pct "$ctx_pct")

# ═══════════════════════════════════════════════════════════════
# Effort (shorthand in parens, colored by the same severity scale)
# ═══════════════════════════════════════════════════════════════

effort_segment=""
if [[ -n "$effort_level" ]]; then
  effort_label=$(effort_shorthand "$effort_level")
  effort_color=$(tier_color "$(effort_risk_pct "$effort_level")")
  effort_segment=" ${effort_color}(${effort_label})${RST}"
fi

# ═══════════════════════════════════════════════════════════════
# Directory (repo name > cwd basename > ~ alias), light grey/white
# ═══════════════════════════════════════════════════════════════

if [[ -n "$repo_name" ]]; then
  dir_label="$repo_name"
elif [[ -n "${cwd_full:-}" && "$cwd_full" == "$HOME" ]]; then
  dir_label="~"
else
  dir_label="${dir:-.}"
fi

# ═══════════════════════════════════════════════════════════════
# Git branch, dirty marker, ahead/behind (with per-directory cache)
# ═══════════════════════════════════════════════════════════════

git_cache_key=$(printf '%s' "${cwd_full:-}" | md5 -q 2>/dev/null || echo "nodir")
GIT_CACHE="/tmp/claude-statusline-git-cache-${git_cache_key}"
GIT_CACHE_MAX_AGE=5

git_branch="${branch:-}"
dirty=""
git_ahead=0
git_behind=0
in_git_repo=0

git_cache_is_stale() {
  [[ ! -f "$GIT_CACHE" ]] && return 0
  local cache_age=$(( $(date +%s) - $(stat -f %m "$GIT_CACHE" 2>/dev/null || echo 0) ))
  (( cache_age > GIT_CACHE_MAX_AGE ))
}

if [[ -n "${cwd_full:-}" && -d "${cwd_full:-}" ]]; then
  if git_cache_is_stale; then
    if git -C "$cwd_full" rev-parse --git-dir &>/dev/null; then
      cached_branch="${git_branch}"
      if [[ -z "$cached_branch" ]]; then
        cached_branch=$(git -C "$cwd_full" -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null) || true
        if [[ -z "$cached_branch" ]]; then
          cached_branch=$(git -C "$cwd_full" rev-parse --short HEAD 2>/dev/null) || true
        fi
      fi
      cached_dirty=""
      if ! git -C "$cwd_full" -c core.useBuiltinFSMonitor=false diff --quiet 2>/dev/null || \
         ! git -C "$cwd_full" -c core.useBuiltinFSMonitor=false diff --cached --quiet 2>/dev/null; then
        cached_dirty="*"
      fi
      cached_ab=$(git -C "$cwd_full" -c core.useBuiltinFSMonitor=false rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null) || true
      cached_behind=0
      cached_ahead=0
      if [[ -n "$cached_ab" ]]; then
        cached_behind=$(awk '{print $1}' <<< "$cached_ab")
        cached_ahead=$(awk '{print $2}' <<< "$cached_ab")
      fi
      echo "${cached_branch}|${cached_dirty}|${cached_ahead}|${cached_behind}|1" > "$GIT_CACHE"
    else
      echo "||0|0|0" > "$GIT_CACHE"
    fi
  fi

  if [[ -f "$GIT_CACHE" ]]; then
    IFS='|' read -r cached_br cached_dt cached_ah cached_bh cached_in_repo < "$GIT_CACHE"
    if [[ -z "$git_branch" ]]; then git_branch="${cached_br}"; fi
    dirty="${cached_dt}"
    git_ahead="${cached_ah:-0}"
    git_behind="${cached_bh:-0}"
    in_git_repo="${cached_in_repo:-0}"
  fi
fi

git_segment=""
if (( in_git_repo )) && [[ -n "$git_branch" ]]; then
  git_needs_action=0
  [[ -n "$dirty" ]] && git_needs_action=1
  (( git_ahead > 0 || git_behind > 0 )) && git_needs_action=1

  if (( git_ahead + git_behind >= 10 )); then
    git_color=$(tier_color 95)
  elif (( git_needs_action )); then
    git_color=$(tier_color 88)
  else
    git_color="$GRAY"
  fi

  ab=""
  if (( git_ahead > 0 || git_behind > 0 )); then
    ab=" "
    (( git_ahead > 0 ))  && ab+="↑${git_ahead}"
    (( git_ahead > 0 && git_behind > 0 )) && ab+=" "
    (( git_behind > 0 )) && ab+="↓${git_behind}"
  fi
  git_segment="${SEP}${git_color}${S_BRANCH}${git_branch}${dirty}${ab}${RST}"
fi

# ═══════════════════════════════════════════════════════════════
# Rate limits (5h / 7d)
# ═══════════════════════════════════════════════════════════════

rate5h_int=${rate5h%.*}; rate5h_int=${rate5h_int:-0}
rate7d_int=${rate7d%.*}; rate7d_int=${rate7d_int:-0}

# ═══════════════════════════════════════════════════════════════
# Build first line: model+effort, session name, directory, git
# ═══════════════════════════════════════════════════════════════

line1="$(model_color "$model")${model}${RST}${effort_segment}"
if [[ -n "$session_name" ]]; then
  line1+="${SEP}${SESSION_COLOR}\"$(trim_session "$session_name")\"${RST}"
fi
line1+="${SEP}${FOLDER_COLOR}${dir_label}${RST}"
line1+="${git_segment}"

# ═══════════════════════════════════════════════════════════════
# Build second line: C, 5h, 7d bars, each pill one solid severity color
# ═══════════════════════════════════════════════════════════════

# Renders one rate-limit pill: "<label>:<bar> <pct>% <timer-icon> <countdown>",
# the whole thing in one color end to end.
rate_pill() {
  local label="$1" pct="$2" resets_at="$3"
  local color bar pill
  color=$(tier_color "$pct")
  bar=$(render_bar "$pct" "$color")
  pill="${color}${label}:${bar} ${color}${pct}%"
  if [[ -n "$resets_at" ]]; then
    pill+=" ${color}${S_TIMER} $(time_until "$resets_at")"
  fi
  pill+="${RST}"
  printf '%s' "$pill"
}

bar_parts=()

if (( rate7d_int >= 0 )); then
  bar_parts+=("$(rate_pill "7d" "$rate7d_int" "$seven_day_resets_at")")
fi

if (( rate5h_int >= 0 )); then
  bar_parts+=("$(rate_pill "5h" "$rate5h_int" "$five_hour_resets_at")")
fi

if (( ctx_size > 0 )); then
  c_color=$(tier_color "$pct_int")
  c_bar=$(render_bar "$pct_int" "$c_color")
  c_used=$(human_count "$(( ${ctx_input_tokens:-0} + ${ctx_output_tokens:-0} ))")
  c_total=$(human_count "${ctx_size:-0}")
  bar_parts+=("${c_color}C:${c_bar} ${c_color}${pct_int}% ${c_used}/${c_total}${RST}")
fi

line2=""
for i in "${!bar_parts[@]}"; do
  (( i > 0 )) && line2+="${SEP}"
  line2+="${bar_parts[$i]}"
done

# ═══════════════════════════════════════════════════════════════
# Output
# ═══════════════════════════════════════════════════════════════

# Output only two lines (Claude Code has its own input prompt, so we do not render ours)
printf '%b\n%b' "$line1" "$line2"
