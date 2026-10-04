# STACK.md — Strict TypeScript / Node LTS / Hono / React / Vite / Vitest profile

Policy revision: 2

> Strict TypeScript monorepo with a Hono backend (`apps/api`), a React + Vite frontend (`apps/web`), and a shared `packages/shared` module. pnpm workspaces, Vitest for tests.

Use with `DOCTRINE.md` (P1–P9) and the selected host contract. This is an
example profile, not evidence that a project has implemented its checks. On
adoption, confirm its scope, pin versions, define each command, and complete
§14–15. Record exclusions and gaps. A profile does not grant merge or release
authority beyond the adopted project contract.

---

## 0. Project shape

- **Project risk rationale:** identify affected people, data, and dependent systems. Record failure consequences, material uncertainty, and reversibility.
- **Change risk:** assess the surfaces affected by each task against that project rationale. A risk label does not waive required checks or review.

- **Shape:** UI app (`apps/web`) + backend service (`apps/api`).
- **Critical execution path:** the browser main thread / React render path on the web; the per-request hot path on the API.
- **Applicable states:** web surfaces handle awaiting-first-data, success, empty, degraded, offline, error (plus product-specific); API responses are typed success / typed error.

---

## 1. Language & Runtime

- **Primary language:** TypeScript 6.0
- **Strictness mode:** `"strict": true`, `"noUncheckedIndexedAccess": true`, `"exactOptionalPropertyTypes": true`, `"noImplicitOverride": true`, `"verbatimModuleSyntax": true`. ESLint with `@typescript-eslint/strict-type-checked`.
- **Target runtime:** Node.js 24 LTS; pin the supported patch version in `mise.toml`
- **Minimum runtime version:** Node 24.0 (no back-deployment to Node 22 / 20)
- **Package manager:** pnpm (workspaces)
- **Lockfile:** `pnpm-lock.yaml`
- **Dev-environment provisioning:** [`mise`](https://mise.jdx.dev/) is the single bootstrap. `mise install` provisions **every pinned tool and runtime version** from `mise.toml` — the exact Node.js 24 interpreter and `pnpm` — so a fresh checkout reaches a reproducible environment with one command. Wire dependency install as a mise task (e.g. `mise run setup` → `pnpm install`) so `mise install` followed by that task fully bootstraps. `mise.toml` is the source of truth for tool/runtime versions; commit it alongside the lockfile.
- **Pinning surfaces (two layers, each owns one):** `mise.toml` pins tool/runtime versions (Node, pnpm); `pnpm-lock.yaml` pins the resolved dependency graph. Never rely on a globally-installed Node or pnpm — go through mise so local and CI use identical versions.

---

## 2. Frameworks

| Concern                  | Framework / library                                                                 | Notes                                                                     |
| ------------------------ | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| Backend HTTP framework   | Hono                                                                                | Edge-runtime-friendly, web-standards-aligned                              |
| Frontend UI              | React 19                                                                            | Function components only                                                  |
| Build tool               | Vite 8                                                                              | For `apps/web`                                                            |
| State / observation      | React built-ins (`useState`, `useReducer`) + signals where appropriate              | No Redux / MobX by default                                                |
| Routing                  | TanStack Router (frontend) / Hono router (backend)                                  |                                                                           |
| Data fetching (frontend) | TanStack Query                                                                      |                                                                           |
| Validation               | Zod                                                                                 | Boundary validation for every external input (HTTP, env, persisted state) |
| Persistence              | declared per project — common defaults: SQLite via Drizzle, IndexedDB via idb, none |                                                                           |
| Testing                  | Vitest 4 (unit + integration)                                                       | Playwright optional for end-to-end                                        |
| Logging                  | pino                                                                                | structured, JSON-friendly                                                 |
| Telemetry                | none by default                                                                     | Add only with explicit `STACK.md` approval                                |
| Formatting               | Prettier 3                                                                          |                                                                           |
| Linting                  | ESLint 10 with @typescript-eslint flat config                                       |                                                                           |

---

## 3. Build & verify commands

| Variable      | Command                                             |
| ------------- | --------------------------------------------------- |
| `$FORMAT_CMD` | `pnpm format`                                       |
| `$LINT_CMD`   | `pnpm lint`                                         |
| `$BUILD_CMD`  | `pnpm build`                                        |
| `$TEST_CMD`   | `pnpm test`                                         |
| `$VERIFY_CMD` | `pnpm test-all` (format-check → type/lint/security checks → build → required tests) |

Implement these scripts in the adopting project; this profile does not supply `package.json`. Bootstrap with `mise install` (pinned Node/pnpm versions). The `package.json` scripts are the single source of truth. Never invoke `eslint`, `tsc`, `vitest`, or `vite` directly from commits, CI, or agent scripts.

---

## 4. Performance budgets

- **API request p99:** 100 ms (per route, excluding upstream calls).
- **API request p50:** 30 ms.
- **Cold start (edge runtime):** < 500 ms.
- **Cold start (Node):** < 2 s.
- **Web bundle:** < 200 KB gzipped initial JS, < 50 KB gzipped initial CSS.
- **Time to Interactive (web, slow 4G simulation):** < 3 s.
- **Memory ceiling (API container):** < 512 MB resident.

---

## 5. Persistence shape

- **Storage primitive:** declared per project. Common defaults:
  - Backend: SQLite via Drizzle ORM, or PostgreSQL via Drizzle if multi-instance.
  - Frontend: IndexedDB via idb, or `localStorage` for tiny single-user state.
- **Persisted entities:** declared by `VISION.md → Persistence and Privacy Posture`.
- **Schema migration policy:** numbered migrations under `apps/api/db/migrations/` (or equivalent). Drizzle generates them; agents review them before applying.
- **Forbidden persistence:** anything declared forbidden in `VISION.md → Persistence and Privacy Posture`.

---

## 6. Approved dependencies

Prefer supported platform capabilities. New dependencies need a PR rationale for necessity, provenance, maintenance, licence, transitive cost, and replacement cost. The lead can approve routine libraries within project authority. New providers, external data transfers, costs, or material lock-in need owner approval. The list is a starting point, not a requirement to install unused packages.

| Dependency               | Version | Why it earns its place                                | Approver  | Date       |
| ------------------------ | ------- | ----------------------------------------------------- | --------- | ---------- |
| `hono`                   | `^4.12` | Backend HTTP framework — the project's chosen default | (default) | (template) |
| `react`                  | `^19`   | Frontend UI framework                                 | (default) | (template) |
| `vite`                   | `^8`    | Frontend build tool                                   | (default) | (template) |
| `vitest`                 | `^4`    | Test runner                                           | (default) | (template) |
| `zod`                    | `^4`    | Boundary validation for every external input          | (default) | (template) |
| `pino`                   | `^10`   | Structured logging                                    | (default) | (template) |
| `@tanstack/react-query`  | `^5`    | Frontend data fetching cache                          | (default) | (template) |
| `@tanstack/react-router` | `^1`    | Frontend routing                                      | (default) | (template) |
| `eslint`                 | `^10`   | Linter                                                | (default) | (template) |
| `@typescript-eslint/*`   | `^8`    | TS-aware lint rules                                   | (default) | (template) |
| `prettier`               | `^3`    | Formatter                                             | (default) | (template) |
| `typescript`             | `^6.0`  | Language                                              | (default) | (template) |

---

## 7. Stack-specific reject-list additions

- `any` (explicit or implicit via `@typescript-eslint/no-explicit-any`) without an inline `// reason: ...` justification.
- `as` casts that bypass type checking — use `satisfies` or a runtime guard.
- `// @ts-ignore` / `// @ts-expect-error` without an inline explanation that names the underlying constraint.
- `moment` / `moment.js` in new code — use supported platform APIs or an approved time library.
- Treating local calendar values as UTC instants without their required calendar/zone, or manual UTC-offset arithmetic (see §10).
- Host-local `Date` arithmetic for zoned calendar rules; parsing a local-format string as an instant without a declared timezone.
- Full-import of `lodash` (`import _ from 'lodash'`) — import single functions only, or use the standard library equivalent.
- Raw `fetch` without zod-validated response parsing for any external network call.
- `console.log` / `console.warn` / `console.error` in shipped code — use the `pino` logger.
- Default exports for non-component, non-route modules — prefer named exports for tree-shakability and refactor safety.
- `useEffect` with empty dependency arrays for data fetching — use TanStack Query.
- Class-based React components — function components only.
- Redux, MobX, Recoil, Jotai unless `Section 6 → Approved Dependencies` explicitly authorises them.
- `process.env.X` reads outside a single `env.ts` module that validates with zod and re-exports a typed constant.

---

## 8. Logging & privacy

- **Logger:** `pino` with structured JSON output and per-environment formatters.
- **PII redaction:** `pino` `redact` paths configured in the logger setup. Allowlist log fields; default is to drop unknown fields rather than log them.
- **Crash / error reporter:** none by default. If added (e.g. Sentry), declare it in `Section 6 → Approved Dependencies` with explicit data-flow justification.

---

## 9. Background & lifecycle

- **Allowed background work:** scheduled cron jobs (defined in code, not the deploy platform), declared explicitly per service in `apps/api/src/jobs/`.
- **Forbidden background work:** long-polling websockets that keep a connection alive without active user interaction; background tabs that drive expensive computation; service workers that retain data forbidden by `VISION.md`.

---

## 10. Time & timezones

- **Instant:** `Date`, or `Temporal.Instant` where runtime support or an approved polyfill is declared. Validate external values with Zod. Store and exchange instants as UTC ISO-8601 (`Z`) or explicitly typed epoch values.
- **Calendar value:** use validated date-only or local-time fields. With Temporal, use `PlainDate` / `PlainTime`; use a named IANA zone for schedules that resolve to instants. Do not turn a birthday or recurring local schedule into a fixed UTC timestamp.
- **Duration:** use a typed value with an explicit unit, or `Temporal.Duration` when selected. Use a monotonic clock for elapsed-time measurement; distinguish elapsed hours from calendar days.
- **Conversion:** use supported calendar/zone APIs. Set `timeZone` explicitly for `Intl.DateTimeFormat`. Define handling for missing and repeated local times. Never compute timezone offsets by hand.
- **Tests:** inject the clock or use Vitest fake timers. Cover DST and zone changes when relevant. Test results must not depend on the host timezone.

---

## 11. Design guidelines & UX thresholds

- **Design authority:** WCAG 2.2 AA + native HTML semantics (browser platform conventions). Semantic elements first; ARIA only when no native element fits.
- **Documented thresholds to exercise at the threshold:**
  - Pointer target size ≥ 24×24 CSS px (WCAG 2.5.8).
  - Text contrast ≥ 4.5:1 body / 3:1 large text (WCAG 1.4.3).
  - Visible focus indicator on every interactive element (WCAG 2.4.7).
- **Input paths:** full keyboard operability; focus order follows DOM order; no pointer-only interactions.

---

## 12. Best practices source

Consult current, version-relevant MDN, Node.js, TypeScript, and the selected framework documentation for uncertain APIs, platform rules,
and material design decisions. Use the documentation tools available in the
current host. Cite the relevant section in the decision or review. Do not
require every role to repeat the same lookup or assume host-specific tools.

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

On adoption, fill in project commands, CI job names, environments, and known
gaps for each row. P1–P9 refer to `DOCTRINE.md`. Keep the matrix current with
the change. `$VERIFY_CMD` must run the applicable automated checks or report
which required external results remain pending. Assign each check a phase:
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

| Doctrine / applicability | Required evidence | Environment / gap to resolve |
| --- | --- | --- |
| P1, P6: every task | Acceptance criteria, material failure cases, assumptions, and their check mapping in the issue or PR | Lead prepares; independent review for material changes |
| P2–P5: changed code and dependencies | Strict types, format/lint, module-boundary checks, boundary validation, deterministic tests, dependency rationale | Local and CI; declare checks that rely on review |
| P5–P6: changed data boundaries | Meaning-preserving normalisation; declared independent-item or atomic failure containment; tests for transformations, mixed valid/invalid items, and atomic failures | Preserve decision-relevant distinctions, precision, and uncertainty; test containment per boundary, not a universal skip policy |
| P3, P7: security and dependencies | Gitleaks for changed files/history; locked-dependency vulnerability scan; supported static-security rules | Wire pinned tools into `pnpm test-all`; name scanner/rules and uncovered surfaces on adoption |
| P5–P7: API and web journeys | Vitest integration/contract tests; Playwright for critical flows, keyboard and supported accessibility checks; migration/recovery tests when storage changes | Local/CI with representative browser/service; record hardware or external-service gaps |
| P7: release and recovery | Before merge: release readiness and migration/recovery evidence. After release: deployed version and required health/smoke results (§15) | Target environment; a successful build does not prove release success |
| P8–P9: material changes | Current setup instructions, significant ADRs, independent review of the integrated result, explicit limitations | Separate reviewer context; no read-all-ADR prerequisite |

Pin scanner versions and configuration with the project tools. Scanners must
redact findings. Do not send source or dependency data to a new
external provider without the required authorization. An unavailable scanner
is a recorded gap, not a successful check. Select proportionate property,
mutation, and coverage analysis when it tests a named risk; scores do not
replace behavioural evidence.

---

## 15. Release, recovery, and maintenance

- **Release:** declare the web/API deployment jobs, environments, immutable version identifier, configuration validation, and required permissions. Record whether merging `main` deploys automatically.
- **Observe:** verify deployed versions, API health, and one critical web journey. Declare a bounded observation window and the diagnostic source.
- **Recover:** define rollback or roll-forward to a known artifact. For database changes, test migration from supported schemas and backup restoration; preserve compatibility during rollout.
- **Data:** document each store's purpose, retention/deletion rules, credentials, and access boundary. A cache reset is not a recovery plan for durable data.

The responsible lead verifies the integrated release within the adopted
project authority. Main remains production-ready. Added cost, a new provider
or external data transfer, material lock-in or product change, and irreversible
production-data changes require owner approval unless already authorized by
an applicable policy. Required owner tests block merge. Stop after the agreed
task and release checks; report follow-up needs without taking new backlog
work. Apply the same evidence requirements to maintenance updates.
