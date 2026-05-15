@AGENTS.md
@VISION.md
@STACK.md
@ROADMAP.md

# Claude Code workflow

`VISION.md`, `AGENTS.md`, `STACK.md`, and `ROADMAP.md` are the single sources of truth for product, technical, and milestone rules. This file only adds Claude-Code-specific operational rules (skills, verification, git workflow, safeguards, decision rights). Nothing is duplicated from the other documents.

## Autonomy

This project runs on the autonomous "default agent stack" pattern. When the user asks Claude to build the product (or sends a one-line prompt like "build it" / "go" once `VISION.md` and `STACK.md` are filled), invoke the `/start-team` skill. It spins up a five-teammate agent team (`project-manager`, `architect`, `lead-dev`, `qa-enforcer`, `ux-guardian`) and drives the milestone chain to completion without further prompts.

The autonomy fallback rule from `AGENTS.md §14.1` applies everywhere: when a decision is ambiguous, pick the smallest-surface, most-conservative interpretation that satisfies the `VISION.md` decision filter, document it in `ROADMAP.md → Strategic decisions`, and proceed. Do not call `AskUserQuestion`. The only exception is direct edits to `VISION.md` or `AGENTS.md` themselves — those require an explicit user request.

## Language

Everything that lives in the repository or ever reaches GitHub is written in English. That includes:

- Source code, tests, and code comments
- Git commit messages and branch names
- PR titles, PR descriptions, PR review comments, PR inline comments
- Issue titles and issue bodies
- Any documentation, including this file

The _only_ exception is Claude's spoken replies back to the user in the chat window — those are in Finnish. The moment text is about to be written into a file, staged, pushed, or posted to GitHub, it is in English.

## Verification

Run before every commit and PR — all must pass:

```sh
$VERIFY_CMD
```

`$VERIFY_CMD` is declared in `STACK.md`. It is the single source of truth for how to verify, lint, build, and test this project. Never invent raw tool invocations (`swift-format`, `xcodebuild`, `eslint`, `tsc`, etc.) in commits, CI, or agent scripts — always go through the named command in `STACK.md`.

## Git workflow

- Use `/implement <task>` for the feature-branch workflow.
- Conventional Commits: `<type>(<scope>): <summary>`.
- Every commit authored by an agent ends with a `Co-Authored-By: <agent display name> <noreply@anthropic.com>` trailer (one trailer per agent that contributed to that commit). Human commits do not need the trailer.
- Branch names: `feat/<topic>`, `fix/<topic>`, `chore/<topic>`, `docs/<topic>` (max 50 chars, lowercase, hyphens only).
- **Always merge to `main` with a merge commit — never squash.** The PR keeps its full commit history as the audit trail. This is enforced in the GitHub repo settings.
- Every PR description covers _why_ and _what_, the relevant `AGENTS.md` sections, and the `VISION.md → Decision Filter` outcome. The PR is the permanent audit trail.
- Delete the branch after merge.
- **Never** commit or push directly to `main`.
- **Trivial PR exception** — for typo fixes, dependency bumps, dead-code removals, formatting-only PRs, and other non-feature PRs (no behavioral change, no new state, no new dependency, no new persisted/transmitted data, no new external system), the `VISION decision filter`, `States handled`, and `AGENTS.md / STACK.md sections involved` blocks of the PR template may be filled with a single line: `N/A — trivial change, no behavioral surface affected.` The `Why`, `What`, and `Verification` sections are still mandatory. The `qa-enforcer` applies the `AGENTS.md §15` checklist as usual; if any rule does apply (e.g. a "typo fix" turns out to touch a privacy-relevant log line), the trivial-PR exception is forfeit and the full template fields are required.

## Skills

- `/start-team` — autonomous orchestration entry point. Spawns the five-teammate agent team and drives the milestone chain to completion. Use this when the user wants the application built end-to-end with no further prompts.
- `/implement <task>` — feature branch → change → `$VERIFY_CMD` → commit → push → PR. Enforces the `VISION.md` decision filter and the `AGENTS.md §14` workflow rules. The `lead-dev` teammate calls this once per milestone.
- `/codereview` — isolated subagent review of the current branch against `main`. It applies the project governance files first, then risk-based review lenses for correctness, architecture, concurrency, security, privacy, reliability, performance, tests, supply chain, and operability. It posts a plain-text PASS or FAIL PR comment as the audit-trail entry. Every FAIL finding must include evidence, impact, violated local rule, minimum fix, and verification; external standards such as OWASP, CWE, NIST SSDF, SLSA, 12-Factor, ISO/IEC 25010, OpenTelemetry, or OWASP LLM Top 10 are cited only when materially relevant. The `qa-enforcer` teammate calls this after each `/implement` finishes.

## Roadmap

`ROADMAP.md` at the repository root is the canonical status document for the milestone chain. Every milestone PR must update it before being merged:

1. When the branch is opened, move that milestone's row from `Todo` to `In progress`.
2. Before merging, move the row to `Done` and fill in the PR link.
3. If a new strategic decision or technical risk surfaces mid-PR, add a line to the relevant section and a corresponding `Change log` entry.

Do not delete historical entries — the change log is an audit trail. Never write PII or any data forbidden by `VISION.md → Persistence and Privacy Posture` into `ROADMAP.md`.

## Safeguards

Safeguards are implemented in `.claude/settings.json` (permissions + hooks). The list below is a reminder; the authoritative enforcement lives in settings.json.

- `git push --force` and `git push origin main|HEAD:main`: blocked by the `PreToolUse` Bash hook and the deny list.
- `rm -rf`: deny-listed (requires an explicit permission prompt).
- `gh pr merge`: **never run on the agent's own initiative.** Merging always requires an explicit user request. The command itself is not deny-listed, so the agent may execute it _when asked by the user_, but never autonomously.

## Decision rights

- **Auto-allow**: read-only commands, `STACK.md` build/test/lint commands, feature-branch operations (create, commit, push origin `<branch>`), PR creation, `gh pr view` / `comment` / `diff` / `review`, `ROADMAP.md` / `STACK.md` edits.
- **Ask first**: edits to `VISION.md` or `AGENTS.md`, `gh api` calls that modify repo settings. `gh pr merge` is allowed only when the user explicitly asks for it.
- **Never**: force push, push to `main`, bypass hooks (`--no-verify` etc.), `rm -rf` anything inside the project, violate any guardrail in `AGENTS.md §13`, persist or transmit data forbidden by `VISION.md → Persistence and Privacy Posture`.
