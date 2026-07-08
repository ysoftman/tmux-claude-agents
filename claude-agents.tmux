#!/usr/bin/env bash
# ysoftman
# tmux-claude-agents 플러그인 엔트리 — TPM(@plugin) 또는 .tmux.conf 의 run-shell 이 로드한다.
# 두 번째 status line 에 실행 중인 claude code 에이전트 목록과 작업중 여부를 표시한다.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tmux set -g status 2
tmux set -g 'status-format[1]' "#[align=left] #($CURRENT_DIR/scripts/claude_agents.sh)"
