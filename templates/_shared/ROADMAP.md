# Roadmap

> **Template — populated automatically by the `/project-manager` skill on its first run against this repo (`bootstrap` mode).**
> Forward-looking only. The audit trail of *what happened and why* is git history + PR descriptions + merge-commit chains (`CLAUDE.md → Git workflow` enforces merge-not-squash). This file plans what is coming next.
>
> Read order for any agent picking up a milestone: `VISION.md` → `AGENTS.md` → `STACK.md` → this file. Each milestone scope below should be self-contained enough to execute from this file alone.

---

## Milestones

| # | Status | Milestone | Scope summary | PR |
| - | ------ | --------- | ------------- | -- |
| `<M0>` | `Todo` | `<short title>` | `<one-line scope>` | `<PR link once merged>` |

Statuses: `Todo` · `In progress` · `Done` · `Blocked` · `Needs human`.

---

## Strategic decisions in force

*Active architectural and product constraints that bind future work — ADR-style. Each entry is a rule that applies **now**, not a log of how we got here. When a decision is superseded, **rewrite or remove** the entry; the git history of this file preserves the prior state. The originating PR (linked when relevant) carries the full rationale.*

- `<active constraint>`. Why it binds future work: `<rationale>`. PR: `<link if applicable>`.

---

## Open risks

*Risks currently threatening a milestone. When a risk is mitigated or no longer relevant, **delete the row** — the PR or commit that resolved it is the audit trail.*

| Risk | Failing condition | Mitigation | Milestone |
| ---- | ----------------- | ---------- | --------- |
| `<title>` | `<what would have to be true to break it>` | `<the planned mitigation>` | `<M…>` |

---

## Milestone scopes

*One subsection per milestone. Each subsection lists: scope (in / out), files to add, files to remove, verification steps, and any open questions. The `/project-manager` skill generates these from `VISION.md` and `STACK.md` in `bootstrap` mode; the `lead-dev` teammate uses them as the implementation contract.*

### `<M0 — title>`

**Status:** `Todo`
**Scope (in):** `<bullets>`
**Scope (out — explicitly not in this milestone):** `<bullets>`
**Files to add:** `<paths>`
**Files to remove:** `<paths>`
**Verification:** `<test names, screens to preview, commands to run>`
**Open questions:** `<list — agents resolve these via §14.1 autonomy fallback unless they touch VISION.md / AGENTS.md>`
