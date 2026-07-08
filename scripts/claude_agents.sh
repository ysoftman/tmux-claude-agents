#!/usr/bin/env bash
# ysoftman
# tmux status line 용 claude code 에이전트 목록 모듈.
# claude 가 OSC title 로 내보내는 상태(점자 스피너=작업중, ✳=대기)를 tmux 가
# pane_title 에 캡처해 두므로, pane 단위로 세션별 상태를 정확히 읽는다.
# 상주 루프 — tmux #() 는 살아있는 명령의 최신 출력 줄을 쓰므로 status-interval 보다
# 빠르게 스피너가 돈다.

# 점자 스피너(U+2800-U+28FF) 판별을 로케일 무관하게 UTF-8 바이트 접두사로 매칭
export LC_ALL=C

idle_text='#[fg=colour244]no claude agents#[default]'
frames=('✢' '✳' '✶' '✻' '✽')

scan() {
    local title path name
    cached=""
    # ponytail: claude 종료 후 셸이 pane 제목을 덮지 않으면 유령 항목이 남을 수 있음
    # — 문제되면 pane_pid 하위에 claude 프로세스가 있는지 교차검증 추가
    while IFS=$'\t' read -r title path; do
        name="${path##*/}"
        case "$title" in
            $'\xe2\xa0'* | $'\xe2\xa1'* | $'\xe2\xa2'* | $'\xe2\xa3'*) # 점자 U+2800-28FF = 작업중
                cached+="#[fg=yellow,bold]@ICON@ ${name}#[default]   "
                ;;
            $'\xe2\x9c\xb3 '*) # '✳ ' (U+2733) = 대기
                cached+="#[fg=green]● ${name}#[default]   "
                ;;
        esac
    done < <(tmux list-panes -a -F $'#{pane_title}\t#{pane_current_path}')
    cached="${cached:-$idle_text}"
}

tick=0
while :; do
    # 스캔은 약 3초에 한 번, 프레임 갱신은 매 반복
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
