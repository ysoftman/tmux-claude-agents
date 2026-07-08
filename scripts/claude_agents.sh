#!/usr/bin/env bash
# ysoftman
# tmux status line 용 claude code 에이전트 목록 모듈.
# claude 프로세스의 cwd 로 프로젝트를 식별하고, 세션 transcript 최근 수정 여부로
# 작업중(스피너)/대기(●) 를 표시한다. 상주 루프 — tmux #() 는 살아있는 명령의
# 최신 출력 줄을 쓰므로 status-interval 보다 빠르게 스피너가 돈다.

busy_window="$(tmux show-option -gqv @claude_agents_busy_window)"
busy_window="${busy_window:-30}"
idle_text='#[fg=colour244]no claude agents#[default]'
frames=('✢' '✳' '✶' '✻' '✽')

# BSD(macOS) / GNU(Linux) 분기
if stat -f %m / >/dev/null 2>&1; then
    mtime_of() { stat -f %m "$1" 2>/dev/null || echo 0; }
else
    mtime_of() { stat -c %Y "$1" 2>/dev/null || echo 0; }
fi
if [ -e /proc/self/cwd ]; then
    cwds_of() {
        local p
        # shellcheck disable=SC2086 # pid 목록 공백 분리 의도
        for p in $1; do readlink "/proc/$p/cwd" 2>/dev/null; done | sort
    }
else
    cwds_of() { lsof -a -p "${1// /,}" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | sort; }
fi

last_pids=""
cwds=""

scan() {
    local pids now cnt cwd name slug icons n f
    # claude 는 프로세스 타이틀을 바꿔 pgrep 으로 못 잡아서 ps comm 기준
    pids="$(ps -eo pid=,comm= | awk '{c=$2; sub(/.*\//,"",c)} c=="claude"{print $1}' | paste -sd' ' -)"
    if [ -z "$pids" ]; then
        cached="$idle_text"
        last_pids=""
        return
    fi
    # pid 목록이 같으면 cwd 조회(lsof/proc) 생략
    if [ "$pids" != "$last_pids" ]; then
        cwds="$(cwds_of "$pids")"
        last_pids="$pids"
    fi
    now="$(date +%s)"
    cached=""
    # 같은 cwd 에 세션이 여러 개면 프로세스 수(cnt)만큼 최신 transcript 를 각각 판별
    # ponytail: pid↔transcript 매핑은 불가(파일을 열어두지 않음) — 최신 cnt 개로 근사
    while read -r cnt cwd; do
        [ -z "$cwd" ] && continue
        name="${cwd##*/}"
        slug="${cwd//[^a-zA-Z0-9]/-}"
        icons=""
        n=0
        # shellcheck disable=SC2012 # 파일명이 UUID.jsonl 뿐이라 ls -t 로 충분
        while read -r f; do
            [ -z "$f" ] && continue
            n=$((n + 1))
            if [ $((now - $(mtime_of "$f"))) -le "$busy_window" ]; then
                icons+='#[fg=yellow,bold]@ICON@#[default]'
            else
                icons+='#[fg=green]●#[default]'
            fi
        done < <(ls -t "$HOME/.claude/projects/$slug"/*.jsonl 2>/dev/null | head -"$cnt")
        # transcript 가 프로세스 수보다 적으면(막 시작) 나머지는 대기로 채움
        while [ "$n" -lt "$cnt" ]; do
            icons+='#[fg=green]●#[default]'
            n=$((n + 1))
        done
        if [[ "$icons" == *@ICON@* ]]; then
            cached+="${icons} #[fg=yellow,bold]${name}#[default]   "
        else
            cached+="${icons} #[fg=green]${name}#[default]   "
        fi
    done < <(uniq -c <<<"$cwds")
    cached="${cached:-$idle_text}"
}

tick=0
while :; do
    # 스캔(fork 비용)은 약 3초에 한 번, 프레임 갱신은 매 반복
    ((tick % 3 == 0)) && scan
    tick=$((tick + 1))
    if [[ "$cached" == *@ICON@* ]]; then
        for f in "${frames[@]}"; do
            printf '%s\n' "${cached//@ICON@/$f}"
            sleep 0.2
        done
    else
        printf '%s\n' "$cached"
        sleep 1
    fi
done
