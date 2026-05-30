# Default Agent Stack

## What this is

A pre-wired template for **Claude Code** that gives a new project:

- Three governance contracts: `VISION.md` (product), `AGENTS.md` (engineering rules), and `STACK.md` (per-stack tech config). The **backlog and roadmap are GitHub issues** (you own the list); the audit trail lives in issues, commits, and PR descriptions.
- A five-teammate agent team — `architect`, `ux-guardian`, `devils-advocate`, `lead-dev`, and `qa-enforcer` — convened in full for every issue.
- Three skills: `/project-manager` (the only surface that talks to you), `/implement` (feature branch → PR), and `/codereview` (PASS/FAIL audit on the current branch).
- A pre-configured `.claude/settings.json` with permission rules and hooks.

## Layout

```
template/          # the bundle you copy into your project
  .claude/         #   skills (project-manager, implement, codereview) + agents
  .github/         #   PR template
  AGENTS.md        #   engineering contract
  CLAUDE.md        #   Claude-Code operating rules
  VISION.md        #   product contract (fill this in)
stacks/            # example STACK.md profiles — pick one, copy it in as STACK.md
  STACK-TS.md      #   strict TypeScript / Node / Hono / React / Vite / Vitest
  STACK-SWIFT.md   #   strict Swift 6 / SwiftUI / Xcode 26+
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

Each `stacks/STACK-*.md` documents the language version, runtime, build commands, performance budgets, approved-dependencies list, and stack-specific reject-list. They are **examples**: copy one in as `STACK.md` and edit it to match your real project.

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
