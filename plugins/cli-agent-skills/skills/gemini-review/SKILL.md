---
name: gemini-review
description: This skill should be used when the user asks to "review staged changes with Gemini", "run a gemini-review", "have Gemini review my code", "gemini distinguished review", "gemini sre review", "gemini team review", or wants a second-opinion code review of staged git changes delegated to Gemini CLI. Requires a persona argument: distinguished, sre, or team.
---

# Gemini Review

Delegate code review of staged git changes to Gemini CLI using a role-specific critique lens. Provides a second opinion from a different model compared to `codex-review`.

## Personas

| Argument | Reviewer Voice |
|----------|---------------|
| `distinguished` | Distinguished Engineer — architectural depth, long-term maintainability, systems thinking |
| `sre` | Mid-level SRE/DevOps Engineer — operational concerns, deployment risk, observability, toil reduction |
| `team` | Five named reviewers in separate sections: Senior Security Engineer, Junior Security Engineer, Staff SRE, Mid-level Reliability Engineer, Principal DevOps Engineer |

## Usage

When this skill triggers, first confirm staged changes exist, then run:

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/gemini-review/scripts/gemini-review.sh" "<persona>"
```

Valid persona values: `distinguished`, `sre`, `team`.

If the user hasn't specified a persona, ask which one they want before running the script.

## What the Script Does

- Validates that staged changes exist (exits early with a clear message if `git diff --staged` is empty)
- Validates the persona argument
- Pipes the staged diff and persona-specific system prompt into `gemini -p`
- Captures output and writes a JSON artifact to `~/.claude/cli-reviews/`
- Prints formatted markdown to stdout

## Presenting Results

Present the markdown output the script prints to stdout. Do not add your own code review on top of it. If the user wants your opinion afterward, they will ask.

If the script exits non-zero, report the error message it printed.

## Artifact Location

Each run writes one JSON file to `~/.claude/cli-reviews/gemini-review-<persona>-<timestamp>.json`. Mention the artifact path at the end of your response.
