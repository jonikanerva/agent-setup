# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is **not an application** — it is the versioned source bundle for static Claude Code and Codex project setups. It ships pre-wired host configurations, operating contracts, and per-stack profiles that get copied into other projects or linked into user-level discovery locations. There is no generated setup: every distributed file is checked in as the final artifact downstream projects consume.

Global roles and skills are linked first. Each project then receives only the
product contract, one stack profile, the ADR template, and its selected host contract:

```sh
bin/link-global.sh
PROJECT_DIR="/path/to/project"
cp template/VISION.md "$PROJECT_DIR/VISION.md"
cp stacks/STACK-TS.md "$PROJECT_DIR/STACK.md"
mkdir -p "$PROJECT_DIR/docs/adr" && cp template/docs/adr/TEMPLATE.md "$PROJECT_DIR/docs/adr/"
cp template/CLAUDE.md "$PROJECT_DIR/CLAUDE.md"   # Claude
cp template/AGENTS.md "$PROJECT_DIR/AGENTS.md"   # Codex
```

`README.md` is the canonical explanation of the whole system — read it first.

## The core design: host contracts, shared project documents, one indirection

The setup rests on a separation that you must preserve when editing:

- **`template/CLAUDE.md` and `template/AGENTS.md`** — host-specific operating contracts: values and pre-decided conflicts, decision rights, workflow, records, engineering rules, definition of done. Both are **technology-neutral**: they name no language, framework, tool, or concrete command. When they need one, they defer with *"as in `STACK.md`"* or a `$*_CMD` variable.
- **`template/VISION.md`** — the product contract: what the product *is* and *is not*, the Decision Filter, Owner Decisions, and Data and Permissions.
- **`template/docs/adr/TEMPLATE.md`** — the ADR template. Projects keep decisions, exceptions, and lessons in `docs/adr/`.
- **`stacks/STACK-*.md`** — concrete technology profiles. Each one is copied into a target project as `STACK.md` and holds every language, framework, command, gate, threshold, budget, and banned call.

**The load-bearing indirection:** both host contracts and all skills and agents refer to commands only through variables — `$FORMAT_CMD`, `$LINT_CMD`, `$BUILD_CMD`, `$TEST_CMD`, `$VERIFY_CMD`, `$MUTATION_CMD` — which are **defined once** in each `STACK.md` Section 3. **Never hard-code a concrete command, tool, or framework name into an operating contract, skill, or agent.** Concrete tooling lives in `STACK.md` alone.

**Gates over rules:** mechanical conformance (format, types, lint, complexity, dead code, dependency direction, secrets, vulnerabilities, commit messages, tests) belongs in `$VERIFY_CMD`, listed per stack in Section 3 → *Gates*. The review skill judges only what machines cannot. Do not add a mechanical check to a skill or agent when a gate can enforce it.

## The agent team and workflow (what the template encodes)

Each host bundle wires up the same five roles and three skills. Claude uses Markdown agent definitions and slash-command skills; Codex uses TOML custom agents, dollar-prefixed skills, and subagent delegation.

- **`lead`** skill — the **only** role that talks to the owner (the user). Agrees checkpoints and merge authority per task, writes acceptance criteria, sizes the team, escalates owner decisions in chat while independent work continues, and reports what was and was not verified. Never writes app code.
- **`implement`** skill — branch → change → per-commit checks → `$VERIFY_CMD` → push → PR. Run by the `implementer` agent.
- **`codereview`** skill — runs in a separate context (`context: fork`, `agent: reviewer`) and posts a `**Verdict: PASS**` / `**Verdict: FAIL**` comment. Judgement only; it confirms the gates ran.
- Five agents (`template/.claude/agents/`): `architect`, `product-guardian`, `devils-advocate` (read-only), `implementer` (writes), `reviewer` (read-only for product code). The lead chooses the roles per task; a review is mandatory whenever code changes.

The Codex files live under `template/.codex/agents/` and `template/.agents/skills/`. Their host-native syntax is intentionally separate and visible in Git. Keep semantics aligned, but do not introduce a generator or runtime include mechanism.

## Invariants to keep consistent across files

These rules are stated in both operating contracts and relied upon in the skills, agents, PR template, and host safeguards. If you change one, grep both host trees and update every affected static file:

- **Language split:** everything written to the repo or GitHub is in **English**; only the active host's chat replies to the user are in **Finnish**.
- **Simplified Technical English:** use STE for new user-facing English in the repository and on GitHub, including ADRs.
- **Git:** never commit/push to `main` — normal or force; `main` protection on GitHub is the real gate; a force-push to a feature branch uses `--force-with-lease`; branches `feat|fix|chore|docs|refactor/<topic>` (≤50 chars); Conventional Commits with the host-specific `Co-Authored-By` trailer; fixup commits are folded before the final review; **merge commits, never squash**; `Closes #<N>` links the issue.
- **Records:** GitHub issues hold the backlog and acceptance criteria; PRs hold what changed and *what was not verified*; `docs/adr/` holds decisions, exceptions, and lessons. No roadmap, backlog, changelog, or progress files — in downstream projects or here.
- **Decision rights:** owner decisions (cost, new external services, `VISION.md → Owner Decisions`, irreversible data operations, edits to `VISION.md` or the operating contract, task checkpoints) stop the affected work and go to the owner in chat. Everything else the team decides and records. The team merges only with merge authority granted for that task.
- **Structure first:** when the structure does not fit a change, a refactoring PR lands first.
- **Safeguards:** `template/.claude/settings.json` is the reference Claude deny-list and hook configuration; the global linker does not install it. Codex uses custom-agent sandbox defaults plus the user's sandbox and approval controls. Both contracts' Safeguards describe the same behavioural boundaries without claiming identical host enforcement.

## Adding or editing a stack profile

A new stack is added by copying `stacks/STACK-TEMPLATE.md` to `stacks/STACK-<name>.md` and filling it — **nothing else in the setup changes**. Match the section structure: Project shape · Language & Runtime · Frameworks · Build & verify commands (with *Gates*, *Gaps*, *Change size soft limit*, *Owner-run checks*) · Performance budgets · Persistence shape · Approved dependencies · Stack-specific reject-list additions · Logging & privacy · Background & lifecycle · Base units & time · Design guidelines & UX thresholds (optional) · Best practices source (optional). Section 3 **must** define all six `$*_CMD` variables. `product-guardian` dereferences "Design guidelines & UX thresholds" and `architect` dereferences "Best practices source" by name.

## Editing rules of thumb

- Changing an operating contract, a skill, or an agent changes the doctrine downstream projects inherit. Keep it neutral and verify the other host does not contradict the change.
- Claude subagents and teammates load the project `CLAUDE.md`, so Claude agents and skills reference the contract instead of restating it. Codex custom agents are told to read `AGENTS.md` explicitly, because that loading is not documented for Codex.
- Keep `README.md` accurate when you add a stack, a role, or change the flow — it is the front door.
- Run `bin/check-setup.sh` before committing. It validates the checked-in static distributions and does not generate or rewrite files.
