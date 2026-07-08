#!/usr/bin/env bash
# ysoftman
# tmux status line 용 claude code 에이전트 목록 모듈 (herdr 에이전트 바 대체용).
# 실행 중인 claude 프로세스의 cwd 로 프로젝트를 식별하고, 해당 프로젝트의
# 세션 transcript(~/.claude/projects/<slug>/*.jsonl) 최근 수정 여부로
# 작업중(✳)/대기(●) 를 판별한다. claude-agents.tmux 가 status-format[1] 에 등록한다.

# transcript 가 이 시간(초) 내에 수정됐으면 작업중으로 간주 (@claude_agents_busy_window 로 조정)
busy_window="$(tmux show-option -gqv @claude_agents_busy_window)"
busy_window="${busy_window:-10}"
idle_text='#[fg=colour244]no claude agents#[default]'

# pgrep 은 claude 가 프로세스명을 버전 문자열로 바꿔 놓쳐서 ps comm 기준으로 찾는다
pids="$(ps -axo pid=,comm= | awk '{c=$2; sub(/.*\//,"",c)} c=="claude"{print $1}' | paste -sd, -)"
if [ -z "$pids" ]; then
    printf '%s' "$idle_text"
    exit 0
fi

now="$(date +%s)"
out=""
while read -r cwd; do
    [ -z "$cwd" ] && continue
    name="${cwd##*/}"
    slug="$(printf '%s' "$cwd" | sed 's/[^a-zA-Z0-9]/-/g')"
    # ponytail: 같은 디렉토리에 세션이 여러 개면 최신 transcript 하나로 뭉뚱그려 판별
    # shellcheck disable=SC2012 # 파일명이 UUID.jsonl 뿐이라 ls -t 로 충분
    newest="$(ls -t "$HOME/.claude/projects/$slug"/*.jsonl 2>/dev/null | head -1)"
    mtime="$(stat -f %m "$newest" 2>/dev/null || echo 0)"
    if [ $((now - mtime)) -le "$busy_window" ]; then
        out+="#[fg=green,bold]✳ ${name}#[default]   "
    else
        out+="#[fg=colour244]● ${name}#[default]   "
    fi
done < <(lsof -a -p "$pids" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | sort)

printf '%s' "${out:-$idle_text}"
