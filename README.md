# Default Agent Stack

## What this is

A pre-wired, fully static template for **Claude Code and Codex** that gives a new project:

- **`CLAUDE.md` and `AGENTS.md`** — host-specific, **technology-neutral** engineering doctrines + workflows. They name no language or framework; they do not change between projects.
- Two per-project contracts: **`VISION.md`** (what the product is) and **`STACK.md`** (the technology and all its concrete rules). The **backlog and roadmap are GitHub issues** (you own the list); the audit trail lives in issues, commits, and PR descriptions.
- A five-teammate agent team — architect, UX guardian, devil's advocate, lead developer, and QA enforcer — convened in full for every issue.
- Three skills: project manager (the only surface that talks to you), implement (feature branch → PR), and code review (PASS/FAIL audit on the current branch). Claude invokes them with `/`; Codex invokes them with `$`.
- Host-native static definitions: Markdown agents and `.claude/settings.json` for Claude; TOML custom agents, `AGENTS.md`, and Codex skills for Codex.

**Technology-agnostic by design:** every technology choice lives in `STACK.md` alone. The same agents, skills, and doctrine work for iOS, macOS, TypeScript, Kotlin, a backend, a CLI, a library — you swap `STACK.md` (and `VISION.md`), nothing else.

## Layout

```
template/             # the complete static bundle you copy into your project
  .claude/            #   Claude agents, skills, and settings.json
  .codex/agents/      #   Codex custom agents (TOML)
  .agents/skills/     #   Codex skills
  .github/            #   shared PR template
  CLAUDE.md           #   Claude doctrine + workflow
  AGENTS.md           #   Codex doctrine + workflow
  VISION.md           #   shared product contract (fill this in)
stacks/               # STACK.md profiles — copy one in as STACK.md
  STACK-TEMPLATE.md   #   empty skeleton for a new stack (Kotlin, Go, …)
  STACK-TS.md         #   example: strict TypeScript / Node / Hono / React / Vite / Vitest
  STACK-EFFECT.md     #   example: strict TypeScript / Effect v3 / HttpApi / React
  STACK-SWIFT.md      #   example: strict Swift 6 / SwiftUI / Xcode 26+
  STACK-PY.md         #   example: strict Python 3.13 / Home Assistant custom integration (HACS)
```

## How it works

1. You keep a **backlog of GitHub issues** of any size. You are the boss.
2. You invoke `/project-manager` in Claude or `$project-manager` in Codex, with either `solve issue #42` or a direct problem description.
3. The PM convenes the full team — they run the `VISION.md` decision filter, design, stress-test, implement on a feature branch, open a PR, and run the host's code-review skill to **PASS**.
4. Only once the team's review is PASS does the PM surface the PR to you for the final human code review and merge. You can pre-authorise self-merge or batching, but neither is the default.
5. PRs always **merge** (never squash) so the audit trail survives. There is no roadmap, backlog, or change-log file in the repo — issues + commits + PR descriptions are the record.

Once `VISION.md` and `STACK.md` are filled, run `/project-manager <issue # or problem>` in Claude or `$project-manager <issue # or problem>` in Codex.

---

## Example stacks

| Stack      | Profile                                                                                    |
| ---------- | ------------------------------------------------------------------------------------------ |
| **ts**     | Strict TypeScript 6 + Node 24 LTS + Hono 4 + React 19 + Vite 8 + Vitest 4, pnpm workspaces |
| **effect** | Strict TypeScript + Effect v3 + `@effect/platform` HttpApi + React 19 + Vite, pnpm         |
| **swift**  | Strict Swift 6 + SwiftUI + Xcode 26+, `make`-driven (`make test-all`)                      |
| **py**     | Strict Python 3.13 Home Assistant custom integration (HACS), uv + ruff + `mypy --strict`  |

Each `stacks/STACK-*.md` documents the project shape, language version, runtime, build commands, performance budgets, approved-dependencies list, and stack-specific reject-list. They are **examples**: copy one in as `STACK.md` and edit it to match your real project. For a stack not covered here (Kotlin, Go, Rust, …), copy `stacks/STACK-TEMPLATE.md` and fill the skeleton — nothing else in the setup changes.

---

## Use it

You need Claude Code and/or Codex, plus `gh` and `jq`.

### Copy the setup into your project

Copy the template and one stack example into your project, replacing `<your-project-dir>` with your project path:

```sh
cp -R template/. <your-project-dir>/
cp stacks/STACK-TS.md <your-project-dir>/STACK.md   # or STACK-SWIFT.md
```

Then in your project: fill `VISION.md` and `STACK.md`, open GitHub issues as your backlog, and start the host you use. Run `/project-manager solve issue #1` in Claude or `$project-manager solve issue #1` in Codex (or describe a problem directly).

The bundled `.claude/settings.json` allow-lists the git/GitHub commands the Claude team needs, denies destructive ones (force-push in both spellings, pushes to `main`, the `rm -rf`/`rm -Rf` variants, `git reset --hard`), and backs the deny-list with a `PreToolUse` hook. Codex uses its native sandbox and approval controls; the custom agents set role-appropriate sandbox defaults without replacing the user's live permission choice.

### Use the setup globally

To make the setup available in every Claude and Codex project, symlink the checked-in static files into each host's user-level discovery locations. The repo stays the single source of truth: edits and `git pull` take effect for new sessions immediately, with no generated output or copy step to keep in sync.

```sh
bin/link-global.sh                         # both hosts
bin/link-global.sh --host claude           # Claude only
bin/link-global.sh --host codex            # Codex only
bin/link-global.sh --host all --prune       # both, plus dead repo-link cleanup
```

Claude agents and skills are linked under `~/.claude`. Codex gets `~/.codex/AGENTS.md`, custom agents under `~/.codex/agents`, and skills under `~/.agents/skills`. Codex officially supports symlinked skill directories. The script also links the other Codex files as ordinary filesystem symlinks; run `bin/check-setup.sh` and the temporary-HOME smoke test before changing those mappings.

The script is idempotent and never overwrites a real file or directory. Re-run it only after adding or removing an agent or skill. `template/.claude/settings.json` remains project-distribution configuration and is not linked into the global Claude settings. Existing Codex configuration, authentication, memories, and unrelated skills remain untouched. Start a new session after changing global instructions or custom agents; Codex detects skill changes automatically, but a restart is the fallback if an update is not visible.

### Static source of truth

There is no generator. Every file consumed by Claude or Codex is checked into Git in its final form, so a pull request shows the complete installed behavior. Some policy is intentionally repeated because agents run in isolated contexts and the two hosts use different manifest formats. `bin/check-setup.sh` verifies that both static rosters and all three workflows remain present without producing or rewriting files.
