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
the product contract, one stack profile, the ADR template, and the selected
host contract:

```sh
bin/link-global.sh
PROJECT_DIR="/path/to/project"
cp template/VISION.md "$PROJECT_DIR/VISION.md"
cp stacks/STACK-TS.md "$PROJECT_DIR/STACK.md"
mkdir -p "$PROJECT_DIR/docs/adr" && cp template/docs/adr/TEMPLATE.md "$PROJECT_DIR/docs/adr/"
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
- `template/VISION.md`, `template/docs/adr/`, `template/.github/`, and
  `stacks/` are shared.

The two hosts use different agent and orchestration formats. Keep both outputs
static and explicit in Git. Share concepts and policy, but do not hide their
differences behind generated files or runtime indirection.

## Load-bearing indirection

The operating contracts, agents, and skills are technology-neutral. Concrete
technology belongs in `STACK.md` alone. Refer to commands only through
`$FORMAT_CMD`, `$LINT_CMD`, `$BUILD_CMD`, `$TEST_CMD`, `$VERIFY_CMD`, and
`$MUTATION_CMD`, which each stack profile defines in its Build & verify
commands section.

Never hard-code a language, framework, tool, package manager, or build command
into the operating contracts, agents, or skills.

Mechanical checks belong in the `$VERIFY_CMD` gates of each stack profile. The
review skill judges only what machines cannot.

## Workflow parity

Both hosts expose the same five roles and three workflows:

- Roles: architect, product guardian, devil's advocate, implementer, reviewer.
- Workflows: lead, implementation, and code review.
- Sequence: agree checkpoints; write acceptance criteria; the lead sizes the
  team; design and challenge as needed; refactoring PR first when the
  structure does not fit; implementation; independent review to PASS when code
  changes; merge only with merge authority for the task.

Host-specific syntax is intentional: Claude uses slash commands and Markdown
agent manifests; Codex uses dollar-prefixed skills, TOML custom agents, and
subagent delegation. Do not copy host-specific tool names into the other
host's files. Codex custom agents read `AGENTS.md` explicitly, because Codex
does not document that subagents load it.

## Invariants to keep consistent

When changing policy, search both host trees and update every affected static
file.

- Repository and GitHub artifacts are English; user chat is Finnish.
- New user-facing English, including ADRs, uses Simplified Technical English.
- Never commit or push to `main`; use `feat|fix|chore|docs|refactor/<topic>`
  branches. A force-push to a feature branch uses `--force-with-lease`.
- Conventional Commits with the host-specific co-author trailer; fold fixup
  commits before the final review; merge commits, never squash.
- GitHub issues hold the backlog and acceptance criteria; PRs hold changes and
  what was not verified; `docs/adr/` holds decisions, exceptions, and lessons.
  No roadmap, backlog, changelog, or progress files.
- Owner decisions stop the affected work and go to the owner in chat; the team
  decides and records everything else. The team merges only with merge
  authority for that task.
- Read-only roles never edit product code. The implementer never reviews its
  own work or approves its own exception.
- Direct pushes to `main` are forbidden, normal and force. Destructive
  deletion and hook bypasses are forbidden.

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
- Never push to `main`, normal or force. Never bypass hooks, read secret files,
  or merge without explicit user authorization.
