# AGENTS.md

This file provides guidance to Codex when working in this repository.

## What this repository is

This is not an application. It is the versioned source bundle for a static
Claude Code and Codex project setup. Every file under `template/` is a final,
human-reviewable artifact that downstream projects or global symlinks consume
directly. Do not introduce a generator, build step, or hidden source format for
the agent setup.

Read `README.md` first. It is the canonical explanation of the distribution
model and supported hosts.

## Distribution model

Link global roles and skills before you configure a project. Then copy only
the product contract, one stack profile, and the selected host contract:

```sh
bin/link-global.sh
PROJECT_DIR="/path/to/project"
cp template/VISION.md "$PROJECT_DIR/VISION.md"
cp stacks/STACK-TS.md "$PROJECT_DIR/STACK.md"
cp template/CLAUDE.md "$PROJECT_DIR/CLAUDE.md"
cp template/AGENTS.md "$PROJECT_DIR/AGENTS.md"
```

Global distribution uses `bin/link-global.sh`. It symlinks the static role and
skill files into the user-level discovery locations for Claude and Codex.
Edits and `git pull` apply to new sessions without a copy or render step.

Never overwrite a user's real file while changing the linker. It may replace
only symlinks, and pruning may remove only dead links whose target is inside
this repository.

## Cross-host structure

- `template/CLAUDE.md` and `template/.claude/` are the Claude distribution.
- `template/AGENTS.md`, `template/.codex/agents/`, and
  `template/.agents/skills/` are the Codex distribution.
- `template/VISION.md`, `template/.github/`, and `stacks/` are shared.

The two hosts use different agent and orchestration formats. Keep both outputs
static and explicit in Git. Share concepts and policy, but do not hide their
differences behind generated files or runtime indirection.

## Load-bearing indirection

The operating contracts, agents, and skills are technology-neutral. Concrete
technology belongs in `STACK.md` alone. Refer to commands only through
`$FORMAT_CMD`, `$LINT_CMD`, `$BUILD_CMD`, `$TEST_CMD`, and `$VERIFY_CMD`, which
each stack profile defines in its Build & verify commands section.

Never hard-code a language, framework, package manager, or build command into
the operating contracts, agents, or skills.

## Workflow parity

Both hosts expose the same five roles and three workflows:

- Roles: architect, UX guardian, devil's advocate, lead developer, QA enforcer.
- Workflows: project manager, implementation, and code review.
- Sequence: plan and approve; UX and architecture review; stress-test;
  implementation; QA-owned code review to PASS; human review and merge.

Host-specific syntax is intentional: Claude uses slash commands and Markdown
agent manifests; Codex uses dollar-prefixed skills, TOML custom agents, and
subagent delegation. Do not copy host-specific tool names into the other host's
files.

## Invariants to keep consistent

When changing policy, search both host trees and update every affected static
file. The files are deliberately self-contained because agents may run in
isolated contexts.

- Repository and GitHub artifacts are English; user chat is Finnish.
- New user-facing English uses Simplified Technical English. Write short
  sentences. Use active voice and plain, consistent terms. Do not rewrite
  compact operating contracts only to apply STE.
- Never commit or push to `main`; use `feat|fix|chore|docs/<topic>` branches.
- Conventional Commits with the host-specific co-author trailer; merge commits,
  never squash.
- Issues, commits, PR descriptions, and review comments are the audit trail.
- The user owns product direction, backlog changes, and merge authority.
- Read-only roles never edit product code.
- `lead-dev` implements; `qa-enforcer` owns the semantic review gate.
- Force-push, direct pushes to `main`, destructive deletion, hook bypasses, and
  autonomous merges are forbidden.

## Verification

There is no application build. Before committing setup changes:

1. Run `bin/check-setup.sh`.
2. Exercise `bin/link-global.sh` against a temporary `HOME` for every changed
   host path; never test by replacing the user's live files.
3. Inspect `git diff --check` and the complete Git diff.
4. Keep `README.md` accurate.

## Decision rights

- Feature-branch edits, commits, pushes, and PR creation are allowed when the
  user requested the change.
- Ask before editing product vision, restructuring the backlog, changing
  repository settings, or merging.
- Never force-push, push to `main`, bypass hooks, read secret files, or merge
  without explicit user authorization.
