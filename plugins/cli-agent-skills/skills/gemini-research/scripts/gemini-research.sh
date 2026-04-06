#!/usr/bin/env bash
set -euo pipefail

# gemini-research.sh — delegate structured research to Gemini CLI
# Usage: gemini-research.sh "<topic>"

TOPIC="${1:-}"

if [[ -z "$TOPIC" ]]; then
  echo "Error: topic argument is required." >&2
  echo "Usage: gemini-research.sh \"<topic>\"" >&2
  exit 1
fi

# Verify gemini is available
if ! command -v gemini &>/dev/null; then
  echo "Error: 'gemini' binary not found on PATH." >&2
  echo "Install Gemini CLI: https://github.com/google-gemini/gemini-cli" >&2
  exit 1
fi

OUTPUT_DIR="${HOME}/.claude/cli-reviews"
mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date -u +"%Y%m%d-%H%M%S")
TOPIC_SLUG=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | cut -c1-40)
ARTIFACT_PATH="${OUTPUT_DIR}/gemini-research-${TOPIC_SLUG}-${TIMESTAMP}.json"

PROMPT="You are a technical research assistant. Conduct a thorough, structured research report on the following topic.

Topic: ${TOPIC}

Provide your findings in exactly this format:

## Executive Summary
[2-3 sentence overview of the topic and its significance]

## Key Concepts
[Bullet points covering the core concepts a practitioner needs to understand]

## Technical Deep-Dive
[Detailed technical analysis: how it works, architecture, internals]

## Current State & Trends
[What is happening now, recent developments, ecosystem maturity]

## Practical Implications
[Real-world applications, trade-offs, when to use vs avoid, recommendations]

## References & Further Reading
[Key resources, papers, documentation, tools]"

# Run Gemini and capture output
GEMINI_OUTPUT=""
GEMINI_ERROR=""
EXIT_CODE=0

GEMINI_OUTPUT=$(gemini -p "$PROMPT" 2>/tmp/gemini-research-stderr) || EXIT_CODE=$?
GEMINI_ERROR=$(cat /tmp/gemini-research-stderr 2>/dev/null || true)

ISO_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [[ $EXIT_CODE -ne 0 ]]; then
  # Write failure artifact
  python3 -c "
import json, sys
artifact = {
    'tool': 'gemini',
    'skill': 'gemini-research',
    'persona': None,
    'topic_or_diff_summary': sys.argv[1],
    'timestamp': sys.argv[2],
    'output_markdown': '',
    'error': sys.argv[3],
    'artifact_path': sys.argv[4]
}
print(json.dumps(artifact, indent=2))
" "$TOPIC" "$ISO_TIMESTAMP" "$GEMINI_ERROR" "$ARTIFACT_PATH" > "$ARTIFACT_PATH"

  echo "Error: Gemini CLI failed (exit $EXIT_CODE)."
  if [[ -n "$GEMINI_ERROR" ]]; then
    echo "$GEMINI_ERROR"
  fi
  exit 1
fi

# Write success artifact
python3 -c "
import json, sys
artifact = {
    'tool': 'gemini',
    'skill': 'gemini-research',
    'persona': None,
    'topic_or_diff_summary': sys.argv[1],
    'timestamp': sys.argv[2],
    'output_markdown': sys.argv[3],
    'artifact_path': sys.argv[4]
}
print(json.dumps(artifact, indent=2))
" "$TOPIC" "$ISO_TIMESTAMP" "$GEMINI_OUTPUT" "$ARTIFACT_PATH" > "$ARTIFACT_PATH"

# Print formatted output to stdout for Claude to present
cat <<EOF
# Gemini Research: ${TOPIC}

${GEMINI_OUTPUT}

---
*Artifact saved to: ${ARTIFACT_PATH}*
EOF
