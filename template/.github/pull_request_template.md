<!--
Fill every section. Write "N/A" with a reason when a section does not apply.
Use Simplified Technical English: short sentences, active voice, plain terms.
Delete this comment.
-->

## Why

<The problem this PR solves, in one paragraph.>

Closes #<issue number, when this PR resolves an issue>

## Acceptance criteria

<Copy the criteria from the issue, or write them here when there is no issue. Mark each criterion as met, and name the test or evidence.>

- [ ] <criterion> — <test or evidence>

**Given:** <requirements that the owner or the issue stated>
**Observed:** <facts found in the code, data, or documentation>
**Assumed:** <assumptions made by the team, and why the chosen option is the most reversible one>

## What

- <change 1>
- <change 2>

## Team and criticality

- **Roles used:** <e.g. architect, implementer, reviewer — and why this set is enough>
- **Criticality:** <normal | critical> — <reason>. Critical logic received: <mutation testing, property tests, devils-advocate challenge, or N/A>.

## Decisions

- **ADRs:** <links to new or changed `docs/adr/` files, or "none">
- **Owner decisions:** <escalations and the owner's answer, or "none">
- **Product fit:** <Decision Filter answers when the PR changes product behaviour, else "no product behaviour change">

## Verification

- `$VERIFY_CMD` on `<head SHA>`: `<summary line>`
- `$MUTATION_CMD` (critical logic only): `<score and scope, or N/A>`
- Owner-run checks (per `STACK.md`): `<none declared | none triggered | ran on <SHA>: PASS | triggered, pending owner run>`
- Manual checks: `<what was checked by hand, with result, or none>`

## What was not verified

<Required. List what no check covered: environments, devices, data volumes, integrations, edge cases. "Nothing" needs a reason.>

## Notes for reviewer

<Anything the diff does not show: a known limitation, a follow-up issue, a risk.>
