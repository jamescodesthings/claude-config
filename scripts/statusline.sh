#!/usr/bin/env bash
set -euo pipefail

# Temporary hard-coded debug switch. Set to 1 to log each input payload.
DEBUG=1
DEBUG_LOG_DIR="$HOME/.claude/status-logs"

# Originally: https://github.com/kcchien/claude-code-statusline
# modified for my needs

debug_log_input() {
  [[ "$DEBUG" == "1" ]] || return 0

  local ts log_file
  ts=$(date +"%Y-%m-%dT%H:%M:%S%z")
  log_file="$DEBUG_LOG_DIR/statusline-$(date +%Y-%m-%d).log"

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
USE_POWERLINE="${CLAUDE_STATUSLINE_POWERLINE:-$USE_NERDFONT}"
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
else
  GRAY='\033[90m'
fi

# Gradient stops (truecolor): green -> yellow -> orange -> red.
# Shared by the context/rate-limit bars, gradient_color(), and effort color.
GRAD_R=(46 116 186 241 239 236 233 231 211 192)
GRAD_G=(204 195 186 196 161 126 101 76 66 57)
GRAD_B=(113 89 64 15 24 34 44 60 50 43)

# Symbol set
if [[ "$USE_ASCII" == "1" ]]; then
  S_BRANCH=">"
  S_COST=""
  S_THINK="[think]"
  S_FAST="[fast]"
  S_TIMER=""
  SEP=" | "
else
  if [[ "$USE_NERDFONT" == "1" ]]; then
    S_BRANCH=" "
    S_COST=" "
    S_THINK=$'\xEF\x97\x9C'   # nf-md-brain (U+F5DC)
    S_FAST=$'\xEF\x83\xA7'    # nf-fa-bolt (U+F0E7)
    S_TIMER=$'\xEF\x80\x97'   # nf-fa-clock-o (U+F017)
  else
    S_BRANCH="⎇"
    S_COST=""
    S_THINK="🧠"
    S_FAST="⚡"
    S_TIMER="⏱"
  fi
  if [[ "$USE_POWERLINE" == "1" ]]; then
    SEP="  "
  else
    SEP=" │ "
  fi
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
# Helpers: human-readable counts, reset countdowns, color gradient
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

# Green/yellow/red for a percentage, given the red and yellow thresholds.
# Used wherever truecolor is unavailable, so the gradient can't be applied.
threshold_color() {
  local pct="$1" red_at="$2" yellow_at="$3"
  if (( pct >= red_at )); then printf '%b' "$RED"
  elif (( pct >= yellow_at )); then printf '%b' "$YELLOW"
  else printf '%b' "$GREEN"
  fi
}

# Returns a truecolor escape (or ANSI fallback color) for a 0-100 percentage,
# interpolated across the shared GRAD_R/G/B stops.
gradient_color() {
  local pct
  pct=$(clamp_pct "${1:-0}")
  if (( ! USE_TRUECOLOR )); then
    threshold_color "$pct" 80 50
    return
  fi
  local idx=$(( pct * 9 / 100 ))
  printf '\033[38;2;%d;%d;%dm' "${GRAD_R[$idx]}" "${GRAD_G[$idx]}" "${GRAD_B[$idx]}"
}

# Renders a 10-segment bar for a 0-100 percentage, honoring USE_ASCII/USE_TRUECOLOR.
render_bar() {
  local pct
  pct=$(clamp_pct "${1:-0}")
  local filled=$(( pct / 10 ))
  local bar="" i

  if [[ "$USE_ASCII" == "1" ]]; then
    for (( i=0; i<10; i++ )); do
      if (( i < filled )); then bar+="#"; else bar+="-"; fi
    done
    printf '%s' "$bar"
    return
  fi

  # Truecolor: every filled segment takes its own gradient stop. Unfilled
  # segments use Solarized base01 (#586e75) rather than near-black, so the
  # empty part of the bar stays visible against a dark background.
  if (( USE_TRUECOLOR )); then
    for (( i=0; i<10; i++ )); do
      if (( i < filled )); then
        bar+="\\033[38;2;${GRAD_R[$i]};${GRAD_G[$i]};${GRAD_B[$i]}m█"
      else
        bar+="\\033[38;2;88;110;117m░"
      fi
    done
    printf '%s' "${bar}${RST}"
    return
  fi

  # Otherwise: one threshold color for the whole bar.
  for (( i=0; i<10; i++ )); do
    if (( i < filled )); then bar+="█"; else bar+="░"; fi
  done
  printf '%s' "$(threshold_color "$pct" 90 70)${bar}${RST}"
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

# Maps effort level to a 0-100 "cost risk" position on the same gradient used
# elsewhere, so a session accidentally left on max effort reads as loud/red.
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

# ═══════════════════════════════════════════════════════════════
# Read JSON (single jq invocation)
# ═══════════════════════════════════════════════════════════════

input=$(cat)
debug_log_input "$input"

parsed=$(echo "$input" | jq -r '
  (.model.display_name // ""),
  (.context_window.used_percentage // 0 | tostring),
  (.cost.total_cost_usd // 0 | tostring),
  (.workspace.current_dir // "." | split("/") | last),
  (.worktree.branch // ""),
  (.rate_limits.five_hour.used_percentage // -1 | tostring),
  (.rate_limits.seven_day.used_percentage // -1 | tostring),
  (.workspace.current_dir // "."),
  (.context_window.context_window_size // 0 | tostring),
  (.session_name // ""),
  (.effort.level // ""),
  (.workspace.repo.name // ""),
  (.thinking.enabled // false),
  (.fast_mode // false),
  (.exceeds_200k_tokens // false),
  (.rate_limits.five_hour.resets_at // "" | tostring),
  (.rate_limits.seven_day.resets_at // "" | tostring),
  (.context_window.total_input_tokens // 0 | tostring),
  (.context_window.total_output_tokens // 0 | tostring),
  "END"
' 2>/dev/null) || fallback_prompt "─ │ parse error"

{
  IFS= read -r model_name
  IFS= read -r ctx_pct
  IFS= read -r cost
  IFS= read -r dir
  IFS= read -r branch
  IFS= read -r rate5h
  IFS= read -r rate7d
  IFS= read -r cwd_full
  IFS= read -r ctx_size
  IFS= read -r session_name
  IFS= read -r effort_level
  IFS= read -r repo_name
  IFS= read -r thinking_enabled
  IFS= read -r fast_mode
  IFS= read -r exceeds_200k
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
# Cost (hidden entirely at $0)
# ═══════════════════════════════════════════════════════════════

cost_fmt=$(printf '%.2f' "${cost:-0}" 2>/dev/null || echo "0.00")
cost_int=${cost%.*}
cost_int=${cost_int:-0}

cost_segment=""
if [[ "$cost_fmt" != "0.00" ]]; then
  if (( cost_int >= 10 )); then cost_color="$RED"; else cost_color="$YELLOW"; fi
  cost_segment="${SEP}${cost_color}${S_COST}\$${cost_fmt}${RST}"
fi

# ═══════════════════════════════════════════════════════════════
# Effort (shorthand + risk-colored so max doesn't go unnoticed)
# ═══════════════════════════════════════════════════════════════

effort_segment=""
if [[ -n "$effort_level" ]]; then
  effort_label=$(effort_shorthand "$effort_level")
  effort_color=$(gradient_color "$(effort_risk_pct "$effort_level")")
  effort_segment=" ${effort_color}${effort_label}${RST}"
fi

# ═══════════════════════════════════════════════════════════════
# Directory (repo name > cwd basename > ~ alias)
# ═══════════════════════════════════════════════════════════════

if [[ -n "$repo_name" ]]; then
  dir_label="$repo_name"
elif [[ -n "${cwd_full:-}" && "$cwd_full" == "$HOME" ]]; then
  dir_label="~"
else
  dir_label="${dir:-.}"
fi

# ═══════════════════════════════════════════════════════════════
# Git branch, dirty marker, ahead/behind (with cache)
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
  ab=""
  if (( git_ahead > 0 || git_behind > 0 )); then
    ab_color="$GRAY"
    (( git_ahead + git_behind >= 10 )) && ab_color="\033[1m${RED}"
    ab=" ${ab_color}"
    (( git_ahead > 0 ))  && ab+="↑${git_ahead}"
    (( git_ahead > 0 && git_behind > 0 )) && ab+=" "
    (( git_behind > 0 )) && ab+="↓${git_behind}"
    ab+="${RST}"
  fi
  git_segment="${SEP}${GRAY}${S_BRANCH}${git_branch}${dirty}${RST}${ab}"
fi

# ═══════════════════════════════════════════════════════════════
# Rate limits (5h / 7d) with reset countdowns
# ═══════════════════════════════════════════════════════════════

rate5h_int=${rate5h%.*}; rate5h_int=${rate5h_int:-0}
rate7d_int=${rate7d%.*}; rate7d_int=${rate7d_int:-0}

# ═══════════════════════════════════════════════════════════════
# Global tone: escalates only with the worse of 5h/7d, never context
# ═══════════════════════════════════════════════════════════════

global_tone_pct=$rate5h_int
(( rate7d_int > global_tone_pct )) && global_tone_pct=$rate7d_int
tone_bold=""
(( global_tone_pct >= 80 )) && tone_bold='\033[1m'

# ═══════════════════════════════════════════════════════════════
# Tags (far right, no background)
# ═══════════════════════════════════════════════════════════════

tags=""
if [[ "$thinking_enabled" == "true" ]]; then tags+=" ${S_THINK}"; fi
if [[ "$fast_mode" == "true" ]]; then tags+=" ${YELLOW}${S_FAST}${RST}"; fi
if [[ "$exceeds_200k" == "true" ]]; then tags+=" ${GRAY}!200k${RST}"; fi

# ═══════════════════════════════════════════════════════════════
# Build first line: model+effort, dir, git, cost, session name
# ═══════════════════════════════════════════════════════════════

line1="$(model_color "$model")${model}${RST}${effort_segment}"
line1+="${SEP}${BLUE}${dir_label}${RST}"
line1+="${git_segment}"
line1+="${cost_segment}"
if [[ -n "$session_name" ]]; then
  line1+="${SEP}${GRAY}${session_name}${RST}"
fi

# ═══════════════════════════════════════════════════════════════
# Build second line: C bar (context, merged with the old S detail), 5h, 7d, tags
# ═══════════════════════════════════════════════════════════════

# Renders one rate-limit pill: "<label>:<pct>% <timer-icon><countdown>".
rate_pill() {
  local label="$1" pct="$2" resets_at="$3"
  local pill="${tone_bold}${label}:$(gradient_color "$pct")${pct}%${RST}"
  if [[ -n "$resets_at" ]]; then
    pill+=" ${GRAY}${S_TIMER}$(time_until "$resets_at")${RST}"
  fi
  printf '%s' "$pill"
}

bar_parts=()

if (( ctx_size > 0 )); then
  c_bar=$(render_bar "$pct_int")
  c_used=$(human_count "$(( ${ctx_input_tokens:-0} + ${ctx_output_tokens:-0} ))")
  c_total=$(human_count "${ctx_size:-0}")
  bar_parts+=("${tone_bold}C:${c_bar} $(gradient_color "$pct_int")${pct_int}%${RST} ${GRAY}${c_used}/${c_total}${RST}")
fi

if (( rate5h_int >= 0 )); then
  bar_parts+=("$(rate_pill "5h" "$rate5h_int" "$five_hour_resets_at")")
fi

if (( rate7d_int >= 0 )); then
  bar_parts+=("$(rate_pill "7d" "$rate7d_int" "$seven_day_resets_at")")
fi

line2=""
for i in "${!bar_parts[@]}"; do
  (( i > 0 )) && line2+=" ${SEP}"
  line2+="${bar_parts[$i]}"
done
line2+="${tags}"

# ═══════════════════════════════════════════════════════════════
# Output
# ═══════════════════════════════════════════════════════════════

# Output only two lines (Claude Code has its own input prompt, so we do not render ours)
printf '%b\n%b' "$line1" "$line2"
