---
name: codereview
description: Independently review the complete current branch against main and post an audit-grade PASS or FAIL review to its PR. Use only for the QA-owned merge gate after implementation.
---

# Code Review Gate

Review the complete branch against `main` as an independent QA pass. Do not
rely on implementation-chat context. Derive scope and intent from the issue,
PR, branch history, diff, checks, and governance files. Never edit product or
governance files, commit, push, or merge.

The PR review is English. Use Simplified Technical English for the review
prose. Progress and the result returned to the user are Finnish.

## Evidence to read

- `VISION.md`, `AGENTS.md`, `STACK.md`, and `README.md`.
- The complete PR description, comments, checks, and diff.
- `git log main..HEAD --oneline` and the surrounding code for changed paths.
- The linked issue and comments when the PR resolves an issue.
- Current official documentation for any finding that depends on external
  tool, platform, framework, API, GitHub, or security-standard behavior.

If no PR exists, create the minimal PR required to preserve the audit trail,
but do not broaden its scope.

## Review standard

Every rule-backed defect, regression risk, missing required evidence,
security or privacy issue, production failure mode, required-test gap,
unsupported dependency, build-system change, or scope mismatch is a blocking
FAIL. Omit subjective style preferences and alternatives without a concrete
local rule or material risk.

Review all of these:

1. Scope matches issue and PR description; removals, migrations, dependencies,
   generated files, and CI changes are disclosed.
2. Every VISION decision-filter answer remains yes and no non-goal is added.
3. Functional behavior handles invalid, empty, repeated, partial-failure, and
   compatibility cases that apply.
4. Security and privacy boundaries, permission scope, secrets, logs,
   persistence, transport, and telemetry comply.
5. Production failure modes cover concurrency, cancellation, timeouts, stale
   data, retries, idempotency, resource load, and recovery as applicable.
6. Architecture preserves interface, domain, and infrastructure boundaries and
   right-sized state ownership.
7. Critical-path, background-work, and resource budgets in STACK.md hold.
8. Changed visible surfaces cover every declared state, accessibility path, and
   documented design threshold.
9. Tests cover new domain rules, state timelines, edge cases, and meaningful
   async behavior.
10. Dependencies, lockfiles, CI permissions, generated artifacts, and supply
    chain changes are approved and intentional.
11. No dead code, duplicated existing helper, placeholder, debug output,
    commented-out code, unsafe escape hatch, or forbidden marker remains.
12. `$FORMAT_CMD` is idempotent and `$VERIFY_CMD` passes without new warnings.
13. Branch, commits, issue linkage, PR body, and audit trail follow AGENTS.md.

## Finding format

Every blocking finding must contain:

```md
### <check>: <short title>

- **Location:** `<file>:<line>` or a PR metadata location
- **Evidence:** <what the diff and surrounding code prove>
- **Impact:** <production or workflow consequence>
- **Local rule:** `<VISION.md / AGENTS.md / STACK.md section>`
- **External reference:** <current official URL when relevant, otherwise N/A>
- **Minimum fix:** <smallest resolving change>
- **Verification:** <test or command proving the fix>
```

Do not assert external behavior that current official documentation does not
establish. Put unresolved factual uncertainty in a Verification notes section
unless a local rule requires the missing evidence, in which case it is a FAIL.

## Post the review safely

1. Resolve the PR number and current HEAD SHA first.
2. Write the body to a fresh uniquely named file in an allowed temporary
   directory. Never reuse a fixed review filename.
3. Begin with exactly `**Verdict: PASS**` or `**Verdict: FAIL**`.
4. End with `Reviewed: PR #<PR> @ <HEAD_SHA> (round <R>)`.
5. Post with `gh pr review <PR> --comment --body-file <file>`.
6. Fetch the newest review and verify its verdict, PR number, and SHA. If they
   do not match, edit it to mark it mis-posted and post a corrected fresh body.

PASS requires zero blocking findings across every check. Return the verdict,
finding count, and review URL to `qa_enforcer`. Do not merge.
