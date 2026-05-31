# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is **not an application** — it is the source bundle for a Claude Code project setup. It ships a pre-wired `.claude/` configuration, an engineering doctrine, and per-stack profiles that get **copied into other projects**. There is no build, lint, or test command here; "the code" is Markdown and JSON config. When you edit a file, you are editing the template that downstream projects will inherit.

Distribution is a manual copy (no installer, no package):

```sh
cp -R template/. <target-project>/     # the bundle
cp stacks/STACK-TS.md <target-project>/STACK.md   # one stack profile, renamed to STACK.md
```

`README.md` is the canonical explanation of the whole system — read it first.

## The core design: three documents, one indirection

The entire setup rests on a separation that you must preserve when editing:

- **`template/CLAUDE.md`** — the engineering doctrine + team workflow. It is **technology-neutral**: it names no language, framework, or command. It is meant to be identical across every project that uses this setup. When it needs a concrete rule, it defers with the phrase *"as in `STACK.md`"* or a `$VAR_CMD` placeholder.
- **`template/VISION.md`** — a fill-in-the-blank product contract (what the product *is* and *is not*). Shipped as a template full of `<…>` placeholders.
- **`stacks/STACK-*.md`** — concrete technology profiles. Each one is copied into a target project as `STACK.md` and holds every language/framework/command/budget/banned-call.

**The load-bearing indirection:** `template/CLAUDE.md` and the skills/agents refer to commands only through variables — `$FORMAT_CMD`, `$LINT_CMD`, `$BUILD_CMD`, `$TEST_CMD`, `$VERIFY_CMD` — which are **defined once** in each `STACK.md` Section 3 ("Build & verify commands"). This is why the doctrine works unchanged for TypeScript, Swift, or any future stack. **Never hard-code a concrete command or framework name into `template/CLAUDE.md`, the skills, or the agents** — that would break the neutrality the whole system depends on. Concrete tooling lives in `STACK.md` alone.

## The agent team and workflow (what the template encodes)

The bundle wires up a five-agent team driven by three skills. Understanding this flow is essential before editing any of the pieces, because they cross-reference each other heavily:

- **`project-manager`** (`template/.claude/skills/project-manager/SKILL.md`) — the **only** surface that talks to the user. Two phases: **Phase A** (interactive — reads the issue, proposes a plan, `AskUserQuestion` allowed) and **Phase B** (autonomous — convenes the team, drives to a PASS-reviewed PR, `AskUserQuestion` **forbidden**, autonomy fallback applies). It never writes app code itself.
- **`implement`** skill — the branch → change → `$VERIFY_CMD` → commit → push → PR loop. Run once per issue by the `lead-dev` agent.
- **`codereview`** skill — runs as an **isolated subagent** (`context: fork`), posts a `**Verdict: PASS**` / `**Verdict: FAIL**` comment to the PR. Run by `qa-enforcer` after each implement.
- Five agents (`template/.claude/agents/`): `architect`, `ux-guardian`, `devils-advocate` (all read-only), `lead-dev` (writes), `qa-enforcer` (read-only verifier). The **full team is convened for every issue** — depth scales, the roster does not.

The PM convenes the team for every issue; the team reviews its own work to PASS *before* a PR is ever surfaced to the user.

## Invariants to keep consistent across files

These rules are stated in `template/CLAUDE.md` and **repeated and relied upon** in the skills, agents, PR template, and `settings.json`. If you change one, grep for every other mention and update them together — they are intentionally redundant so each agent reads them in isolation:

- **Language split:** everything written to the repo or GitHub (code, commits, branches, PRs, issues, docs) is in **English**; only Claude's chat replies to the user are in **Finnish**. (Note: this `agent-setup` repo's own response language follows the user's global setting; the English/Finnish split is a *rule the template imposes on downstream projects*.)
- **Git:** never commit/push to `main`; feature branches `feat|fix|chore|docs/<topic>` (≤50 chars); Conventional Commits with a `Co-Authored-By` agent trailer; **merge commits, never squash**; `Closes #<N>` links the issue.
- **No ledger files:** the backlog is GitHub issues; the audit trail is issues + commits + PR descriptions. The template forbids creating `ROADMAP.md` / changelog / backlog files — do not add one here either.
- **Autonomy fallback:** in autonomous phases, agents do not call `AskUserQuestion`; they pick the smallest-surface conservative interpretation and document it. `VISION.md` / `CLAUDE.md` edits require an explicit user request.
- **Safeguards** live in `template/.claude/settings.json`: deny-list (force-push, push to `main`, `rm -rf`, `git reset --hard`) + a `PreToolUse` hook that blocks destructive pushes. The doctrine's "Safeguards" / "Decision rights" sections must stay in sync with this JSON.

## Adding or editing a stack profile

A new stack (Kotlin, Go, Rust, …) is added by writing a new `stacks/STACK-<name>.md` — **nothing else in the setup changes**. Match the section structure of the existing profiles (`STACK-TS.md` is the fullest reference): Project shape · Language & Runtime · Frameworks · Build & verify commands · Performance budgets · Persistence shape · Approved dependencies · Stack-specific reject-list additions · Logging & privacy · Background & lifecycle · Intentional Divergences. Section 3 **must** define all five `$*_CMD` variables, because every skill and agent dereferences them.

## Editing rules of thumb

- Changing `template/CLAUDE.md`, the skills, or the agents = changing the doctrine every downstream project inherits. Keep it neutral, keep the cross-references intact, and verify a rule isn't contradicted in a sibling file.
- The skill/agent files are long and deliberately self-contained (each is read in isolation by a separate subagent). Some redundancy is by design — do not "DRY it up" across files in a way that assumes shared context.
- Keep `README.md` accurate when you add a stack or change the flow — it is the front door.
