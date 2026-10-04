---
name: codereview
description: Independently review the current branch's PR against main in a separate context and post a PASS/FAIL review comment. Focuses on judgement that machines cannot make; relies on $VERIFY_CMD for mechanical checks.
context: fork
agent: reviewer
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, WebFetch
---

Review the PR for the current branch against `main`. You run in a separate context: do not rely on any earlier conversation. Derive everything from the repository, the issue, the PR, and the evidence. Report progress to the user in Finnish; write the review in English, in Simplified Technical English.

## 1. Read

- `gh pr view --comments`, `gh pr diff`, `gh pr checks`, and `git log main..HEAD --oneline`.
- The linked issue with comments (`Closes #<N>`). Its acceptance criteria are the scope contract. When neither the issue nor the PR has acceptance criteria, that is a finding.
- `VISION.md`, `CLAUDE.md`, `STACK.md`, and the ADRs that the PR adds, changes, or touches by area.
- The surrounding code of every changed path: callers, state owners, boundaries, tests.

If no PR exists, create a minimal one from the latest commit and continue. Do not ask the user.

## 2. Confirm the gates

The gates own mechanical conformance. Do not repeat their work. Check only:

- The PR states a `$VERIFY_CMD` summary line for the current head SHA, and CI checks on that head pass.
- No gate was disabled, weakened, or bypassed in the diff (lint rules, thresholds, ignore lists, `$VERIFY_CMD` scripts) without an Exception ADR.
- Critical logic, as marked in the PR, has its `$MUTATION_CMD` result and property-based tests where the input space is large.

A missing or weakened gate is a finding.

## 3. Judge

Answer these questions. Each FAIL finding must point to evidence.

1. **Right problem.** Does the change meet every acceptance criterion? Does it do anything the criteria do not ask for? Do the *Given / Observed / Assumed* lists hold up against the code?
2. **Simplest solution.** Is there a clearly smaller or more conventional solution that meets the same criteria? Does the change add an abstraction, option, or extension point that no criterion needs? Is a shared abstraction introduced before the third occurrence of the same knowledge?
3. **Right structure.** Does the structure match the current understanding of the problem, or does the change patch over a structure that no longer fits (`CLAUDE.md → Pre-decided conflicts → Local patch vs. structural change`)? Are layers, ownership, and boundaries right?
4. **Correctness under stress.** Invalid input, empty data, repeated requests, interruption, partial failure, concurrency, cancellation, timeouts, and compatibility — wherever they can occur. Do base units and the three time concepts hold?
5. **Tests.** Do the tests derive from the acceptance criteria and assert behaviour at the public boundary? Would they fail if the behaviour broke? Is anything critical untested?
6. **Security and privacy.** Data and permissions match `VISION.md → Data and Permissions`. No personal data or secrets in logs. Authorization and input handling are sound. Use OWASP, CWE, or WCAG references only when they apply.
7. **Records.** ADRs exist for decisions that need one (`CLAUDE.md → Records`). Exceptions have an Exception ADR. Owner decisions were escalated, not decided by the team. The PR states *What was not verified*.
8. **Comments.** Comments follow `CLAUDE.md → Comments`. A missing constraint is a defect as much as a narrating comment.
9. **Regret.** What will the team regret in six months? Name it only with a concrete reason.

For critical logic, argue the opposing case before you conclude.

Verify every claim about external tool, framework, or standard behaviour against current official documentation. If you cannot verify it, put it under *Verification notes*, not as a finding.

## 4. Verdict

- **FAIL** when any finding shows a broken acceptance criterion, a correctness, security, or privacy risk, a missing required record, a weakened gate, or a clearly simpler solution that the PR must take.
- **PASS** otherwise. Do not fail a PR for taste. Do not add "nit" or "suggestion" items; a point is a finding or it is left out.

In the PASS round only, run `$VERIFY_CMD` once on the PR head, in a detached worktree or the review location that `STACK.md` names. If it fails, the verdict is FAIL.

Finding format:

```md
### <question>: <short title>

- **Location:** `<file>:<line>` or a PR metadata location
- **Evidence:** <what the code or PR shows>
- **Impact:** <the consequence>
- **Rule:** <`CLAUDE.md` / `STACK.md` / `VISION.md` section or ADR, or the acceptance criterion>
- **Minimum fix:** <the smallest change that resolves it>
```

## 5. Post

1. `PR=$(gh pr view --json number -q .number)` and `HEAD_SHA=$(gh pr view --json headRefOid -q .headRefOid)`.
2. Write the body to a new, uniquely named file in the scratchpad or `$TMPDIR`, for example `review-pr${PR}-${HEAD_SHA:0:12}-$(date +%s).md`. Never reuse a file.
3. The body starts with `**Verdict: PASS**` or `**Verdict: FAIL**` and ends with `Reviewed: PR #<PR> @ <HEAD_SHA> (round <R>)`.
4. Post with `gh pr review "$PR" --comment --body-file <file>`.
5. Fetch the newest review back and check the verdict, the PR number, and the SHA. If one is wrong, edit that review to `MIS-POSTED — DISREGARD.` and post a corrected one.

Every round gets its own comment. Report the verdict, the number of findings, and the review link in Finnish.
