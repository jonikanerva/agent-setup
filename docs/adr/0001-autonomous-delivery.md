# 0001: Delegate delivery with independent evidence

Status: accepted by the owner for implementation, 2026-10-04.

## Context

The fixed five-role workflow costs coordination on small tasks. Its two host
implementations differ on escalation. A QA PASS can coexist with missing
required owner evidence. Global skills also update before copied contracts.

## Decision

Use shared P1–P9 quality principles and explicit host contracts. The lead owns
the result and chooses contributors. Material changes need independent review
in a separate context. Acceptance needs version-bound evidence, including
required owner tests. Adopted projects allow scoped merge and release, subject
to owner reservations and the doctrine's escalation boundaries.

Keep artifacts static. Require matching revision-2 project documents before
new autonomy applies. Preserve legacy authority. Keep backlog and history in
GitHub; use short ADRs only for durable decisions and read them as needed.

## Alternatives

- Keep all five roles mandatory: consistent ceremony, but no evidence that
  each role adds value on every task.
- Trust one implementer alone: less coordination, but no independent challenge
  of material changes or their acceptance evidence.
- Generate host files: reduces duplication but hides the final contracts and
  conflicts with the static distribution requirement.

## Consequences and reassessment

Profiles must define applicable checks and release evidence. Static checks and
linker regressions support the bundle; scenario evaluation assesses decisions.
Neither proves production model behaviour. Reassess using observed defects,
owner corrections, review rework, lead time, and cost.

Reversal requires reverting the shared policy and both host distributions.
Copied project contracts need a separate reviewed migration. Global updates
must not silently expand their authority. This change updates this source
repository only; the owner retains review and merge of its PR.
