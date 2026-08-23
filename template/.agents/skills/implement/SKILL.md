---
name: implement
description: Implement an approved feature, fix, or code change on a feature branch, run the project verification contract, commit, push, and open or update a PR. Use for the lead developer's ship loop; never merge.
---

# Implement and Ship

Complete the approved change and leave a verified PR for independent review.
Communicate with the user in Finnish. Write code, comments, branches, commits,
issues, and PR text in English.

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
- Never commit or push to `main` and never force-push.

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

## 4. Verify

Run `$FORMAT_CMD`, then `$VERIFY_CMD`, exactly as declared in `STACK.md`. Both
must pass without new warnings and formatting must be idempotent.

Fix root causes rather than suppressing diagnostics. Stop after 10 unsuccessful
repair attempts. Preserve the work on a `chore/abandoned-<task>` branch and a
draft PR describing the failure; do not claim success.

## 5. Commit and push

Stage only task-related files; never use `git add .` or `git add -A`. Use one
logical Conventional Commit per unit, explain why, and append
`Co-Authored-By: Codex <noreply@openai.com>`. Never include `.env`, credentials,
tokens, or other secrets. Push only the feature branch.

## 6. Open or update the PR

Check whether the current branch already has a PR. Create one when absent; add
an update comment when it already exists. Keep the title under 70 characters.

Follow `.github/pull_request_template.md`. Include why, what, decision-filter
answers, rules involved, verification, states handled, and any autonomy
fallback. Add `Closes #<N>` when the PR resolves an issue.

Return the PR URL, commit SHA, changed files, and `$VERIFY_CMD` summary to the
project manager. Do not run `$codereview`; `qa_enforcer` owns that gate. Never
merge.
