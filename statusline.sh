#!/bin/bash
# Status line: two lines
# Line 1: dir [model] git +added/-removed
# Line 2: context bar + duration + load

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
        # Ahead/behind upstream
        ab=$(git -C "$cwd" rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)
        if [ -n "$ab" ]; then
            behind=$(echo "$ab" | awk '{print $1}')
            ahead=$(echo "$ab" | awk '{print $2}')
            [ "$ahead" -gt 0 ] && git_info="${git_info}↑${ahead}"
            [ "$behind" -gt 0 ] && git_info="${git_info}↓${behind}"
        fi
    fi
fi

# Line 1: dir [model] git +/-
dir_display="${cwd/#$HOME/\~}"
printf "%s [%s]%s" "$dir_display" "$model" "$git_info"

added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
if [ "$added" -gt 0 ] || [ "$removed" -gt 0 ]; then
    printf " +%d/-%d" "$added" "$removed"
fi

# Line 2: animated pet + context bar + duration + load
printf "\n"

printf "=^.^= "

if [ -n "$used" ]; then
    pct=$(printf "%.0f" "$used")
    filled=$(( pct / 10 ))
    empty=$(( 10 - filled ))
    bar=""
    for i in $(seq 1 $filled); do bar="${bar}█"; done
    for i in $(seq 1 $empty);  do bar="${bar}░"; done
    if [ "$pct" -ge 85 ]; then
        color="\033[31m"
    elif [ "$pct" -ge 70 ]; then
        color="\033[33m"
    else
        color="\033[32m"
    fi
    reset="\033[0m"
    printf "${color}%s %d%%${reset}" "$bar" "$pct"
fi

# Session duration
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

# System load
ncpu=$(sysctl -n hw.ncpu)
load=$(sysctl -n vm.loadavg | awk '{printf "%.2f", $2}')
load_int=$(echo "$load $ncpu" | awk '{printf "%.0f", ($1/$2)*100}')
if [ "$load_int" -ge 100 ]; then
    load_color="\033[31m"
elif [ "$load_int" -ge 50 ]; then
    load_color="\033[33m"
else
    load_color="\033[32m"
fi
printf " ${load_color}⚡%s\033[0m" "$load"
