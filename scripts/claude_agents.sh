#!/usr/bin/env bash
# ysoftman
# Claude Code / OpenCode agents status-line daemon for tmux — started by claude-agents.tmux.
# Claude Code reports its state via the OSC title (braille spinner = working),
# which tmux captures in pane_title, so per-session state is read per pane.
# OpenCode only puts the session name in the title, so its state is read from
# the TUI footer line instead.
# Sessions in the same directory are merged into one entry with stacked icons
# (e.g. ✻● myenv).
# Sets status-format[1] directly and shrinks status back to one line when no
# agent is running, hiding the line entirely. Exits when tmux server dies
# (set fails).

# match braille spinner (U+2800-U+28FF) by UTF-8 byte prefix, locale-independent
export LC_ALL=C

# claude: same star sequence Claude Code animates with, ping-ponging back down
# opencode: braille spin. both are 10 frames, so one index drives both
frames=('·' '✢' '✳' '✶' '✻' '✽' '✻' '✶' '✳' '✢')
bframes=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
blocked_re='do you want to|would you like to|waiting for permission|esc to cancel'

# append icons collected for the previous directory (prev) to cached as one entry
flush() {
    local name
    [ -z "$prev" ] && return
    name="${prev##*/}"
    if [[ "$icons" == *fg=red* ]]; then
        cached+="${icons} #[fg=red,bold]${name}#[default]   "
    elif [[ "$icons" == *ICON@* ]]; then
        cached+="${icons} #[fg=yellow,bold]${name}#[default]   "
    else
        cached+="${icons} #[fg=green]${name}#[default]   "
    fi
}

scan() {
    local cmd path id title agent screen
    cached=""
    prev=""
    icons=""
    while IFS=$'\t' read -r cmd path id title; do
        # identify agent panes by process/command name so stale pane titles after
        # exit don't become ghost entries:
        # - claude sets its process title to a version string (e.g. 2.1.204)
        # - opencode runs as a binary named opencode (or opencode.exe)
        # ponytail: if the title convention changes, switch to checking child process comm under pane_pid
        case "$cmd" in
            [0-9]*.[0-9]*) agent=claude ;;             # claude code
            opencode | opencode.exe) agent=opencode ;; # opencode
            *) continue ;;
        esac
        if [ "$path" != "$prev" ]; then
            flush
            prev="$path"
            icons=""
        fi
        if [ "$agent" = opencode ]; then
            # opencode puts only the session name in the title (OC | ...), so state
            # comes off the screen: a "Permission required" dialog while it needs
            # the user, "esc interrupt" in the footer while a turn is running
            screen=$(tmux capture-pane -p -t "$id" 2>/dev/null | tail -20)
            case "$screen" in
                *"Permission required"*) icons+='#[fg=red,bold]!#[default]' ;;
                *"esc interrupt"*) icons+='#[fg=yellow,bold]@BICON@#[default]' ;;
                *) icons+='#[fg=green]●#[default]' ;;
            esac
            continue
        fi
        case "$title" in
            $'\xe2\xa0'* | $'\xe2\xa1'* | $'\xe2\xa2'* | $'\xe2\xa3'*) # braille = working
                icons+='#[fg=yellow,bold]@ICON@#[default]'
                ;;
            *) # claude: blocked if a permission prompt is on screen
                # ponytail: conversation output containing the same phrases near the bottom can false-positive — resolves itself once it scrolls
                if tmux capture-pane -p -t "$id" 2>/dev/null | tail -20 | grep -qiE "$blocked_re"; then
                    icons+='#[fg=red,bold]!#[default]'
                else
                    icons+='#[fg=green]●#[default]'
                fi
                ;;
        esac
    done < <(tmux list-panes -a -F $'#{pane_current_command}\t#{pane_current_path}\t#{pane_id}\t#{pane_title}' | sort -t$'\t' -k2,2)
    flush
}

# set only when the line content changes (exit if tmux server is gone)
show_line() {
    [ "$1" = "$last_line" ] && return
    last_line="$1"
    tmux set -g 'status-format[1]' "#[align=left] $1" || exit 0
}

last_line=""
visible=""
tick=0
while :; do
    # scan about every 3 seconds, refresh the frame every iteration
    ((tick % 3 == 0)) && scan
    tick=$((tick + 1))
    if [ -z "$cached" ]; then
        if [ "$visible" != off ]; then
            tmux set -g status on || exit 0 # no agents — hide the line
            visible=off
        fi
        sleep 1
        continue
    fi
    if [ "$visible" != on ]; then
        tmux set -g status 2 || exit 0
        visible=on
    fi
    if [[ "$cached" == *ICON@* ]]; then
        for i in "${!frames[@]}"; do
            line="${cached//@ICON@/${frames[i]}}"
            show_line "${line//@BICON@/${bframes[i]}}"
            sleep 0.2
        done
    else
        show_line "$cached"
        sleep 1
    fi
done
