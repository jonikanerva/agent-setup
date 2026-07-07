# STACK.md — `<stack name>` profile

> **Template — copy to your project as `STACK.md` and replace every `<…>` placeholder.**
> `<One-sentence summary: language + frameworks + build tooling.>`
>
> `CLAUDE.md` (the engineering doctrine) is technology-neutral and defers every concrete decision to this file. Every skill and agent dereferences the five `$*_CMD` variables in Section 3 — they MUST be defined. Keep this file concrete: name types, calls, commands, and budgets. Universal rules (layering, concurrency discipline, UTC-internally, privacy) live in `CLAUDE.md`; do not restate them here.

---

## 0. Project shape

- **Shape:** `<UI app | backend service | CLI | library | …>`
- **Critical execution path:** `<the surface that must never block — UI thread / event loop / request hot path>`
- **Applicable states:** `<the states every visible surface handles — commonly awaiting-first-data, success, empty, degraded, permission-blocked, offline, error, plus product-specific>`
- **Recommended repository layout:** `<optional — a directory sketch that names where the interface / domain / infrastructure layers live>`

---

## 1. Language & Runtime

- **Primary language:** `<language + version>`
- **Strictness mode:** `<the strictest type / concurrency mode the toolchain offers — exact compiler flags or lint config. The doctrine requires the strictest mode declared here, with no new warnings.>`
- **Target runtime:** `<runtime + version>`
- **Minimum runtime version:** `<the floor — agents may never lower it; it is user-owned>`
- **Package manager:** `<tool>`
- **Lockfile:** `<path>`
- **Dev-environment provisioning:** `<how a fresh checkout reaches a working environment with one command — e.g. mise install, and which file pins the tool/runtime versions>`

---

## 2. Frameworks

| Concern              | Framework / library | Notes                                  |
| -------------------- | ------------------- | -------------------------------------- |
| UI / interface layer | `<…>`               |                                        |
| State / observation  | `<…>`               | `<patterns forbidden in new code>`     |
| Concurrency          | `<…>`               |                                        |
| Networking           | `<…>`               |                                        |
| Persistence          | `<…>`               |                                        |
| Logging              | `<…>`               | `<the banned debug-output calls>`      |
| Testing              | `<…>`               |                                        |
| Formatting / linting | `<…>`               |                                        |

---

## 3. Build & verify commands

All five variables MUST be defined — every skill and agent dereferences them. Route them through one declared entry point (package scripts, Makefile, …) that is the single source of truth; never invoke the underlying tools directly from commits, CI, or agent scripts.

| Variable      | Command                                                    |
| ------------- | ---------------------------------------------------------- |
| `$FORMAT_CMD` | `<…>`                                                      |
| `$LINT_CMD`   | `<…>`                                                      |
| `$BUILD_CMD`  | `<…>`                                                      |
| `$TEST_CMD`   | `<…>`                                                      |
| `$VERIFY_CMD` | `<one command: format-check → lint → build → tests>`       |

---

## 4. Performance budgets

- **Critical-path budget:** `<frame time / request p99 / event-loop stall limit>`
- **Cold start:** `<…>`
- **Memory ceiling:** `<…>`
- **Bundle / binary size:** `<…>`

---

## 5. Persistence shape

- **Storage primitive:** `<the one allowed primitive; name the ones that are not the default>`
- **Persisted entities:** declared by `VISION.md → Persistence and Privacy Posture`.
- **Schema migration policy:** `<how decode / migration failures degrade gracefully instead of crashing>`
- **Forbidden persistence:** anything declared forbidden in `VISION.md → Persistence and Privacy Posture`.

---

## 6. Approved dependencies

Default answer to "should we add a library?" is **no**. New entries require a `STACK.md` PR with justification.

| Dependency | Version | Why it earns its place | Approver | Date |
| ---------- | ------- | ---------------------- | -------- | ---- |
| `<…>`      | `<…>`   | `<…>`                  | `<…>`    | `<…>` |

---

## 7. Stack-specific reject-list additions

Hard rules for this stack; `/codereview` enforces every entry on every PR:

- `<the type / concurrency escape hatches that are banned without an inline justification naming the underlying-API constraint>`
- `<the banned debug-output calls>`
- `<framework patterns forbidden in new code>`
- `<local-time storage or computation and hand-rolled offset arithmetic — see §10>`
- `<…>`

---

## 8. Logging & privacy

- **Logger:** `<the one logger>`
- **PII redaction:** `<the concrete mechanism>`
- **Crash / error reporting:** `<none by default; anything added is an approved dependency with a data-flow justification>`

---

## 9. Background & lifecycle

- **Allowed background work:** `<…>`
- **Forbidden background work:** `<…>`

---

## 10. Time & timezones

UTC everywhere internally, converted only at the boundary (`CLAUDE.md → Time`). This section pins the concrete mechanics:

- **Internal representation:** `<the UTC instant type used in logic, persistence, caches, and logs>`
- **Boundary conversion:** `<the parse-inbound and render-outbound calls, with explicit timezone>`
- **Banned:** `<the naive / local-time types and calls, and hand-rolled offset arithmetic>`
- **Tests:** `<the clock-injection / fake-timer mechanism; no timezone-dependent assertions>`

---

## 11. Design guidelines & UX thresholds *(optional — UI-facing projects)*

*Declare the platform's design authority and the documented numeric thresholds `ux-guardian` must exercise at the threshold. Remove this section for projects with no user-facing surface.*

- **Design authority:** `<the platform's design guidelines, e.g. Apple HIG, Material Design, WCAG>`
- **Documented thresholds to exercise at the threshold:** `<component → threshold, e.g. "alert button count → truncates past ~10">`
- **Input paths:** `<what must stay fully operable — keyboard / pointer / touch / screen reader>`

---

## 12. Best practices source *(optional)*

*Name the documentation source agents consult before design and review passes (and how), so API-level verdicts are grounded in current docs, not training-data memory. Remove if the project has no such source.*

`<e.g. "architect and ux-guardian fetch current platform docs via <tool / URL> before every design and review pass, and cite the doc section in their reports.">`

---

## 13. Intentional Divergences

| Date     | CLAUDE.md rule | Divergence | Reason |
| -------- | -------------- | ---------- | ------ |
| _(none)_ | —              | —          | —      |
