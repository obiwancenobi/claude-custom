#!/bin/bash
# Claude Code Statusline Script
# Reads JSON from stdin and outputs formatted statusline
# Supports: model, tokens, git branch, context bar, compaction, cost,
#           session duration, unpushed commits, turn count, themes

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "jq not installed"
    exit 0
fi

# Read JSON from stdin
input=$(cat)

# ============================================================================
# Theme Configuration
# ============================================================================
# STATUSLINE_THEME is passed from settings.json env block.
# Possible values: "compact", "detailed", "monochrome"
STATUSLINE_THEME="${STATUSLINE_THEME:-detailed}"

# ============================================================================
# Session Tracking (temp dir for persistent state across invocations)
# ============================================================================
SESSION_DIR="${TMPDIR:-/tmp}/claude-statusline-$(id -u)"
mkdir -p "$SESSION_DIR" 2>/dev/null
SESSION_FILE="${SESSION_DIR}/session_start"
TURNS_FILE="${SESSION_DIR}/turns"
NOW=$(date +%s)

# Initialize session start time if not present
if [[ ! -f "$SESSION_FILE" ]]; then
    echo "$NOW" > "$SESSION_FILE"
fi
SESSION_START=$(cat "$SESSION_FILE" 2>/dev/null || echo "$NOW")

# Increment turn counter
if [[ -f "$TURNS_FILE" ]]; then
    TURNS=$(cat "$TURNS_FILE" 2>/dev/null)
    TURNS=$((TURNS + 1))
else
    TURNS=1
fi
echo "$TURNS" > "$TURNS_FILE"
# To reset session: rm -rf "$SESSION_DIR"

# Extract data from JSON
MODEL=$(echo "$input" | jq -r '.model.id // .model.display_name // "unknown"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "."')
DIRNAME=$(basename "$DIR")

# Context window info
USED_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
REMAINING_PCT=$(echo "$input" | jq -r '.context_window.remaining_percentage // 100')

# Token counts
INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# Cost info
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Check for exceeds_200k_tokens (compaction prediction)
EXCEEDS_200K=$(echo "$input" | jq -r '.exceeds_200k_tokens // false')

# Git branch and status (from worktree if available, otherwise try to get from git)
GIT_BRANCH=""
CHANGED=0
DELETED=0
if [[ "$input" != "null" ]]; then
    # Try worktree branch first
    GIT_BRANCH=$(echo "$input" | jq -r '.worktree.branch // empty')
    if [[ -z "$GIT_BRANCH" ]] || [[ "$GIT_BRANCH" == "null" ]]; then
        # Try to get from git directly
        GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    fi
    
    # Get git status counts if we're in a git repo
    if [[ -n "$GIT_BRANCH" ]] && [[ "$GIT_BRANCH" != "null" ]]; then
        # Count changed files: modified (M) + added (A) + renamed (R) + copied (C) + untracked (??)
        CHANGED=$(git status --porcelain 2>/dev/null | grep -cE "^[MARC] |^\?\?" || true)
        [[ -z "$CHANGED" ]] && CHANGED=0
        # Count deleted files (D)
        DELETED=$(git status --porcelain 2>/dev/null | grep -cE "^D " || true)
        [[ -z "$DELETED" ]] && DELETED=0
    fi
fi

# Colors (ANSI escape codes)
CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to create progress bar
create_progress_bar() {
    local pct=$1
    local width=10
    local filled=$((pct * width / 100))
    local empty=$((width - filled))
    
    local bar=""

    for ((i=0; i<filled; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done
    
    echo "$bar"
}

# Determine context bar color based on percentage
get_context_color() {
    local pct=$1
    if [[ "$STATUSLINE_THEME" == "monochrome" ]]; then
        echo ""
        return
    fi
    if (( pct >= 90 )); then
        echo "$RED"
    elif (( pct >= 70 )); then
        echo "$YELLOW"
    else
        echo "$GREEN"
    fi
}

# Format session duration as Xm Ys or Xh Ym
format_duration() {
    local secs=$1
    if (( secs >= 3600 )); then
        local hours=$((secs / 3600))
        local mins=$(( (secs % 3600) / 60 ))
        echo "${hours}h${mins}m"
    elif (( secs >= 60 )); then
        local mins=$((secs / 60))
        local secs_left=$((secs % 60))
        echo "${mins}m${secs_left}s"
    else
        echo "${secs}s"
    fi
}

# Get count of unpushed commits (commits ahead of upstream)
get_unpushed_count() {
    git rev-list --count "@{u}..HEAD" 2>/dev/null || echo "0"
}

# Build the statusline
STATUSLINE=""

# Compute additional data
SESSION_ELAPSED=$((NOW - SESSION_START))
SESSION_FMT=$(format_duration "$SESSION_ELAPSED")
UNPUSHED=$(get_unpushed_count)

# Determine colors based on theme
if [[ "$STATUSLINE_THEME" == "monochrome" ]]; then
    C_MODEL=""
    C_GREEN=""
    C_PURPLE=""
    C_BLUE=""
    C_ORANGE=""
    C_GRAY=""
    C_BOLD=""
    C_RED=""
    C_RESET=""
    SEP="|"
else
    C_MODEL="${CYAN}"
    C_GREEN="${GREEN}"
    C_PURPLE="${PURPLE}"
    C_BLUE="${BLUE}"
    C_ORANGE="${ORANGE}"
    C_GRAY="${GRAY}"
    C_BOLD="${BOLD}"
    C_RED="${RED}"
    C_RESET="${NC}"
    SEP="${GRAY}│${NC}"
fi

if [[ "$STATUSLINE_THEME" == "compact" ]]; then
    # Compact: model, branch, context% with minimal icons
    STATUSLINE+="${C_MODEL}${C_BOLD}🤖 ${MODEL}${C_RESET}"
    if [[ -n "$GIT_BRANCH" ]] && [[ "$GIT_BRANCH" != "null" ]]; then
        STATUSLINE+=" ${SEP} ${C_BLUE}⎇ ${DIRNAME}@${GIT_BRANCH}${C_RESET}"
    fi
    CONTEXT_COLOR=$(get_context_color "$USED_PCT")
    STATUSLINE+=" ${SEP} ${CONTEXT_COLOR}${USED_PCT}%${C_RESET}"

else
    # Detailed (default): full statusline, 2 lines
    # --- Line 1: Session context (model, tokens, git) ---
    LINE1=""

    # Model ID
    LINE1+="${C_MODEL}${C_BOLD}🤖 ${MODEL}${C_RESET}"

    # Input/Output tokens
    LINE1+=" ${SEP} ${C_GREEN}↑${INPUT_TOKENS}${C_RESET} ${C_PURPLE}↓${OUTPUT_TOKENS}${C_RESET}"

    # Git branch with project name and status
    if [[ -n "$GIT_BRANCH" ]] && [[ "$GIT_BRANCH" != "null" ]]; then
        LINE1+=" ${SEP} ${C_BLUE}⎇ ${DIRNAME}@${GIT_BRANCH}${C_RESET} ${C_GREEN}+${CHANGED}${C_RESET} ${C_RED}-${DELETED}${C_RESET}"
        # Unpushed commits
        if (( UNPUSHED > 0 )); then
            LINE1+=" ${C_ORANGE}⇡${UNPUSHED}${C_RESET}"
        fi
    fi

    STATUSLINE+="$LINE1\n"

    # --- Line 2: Usage metrics (context, duration, turns, cost) ---
    LINE2="  "

    # Context bar with percentage
    CONTEXT_COLOR=$(get_context_color "$USED_PCT")
    PROGRESS_BAR=$(create_progress_bar "$USED_PCT")
    LINE2+="${C_GRAY}📊${CONTEXT_COLOR}${PROGRESS_BAR}${C_RESET} ${CONTEXT_COLOR}${USED_PCT}%${C_RESET}"

    # Session duration
    LINE2+=" ${SEP} ${C_GRAY}⏱ ${SESSION_FMT}${C_RESET}"

    # Turn count
    LINE2+=" ${C_GRAY}💬 ${TURNS}${C_RESET}"

    # Compaction warning
    if [[ "$EXCEEDS_200K" == "true" ]]; then
        LINE2+=" ${SEP} ${C_ORANGE}⚡ compaction${C_RESET}"
    elif (( REMAINING_PCT <= 20 )); then
        LINE2+=" ${SEP} ${C_ORANGE}⚡ ~${REMAINING_PCT}% remaining${C_RESET}"
    fi

    # Cost (muted)
    COST_FORMATTED=$(printf "%.3f" "$COST" 2>/dev/null || echo "0.000")
    if awk "BEGIN {exit ($COST > 0 ? 0 : 1)}"; then
        LINE2+=" ${SEP} ${C_GRAY}💰 \$${COST_FORMATTED}${C_RESET}"
    fi

    STATUSLINE+="$LINE2"
fi

echo -e "$STATUSLINE"
