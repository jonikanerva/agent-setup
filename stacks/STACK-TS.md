# STACK.md — Strict TypeScript / Node LTS / Hono / React / Vite / Vitest profile

> Strict TypeScript monorepo with a Hono backend (`apps/api`), a React + Vite frontend (`apps/web`), and a shared `packages/shared` module. pnpm workspaces, Vitest for tests.

---

## 0. Project shape

- **Shape:** UI app (`apps/web`) + backend service (`apps/api`).
- **Critical execution path:** the browser main thread / React render path on the web; the per-request hot path on the API.
- **Applicable states:** web surfaces handle awaiting-first-data, success, empty, degraded, offline, error (plus product-specific); API responses are typed success / typed error.

---

## 1. Language & Runtime

- **Primary language:** TypeScript 6.0
- **Strictness mode:** `"strict": true`, `"noUncheckedIndexedAccess": true`, `"exactOptionalPropertyTypes": true`, `"noImplicitOverride": true`, `"verbatimModuleSyntax": true`. ESLint with `@typescript-eslint/strict-type-checked`.
- **Target runtime:** Node.js 24 (Krypton — active LTS, latest 24.15.0)
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
| `$VERIFY_CMD` | `pnpm test-all` (type-check → lint → build → tests) |

Bootstrap the environment with `mise install` (provisions the pinned Node/pnpm versions) before running any command above. The `package.json` scripts are the single source of truth. Never invoke `eslint`, `tsc`, `vitest`, or `vite` directly from commits, CI, or agent scripts.

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

Default answer to "should we add a library?" is **no**. The lists below are intentionally short; new entries require a `STACK.md` PR with justification.

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
- `moment` / `moment.js` — use `Temporal` (proposal) via polyfill or `date-fns` if approved.
- Local-time storage or computation, and manual UTC-offset arithmetic — timezone conversion happens only at the request-parse / response-build edges (see §10).
- `new Date(...)`-based local-time math or storing `Date`/timestamps that implicitly carry a local offset; formatting to a local-time string anywhere except the display boundary.
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

Time is treated exactly like any other external input: **UTC everywhere internally, converted only at the boundary.** This is the same "validate/narrow at the edge" discipline this profile applies to data, applied to instants.

- **Internal representation:** all timestamps in logic, API payloads, persistence, caches, and logs are **UTC instants** — a `Date` (which is an absolute epoch instant, not a wall-clock time) or a UTC `Temporal.Instant` / ISO-8601 string with a `Z` offset. Values that carry an implicit local offset are forbidden (see §7).
- **Conversion happens only at the two edges:** parsing an inbound request/payload → normalise to a UTC instant immediately (validate with Zod, e.g. `z.string().datetime()` / `z.coerce.date()`); building an outbound response → serialise as UTC ISO-8601 (`.toISOString()`); rendering a user-facing value → convert to the target timezone at the last moment (`Intl.DateTimeFormat` with an explicit `timeZone`). Nothing in between ever holds local time.
- **Mechanics:** prefer `Temporal` (via the approved polyfill) or `date-fns` for date math; never hand-roll `timedelta`/offset arithmetic. When using `Date`, only ever read/write epoch milliseconds or ISO-8601-with-`Z`; never `Date.parse` a local-format string and never assemble a date from local components for logic.
- **Wire format:** the API contract exchanges UTC ISO-8601 strings (`Z` suffix); the frontend converts to the user's timezone for display only.
- **Tests:** freeze/inject the clock (a fixed `Date` / Vitest fake timers) rather than reading wall-clock time; no timezone-dependent assertions.

> The language-neutral UTC-in-logic / convert-at-edges rule lives in `CLAUDE.md → Time`; this section pins the concrete TypeScript mechanics.

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

`architect` and `ux-guardian` consult current MDN and framework documentation before design and review verdicts on API-level questions, and cite the section. **Tool:** the `ctx7` CLI via Bash — `npx ctx7@latest library "<name>" "<question>"`, then `npx ctx7@latest docs <libraryId> "<question>"` (workflow in `~/.claude/rules/context7.md`) — with MDN via WebFetch as fallback. Training-data memory is not an acceptable source for API signatures or accessibility specifics.

---

## 13. Intentional Divergences

| Date     | CLAUDE.md rule | Divergence | Reason |
| -------- | -------------- | ---------- | ------ |
| _(none)_ | —              | —          | —      |
