# STACK.md — `<stack name>` profile

> **Template — copy to your project as `STACK.md` and replace every `<…>` placeholder.**
> `<One-sentence summary: language + frameworks + build tooling.>`
>
> The operating contract (`CLAUDE.md` / `AGENTS.md`) is technology-neutral and defers every concrete decision to this file. Every skill and agent dereferences the six `$*_CMD` variables in Section 3 — they MUST be defined. Keep this file concrete: name types, calls, commands, tools, and thresholds. Universal rules (layering, base units, privacy, testing) live in the operating contract; do not restate them here. Record a decision or exception that changes this file in an ADR under `docs/adr/`.

---

## 0. Project shape

- **Shape:** `<UI app | backend service | CLI | library | …>`
- **Critical execution path:** `<the surface that must never block — UI thread / event loop / request hot path>`
- **Applicable states:** `<the states every visible surface handles — commonly awaiting-first-data, success, empty, degraded, permission-blocked, offline, error, plus product-specific>`
- **Recommended repository layout:** `<a directory sketch that names where the interface / domain / infrastructure layers live>`

---

## 1. Language & Runtime

- **Primary language:** `<language + version>`
- **Strictness mode:** `<the strictest type / concurrency mode the toolchain offers — exact compiler flags or lint config>`
- **Target runtime:** `<runtime + version>`
- **Minimum runtime version:** `<the floor — agents never lower it; it is owner-owned>`
- **Package manager:** `<tool>`
- **Lockfile:** `<path>`
- **Dev-environment provisioning:** `<one command from a fresh checkout to a working environment — e.g. mise install — and the file that pins tool versions>`

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
| Testing              | `<…>`               | `<property-based testing library>`     |
| Formatting / linting | `<…>`               |                                        |

---

## 3. Build & verify commands

All six variables MUST be defined. Route them through one entry point (package scripts, Makefile, task runner) that is the single source of truth. Never call the underlying tools directly from commits, CI, or agent scripts.

| Variable         | Command                                                     |
| ---------------- | ----------------------------------------------------------- |
| `$FORMAT_CMD`    | `<…>`                                                       |
| `$LINT_CMD`      | `<…>`                                                       |
| `$BUILD_CMD`     | `<…>`                                                       |
| `$TEST_CMD`      | `<…>`                                                       |
| `$VERIFY_CMD`    | `<one command that runs every gate below, in order>`        |
| `$MUTATION_CMD`  | `<mutation testing limited to given files — run for critical logic only>` |

**Narrowest test selector:** `<how to run one test or one file, used to prove a new test fails without the change>`

### Gates in `$VERIFY_CMD`

Each gate enforces a rule of the operating contract. A gate that the ecosystem cannot provide is listed as a gap, with the review question that covers it.

| Gate | Tool and threshold | Contract rule |
| ---- | ------------------ | ------------- |
| Format check | `<…>` | Code conventions |
| Strict types | `<…>` | Validate once, model the domain |
| Lint | `<…>` | Code conventions |
| Complexity | `<function complexity, nesting depth, function length, file length>` | Simple and deletable |
| Dead code | `<unused files, exports, dependencies>` | Code conventions |
| Dependency direction | `<layer rules>` | Architecture |
| Secret scan | `<…>` | Privacy and security |
| Vulnerability scan | `<…>` | Dependencies |
| Commit messages | `<Conventional Commits lint>` | Git and verification |
| Tests | `<…>` | Testing |

**Gaps:** `<gates this stack cannot provide, and the review question that covers each — or "none">`

**Change size soft limit:** `<e.g. 400 changed lines, lockfiles and generated files excluded>`

**Owner-run checks:** `<checks only the owner runs (e.g. on-device or paid), with their trigger — or "none declared">`

---

## 4. Performance budgets

- **Critical-path budget:** `<frame time / request p99 / event-loop stall limit>`
- **Cold start:** `<…>`
- **Memory ceiling:** `<…>`
- **Bundle / binary size:** `<…>`

---

## 5. Persistence shape

- **Storage primitive:** `<the one allowed primitive; name the ones that are not the default>`
- **Persisted entities:** declared by `VISION.md → Data and Permissions`.
- **Schema migration policy:** `<how decode / migration failures degrade gracefully instead of crashing>`
- **Forbidden persistence:** anything not listed in `VISION.md → Data and Permissions`.

---

## 6. Approved dependencies

Default answer to "should we add a library?" is **no**. A new entry answers the dependency questions in the operating contract in its PR. A dependency that shapes the architecture or is costly to remove also gets an ADR.

| Dependency | Version | Why it earns its place | Approver | Date |
| ---------- | ------- | ---------------------- | -------- | ---- |
| `<…>`      | `<…>`   | `<…>`                  | `<…>`    | `<…>` |

---

## 7. Stack-specific reject-list additions

Hard rules for this stack. Prefer a gate over a rule here: when a lint rule can enforce an entry, configure it and say so.

- `<the type / concurrency escape hatches that are banned without an inline comment naming the underlying constraint>`
- `<the banned debug-output calls>`
- `<framework patterns forbidden in new code>`
- `<types or calls that mix the time concepts, and hand-written offset arithmetic — see §10>`
- `<…>`

---

## 8. Logging & privacy

- **Logger:** `<the one logger>`
- **PII redaction:** `<the concrete mechanism>`
- **Crash / error reporting:** `<none by default; anything added is an approved dependency and a VISION.md data entry>`

---

## 9. Background & lifecycle

- **Allowed background work:** `<…>`
- **Forbidden background work:** `<…>`

---

## 10. Base units & time

The operating contract requires one canonical internal form per concept, converted only at the boundaries. This section pins the concrete types.

| Concept | Internal base unit | Boundary conversion |
| ------- | ------------------ | ------------------- |
| Instant | `<UTC instant type>` | `<parse inbound / serialise outbound calls>` |
| Local calendar time | `<local date-time + zone type>` | `<resolve to an instant only when needed, with the zone>` |
| Duration | `<duration type or fixed unit>` | `<…>` |
| Money | `<integer minor units + currency, or "not used">` | `<…>` |
| `<other domain unit>` | `<…>` | `<…>` |

- **Clock:** `<the injected clock and the test clock>`
- **Banned:** `<naive / local-time types and calls in logic, hand-written offset arithmetic>`
- **Tests:** `<fixed-clock mechanism; no time-zone-dependent assertions>`

---

## 11. Design guidelines & UX thresholds *(optional — UI-facing projects)*

*Declare the platform's design authority and the documented numeric thresholds `product-guardian` must test at the threshold. Remove this section for projects with no user-facing surface.*

- **Design authority:** `<the platform's design guidelines, e.g. Apple HIG, Material Design, WCAG>`
- **Documented thresholds to exercise at the threshold:** `<component → threshold>`
- **Input paths:** `<what must stay fully operable — keyboard / pointer / touch / screen reader>`

---

## 12. Best practices source *(optional)*

*Name the documentation source agents consult before design and review, and the concrete tool invocation. Subagents have only the tools their definition grants, so prefer a CLI that runs from Bash (e.g. `npx ctx7@latest`) or a URL that WebFetch can read. Remove when the project has no such source.*

`<e.g. "architect and product-guardian fetch current platform docs via <tool / URL> before design and review, and cite the section.">`
