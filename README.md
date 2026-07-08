# tmux-claude-agents

Show running [Claude Code](https://claude.com/claude-code) agents — and whether they are working — in a second tmux status line.

```text
⠹ myenv   ● helm
```

- `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏` (yellow, animated spinner): working
- `●` (green): idle — waiting for user input
- `!` (red): blocked — waiting for your approval (permission prompt or selection)

When no claude session is running, the line disappears entirely (status drops back to a single line).

## Requirements

- tmux >= 3.0 (uses `status-format[1]`)
- Claude Code terminal title updates (on by default) — used to tell working from idle; without them sessions still show as idle

## Installation

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'ysoftman/tmux-claude-agents'
```

Or manually in `.tmux.conf`:

```tmux
run-shell /path/to/tmux-claude-agents/claude-agents.tmux
```

## License

[MIT](LICENSE)
