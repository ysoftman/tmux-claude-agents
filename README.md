# tmux-claude-agents

Show running [Claude Code](https://claude.com/claude-code) and [OpenCode](https://opencode.ai) agents — and whether they are working — as an icon at the end of each tmux window tab.

```text
 0:zsh  1:myenv ✻  2:helm ●
```

- `· ✢ ✳ ✶ ✻ ✽` (yellow, animated spinner — same one Claude Code uses): a Claude Code session working
- `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏` (yellow, animated spinner): an OpenCode session working
- `●` (green): idle — waiting for user input
- `!` (red): blocked — waiting for your approval (permission prompt or selection)

Windows without an agent show no icon. Multiple agent panes in one window stack their icons (e.g. `✻●`). The icon is shown by keeping `#{@ca_icon}` in `window-status-format` / `window-status-current-format`, inserted next to the window name (before the theme's closing style block), so it works with theme plugins too.

## Requirements

- tmux >= 3.0 (uses window user options in formats)
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
