@AGENTS.md
@VISION.md
@STACK.md

# Claude Code workflow

`VISION.md`, `AGENTS.md`, and `STACK.md` are the single sources of truth for product and technical rules. The **backlog and roadmap are the GitHub issue list** (the user owns it) — there is no roadmap or backlog file in this repo. This file only adds Claude-Code-specific operational rules (skills, verification, git workflow, safeguards, decision rights). Nothing is duplicated from the other documents.

## Autonomy

This project runs on the autonomous "default agent stack" pattern. Invoke the `/project-manager` skill — it is the team-lead entry point and the only surface that talks to the user. You drive it by issue (`solve issue #42`) or by describing the problem directly. The skill runs in two phases: an interactive Phase A where it reads the issue / interprets your prompt, asks any genuinely ambiguous clarifying questions, and waits for plan approval; and an autonomous Phase B where it convenes the full five-teammate agent team (`architect`, `ux-guardian`, `devils-advocate`, `lead-dev`, `qa-enforcer`) and drives the work to a PR. The team runs its own `/codereview` to PASS before the PR is ever surfaced to you for the final human code review. The PM role itself lives in the skill — the lead is the PM in agent-teams mode.

The autonomy fallback rule from `AGENTS.md §14.1` applies in Phase B: when a decision is ambiguous, pick the smallest-surface, most-conservative interpretation that satisfies the `VISION.md` decision filter, document the choice in the PR description (and, if it introduces a binding decision for future work, also note it in the relevant issue), and proceed. Do not call `AskUserQuestion` in Phase B. The only exceptions are (1) Phase A of the `/project-manager` skill, which is interactive by design, and (2) direct edits to `VISION.md` or `AGENTS.md`, which always require an explicit user request.

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
- When a PR resolves an issue, link it with `Closes #<N>` in the description so merging closes the issue and the issue thread carries the outcome.
- Every PR description covers _why_ and _what_, the relevant `AGENTS.md` sections, and the `VISION.md → Decision Filter` outcome. The PR is the permanent audit trail.
- Delete the branch after merge.
- **Never** commit or push directly to `main`.
- **Trivial PR exception** — for typo fixes, dependency bumps, dead-code removals, formatting-only PRs, and other non-feature PRs (no behavioral change, no new state, no new dependency, no new persisted/transmitted data, no new external system), the `VISION decision filter`, `States handled`, and `AGENTS.md / STACK.md sections involved` blocks of the PR template may be filled with a single line: `N/A — trivial change, no behavioral surface affected.` The `Why`, `What`, and `Verification` sections are still mandatory. The `qa-enforcer` applies the `AGENTS.md §15` checklist as usual; if any rule does apply (e.g. a "typo fix" turns out to touch a privacy-relevant log line), the trivial-PR exception is forfeit and the full template fields are required.

## Skills

- `/project-manager <issue # or problem>` — the orchestration entry point and the only surface that talks to the user. Driven by an issue number or a free-form problem description; it reads the issue / interprets the prompt, clarifies if needed, proposes a plan, and only convenes the team after approval. The full five-teammate team is convened for every issue, the team runs its own `/codereview` to PASS, and the PR is surfaced to the user only after PASS for the final human code review.
- `/implement <task>` — feature branch → change → `$VERIFY_CMD` → commit → push → PR. Enforces the `VISION.md` decision filter and the `AGENTS.md §14` workflow rules. The `lead-dev` teammate calls this once per issue.
- `/codereview` — isolated subagent review of the current branch against `main`. It applies the project governance files first, then risk-based review lenses for correctness, architecture, concurrency, security, privacy, reliability, performance, tests, supply chain, and operability. It posts a plain-text PASS or FAIL PR comment as the audit-trail entry. Every FAIL finding must include evidence, impact, violated local rule, minimum fix, and verification; external standards such as OWASP, CWE, NIST SSDF, SLSA, 12-Factor, ISO/IEC 25010, OpenTelemetry, or OWASP LLM Top 10 are cited only when materially relevant. The `qa-enforcer` teammate calls this after each `/implement` finishes.

## Backlog & audit trail

The **backlog and roadmap are the GitHub issue list** — the user owns and maintains it. Issues can be any size. There is no `ROADMAP.md`, backlog file, or change-log file in this repo, and none should be created.

The audit trail of *what happened and why* is:

- **GitHub issues** — the problem statement, scope clarifications in the thread, and the decision-filter outcome when an issue is rejected or narrowed.
- **Commits** — Conventional Commits, one logical unit each, "why" in the message.
- **PR descriptions and review comments** — the rationale for every decision, the four decision-filter answers, the `AGENTS.md` / `STACK.md` sections touched, and the `/codereview` PASS/FAIL verdicts.
- **The merge-commit chain on `main`** (merge, never squash) — the permanent, ordered record.

A PR that resolves an issue links it with `Closes #<N>`. A decision that binds future work is written in plain, audit-grade language into the PR description and the relevant issue — never an opaque "we did X". Never write PII or any data forbidden by `VISION.md → Persistence and Privacy Posture` into an issue, commit, or PR.

## Safeguards

Safeguards are implemented in `.claude/settings.json` (permissions + hooks). The list below is a reminder; the authoritative enforcement lives in settings.json.

- `git push --force` and `git push origin main|HEAD:main`: blocked by the `PreToolUse` Bash hook and the deny list.
- `rm -rf`: deny-listed (requires an explicit permission prompt).
- `gh pr merge`: **never run on the agent's own initiative.** Merging always requires an explicit user request. The command itself is not deny-listed, so the agent may execute it _when asked by the user_, but never autonomously.

## Decision rights

- **Auto-allow**: read-only commands, `STACK.md` build/test/lint commands, feature-branch operations (create, commit, push origin `<branch>`), PR creation, `gh pr view` / `comment` / `diff` / `review`, `gh issue view` / `list` / `comment`, `STACK.md` edits.
- **Ask first**: edits to `VISION.md` or `AGENTS.md`, creating or restructuring issues (the user owns the backlog), `gh api` calls that modify repo settings. `gh pr merge` is allowed only when the user explicitly asks for it.
- **Never**: force push, push to `main`, bypass hooks (`--no-verify` etc.), `rm -rf` anything inside the project, violate any guardrail in `AGENTS.md §13`, persist or transmit data forbidden by `VISION.md → Persistence and Privacy Posture`.
