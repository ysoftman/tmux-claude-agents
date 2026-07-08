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

## Notes

- All tmux status lines stack at `status-position`, so the agent line renders next to the main status bar (top or bottom follows your setting).
- The plugin runs as a background daemon that updates `status-format[1]` and toggles `status` between `2` and `on`; it exits by itself when the tmux server does.
- Detection is per pane: a pane counts as claude when its foreground process title is claude's version string, and it counts as working when the terminal title starts with a braille spinner. Non-working panes are marked blocked when a permission/selection prompt is visible at the bottom of the screen.
- Multiple sessions in the same directory are merged into one entry with one icon per session, e.g. `✻● myenv` (one working, one idle).
- Only claude sessions running inside tmux panes are shown.

## License

[MIT](LICENSE)
