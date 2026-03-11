# cc-line

A minimal Claude Code statusline script that shows useful context at a glance.

## Preview

```
~/projects/cc-line [Sonnet] ⎇ main ░░░░░░░░░░ 8% +156/-23 ⏱ 2m05s ⚡0.13
```

| Segment | Description |
|---------|-------------|
| `~/projects/cc-line` | Current working directory (`$HOME` shortened to `~`) |
| `[Sonnet]` | Active Claude model name |
| `⎇ main` | Git branch (`*` suffix indicates uncommitted changes) |
| `░░░░░░░░░░ 8%` | Context window usage with progress bar |
| `+156/-23` | Lines added/removed in the session |
| `⏱ 2m05s` | Session duration |
| `⚡0.13` | System 1-minute load average |

## Requirements

- `jq`
- `git`

```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq
```

## Installation

1. Copy the script and make it executable:

```bash
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

2. Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

3. Restart Claude Code — the statusline appears at the bottom of the session.

## How it works

Claude Code pipes a JSON object to the script's stdin on every assistant response. The script extracts the relevant fields with `jq`, reads git state and `/proc/loadavg` locally, then prints a single line to stdout which Claude Code renders as the statusline.

```
Claude Code → JSON (stdin) → statusline.sh → text (stdout) → statusline
```

The full JSON schema is documented in the [official Claude Code docs](https://docs.anthropic.com/en/docs/claude-code/statusline).
