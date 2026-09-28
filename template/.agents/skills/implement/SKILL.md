---
name: implement
description: Implement an approved feature, fix, or code change on a feature branch, run the project verification contract, commit, push, and open or update a PR. Use for the lead developer's ship loop; never merge.
---

# Implement and Ship

Complete the approved change and leave a verified PR for independent review.
Communicate with the user in Finnish. Write code, comments, branches, commits,
issues, and PR text in English. Use Simplified Technical English for
user-facing prose.

## 1. Validate scope

Read `VISION.md`, `AGENTS.md`, `STACK.md`, and the issue when one exists. Run
every question in `VISION.md → Decision Filter`. Also scan
`AGENTS.md → Reject changes that…` and
`STACK.md → Stack-specific reject-list additions`.

If the approved task fails a rule, do not silently implement it. Record the
conflict in the existing issue or PR and reduce the task to the smallest shape
that passes. Do not create an issue when the user supplied the task directly.

## 2. Ensure a feature branch

Inspect the current branch and `git log main..HEAD --oneline`.

- On `main`, create `feat|fix|chore|docs/<topic>` with lowercase hyphenated
  text and a maximum total length of 50 characters.
- On an existing feature branch, continue only when it belongs to this task.
- Never commit or push to `main`. This rule covers a normal push and a
  force-push.
- A force-push to your feature branch is allowed. Use `--force-with-lease`,
  never a bare `--force`.

## 3. Implement

Follow the approved architecture and the engineering doctrine in `AGENTS.md`.
Obtain every concrete technology choice and command from `STACK.md`; never
substitute an underlying tool for a named command.

- Add or update tests for behavior and domain edge cases.
- Add previews, stories, or fixtures for every changed visible state.
- Update privacy declarations for new data flows.
- Preserve cancellation, concurrency, critical-path, and dependency rules.
- Leave no debug output, placeholder implementation, dead code, or secret.

When an ambiguity is not resolved by the approved scope or governance, choose
the smallest conservative shape that passes the decision filter and document
the decision in the PR.

## 4. Check each commit

Before each commit, run `$FORMAT_CMD`, `$LINT_CMD`, and `$BUILD_CMD`, exactly
as declared in `STACK.md`. All must pass without new warnings, and formatting
must be idempotent. Run `$VERIFY_CMD` in step 5, once before each push.

Fix root causes rather than suppressing diagnostics. Stop after 10 unsuccessful
repair attempts. Preserve the work on a `chore/abandoned-<task>` branch and a
draft PR describing the failure; do not claim success.

## 5. Commit and push

Stage only task-related files; never use `git add .` or `git add -A`. Use one
logical Conventional Commit per unit, explain why, and append
`Co-Authored-By: Codex <noreply@openai.com>`. Never include `.env`, credentials,
tokens, or other secrets.

Before each push, run `$VERIFY_CMD` once on the exact committed tree that you
push: commit every change first, so the working tree is clean. It must pass
without new warnings. If it fails, fix the cause, commit the fix, and run it
again; these attempts count toward the limit in step 4. Do not run it again on
a tree that already passed it. Record the pushed head SHA and the
`$VERIFY_CMD` summary line, or the stamp line when `STACK.md` defines one. Push
only the feature branch.

Do not run an owner-run check that `STACK.md` reserves for the owner unless the
owner asks for it in the current task. For a mutation check, run the narrowest
test selector that `STACK.md` names, else `$TEST_CMD`.

## 6. Open or update the PR

Check whether the current branch already has a PR. Create one when absent; add
an update comment when it already exists. Keep the title under 70 characters.

Follow `.github/pull_request_template.md` when the project has that file.
Otherwise include why, what, decision-filter answers, rules involved,
verification, states handled, and any autonomy fallback. Add `Closes #<N>`
when the PR resolves an issue. List each owner-run check that `STACK.md`
triggers for the diff as `ran on <SHA>: PASS` or
`triggered, pending owner run`.

Return the PR URL, the pushed head SHA, changed files, and the `$VERIFY_CMD`
summary line (the stamp line when `STACK.md` defines one) to the project
manager. After the hand-off, push nothing until the project manager sends
findings. Do not run `$codereview`; `qa_enforcer` owns that gate. Never
merge.
