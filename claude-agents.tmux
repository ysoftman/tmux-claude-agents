#!/usr/bin/env bash
# ysoftman
# tmux-claude-agents 플러그인 엔트리 — TPM(@plugin) 또는 .tmux.conf 의 run-shell 이 로드한다.
# 데몬(scripts/claude_agents.sh)을 시작한다. 데몬이 두 번째 status line 을 직접
# 갱신하고, claude 에이전트가 없으면 라인을 숨긴다.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 재로드 시 이전 데몬 정리
old_pid="$(tmux show-option -gqv @claude_agents_pid)"
[ -n "$old_pid" ] && kill "$old_pid" 2>/dev/null

"$CURRENT_DIR/scripts/claude_agents.sh" >/dev/null 2>&1 &
tmux set -g @claude_agents_pid "$!"
