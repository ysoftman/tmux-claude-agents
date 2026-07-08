#!/usr/bin/env bash
# ysoftman
# tmux status line 용 claude code 에이전트 목록 데몬 — claude-agents.tmux 가 시작한다.
# claude 가 OSC title 로 내보내는 상태(점자 스피너=작업중)를 tmux 가 pane_title 에
# 캡처해 두므로, pane 단위로 세션별 상태를 정확히 읽는다. 같은 디렉토리의 세션들은
# 아이콘을 겹쳐 하나의 항목으로 묶는다(예: ⠹● myenv).
# status-format[1] 을 직접 set 하고, 에이전트가 없으면 status 를 1줄로 줄여
# 라인 자체를 숨긴다. tmux 서버가 종료되면 set 실패로 함께 종료된다.

# 점자 스피너(U+2800-U+28FF) 판별을 로케일 무관하게 UTF-8 바이트 접두사로 매칭
export LC_ALL=C

# 점자 회전 — 10프레임이라 부드럽고, 1칸 폭이라 yellow/bold 색이 그대로 먹는다
frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
# 승인/선택 대기 프롬프트 문구 (herdr 의 claude 매니페스트에서 발췌)
blocked_re='do you want to|would you like to|waiting for permission|esc to cancel'

# 직전 디렉토리(prev)에 모인 아이콘들을 하나의 항목으로 cached 에 붙인다
flush() {
    local name
    [ -z "$prev" ] && return
    name="${prev##*/}"
    if [[ "$icons" == *fg=red* ]]; then
        cached+="${icons} #[fg=red,bold]${name}#[default]   "
    elif [[ "$icons" == *@ICON@* ]]; then
        cached+="${icons} #[fg=yellow,bold]${name}#[default]   "
    else
        cached+="${icons} #[fg=green]${name}#[default]   "
    fi
}

scan() {
    local cmd path id title
    cached=""
    prev=""
    icons=""
    while IFS=$'\t' read -r cmd path id title; do
        # claude 는 프로세스 타이틀을 버전 문자열(예: 2.1.204)로 바꾼다 — 이걸로
        # claude pane 을 식별해, 종료 후 남은 pane 제목이 유령 항목이 되는 걸 막는다
        # ponytail: 타이틀 규칙이 바뀌면 pane_pid 하위 프로세스 comm 검사로 교체
        case "$cmd" in
            [0-9]*.[0-9]*) ;;
            *) continue ;;
        esac
        if [ "$path" != "$prev" ]; then
            flush
            prev="$path"
            icons=""
        fi
        case "$title" in
            $'\xe2\xa0'* | $'\xe2\xa1'* | $'\xe2\xa2'* | $'\xe2\xa3'*) # 점자 = 작업중
                icons+='#[fg=yellow,bold]@ICON@#[default]'
                ;;
            *) # 나머지 = 입력 대기. 화면 하단에 승인 프롬프트가 떠 있으면 blocked
                # ponytail: 대화 출력에 같은 문구가 하단에 걸리면 오탐 가능 — 스크롤되면 자연 해소
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

# 줄 내용이 바뀔 때만 set (tmux 서버가 없으면 종료)
show_line() {
    [ "$1" = "$last_line" ] && return
    last_line="$1"
    tmux set -g 'status-format[1]' "#[align=left] $1" || exit 0
}

last_line=""
visible=""
tick=0
while :; do
    # 스캔은 약 3초에 한 번, 프레임 갱신은 매 반복
    ((tick % 3 == 0)) && scan
    tick=$((tick + 1))
    if [ -z "$cached" ]; then
        if [ "$visible" != off ]; then
            tmux set -g status on || exit 0 # 에이전트 없음 — 라인 숨김
            visible=off
        fi
        sleep 1
        continue
    fi
    if [ "$visible" != on ]; then
        tmux set -g status 2 || exit 0
        visible=on
    fi
    if [[ "$cached" == *@ICON@* ]]; then
        for f in "${frames[@]}"; do
            show_line "${cached//@ICON@/$f}"
            sleep 0.2
        done
    else
        show_line "$cached"
        sleep 1
    fi
done
