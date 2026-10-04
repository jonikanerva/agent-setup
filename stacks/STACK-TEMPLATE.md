# STACK.md — `<stack name>` profile

Policy revision: 2

> **Template — copy to your project as `STACK.md` and replace every `<…>` placeholder.**
> `<One-sentence summary: language + frameworks + build tooling.>`
>
> `DOCTRINE.md` defines P1–P9. The selected host contract defines agent operation and authority. This file gives their concrete application: types, boundaries, commands, budgets, release controls, and evidence. Define all five `$*_CMD` variables in §3. Complete §14–15 before adoption. This profile does not grant authority beyond the project contract.

---

## 0. Project shape

- **Project risk rationale:** identify affected people, data, and dependent systems. Record failure consequences, material uncertainty, and reversibility.
- **Change risk:** assess the surfaces affected by each task against that project rationale. A risk label does not waive required checks or review.

- **Shape:** `<UI app | backend service | CLI | library | …>`
- **Critical execution path:** `<the surface that must never block — UI thread / event loop / request hot path>`
- **Applicable states:** `<the states every visible surface handles — commonly awaiting-first-data, success, empty, degraded, permission-blocked, offline, error, plus product-specific>`
- **Recommended repository layout:** `<optional — a directory sketch with module responsibilities and permitted dependency directions; each layer needs a current purpose>`

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
| `$VERIFY_CMD` | `<one command: format-check → lint/type/security checks → build → required tests>`       |

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

Prefer supported platform capabilities. Record each added dependency's need, provenance, maintenance, licence, transitive cost, and replacement cost in the PR. Record significant decisions in `docs/adr/`. The lead can approve routine libraries within project authority; new providers, external data transfers, costs, or material lock-in need owner approval.

| Dependency | Version | Why it earns its place | Approver | Date |
| ---------- | ------- | ---------------------- | -------- | ---- |
| `<…>`      | `<…>`   | `<…>`                  | `<…>`    | `<…>` |

---

## 7. Stack-specific reject-list additions

Hard rules for this stack; the code-review workflow checks applicable entries:

- `<the type / concurrency escape hatches that are banned without an inline justification naming the underlying-API constraint>`
- `<the banned debug-output calls>`
- `<framework patterns forbidden in new code>`
- `<implicit timezone conversion, mixing instants/calendar values/durations, and manual UTC-offset arithmetic — see §10>`
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

Apply P5 according to meaning. Calendar values are not necessarily instants.

- **Instant:** `<absolute instant type; UTC wire and storage format>`.
- **Calendar value:** `<date-only / local-time types; explicit calendar and IANA zone when conversion to an instant is required>`.
- **Duration:** `<duration type and unit; monotonic clock for elapsed time>`.
- **Conversion:** `<boundary validation and named conversion functions; policy for missing or repeated times at DST transitions>`.
- **Tests:** `<injectable clock; date-only, DST, zone-change, and elapsed-time cases where relevant>`.

---

## 11. Design guidelines & UX thresholds *(optional — UI-facing projects)*

*Declare the platform's design authority and the documented numeric thresholds `ux-guardian` must exercise at the threshold. Remove this section for projects with no user-facing surface.*

- **Design authority:** `<the platform's design guidelines, e.g. Apple HIG, Material Design, WCAG>`
- **Documented thresholds to exercise at the threshold:** `<component → threshold, e.g. "dialog option count → verified platform limit, source and test case">`
- **Input paths:** `<what must stay fully operable — keyboard / pointer / touch / screen reader>`

---

## 12. Best practices source

Name official, version-relevant documentation for this stack. Consult it when
an API, platform rule, or material technology decision is uncertain. Use the
documentation tools available in the current host; do not assume another
agent has the same tools. Cite relevant sections in the decision or review.

- **Sources:** `<official documentation URLs>`.

---

## 13. Scoped exceptions

Do not weaken a rule or check to make a change pass. The responsible lead
resolves exceptions within project authority, with an independent reviewer.
The change author must not approve their own weaker acceptance or checks.
Escalate changes beyond that authority and unresolved material risks to the
owner. Record significant design decisions separately in concise `docs/adr/`
files. Read them when relevant; keep backlog and change history in GitHub.

| Rule / scope | Reason and consequences | Compensating evidence | Responsible lead / reviewer / approval | Expiry or reassessment |
| --- | --- | --- | --- | --- |
| _(none)_ | — | — | — | — |

---

## 14. Applicability and evidence

On adoption, fill in local commands, environments, known gaps, and any
existing required CI jobs. P1–P9 refer to `DOCTRINE.md`. Run required tests
and the full `$VERIFY_CMD` locally for the exact mergeable version against
the current integration base. Failed or missing required local checks block
merge. CI is optional; existing required CI checks must also pass and must
not be bypassed. Do not require new CI or repository protection settings.
Keep this matrix current. Assign each applicable check a phase:
before merge or after release. Missing pre-merge evidence blocks merge;
missing post-release evidence blocks a claim of successful release. A future
production deployment is not a prerequisite for approving its PR.
Do not report full acceptance from a local subset. Record results for the exact commit and
environment; missing required evidence blocks acceptance without a reviewed
§13 exception. Reviewers assess whether checks detect meaningful violations.
Apply P6 to material claims: retain procedures or scripts,
safe inputs or reconstruction steps, expected outcomes, and results. Link the
evidence location from the PR. Trace expectations to original requirements,
independent source evidence, or labelled provisional assumptions. Passing a
test of an assumption does not establish its validity. Include challenge
cases beyond supplied examples. Report unrepeatable claims and their limits;
they cannot count as passed required checks.

For §14–15, a release, monitoring, migration, or recovery item may be
`not applicable` with a short reason tied to project purpose. A CLI or library
label does not waive these duties as a group. An unsupported tool is a gap,
not a reason to claim the requirement does not apply.

| Doctrine / applicability | Required evidence | Environment / gap to resolve |
| --- | --- | --- |
| P1, P6: every task | Acceptance criteria, material failure cases, assumptions, and their check mapping in the issue or PR | Lead prepares; independent review for material changes |
| P2–P5: changed code and dependencies | Strict types, format/lint, module-boundary checks, boundary validation, deterministic tests, dependency rationale | Required locally; existing required CI also passes; declare checks that rely on review |
| P5–P6: changed data boundaries | Meaning-preserving normalisation; declared independent-item or atomic failure containment; tests for transformations, mixed valid/invalid items, and atomic failures | Preserve decision-relevant distinctions, precision, and uncertainty; test containment per boundary, not a universal skip policy |
| P3, P7: security and dependencies | `<pinned secret, dependency-vulnerability, and static-security scanners, commands, and scope>` | Local; existing required CI also passes; document unsupported checks and compensating evidence |
| P5–P7: interfaces and critical journeys | `<integration, contract, UI/accessibility, performance, migration and recovery checks that apply>` | `<local test service, simulator or hardware; existing required CI; pending owner checks>` |
| P7: release and recovery | Before merge: release readiness and migration/recovery evidence. After release: deployed version and required health/smoke results (§15) | Target environment; a successful build does not prove release success |
| P8–P9: material changes | Current setup instructions, significant ADRs, independent review of the integrated result, explicit limitations | Separate reviewer context; no read-all-ADR prerequisite |

### Example check configuration

These tools and numeric limits are examples, not universal mandates. On
adoption, select and justify the applicable checks, scope, and acceptance
conditions. Record required checks in the §3 entry points; optional example
tools need the normal dependency assessment. Do not lower an adopted gate
merely to make a change pass. Existing §13 exception rules still apply.

| Check | Tool | Threshold / acceptance condition | Principle |
| --- | --- | --- | --- |
| Formatting | `<formatter check mode>` | `<no differences>` | P3, P8 |
| Types | `<strict compiler/type checker>` | `<no errors or new warnings; identify untyped boundaries>` | P3 |
| Lint | `<selected ecosystem rules>` | `<no rule violations>` | P3 |
| Complexity | `<complexity analyser or explicit review procedure>` | `<justified metric and limit; scope and exclusions>` | P3, P4 |
| Dead code | `<unused-code analyser>` | `<no unexplained findings; dynamic entry points checked>` | P3, P7 |
| Dependency directions | `<module visibility/import checker>` | `<no forbidden edges; list unenforced boundaries>` | P4 |
| Secrets | `<secret scanner and scan scope>` | `<no confirmed exposed secrets>` | P3, P7 |
| Vulnerabilities | `<resolved-dependency scanner/advisory procedure>` | `<declared risk threshold; all findings triaged>` | P2, P7 |
| Tests | `<unit/integration/critical-flow tools>` | `<all required cases pass locally; criteria and challenge cases covered>` | P5, P6 |

For every unsupported tool or platform, name the enforcement gap and credible
replacement evidence, such as independent boundary review and targeted
failure tests. State what the replacement cannot show. Missing required
evidence still blocks merge.

Pin scanner versions and configuration with the project tools. Scanners must
redact findings. Do not send source or dependency data to a new
external provider without the required authorization. An unavailable scanner
is a recorded gap, not a successful check. Select proportionate property,
mutation, and coverage analysis when it tests a named risk; scores do not
replace behavioural evidence.

---

## 15. Release, recovery, and maintenance

Apply §14's purpose-based applicability assessment to each item below.
Record a short reason for each `not applicable` item; retain the relevant
distribution, compatibility, diagnosis, and data obligations.

- **Release:** `<trigger, target environments, command/job, required permissions, and version identifier>`.
- **Observe:** `<health/smoke check, diagnostic source, and bounded observation window>`.
- **Recover:** `<rollback/roll-forward command, data backup/restore checks, compatibility window, and responsible lead>`.
- **Data:** `<persisted data, purpose, retention/deletion policy, migration and recovery tests; explain exclusions>`.

The responsible lead verifies the integrated release within the adopted
project authority. Main remains production-ready. Added cost, a new provider
or external data transfer, material lock-in or product change, and irreversible
production-data changes require owner approval unless already authorized by
an applicable policy. Required owner tests block merge. Stop after the agreed
task and release checks; report follow-up needs without taking new backlog
work. Apply the same evidence requirements to maintenance updates.
