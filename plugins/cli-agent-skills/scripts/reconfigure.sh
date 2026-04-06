#!/usr/bin/env bash
set -euo pipefail

# reconfigure.sh — idempotently configure the cli-agent-skills plugin environment
# Safe to run after reinstalls or machine migrations.

REVIEWS_DIR="${HOME}/.claude/cli-reviews"
SETTINGS_FILE="${HOME}/.claude/settings.json"
PLUGIN_KEY="cli-agent-skills@mrjamescollins"

echo "=== cli-agent-skills reconfigure ==="
echo ""

# 1. Create output directory
if [[ -d "$REVIEWS_DIR" ]]; then
  echo "[ok]     Output directory already exists: ${REVIEWS_DIR}"
else
  mkdir -p "$REVIEWS_DIR"
  echo "[created] Output directory: ${REVIEWS_DIR}"
fi

# 2. Check plugin is enabled in settings.json
if [[ -f "$SETTINGS_FILE" ]]; then
  if python3 -c "
import json, sys
with open('${SETTINGS_FILE}') as f:
    s = json.load(f)
plugins = s.get('enabledPlugins', {})
sys.exit(0 if '${PLUGIN_KEY}' in plugins and plugins['${PLUGIN_KEY}'] else 1)
" 2>/dev/null; then
    echo "[ok]     Plugin enabled in settings.json: ${PLUGIN_KEY}"
  else
    echo "[warn]   Plugin not found in settings.json as '${PLUGIN_KEY}'."
    echo "         Install via Claude Code: /plugin install cli-agent-skills@mrjamescollins"
  fi
else
  echo "[warn]   settings.json not found at ${SETTINGS_FILE}"
fi

# 3. Verify gemini binary
if command -v gemini &>/dev/null; then
  GEMINI_PATH=$(command -v gemini)
  echo "[ok]     gemini found: ${GEMINI_PATH}"
else
  echo "[warn]   gemini not found on PATH."
  echo "         Install: https://github.com/google-gemini/gemini-cli"
fi

# 4. Verify codex binary
if command -v codex &>/dev/null; then
  CODEX_PATH=$(command -v codex)
  echo "[ok]     codex found: ${CODEX_PATH}"
else
  echo "[warn]   codex not found on PATH."
  echo "         Install: https://github.com/openai/codex"
fi

echo ""
echo "=== Done ==="
