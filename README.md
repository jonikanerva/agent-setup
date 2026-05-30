# Default Agent Stack

## What this is

A pre-wired template for **Claude Code** that gives a new project:

- Three governance contracts: `VISION.md` (product), `AGENTS.md` (engineering rules), and `STACK.md` (per-stack tech config). The **backlog and roadmap are GitHub issues** (you own the list); the audit trail lives in issues, commits, and PR descriptions.
- A five-teammate agent team — `architect`, `ux-guardian`, `devils-advocate`, `lead-dev`, and `qa-enforcer` — convened in full for every issue.
- Three skills: `/project-manager` (the only surface that talks to you), `/implement` (feature branch → PR), and `/codereview` (PASS/FAIL audit on the current branch).
- A pre-configured `.claude/settings.json` with permission rules and hooks.

## How it works

1. You keep a **backlog of GitHub issues** of any size. You are the boss.
2. You tell `/project-manager` either `solve issue #42` or describe the problem directly.
3. The PM convenes the full team — they run the `VISION.md` decision filter, design, stress-test, implement on a feature branch, open a PR, and run `/codereview` to **PASS**.
4. Only once the team's review is PASS does the PM surface the PR to you for the final human code review and merge. You can pre-authorise self-merge or batching, but neither is the default.
5. PRs always **merge** (never squash) so the audit trail survives. There is no roadmap, backlog, or change-log file in the repo — issues + commits + PR descriptions are the record.

Once `VISION.md` and `STACK.md` are filled, run `/project-manager <issue # or problem>`.

---

## Two starter profiles

| Profile   | Stack                                                                                      |
| --------- | ------------------------------------------------------------------------------------------ |
| **swift** | Strict Swift 6 + SwiftUI + Xcode 26+, `make`-driven (`make test-all`)                      |
| **ts**    | Strict TypeScript 6 + Node 24 LTS + Hono 4 + React 19 + Vite 8 + Vitest 4, pnpm 11 workspaces |

Both ship with the language version, runtime version, build commands, performance budgets, approved-dependencies list, and stack-specific reject-list pre-filled in `STACK.md`.

---

## Use it

You should already have `claude`, `gh`, and `jq` installed.

### Generate the scaffold

```sh
make swift   # for Swift / SwiftUI / Xcode
# or
make ts      # for TypeScript / Node / Hono / React
```
