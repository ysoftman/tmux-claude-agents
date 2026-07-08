#!/usr/bin/env bash
# ysoftman
# tmux-claude-agents plugin entry — loaded by TPM (@plugin) or run-shell in .tmux.conf.
# Starts the daemon (scripts/claude_agents.sh), which updates the second status
# line directly and hides it when no claude agent is running.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# kill the previous daemon on reload
old_pid="$(tmux show-option -gqv @claude_agents_pid)"
[ -n "$old_pid" ] && kill "$old_pid" 2>/dev/null

"$CURRENT_DIR/scripts/claude_agents.sh" >/dev/null 2>&1 &
tmux set -g @claude_agents_pid "$!"
