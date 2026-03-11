#!/bin/bash
# Status line: model name + context usage progress bar

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cwd=$(echo "$input" | jq -r '.cwd // ""')
git_info=""
if [ -n "$cwd" ]; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        dirty=$(git -C "$cwd" status --porcelain 2>/dev/null)
        if [ -n "$dirty" ]; then
            git_info=" ⎇ ${branch}*"
        else
            git_info=" ⎇ ${branch}"
        fi
    fi
fi

# Display current directory (replace $HOME with ~)
dir_display="${cwd/#$HOME/\~}"
printf "%s" "$dir_display"

if [ -n "$used" ]; then
    pct=$(printf "%.0f" "$used")
    filled=$(( pct / 10 ))
    empty=$(( 10 - filled ))
    bar=""
    for i in $(seq 1 $filled); do bar="${bar}█"; done
    for i in $(seq 1 $empty);  do bar="${bar}░"; done
    printf " [%s]%s %s %d%%" "$model" "$git_info" "$bar" "$pct"
else
    printf " [%s]%s" "$model" "$git_info"
fi

added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
if [ "$added" -gt 0 ] || [ "$removed" -gt 0 ]; then
    printf " +%d/-%d" "$added" "$removed"
fi

# Session duration from total_duration_ms
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
if [ "$duration_ms" -gt 0 ]; then
    duration_s=$(( duration_ms / 1000 ))
    hours=$(( duration_s / 3600 ))
    minutes=$(( (duration_s % 3600) / 60 ))
    seconds=$(( duration_s % 60 ))
    if [ "$hours" -gt 0 ]; then
        printf " ⏱ %dh%02dm" "$hours" "$minutes"
    elif [ "$minutes" -gt 0 ]; then
        printf " ⏱ %dm%02ds" "$minutes" "$seconds"
    else
        printf " ⏱ %ds" "$seconds"
    fi
fi

# System load (1min average)
load=$(awk '{printf "%.2f", $1}' /proc/loadavg)
printf " ⚡%s" "$load"
