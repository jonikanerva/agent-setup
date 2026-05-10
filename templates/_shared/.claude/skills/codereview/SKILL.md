---
name: codereview
description: Review all changes on the current branch against main
context: fork
user-invocable: true
---

Review all changes on the current branch against `main`. **This skill runs as an isolated subagent** — do not rely on any prior conversation context. Derive all understanding from the PR diff, description, and the project's governance files only.

Communicate in Finnish when reporting progress to the user; write the PR-review comment itself in English (project policy: all PR artifacts are in English).

## Prerequisites

- A PR must exist for the current branch. If not, the autonomy fallback applies: do NOT call `AskUserQuestion`. Instead, run `gh pr create` against the current branch with a minimal title / body derived from the latest commit, then proceed. (The lead-dev should already have done this; the fallback is for races where it has not.)
- Read: `gh pr view --comments`, `gh pr diff`, `gh pr checks`, and the governance files `VISION.md`, `AGENTS.md`, `STACK.md`, `CLAUDE.md`, `README.md`.

## Quality standard

The bar is the quality target stated in `VISION.md → Success Definition` and `STACK.md → Performance budgets`. **Every finding — regardless of severity — is a FAIL.** There is no "nitpick", "minor", "suggestion", or "consider fixing later" category. If something can be improved, it must be improved before merge.

## Fact verification

Every finding must be grounded in evidence. Specifically:

- **Findings about the project's own rules** are grounded in the governance files — cite the section (`AGENTS.md §4 C2`, `VISION.md → Decision Filter`, `STACK.md → Approved Dependencies`, `CLAUDE.md → Language`, etc.). The files in the repo are the source of truth for project rules.
- **Findings that turn on external-tool behavior** — how Claude Code actually treats a setting, how the build tool parses a config key, what `gh` does with a flag, whether a strict-mode diagnostic exists, what a framework API requires, what GitHub's merge-semantics are — must be verified against **current official documentation** before being recorded. A plausible-sounding assumption is not evidence.
- If the docs contradict the assumption, drop the finding.
- If the docs are silent or ambiguous after a reasonable lookup, report it as "could not verify" in the review comment rather than asserting it as a failure. Let the author decide.

This rule is narrow. It only governs factual claims about how a system works. Style preferences, architectural critique, and rule compliance against the governance files still belong in the checklist below and are evaluated on judgment.

Lookups for this rule use documented WebFetch sources (`docs.claude.com`, the framework's official docs site, `docs.github.com`). If a lookup is not possible, the finding does not meet the verification bar — omit it.

## Specific zero-tolerance rules

- No dead code, unused imports, or orphaned helpers.
- No code duplication when a shared helper exists or should be extracted.
- No `TODO`/`FIXME`/`HACK`/`XXX` comments, commented-out code, or debug `print` / `console.log` statements.
- No force-unwraps / non-null assertions outside tests and previews.
- No concurrency / type-check escape hatches (`@unchecked Sendable`, `nonisolated(unsafe)`, `@preconcurrency`, `MainActor.assumeIsolated`, `as any`, `@ts-ignore`, etc.) without a documented, audited justification in an inline comment (`AGENTS.md §4 C8, C13`).
- No unclear naming — every function, variable, and type reads naturally.
- No unnecessary complexity — if simpler code achieves the same result, flag it.
- No inconsistency with existing patterns in the codebase.
- No logging of values forbidden by `AGENTS.md §8`.

## Review checklist

Evaluate the PR against all of these. **Every missed check is a FAIL.**

1. **Scope verification** — does the diff match the PR description? Are there undocumented changes — especially removals, renames, or architectural shifts?

2. **VISION decision filter** — read `VISION.md → Decision Filter` and verify all four questions still answer "yes" for what this PR actually ships. Also verify the PR is not pulling the project toward any category in `AGENTS.md §13` or `STACK.md → Stack-specific reject-list additions`.

3. **Security & privacy** — injection risks, credential exposure, PII leaks in logs, TLS requirements. Verify `AGENTS.md §8` compliance: privacy-aware interpolation for sensitive values, no retained data forbidden by `VISION.md → Persistence and Privacy Posture`, no third-party analytics, no HTTPS opt-outs, privacy declaration updated if a new required-reason / required-data API was adopted.

4. **Threat modeling** — what could go wrong in production? Race conditions, degraded-data masking bugs, missing-permission paths, crashes on first launch without a permission, lifecycle bugs in long-running activities.

5. **Code style** — compliance with the formatter / linter declared in `STACK.md` and `AGENTS.md §10 Code conventions`. No force-unwraps / non-null assertions, no `print` / `console.log`, no broad type erasure (`AnyView`, `as any`), value types preferred, immutable bindings (`let` / `const` / `final`) over mutable, comments explain *why* not *what*.

6. **Concurrency / async safety** — `AGENTS.md §4 C1–C13`. UI-thread isolation; thread-safe primitives for shared mutable state; structured concurrency; cancellation cooperation; thread-safety at boundaries; no sync-over-async on the UI thread; no lower-level concurrency primitives unless the underlying API requires it (bridged immediately).

7. **UI / API responsiveness** — `AGENTS.md §5`. Hot-path work stays within the budget declared in `STACK.md`. No heavy work in render / view-builder / middleware. Lists virtualised with stable ids. Asset / data fetching via async loaders or thread-safe caches. Cancellable async lifecycles. Project-specific UI states (declared in `VISION.md` or the screen-local state enumeration) all handled and previewed.

8. **Architecture compliance** — `AGENTS.md §3`. One obvious state owner per screen. Phases are tagged unions / enums with associated values, not parallel booleans. Service actors / wrappers for external systems. Views consume async streams, not raw framework delegates.

9. **Stack-specific rules** — `STACK.md → Stack-specific reject-list additions`. Every entry there is a hard rule for this project; verify the PR honours all of them.

10. **Dead code, duplication, leftover markers** — scan the diff for unused functions, variables, parameters, imports, unreachable paths, orphaned helpers, copy-paste of existing helpers, `TODO`/`FIXME`/`HACK`/`XXX`, commented-out code, placeholder strings, `print` / `console.log`. Zero debt at merge.

11. **Tests** — `AGENTS.md §9`. Pure domain code has coverage including edge cases. The state holder driving a screen / handler is tested by driving a fake `AsyncSequence` / async iterator and asserting the resulting timeline. No heavyweight mocking frameworks. All tests strict-concurrency / strict-type clean.

## Output

Post every review as a plain PR comment. The PASS / FAIL verdict lives as the first line of the comment body.

```
gh pr review --comment --body "<comment>"
```

Do not use `--approve` or `--request-changes`: GitHub rejects those when the reviewer is also the PR author, which is the common case here. Plain comments work regardless of authorship and still produce a permanent audit-trail entry on the PR.

The comment body starts with one of:

- `**Verdict: PASS**` — every check passed cleanly.
- `**Verdict: FAIL**` — at least one finding exists.

Then list every finding with its file, line, and a one-sentence description. Group by checklist item.

**PASS means zero findings across all 11 checks plus privacy compliance.** One finding in any category — no matter how small — is a FAIL. Do not categorize findings as "nitpick", "minor", or "suggestion". Every finding is a required fix.

Every review round gets its own PR comment — including failed ones — so there is a permanent audit trail on GitHub.

Finally, report to the user in Finnish (Claude's chat replies are the only Finnish artifact — the PR comment itself is English):

- Verdict (PASS / FAIL).
- Number of findings if FAIL.
- Link to the review comment on GitHub.
- For FAIL: suggest running `/codereview` again after fixing (the autonomous flow does this automatically — up to 3 review rounds before the milestone is marked `Needs human`).

## Autonomy fallback

If a check is genuinely ambiguous (the rule does not clearly resolve to PASS or FAIL for this PR), default to **FAIL with the minimum-fix proposal**. Do not call `AskUserQuestion`.
