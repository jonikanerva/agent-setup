# Default Agent Stack

## What this is

A pre-wired template for **Claude Code** that gives a new project:

- **`CLAUDE.md`** — the fixed, **technology-neutral** engineering doctrine + workflow. It names no language or framework; it never changes between projects.
- Two per-project contracts: **`VISION.md`** (what the product is) and **`STACK.md`** (the technology and all its concrete rules). The **backlog and roadmap are GitHub issues** (you own the list); the audit trail lives in issues, commits, and PR descriptions.
- A five-teammate agent team — `architect`, `ux-guardian`, `devils-advocate`, `lead-dev`, and `qa-enforcer` — convened in full for every issue.
- Three skills: `/project-manager` (the only surface that talks to you), `/implement` (feature branch → PR), and `/codereview` (PASS/FAIL audit on the current branch).
- A pre-configured `.claude/settings.json` with permission rules and hooks.

**Technology-agnostic by design:** every technology choice lives in `STACK.md` alone. The same agents, skills, and doctrine work for iOS, macOS, TypeScript, Kotlin, a backend, a CLI, a library — you swap `STACK.md` (and `VISION.md`), nothing else.

## Layout

```
template/             # the bundle you copy into your project
  .claude/            #   skills (project-manager, implement, codereview) + agents + settings.json
  .github/            #   PR template
  CLAUDE.md           #   engineering doctrine + workflow (fixed, technology-neutral)
  VISION.md           #   product contract (fill this in)
stacks/               # STACK.md profiles — copy one in as STACK.md
  STACK-TEMPLATE.md   #   empty skeleton for a new stack (Kotlin, Go, …)
  STACK-TS.md         #   example: strict TypeScript / Node / Hono / React / Vite / Vitest
  STACK-EFFECT.md     #   example: strict TypeScript / Effect v3 / HttpApi / React
  STACK-SWIFT.md      #   example: strict Swift 6 / SwiftUI / Xcode 26+
  STACK-PY.md         #   example: strict Python 3.13 / Home Assistant custom integration (HACS)
```

## How it works

1. You keep a **backlog of GitHub issues** of any size. You are the boss.
2. You tell `/project-manager` either `solve issue #42` or describe the problem directly.
3. The PM convenes the full team — they run the `VISION.md` decision filter, design, stress-test, implement on a feature branch, open a PR, and run `/codereview` to **PASS**.
4. Only once the team's review is PASS does the PM surface the PR to you for the final human code review and merge. You can pre-authorise self-merge or batching, but neither is the default.
5. PRs always **merge** (never squash) so the audit trail survives. There is no roadmap, backlog, or change-log file in the repo — issues + commits + PR descriptions are the record.

Once `VISION.md` and `STACK.md` are filled, run `/project-manager <issue # or problem>`.

---

## Example stacks

| Stack      | Profile                                                                                    |
| ---------- | ------------------------------------------------------------------------------------------ |
| **ts**     | Strict TypeScript 6 + Node 24 LTS + Hono 4 + React 19 + Vite 8 + Vitest 4, pnpm workspaces |
| **effect** | Strict TypeScript + Effect v3 + `@effect/platform` HttpApi + React 19 + Vite, pnpm         |
| **swift**  | Strict Swift 6 + SwiftUI + Xcode 26+, `make`-driven (`make test-all`)                      |

Each `stacks/STACK-*.md` documents the project shape, language version, runtime, build commands, performance budgets, approved-dependencies list, and stack-specific reject-list. They are **examples**: copy one in as `STACK.md` and edit it to match your real project. For a stack not covered here (Kotlin, Go, Rust, …), copy `stacks/STACK-TEMPLATE.md` and fill the skeleton — nothing else in the setup changes.

---

## Use it

You need to have `claude`, `gh` and `jq` installed.

### Copy the setup into your project

Copy the template and one stack example into your project, replacing `<your-project-dir>` with your project path:

```sh
cp -R template/. <your-project-dir>/
cp stacks/STACK-TS.md <your-project-dir>/STACK.md   # or STACK-SWIFT.md
```

Then in your project: fill `VISION.md` and `STACK.md`, open a few GitHub issues as your backlog, and run `claude` → `/project-manager solve issue #1` (or describe a problem directly).

### Use the agents & skills globally

To make the agents and skills available in **every** Claude Code session, symlink them into `~/.claude` instead of copying. The repo stays the single source of truth — symlinks point at the repo files, so edits and `git pull` take effect immediately, with no copy step to keep in sync:

```sh
bin/link-global.sh            # symlink agents & skills into ~/.claude
bin/link-global.sh --prune    # the above, plus remove links whose source was removed
```

The script is idempotent (re-run it after adding a new agent or skill) and never overwrites real files already in `~/.claude` (e.g. other skills). Only the agents and skills are linked — `template/.claude/settings.json` is project-distribution config and is **not** applied to your global `~/.claude`.
