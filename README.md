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
- macOS (needs `lsof`) or Linux (uses `/proc`)

## Installation

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'ysoftman/tmux-claude-agents'
```

Or manually in `.tmux.conf`:

```tmux
run-shell /path/to/tmux-claude-agents/claude-agents.tmux
```

## Options

```tmux
# seconds since the last transcript write to count as "working" (default: 30)
set -g @claude_agents_busy_window 30
```

## Notes

- All tmux status lines stack at `status-position`, so the agent line renders next to the main status bar (top or bottom follows your setting).
- Multiple sessions in the same directory get one status icon each, e.g. `✻● myenv` (one working, one idle). Icons are matched to the newest transcripts in that directory — exact process↔session pairing isn't knowable.

## License

[MIT](LICENSE)
