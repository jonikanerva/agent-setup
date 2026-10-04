---
name: implement
description: >
  Implement an agreed change on a feature branch and ship it as a PR: branch,
  change, tests, per-commit checks, $VERIFY_CMD, push, PR. Use for any code
  change that ships as a PR. Never merges.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent
argument-hint: <what to implement, or the lead's hand-off>
---

# Implement and ship

The task comes from `$ARGUMENTS`. `CLAUDE.md` is the contract; `STACK.md` holds every command and tool. Report to the user in Finnish. Write everything in the repository and on GitHub in English, in Simplified Technical English.

## 1. Scope

Collect the scope, the acceptance criteria, the design, the criticality, and the ADRs to write. When the lead did not provide acceptance criteria, write them first (expected behaviour plus the error and edge cases that matter) with *Given*, *Observed*, and *Assumed* separated.

Stop and report to the lead (or the user, when there is no lead) when the task needs an owner decision (`CLAUDE.md → Owner decisions`) or when the current structure does not fit the change. A structural change goes first, in its own refactoring PR on a `refactor/<topic>` branch.

## 2. Branch

Run `git branch --show-current`.

- On `main`: create `feat|fix|chore|docs|refactor/<topic>` (at most 50 characters, lowercase, hyphens).
- On a feature branch that belongs to this task: stay, and read `git log main..HEAD --oneline`.
- For a change stacked on an unmerged refactoring PR: branch from that PR's branch and set the PR base to it.

Never commit or push to `main`.

## 3. Change

- Write tests from the acceptance criteria. Run the narrowest test selector in `STACK.md` and see each new test fail before the change and pass after it.
- Implement the smallest coherent change that meets the criteria and fits the design.
- For critical logic: add property-based tests where the input space is large, and run `$MUTATION_CMD` on the changed code. Kill the surviving mutants that matter or explain them in the PR.
- Add a preview, story, or fixture for each declared state of a changed visible surface.
- Write the ADRs the task needs from `docs/adr/TEMPLATE.md`.
- Update documentation in the same change as the behaviour.

## 4. Commit

Before each commit, run `$FORMAT_CMD`, `$LINT_CMD`, and `$BUILD_CMD`. All must pass. Fix the cause; never suppress a diagnostic without an exception (`CLAUDE.md → Exceptions`).

Stage only the files of this change; never `git add -A` or `git add .`. Never commit `.env` files or secrets. Conventional Commits, one logical change per commit, the body says why, and the `Co-Authored-By` trailer from `CLAUDE.md`.

After 10 failed repair attempts on the same failure, push the work to `chore/abandoned-<task>`, open a draft PR that describes the failure and what you tried, and report it. Do not loop.

## 5. Verify and push

Commit everything first, so the tree is clean. Run `$VERIFY_CMD` once on that exact tree, then push:

```
$VERIFY_CMD
git push -u origin <branch>
```

If it fails, fix, commit, and run it again; the attempts count toward the limit. Do not run it again on a tree that already passed. Record `git rev-parse HEAD` and the summary line.

Before the final review round, fold fixup commits ("fix lint", "fix typo", "address review") into the commits they belong to without an editor: create them with `git commit --fixup=<sha>`, then run `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash main`. Run `$VERIFY_CMD` on the new head, and push with `--force-with-lease`.

## 6. PR

Check for an existing PR: `gh pr list --head <branch> --json number,url`.

- None: `gh pr create`. Fill `.github/pull_request_template.md` when the project has it. Otherwise cover: why, acceptance criteria with evidence, what changed, team and criticality, decisions (ADRs, owner decisions, assumptions), verification on the head SHA, and *What was not verified*. Add `Closes #<N>` when the PR resolves an issue. Title under 70 characters.
- Exists: update the description so that it is still true, and add a comment that says what changed in this round.

List each owner-run check that `STACK.md` triggers for this diff as `ran on <SHA>: PASS` or `triggered, pending owner run`. Do not run an owner-run check unless the owner asked for it.

## 7. Report

Return the PR URL, the pushed head SHA, and the `$VERIFY_CMD` summary line. `/codereview` comes next and is not part of this skill. In the team flow the lead sends the reviewer. When a human ran `/implement` directly, suggest `/codereview`.

Never merge, never push to `main`, never use `--no-verify`, and never lower the strictness mode or minimum runtime version in `STACK.md`.
