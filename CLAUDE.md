# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is **not an application** — it is the versioned source bundle for static Claude Code and Codex project setups. It ships pre-wired host configurations, engineering doctrines, and per-stack profiles that get copied into other projects or linked into user-level discovery locations. There is no generated setup: every distributed file is checked in as the final artifact downstream projects consume.

Global roles and skills are linked first. Each project then receives only the
product contract, one stack profile, and its selected host contract:

```sh
bin/link-global.sh
PROJECT_DIR="/path/to/project"
cp template/VISION.md "$PROJECT_DIR/VISION.md"
cp stacks/STACK-TS.md "$PROJECT_DIR/STACK.md"
cp template/CLAUDE.md "$PROJECT_DIR/CLAUDE.md"   # Claude
cp template/AGENTS.md "$PROJECT_DIR/AGENTS.md"   # Codex
```

`README.md` is the canonical explanation of the whole system — read it first.

## The core design: host contracts, shared project documents, one indirection

The entire setup rests on a separation that you must preserve when editing:

- **`template/CLAUDE.md` and `template/AGENTS.md`** — host-specific engineering doctrines + team workflows. Both are **technology-neutral**: they name no language, framework, or concrete command. They are static final artifacts, not generated outputs. When they need a concrete rule, they defer with the phrase *"as in `STACK.md`"* or a `$VAR_CMD` placeholder.
- **`template/VISION.md`** — a fill-in-the-blank product contract (what the product *is* and *is not*). Shipped as a template full of `<…>` placeholders.
- **`stacks/STACK-*.md`** — concrete technology profiles. Each one is copied into a target project as `STACK.md` and holds every language/framework/command/budget/banned-call.

**The load-bearing indirection:** both host contracts and all skills/agents refer to commands only through variables — `$FORMAT_CMD`, `$LINT_CMD`, `$BUILD_CMD`, `$TEST_CMD`, `$VERIFY_CMD` — which are **defined once** in each `STACK.md` Section 3 ("Build & verify commands"). This is why the doctrine works unchanged for TypeScript, Swift, or any future stack. **Never hard-code a concrete command or framework name into an operating contract, skill, or agent** — that would break the neutrality the whole system depends on. Concrete tooling lives in `STACK.md` alone.

## The agent team and workflow (what the template encodes)

Each host bundle wires up the same five-agent team driven by three skills. Claude uses Markdown agent definitions and slash-command skills; Codex uses TOML custom agents, dollar-prefixed skills, and subagent delegation. Understanding the flow is essential before editing either host tree:

- **`project-manager`** (`template/.claude/skills/project-manager/SKILL.md`) — the **only** surface that talks to the user. Two phases: **Phase A** (interactive — reads the issue, proposes a plan, `AskUserQuestion` allowed) and **Phase B** (autonomous — convenes the team, drives to a PASS-reviewed PR, `AskUserQuestion` **forbidden**, autonomy fallback applies). It never writes app code itself.
- **`implement`** skill — the branch → change → `$VERIFY_CMD` → commit → push → PR loop. Run once per issue by the `lead-dev` agent.
- **`codereview`** skill — runs as an **isolated subagent** (`context: fork`), posts a `**Verdict: PASS**` / `**Verdict: FAIL**` comment to the PR. Run by `qa-enforcer` after each implement.
- Five agents (`template/.claude/agents/`): `architect`, `ux-guardian`, `devils-advocate` (all read-only), `lead-dev` (writes), `qa-enforcer` (read-only verifier). The **full team is convened for every issue** — depth scales, the roster does not.

The PM convenes the team for every issue; the team reviews its own work to PASS *before* a PR is ever surfaced to the user.

The corresponding Codex files live under `template/.codex/agents/` and `template/.agents/skills/`. Their host-native syntax is intentionally separate and visible in Git. Keep semantics aligned, but do not introduce a generator or runtime include mechanism to hide the final artifacts.

## Invariants to keep consistent across files

These rules are stated in both operating contracts and **repeated and relied upon** in the skills, agents, PR template, and host safeguards. If you change one, grep both host trees and update every affected static file — they are intentionally redundant so each agent reads them in isolation:

- **Language split:** everything written to the repo or GitHub (code, commits, branches, PRs, issues, docs) is in **English**; only the active agent host's chat replies to the user are in **Finnish**. (This is a rule the template imposes on downstream projects.)
- **Simplified Technical English:** use STE for new user-facing English in the repository and on GitHub. Write short sentences. Use active voice and plain, consistent terms. Do not rewrite compact operating contracts only to apply STE.
- **Git:** never commit/push to `main` — normal or force; `main` is protected on GitHub and that protection is the real gate; a force-push to a feature branch is allowed with `--force-with-lease`; feature branches `feat|fix|chore|docs/<topic>` (≤50 chars); Conventional Commits with the host-specific `Co-Authored-By` agent trailer; **merge commits, never squash**; `Closes #<N>` links the issue.
- **No ledger files:** the backlog is GitHub issues; the audit trail is issues + commits + PR descriptions. The template forbids creating `ROADMAP.md` / changelog / backlog files — do not add one here either.
- **Autonomy fallback:** in autonomous phases, agents do not call `AskUserQuestion`; they pick the smallest-surface conservative interpretation and document it. `VISION.md` / `CLAUDE.md` edits require an explicit user request.
- **Safeguards:** `template/.claude/settings.json` is the reference Claude deny-list and hook configuration; the global linker does not install it. Codex uses custom-agent sandbox defaults plus the user's native sandbox and approval controls. Both doctrines' Safeguards and Decision rights must describe the same behavioral boundaries without claiming identical host enforcement.

## Adding or editing a stack profile

A new stack (Kotlin, Go, Rust, …) is added by copying `stacks/STACK-TEMPLATE.md` to `stacks/STACK-<name>.md` and filling it — **nothing else in the setup changes**. Match the section structure of the existing profiles (`STACK-TS.md` is a compact filled example): Project shape · Language & Runtime · Frameworks · Build & verify commands · Performance budgets · Persistence shape · Approved dependencies · Stack-specific reject-list additions · Logging & privacy · Background & lifecycle · Time & timezones · Design guidelines & UX thresholds (optional, UI-facing) · Best practices source (optional) · Intentional Divergences. Section 3 **must** define all five `$*_CMD` variables, because every skill and agent dereferences them. `ux-guardian` dereferences "Design guidelines & UX thresholds" and `architect` dereferences "Best practices source" by name — projects that omit them simply skip those checks.

## Editing rules of thumb

- Changing either operating contract, a skill, or an agent changes the doctrine downstream projects inherit. Keep it neutral, preserve the host-native cross-references, and verify the other host does not contradict the change.
- The skill/agent files are long and deliberately self-contained (each is read in isolation by a separate subagent). Some redundancy is by design — do not "DRY it up" across files in a way that assumes shared context.
- Keep `README.md` accurate when you add a stack or change the flow — it is the front door.
- Run `bin/check-setup.sh` before committing. It validates the checked-in static distributions and does not generate or rewrite files.
