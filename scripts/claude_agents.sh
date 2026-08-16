#!/usr/bin/env bash
# ysoftman
# Claude Code / OpenCode agents tab-icon daemon for tmux — started by claude-agents.tmux.
# Claude Code reports its state via the OSC title (spinner prefix = working),
# which tmux captures in pane_title, so per-session state is read per pane.
# OpenCode only puts the session name in the title, so its state is read from
# the TUI footer line instead.
# Agent panes in the same window stack their icons (e.g. ✻●) into that
# window's @ca_icon option, shown at the end of its tab by the #{@ca_icon}
# reference this daemon keeps appended to window-status-format.
# Exits when the tmux server dies or a newer daemon takes over (see stale),
# logging why to $TMPDIR/tmux-claude-agents.log.

# match spinner chars by UTF-8 byte prefix, locale-independent.
# claude code used braille ⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏ (U+2800-U+28FF) up to ~2.1.2xx, then switched to
# circle quadrants ◐◓◑◒ (U+25D0-U+25D3) as of 2.1.228 — match both.
# the pulsing star ·✢✳✶✻✽ seen while working lives only in the TUI screen,
# not the title; idle teammate panes carry a static ✳ title prefix, so a
# star in the title must NOT be treated as working
export LC_ALL=C

# claude: same star sequence Claude Code animates with, ping-ponging back down
# opencode: braille spin. both are 10 frames, so one index drives both
frames=('·' '✢' '✳' '✶' '✻' '✽' '✻' '✶' '✳' '✢')
bframes=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
blocked_re='do you want to|would you like to|waiting for permission|esc to cancel'
# star status line claude draws at column 1 only while a turn is running,
# e.g. "✳ Processing… (1m 28s · ↓ 2.8k tokens)" — gone when idle
working_re='^(·|✢|✳|✶|✻|✽) .*…'

# exit when a newer daemon has claimed @claude_agents_pid (plugin reloaded),
# so only the newest one drives the icons without anyone sending signals.
# also covers a dead tmux server: show fails, the empty value never matches $$
stale() {
    [ "$(tmux show -gqv @claude_agents_pid)" != "$$" ]
}

# icons stopping is silent, so leave a line behind saying when, why and after
# how long this daemon went away. a signal kill would skip the EXIT trap, so
# the usual suspects are trapped too — that's what tells an outside kill
# apart from the daemon deciding to stop
why=unknown
trap 'date "+%F %T pid $$ after ${SECONDS}s exit: $why" >>"${TMPDIR:-/tmp}/tmux-claude-agents.log"' EXIT
trap 'why=killed-by-signal; exit 0' TERM HUP INT PIPE

# keep #{@ca_icon} in the tab formats: a theme plugin loading after us, or
# a config reload, can overwrite window-status-format — re-add.
# a failing tmux call here is skipped, not fatal: only stale() decides to
# exit, so a transient failure can't silently stop the icons.
# inserted before the format's last #[...] style block, which in powerline
# themes is the closing separator, so the icon sits next to the tab title
# inside the themed segment; formats without styles get it appended.
# a format whose last #[ lives inside a #{?,,} conditional would be mangled
# — none of the common themes do that
hook_format() {
    local opt fmt head
    for opt in window-status-format window-status-current-format; do
        fmt=$(tmux show -gv "$opt") || return
        case "$fmt" in *'#{@ca_icon}'*) continue ;; esac
        head="${fmt%"#["*}"
        if [ "$head" = "$fmt" ]; then
            tmux set -g "$opt" "$fmt#{@ca_icon}"
        else
            tmux set -g "$opt" "$head#{@ca_icon}${fmt#"$head"}"
        fi
    done
}

# true if the title starts with a spinner char (braille or ◐◓◑◒).
# a spinner prefix alone doesn't prove working: claude leaves the last frame
# frozen in the title after it stops (seen on 2.1.228, e.g. after finishing
# while in the agents view). the title also freezes while a tool runs, so
# title animation can't be used either — the screen (working_re) decides
is_spinner() {
    case "$1" in
        $'\xe2\xa0'* | $'\xe2\xa1'* | $'\xe2\xa2'* | $'\xe2\xa3'* | \
            $'\xe2\x97\x90'* | $'\xe2\x97\x91'* | $'\xe2\x97\x92'* | $'\xe2\x97\x93'*) return 0 ;;
    esac
    return 1
}

# append icons collected for the previous window (prev) to cur as one line
flush() {
    [ -n "$prev" ] && cur+="$prev"$'\t'"$icons"$'\n'
}

scan() {
    local cmd wid id title agent screen panes prev icons
    panes=$(tmux list-panes -a -F $'#{pane_current_command}\t#{window_id}\t#{pane_id}\t#{pane_title}') || return
    # lines of "<window_id>\t<icons>"; leading newline so the
    # $'\n'<wid>$'\t' membership checks in apply can't match mid-line
    cur=$'\n'
    prev=""
    icons=""
    # panes of the same window are already adjacent in list-panes output,
    # so consecutive grouping needs no sort
    while IFS=$'\t' read -r cmd wid id title; do
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
        if [ "$wid" != "$prev" ]; then
            flush
            prev="$wid"
            icons=""
        fi
        # last 20 non-blank lines: the agents panel pads the bottom of the
        # screen with blank lines, pushing the status area above a plain
        # tail -20 window — working panes then read as idle
        screen=$(tmux capture-pane -p -t "$id" 2>/dev/null | grep -v '^[[:space:]]*$' | tail -20)
        if [ "$agent" = opencode ]; then
            # opencode puts only the session name in the title (OC | ...), so state
            # comes off the screen: a "Permission required" dialog while it needs
            # the user, "esc interrupt" in the footer while a turn is running
            case "$screen" in
                *"Permission required"*) icons+='#[fg=red,bold]!#[default]' ;;
                *"esc interrupt"*) icons+='#[fg=yellow,bold]@BICON@#[default]' ;;
                *) icons+='#[fg=green]●#[default]' ;;
            esac
            continue
        fi
        # claude: working = spinner title confirmed by the star status line on
        # screen; a spinner title without it is stale (agent already stopped)
        if is_spinner "$title" && grep -qE "$working_re" <<<"$screen"; then
            icons+='#[fg=yellow,bold]@ICON@#[default]'
        # blocked if a permission prompt is on screen
        # ponytail: conversation output containing the same phrases near the bottom can false-positive — resolves itself once it scrolls
        elif grep -qiE "$blocked_re" <<<"$screen"; then
            icons+='#[fg=red,bold]!#[default]'
        else
            icons+='#[fg=green]●#[default]'
        fi
    done <<<"$panes"
    flush
}

# resolve spinner frame $1 into each window's icons and push only changed
# values to @ca_icon; unset it on windows whose agents are gone.
# errors on set are ignored — the window may have closed since the scan
apply() {
    local wid val out=$'\n'
    while IFS=$'\t' read -r wid val; do
        [ -z "$wid" ] && continue
        val="${val//@ICON@/${frames[$1]}}"
        val="${val//@BICON@/${bframes[$1]}}"
        out+="$wid"$'\t'"$val"$'\n'
        case "$shown" in *$'\n'"$wid"$'\t'"$val"$'\n'*) continue ;; esac
        tmux set -w -t "$wid" @ca_icon " $val" 2>/dev/null
    done <<<"$cur"
    while IFS=$'\t' read -r wid val; do
        [ -z "$wid" ] && continue
        case "$out" in *$'\n'"$wid"$'\t'*) continue ;; esac
        tmux set -w -t "$wid" -u @ca_icon 2>/dev/null
    done <<<"$shown"
    shown="$out"
}

shown=$'\n'
tick=0
tmux set -g @claude_agents_pid "$$" || {
    why=no-server-at-start
    exit 0
}
while :; do
    # scan about every 3 seconds, refresh the frame every iteration
    if ((tick % 3 == 0)); then
        stale && {
            why='replaced or tmux server gone'
            exit 0
        }
        hook_format
        scan
    fi
    tick=$((tick + 1))
    case "$cur" in
        *ICON@*)
            for i in "${!frames[@]}"; do
                apply "$i"
                sleep 0.2
            done
            ;;
        *)
            apply 0
            sleep 1
            ;;
    esac
done
