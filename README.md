# Default Agent Stack

## What this is

A pre-wired template for **Claude Code** that gives a new project:

- A clear product vision contract (`VISION.md`).
- A strict, opinionated engineering contract (`AGENTS.md`).
- A per-stack tech configuration (`STACK.md`) preloaded with sane strict-mode defaults.
- An Agent Team.

Once `VISION.md` is filled, call `/project-manager <prompt>`. The skill interprets your prompt, proposes a plan, and — after your approval — spawns the agent team to execute. From spawn onwards the team runs autonomously (no `AskUserQuestion` in the loop): plans milestones, opens PRs, runs code reviews, and only stops when the work is done or a milestone needs human attention.

---

## Two starter profiles

| Profile           | Stack                                                                                      |
| ----------------- | ------------------------------------------------------------------------------------------ |
| **swift-ios**     | Strict Swift 6 + SwiftUI + Xcode 26+, `make`-driven (`make test-all`)                      |
| **ts-node-react** | Strict TypeScript 5.6 + Node 22 LTS + Hono + React 19 + Vite 7 + Vitest 3, pnpm workspaces |

Both ship with the language version, runtime version, build commands, performance budgets, approved-dependencies list, and stack-specific reject-list pre-filled in `STACK.md`.

---

## Use it

You should already have: `claude`, `gh`, `jq`

### Generate the scaffold

```sh
make swift   # for Swift / SwiftUI / Xcode
# or
make ts      # for TypeScript / Node / Hono / React
```
