#!/usr/bin/env bash
# ysoftman
# tmux-claude-agents plugin entry — loaded by TPM (@plugin) or run-shell in .tmux.conf.
# Starts the daemon (scripts/claude_agents.sh), which keeps each window's
# agent state icon in its @ca_icon option, shown next to the tab title via
# #{@ca_icon} inserted into window-status-format.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# kill the previous daemon on reload
old_pid="$(tmux show-option -gqv @claude_agents_pid)"
[ -n "$old_pid" ] && kill "$old_pid" 2>/dev/null

# clear the second status line a pre-tab-icon daemon may have left behind
# (it set "status 2" and status-format[1] and nothing else resets them)
tmux set -gu status 2>/dev/null
tmux set -gu 'status-format[1]' 2>/dev/null

"$CURRENT_DIR/scripts/claude_agents.sh" >/dev/null 2>&1 &
tmux set -g @claude_agents_pid "$!"
