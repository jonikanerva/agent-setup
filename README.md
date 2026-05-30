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
  STACK-SWIFT.md      #   example: strict Swift 6 / SwiftUI / Xcode 26+
```

## How it works

1. You keep a **backlog of GitHub issues** of any size. You are the boss.
2. You tell `/project-manager` either `solve issue #42` or describe the problem directly.
3. The PM convenes the full team — they run the `VISION.md` decision filter, design, stress-test, implement on a feature branch, open a PR, and run `/codereview` to **PASS**.
4. Only once the team's review is PASS does the PM surface the PR to you for the final human code review and merge. You can pre-authorise self-merge or batching, but neither is the default.
5. PRs always **merge** (never squash) so the audit trail survives. There is no roadmap, backlog, or change-log file in the repo — issues + commits + PR descriptions are the record.

Once `VISION.md` and `STACK.md` are filled, run `/project-manager <issue # or problem>`.

---

## Two example stacks

| Stack     | Profile                                                                                    |
| --------- | ------------------------------------------------------------------------------------------ |
| **ts**    | Strict TypeScript 6 + Node 24 LTS + Hono 4 + React 19 + Vite 8 + Vitest 4, pnpm workspaces |
| **swift** | Strict Swift 6 + SwiftUI + Xcode 26+, `make`-driven (`make test-all`)                      |

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
