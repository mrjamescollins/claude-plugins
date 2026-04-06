# claude-plugins

Personal Claude Code plugins by mrjamescollins.

## Structure

```
plugins/
  cli-agent-skills/   — delegate research and code review to Gemini CLI and Codex CLI
```

## Installation

Add this repo as a marketplace in Claude Code, then install plugins from it.

### 1. Register the marketplace

Add to `~/.claude/plugins/known_marketplaces.json`:

```json
{
  "mrjamescollins": {
    "source": {
      "source": "github",
      "repo": "mrjamescollins/claude-plugins"
    },
    "installLocation": "/Users/<you>/.claude/plugins/marketplaces/mrjamescollins"
  }
}
```

### 2. Install a plugin

```
/plugin install cli-agent-skills@mrjamescollins
```

## Plugins

### cli-agent-skills

Skills for delegating research and code review to external CLI agents (Gemini CLI and Codex CLI), keeping Claude Code's context window clean.

**Skills:**
- `gemini-research` — structured research reports via Gemini CLI
- `codex-review` — staged-diff code review via Codex CLI (personas: distinguished, sre, team)
- `gemini-review` — staged-diff code review via Gemini CLI (personas: distinguished, sre, team)

**Command:**
- `/reconfigure-cli-agent-skills` — verify environment, create output dir, check binaries

**Prerequisites:** `gemini` and `codex` on PATH, `python3` available.
