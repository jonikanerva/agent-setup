# STACK.md — `<stack name>` profile

> **Skeleton — fill every section, then save as `STACK.md` in your project.**
> Replace every `<…>` placeholder; delete the guidance italics once a section is final. See `STACK-TS.md` / `STACK-SWIFT.md` for worked examples.

---

## 0. Project shape

*What kind of software this is — this is what makes the universal doctrine concrete.*

- **Shape:** `<UI app | backend service | CLI | library | …>`.
- **Critical execution path:** `<what the doctrine's "critical path" means here — e.g. UI thread / event loop / per-request hot path / none>`.
- **Applicable states:** `<which of awaiting-first-data / success / empty / degraded / permission-blocked / offline / error apply, plus product-specific ones; or "N/A — non-interactive">`.

---

## 1. Language & Runtime

- **Primary language:** `<language + version>`
- **Strictness mode:** `<the strictest compiler/type/concurrency flags, named exactly>`
- **Target runtime:** `<runtime + min version>`
- **Minimum runtime version:** `<no back-deployment below this>`
- **Package manager:** `<tool + lockfile name>`

---

## 2. Frameworks

*The chosen primitive for each concern. The doctrine refers to these generically; name them here.*

| Concern | Framework / library | Notes |
| ------- | ------------------- | ----- |
| Interface layer (UI / HTTP / CLI) | `<…>` | |
| State / observation | `<…>` | |
| Concurrency model | `<…>` | |
| Navigation / routing | `<…>` | |
| Networking | `<…>` | |
| Persistence | `<…>` | |
| Validation | `<…>` | |
| Testing | `<…>` | |
| Logging | `<…>` | |
| Telemetry | `<none by default>` | |
| Formatting / linting | `<…>` | |

---

## 3. Build & verify commands

*The named commands the doctrine and CI call. Never invoke the underlying tools directly.*

| Variable | Command |
| -------- | ------- |
| `$FORMAT_CMD` | `<…>` |
| `$LINT_CMD` | `<…>` |
| `$BUILD_CMD` | `<…>` |
| `$TEST_CMD` | `<…>` |
| `$VERIFY_CMD` | `<…>` (the full gate: type-check → lint → build → tests) |

`<which file holds these as the single source of truth, e.g. package.json scripts / Makefile>`.

---

## 4. Performance budgets

- `<latency / frame / cold-start / memory / bundle budgets that apply to this shape>`

---

## 5. Persistence shape

- **Storage primitive:** `<key-value | document | SQL | file | none>`
- **Persisted entities:** declared by `VISION.md → Persistence and Privacy Posture`.
- **Schema migration policy:** `<how decode / migration failures are handled>`
- **Forbidden persistence:** anything forbidden in `VISION.md → Persistence and Privacy Posture`.

---

## 6. Approved dependencies

*Default answer to "should we add a library?" is no. Each entry needs a `STACK.md` PR with justification.*

| Dependency | Version | Why it earns its place | Approver | Date |
| ---------- | ------- | ---------------------- | -------- | ---- |
| `<…>` | `<…>` | `<…>` | `<…>` | `<…>` |

---

## 7. Stack-specific reject-list additions

*The concrete banned calls, keywords, and anti-patterns for this stack — the doctrine's reject list refers here for specifics. Include the exact escape-hatch tokens that are forbidden.*

- `<banned call / pattern>` — `<why>`.
- `<…>`

---

## 8. Logging & privacy

- **Logger:** `<the structured logger>`
- **PII redaction:** `<the platform's privacy-aware redaction mechanism>`
- **Crash / error reporter:** `<none by default; if any, justify>`

---

## 9. Background & lifecycle

- **Allowed background work:** `<…>`
- **Forbidden background work:** `<…>`

---

## 10. Intentional Divergences

| Date | CLAUDE.md rule | Divergence | Reason |
| ---- | -------------- | ---------- | ------ |
| *(none)* | — | — | — |
