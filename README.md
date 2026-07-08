# tmux-claude-agents

Show running [Claude Code](https://claude.com/claude-code) agents — and whether they are working — in a second tmux status line.

```text
✳ myenv   ● helm
```

- `✳` (green, bold): working — the session transcript was updated within the last N seconds
- `●` (grey): idle — waiting for user input
- `no claude agents`: no claude process running

## How it works

1. Finds running `claude` processes with `ps` (by executable name — `pgrep` misses them because claude renames its process title to a version string).
2. Resolves each process's working directory with `lsof` and shows its basename as the agent name.
3. Claude Code appends to the session transcript (`~/.claude/projects/<slug>/*.jsonl`) continuously while working, so the newest transcript's mtime within the busy window means "working".

## Requirements

- tmux >= 3.0 (uses `status-format[1]`)
- macOS (uses BSD `stat -f` / `lsof`)

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
# seconds since the last transcript write to count as "working" (default: 10)
set -g @claude_agents_busy_window 10
```

## Notes

- All tmux status lines stack at `status-position`, so the agent line renders next to the main status bar (top or bottom follows your setting).
- Multiple sessions in the same directory are listed per process, but the busy check uses the newest transcript in that directory.

## License

[MIT](LICENSE)
