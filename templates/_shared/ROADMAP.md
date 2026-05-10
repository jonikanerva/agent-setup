# Roadmap

> **Template — populated automatically by the `project-manager` agent during `/start-team`.**
> Do not delete historical entries; the change log is an append-only audit trail.
>
> Read order for any agent picking up a milestone: `VISION.md` → `AGENTS.md` → `STACK.md` → this file. Each milestone scope below should be self-contained enough to execute from this file alone.

---

## Milestones

| # | Status | Milestone | Scope summary | PR |
| - | ------ | --------- | ------------- | -- |
| `<M0>` | `Todo` | `<short title>` | `<one-line scope>` | `<PR link once merged>` |

Statuses: `Todo` · `In progress` · `Done` · `Blocked` · `Needs human`.

---

## Strategic decisions

*Append-only. Each entry: dated bullet, what changed, why. When a decision is superseded, **add** a new bullet that references and overrides it — never delete the original.*

- `<YYYY-MM-DD>` — `<decision>`. Reason: `<rationale>`.

---

## Risk register

*Open risks blocking the launch. Each entry: short title, the failing condition, the mitigation, and the milestone where it is most likely to manifest. Closed risks move to the change log on the date of closure (do not delete).*

| Risk | Failing condition | Mitigation | Milestone |
| ---- | ----------------- | ---------- | --------- |
| `<title>` | `<what would have to be true to break it>` | `<the planned mitigation>` | `<M…>` |

---

## Change log

*Append-only, dated, audit-grade. The single source of truth for "what happened on this branch and why". Agents add an entry whenever:*

- *a milestone status row transitions*,
- *a strategic decision is recorded above*,
- *a risk is opened, mitigated, or closed*,
- *an autonomy-fallback default is taken per `AGENTS.md §14.1`*.

- `<YYYY-MM-DD>` — `<event>`.

---

## Milestone scopes

*One subsection per milestone. Each subsection lists: scope (in / out), files to add, files to remove, verification steps, and any open questions. The `project-manager` agent generates these from `VISION.md` and `STACK.md`; the `lead-dev` agent uses them as the implementation contract.*

### `<M0 — title>`

**Status:** `Todo`
**Scope (in):** `<bullets>`
**Scope (out — explicitly not in this milestone):** `<bullets>`
**Files to add:** `<paths>`
**Files to remove:** `<paths>`
**Verification:** `<test names, screens to preview, commands to run>`
**Open questions:** `<list — agents resolve these via §14.1 autonomy fallback unless they touch VISION.md / AGENTS.md>`
