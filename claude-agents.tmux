#!/usr/bin/env bash
# ysoftman
# tmux-claude-agents plugin entry — loaded by TPM (@plugin) or run-shell in .tmux.conf.
# Starts the daemon (scripts/claude_agents.sh), which keeps each window's
# agent state icon in its @ca_icon option, shown next to the tab title via
# #{@ca_icon} inserted into window-status-format.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# clear the second status line a pre-tab-icon daemon may have left behind
# (it set "status 2" and status-format[1] and nothing else resets them)
tmux set -gu status 2>/dev/null
tmux set -gu 'status-format[1]' 2>/dev/null

# start under the tmux server, not as a child of whatever shell ran this entry:
# a daemon backgrounded from a terminal or an agent session dies with it, and
# the icons silently stop until the next reload.
# no kill of the old daemon here — the new one claims @claude_agents_pid and the
# old one sees the change and exits itself (a stored pid may be reused by an
# unrelated process by the time we would kill it)
tmux run-shell -b "'$CURRENT_DIR/scripts/claude_agents.sh' >/dev/null 2>&1"
