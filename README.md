# Default Agent Stack

## What this is

A pre-wired template for **Claude Code** that gives a new project:

- Four governance contracts: `VISION.md` (product), `AGENTS.md` (engineering rules), `STACK.md` (per-stack tech config), and `ROADMAP.md` (forward-looking plan). The audit trail lives in git history and PR descriptions.
- A five-teammate agent team — `architect`, `lead-dev`, `qa-enforcer`, `ux-guardian`, and `devils-advocate`.
- Three skills: `/project-manager` (orchestration entry point), `/implement` (feature branch → PR), and `/codereview` (PASS/FAIL audit on the current branch).
- A pre-configured `.claude/settings.json` with permission rules and hooks.

Once `VISION.md` is filled, run `/project-manager <prompt>`.

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
