---
description: Idempotently configure the cli-agent-skills plugin environment. Creates the ~/.claude/cli-reviews output directory, verifies gemini and codex binaries are on PATH, and checks plugin registration. Safe to re-run after reinstalls or machine migrations.
---

Run the reconfigure script to check and set up the cli-agent-skills environment:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/reconfigure.sh"
```

Present the output to the user exactly as printed. If any `[warn]` lines appear, explain what the user needs to do to resolve them.
