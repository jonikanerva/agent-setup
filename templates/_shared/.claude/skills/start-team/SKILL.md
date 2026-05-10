---
name: start-team
description: >
  Autonomous orchestration entry point. Spawns the five-teammate agent team
  (project-manager, architect, lead-dev, qa-enforcer, ux-guardian) and drives
  the milestone chain to completion without further user prompts.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, Skill
argument-hint: <optional: starting milestone or "from scratch">
---

# Start Team — autonomous build loop

You are the **team lead** Claude Code session. This skill turns you into an autonomous orchestrator that drives the project from `VISION.md` to "all milestones merged" with **no user prompts** beyond the one that started this run.

Communicate progress reports to the user in Finnish. Everything written into the repo or to GitHub is in English (`CLAUDE.md → Language`).

## Step 0: Pre-flight

Run these checks. If any one fails, stop the run and tell the user (in Finnish) which check failed and how to fix it. Do **not** attempt to fix repository state silently.

1. `VISION.md` exists and is **not** the unfilled template — at least the Vision, Goal, Core Principles, Product Shape, Non-Goals, Decision Filter, Success Definition, and Persistence and Privacy Posture sections have real content (no remaining `<…>` placeholders).
2. `STACK.md` exists and is **not** the unfilled template — Language & Runtime, Frameworks, Build & verify commands, Performance budgets, Persistence shape, Approved dependencies, and Stack-specific reject-list additions sections all have real content.
3. `git status` is clean (no uncommitted changes that would conflict with feature-branch work).
4. `git remote get-url origin` returns a GitHub URL.
5. `gh auth status` succeeds.
6. The `$VERIFY_CMD` declared in `STACK.md` is runnable (try `--help` or a dry-run; do not fail the pre-flight if the runnable produces non-zero on `--help`, only if the command-not-found shell error fires).

## Step 1: Bootstrap or refresh ROADMAP.md

Read `ROADMAP.md`.

- **If `ROADMAP.md` is the unfilled template** (the only entry in the Milestones table is `<M0>`): spawn the `project-manager` agent as a teammate with the prompt:

  > "Read VISION.md and STACK.md in full. Generate the initial milestone plan into ROADMAP.md per `project-manager.md → Initial roadmap generation`. Open a `docs/pm-initial-roadmap` PR and stop. Do not call AskUserQuestion."

  Wait for the teammate to finish. **Pause and tell the user**: "Initial milestone plan PR opened — review and merge it before I continue. Reply with 'go' when merged." This is the **one** user-gated step in the autonomous flow, because committing the milestone sequence is consequential. Wait for the user reply.

- **If `ROADMAP.md` already has milestones**: skip the bootstrap; the project is already underway.

## Step 2: Spawn the agent team

Spawn the five teammates with the explicit subagent types:

- `project-manager` (writes; updates `ROADMAP.md`, captures decisions and risks).
- `architect` (read-only; reviews each milestone's design before implementation).
- `lead-dev` (writes; runs the `/implement` skill once per milestone).
- `qa-enforcer` (read-only; runs the `/codereview` skill after each milestone).
- `ux-guardian` (read-only; runs the `VISION.md` decision filter on each milestone scope).

Do **not** spawn `devils-advocate` by default — it is on-demand only. Token budget and coordination overhead are not worth the diminishing return of a sixth voice on every milestone.

**Conditional devils-advocate spawn**: if `arch` or `ux` returns a report whose final line is `Recommended next step: devils-advocate`, you may spawn `devils-advocate` once between Step 4 (architect design) and Step 5 (lead-dev `/implement`). Hand it the milestone scope, the `arch` / `ux` report that triggered the recommendation, and the relevant `VISION.md` / `STACK.md` context. Take its verdict (`PROCEED` / `PROCEED WITH SCOPE CUTS` / `REWORK`) into the milestone:
- `PROCEED` → continue to Step 5 unchanged.
- `PROCEED WITH SCOPE CUTS` → tell `pm` to record the cuts in `ROADMAP.md → Strategic decisions` and update the milestone scope, then continue.
- `REWORK` → tell `pm` to mark the milestone `Blocked` with the devils-advocate findings in the change log; continue to the next milestone.

Do not spawn `devils-advocate` more than once per milestone, and do not call `AskUserQuestion` — the autonomous flow stays autonomous.

When spawning, name each teammate by its role (e.g. `pm`, `arch`, `dev`, `qa`, `ux`) so you can reference them by name later.

## Step 3: Milestone loop

Loop while `ROADMAP.md` has at least one milestone in `Todo` status. For each iteration:

1. **Pick the next milestone** — the lowest-numbered `Todo` row in the Milestones table.

2. **Tell `pm` to transition the row to `In progress`** and surface its scope, files-to-add, files-to-remove, and open-questions list. Wait for `pm` to commit the status change to a `docs/pm-<slug>` branch and merge the trivial status update (or, if you prefer, accept it on the same feature branch the lead-dev will create).

3. **Tell `ux` to run the decision filter** on the milestone scope. If `ux` returns `REJECT`, tell `pm` to mark the milestone `Blocked` with the rejection reason in the change log, then continue to the next milestone. If `ux` returns `NEEDS NARROWING`, tell `pm` to update the milestone scope to the proposed narrower shape (with a Strategic-decisions entry), then re-run `ux` until `ACCEPT`.

4. **Tell `arch` to design the implementation** — propose interfaces, types, layer placement, and the actor / service boundaries. `arch` is read-only and returns its report; do not require plan-approval mode. The `lead-dev` reads `arch`'s report as input.

5. **Tell `dev` to run `/implement`** with the milestone scope as `$ARGUMENTS`. `dev` runs the full feature-branch ship loop (branch → code → `$VERIFY_CMD` → commit → push → PR). Wait for `dev` to report the PR URL.

6. **Tell `qa` to run `/codereview`** on the PR. If `qa` returns FAIL, send the findings back to `dev` with the prompt "address every finding from `/codereview`, then push and re-run `/codereview`". Repeat. **Maximum 3 review rounds.** If `qa` still returns FAIL after 3 rounds, tell `pm` to mark the milestone `Needs human` with the failing PR link and the most recent FAIL findings in the change log; do not merge; continue to the next milestone.

7. **When `qa` returns PASS**, the user merges. The autonomous flow does NOT auto-merge — `gh pr merge` is gated by the user per `CLAUDE.md → Decision rights`. Tell the user (in Finnish): "milestone `<name>` ready to merge — PR: `<url>`. I will continue once you merge."

   Optionally, the user may reply "merge it" — in which case you may run `gh pr merge` (autonomous merge **only** when the user has explicitly said so on this milestone or at the start of the run).

8. **After merge**, tell `pm` to transition the row to `Done`, fill in the PR link, and add a Change-log entry. Then loop to the next milestone.

## Step 4: Stop conditions

Stop the loop, report a final summary in Finnish, and clean up the team (`Clean up the team`) when any of the following is true:

- All milestones are `Done` or `Blocked` (no `Todo` rows remain).
- Three consecutive milestones have been marked `Needs human` (a signal that the autonomy fallback is being exhausted; the user should look).
- The lead-istunto (this session) has been running for more than **8 hours** since `/start-team` was invoked — checkpoint and stop, so the user can resume cleanly.
- The user sends a message asking you to stop.

Do **not** stop just because a single milestone is `Needs human` — continue with the next milestone. The point of the autonomous flow is to keep going through the easy work even when one milestone is stuck.

Do **not** call `AskUserQuestion` anywhere in this skill. The only user-interactive moment is Step 1 (initial roadmap merge) and the merge gate at the end of each milestone.

## Step 5: Final report

When you stop, write a one-screen summary in Finnish:

- Milestones `Done`: count + names.
- Milestones `Blocked`: count + names + the `VISION.md` reason for each.
- Milestones `Needs human`: count + names + the failing PR link for each.
- Strategic decisions captured this run (date + headline only).
- Risks opened / closed this run.
- Next suggested step for the user.

Then ask the user (in Finnish, free-form, **not** via `AskUserQuestion`) whether to clean up the team or leave it spawned. Default to cleaning up.

## Anti-patterns

- Calling `AskUserQuestion` anywhere in this loop. The autonomous flow depends on its absence.
- Auto-merging PRs without an explicit user authorisation.
- Pushing to `main`. Hooks block it; do not test the hook.
- Skipping the `/codereview` round. Every milestone gets a review comment, even if the lead-dev is confident.
- Running more than three review rounds on a single milestone without marking it `Needs human`. The point of the limit is to surface stuck work, not to grind tokens forever.
- Spawning `devils-advocate` by default. Spawn it only when the user asks, or when `arch` flags an unusually risky design.
