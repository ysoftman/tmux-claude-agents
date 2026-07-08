# tmux-claude-agents

Show running [Claude Code](https://claude.com/claude-code) agents — and whether they are working — in a second tmux status line.

```text
✻ myenv   ● helm
```

- `✢ ✳ ✶ ✻ ✽` (yellow, bold, animated spinner): working
- `●` (green): idle — waiting for user input
- `no claude agents`: no claude process running

## Requirements

- tmux >= 3.0 (uses `status-format[1]`)
- Claude Code terminal title updates (on by default) — status is read from each pane's OSC title

## Installation

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'ysoftman/tmux-claude-agents'
```

Or manually in `.tmux.conf`:

```tmux
run-shell /path/to/tmux-claude-agents/claude-agents.tmux
```

## Notes

- All tmux status lines stack at `status-position`, so the agent line renders next to the main status bar (top or bottom follows your setting).
- Detection is per pane: Claude Code writes its state to the terminal title (braille spinner = working, `✳` = idle) and tmux captures it as `pane_title`. Multiple sessions in the same directory show as separate entries.
- Only claude sessions running inside tmux panes are shown.

## License

[MIT](LICENSE)
