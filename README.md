# tmux-claude-agents

Show running [Claude Code](https://claude.com/claude-code) and [OpenCode](https://opencode.ai) agents — and whether they are working — in a second tmux status line.

```text
✻ myenv   ● helm
```

- `· ✢ ✳ ✶ ✻ ✽` (yellow, animated spinner — same one Claude Code uses): a Claude Code session working
- `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏` (yellow, animated spinner): an OpenCode session working
- `●` (green): idle — waiting for user input
- `!` (red): blocked — waiting for your approval (permission prompt or selection)

When no agent session is running, the line disappears entirely (status drops back to a single line).

## Requirements

- tmux >= 3.0 (uses `status-format[1]`)
- Claude Code terminal title updates (on by default) — used to tell working from idle; without them sessions still show as idle
- OpenCode state is read from its TUI footer line, so no extra setup is needed

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
