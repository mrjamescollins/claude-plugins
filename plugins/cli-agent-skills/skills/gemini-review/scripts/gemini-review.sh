#!/usr/bin/env bash
set -euo pipefail

# gemini-review.sh — delegate staged-change code review to Gemini CLI
# Usage: gemini-review.sh "<persona>"
# Personas: distinguished | sre | team

PERSONA="${1:-}"

VALID_PERSONAS="distinguished sre team"

if [[ -z "$PERSONA" ]]; then
  echo "Error: persona argument is required." >&2
  echo "Valid personas: ${VALID_PERSONAS}" >&2
  exit 1
fi

case "$PERSONA" in
  distinguished|sre|team) ;;
  *)
    echo "Error: unknown persona '${PERSONA}'." >&2
    echo "Valid personas: ${VALID_PERSONAS}" >&2
    exit 1
    ;;
esac

# Verify gemini is available
if ! command -v gemini &>/dev/null; then
  echo "Error: 'gemini' binary not found on PATH." >&2
  echo "Install Gemini CLI: https://github.com/google-gemini/gemini-cli" >&2
  exit 1
fi

# Check for staged changes
DIFF=$(git diff --staged 2>/dev/null || true)
if [[ -z "$DIFF" ]]; then
  echo "No staged changes found. Stage your changes with git add before running this review."
  exit 1
fi

DIFF_SUMMARY=$(echo "$DIFF" | head -5 | tr '\n' ' ')

OUTPUT_DIR="${HOME}/.claude/cli-reviews"
mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date -u +"%Y%m%d-%H%M%S")
ARTIFACT_PATH="${OUTPUT_DIR}/gemini-review-${PERSONA}-${TIMESTAMP}.json"

# Build persona-specific prompt
case "$PERSONA" in
  distinguished)
    SYSTEM_PROMPT="You are a Distinguished Engineer with deep expertise in software architecture and systems design. Review the following git diff with focus on:
- Architectural soundness and long-term maintainability
- System design trade-offs and scalability implications
- Code quality, abstraction boundaries, and technical debt
- Security implications and threat surface
- Performance characteristics and bottlenecks
- API design and interface contracts

Provide specific, actionable feedback. Reference line numbers or code snippets where relevant. Be direct — this is a peer review among senior engineers."
    ;;
  sre)
    SYSTEM_PROMPT="You are a mid-level SRE/DevOps Engineer reviewing a git diff. Focus on:
- Operational concerns and runbook implications
- Deployment risk and rollback strategy
- Observability gaps: missing metrics, logs, or traces
- Alert-ability: what new failure modes need alerting
- Toil reduction and automation opportunities
- Infrastructure dependencies and failure modes
- Configuration management and environment parity

Flag anything that would make you nervous during an on-call shift. Be specific."
    ;;
  team)
    SYSTEM_PROMPT="You are reviewing a git diff as five different engineers. Provide a separate review section for each role. Each section must start with the role heading and contain substantive, role-specific feedback.

## Senior Security Engineer Review
[Identify security vulnerabilities, attack surfaces, auth/authz issues, data handling concerns, insecure defaults]

## Junior Security Engineer Review
[Basic security observations, questions, patterns worth noting, learning moments — written from a less experienced perspective]

## Staff SRE Review
[Production readiness, reliability patterns, observability, operational burden, incident response implications]

## Mid-level Reliability Engineer Review
[Error handling, resilience patterns, retry logic, failure modes, graceful degradation]

## Principal DevOps Engineer Review
[CI/CD implications, deployment topology, infrastructure dependencies, toolchain concerns, environment parity]

Be substantive in each section — not just bullet points but actual engineering analysis."
    ;;
esac

FULL_PROMPT="${SYSTEM_PROMPT}

---
## Git Diff to Review

\`\`\`diff
${DIFF}
\`\`\`"

# Run Gemini and capture output
GEMINI_OUTPUT=""
GEMINI_ERROR=""
EXIT_CODE=0

GEMINI_OUTPUT=$(gemini -p "$FULL_PROMPT" 2>/tmp/gemini-review-stderr) || EXIT_CODE=$?
GEMINI_ERROR=$(cat /tmp/gemini-review-stderr 2>/dev/null || true)

ISO_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [[ $EXIT_CODE -ne 0 ]]; then
  python3 -c "
import json, sys
artifact = {
    'tool': 'gemini',
    'skill': 'gemini-review',
    'persona': sys.argv[1],
    'topic_or_diff_summary': sys.argv[2],
    'timestamp': sys.argv[3],
    'output_markdown': '',
    'error': sys.argv[4],
    'artifact_path': sys.argv[5]
}
print(json.dumps(artifact, indent=2))
" "$PERSONA" "$DIFF_SUMMARY" "$ISO_TIMESTAMP" "$GEMINI_ERROR" "$ARTIFACT_PATH" > "$ARTIFACT_PATH"

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
    'skill': 'gemini-review',
    'persona': sys.argv[1],
    'topic_or_diff_summary': sys.argv[2],
    'timestamp': sys.argv[3],
    'output_markdown': sys.argv[4],
    'artifact_path': sys.argv[5]
}
print(json.dumps(artifact, indent=2))
" "$PERSONA" "$DIFF_SUMMARY" "$ISO_TIMESTAMP" "$GEMINI_OUTPUT" "$ARTIFACT_PATH" > "$ARTIFACT_PATH"

# Print formatted output
cat <<EOF
# Gemini Review (${PERSONA})

${GEMINI_OUTPUT}

---
*Artifact saved to: ${ARTIFACT_PATH}*
EOF
