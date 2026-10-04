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

| Variable        | Command                                                                 |
| --------------- | ----------------------------------------------------------------------- |
| `$FORMAT_CMD`   | `pnpm format`                                                           |
| `$LINT_CMD`     | `pnpm lint`                                                             |
| `$BUILD_CMD`    | `pnpm build`                                                            |
| `$TEST_CMD`     | `pnpm test`                                                             |
| `$VERIFY_CMD`   | `pnpm test-all` (every gate below, in table order)                      |
| `$MUTATION_CMD` | `pnpm mutate -- --mutate <files>` (StrykerJS, incremental, critical logic only) |

**Narrowest test selector:** `pnpm test -- <file> -t "<test name>"`.

Bootstrap the environment with `mise install` (provisions the pinned Node, pnpm, and gitleaks versions) before running any command above. The `package.json` scripts are the single source of truth. Never invoke `eslint`, `tsc`, `vitest`, `vite`, `knip`, `depcruise`, `stryker`, or `gitleaks` directly from commits, CI, or agent scripts.

### Gates in `$VERIFY_CMD`

| Gate | Tool and threshold | Contract rule |
| ---- | ------------------ | ------------- |
| Format check | `prettier --check .` | Code conventions |
| Strict types | `tsc -b` with the §1 strictness flags | Validate once, model the domain |
| Lint | ESLint flat config, `@typescript-eslint/strict-type-checked` | Code conventions |
| Complexity | ESLint core: `complexity: 10`, `max-depth: 4`, `max-lines-per-function: 60` (blank lines and comments skipped; off for `*.test.ts` describe blocks), `max-lines: 400` | Simple and deletable |
| Dead code | `knip` (unused files, exports, dependencies) | Code conventions |
| Dependency direction | `dependency-cruiser` with layer rules: `packages/shared` imports neither app; domain modules import no framework, network, or storage module | Architecture |
| Secret scan | `gitleaks git --log-opts=origin/main..HEAD` and `gitleaks dir .` | Privacy and security |
| Vulnerability scan | `pnpm audit --prod --audit-level high` | Dependencies |
| Commit messages | `commitlint --from origin/main` with `@commitlint/config-conventional` | Git and verification |
| Tests | `vitest run` | Testing |

**Why these thresholds:** complexity 10 and depth 4 are the common defaults that flag functions most reviewers find hard to follow; 60 lines per function and 400 per file keep a unit readable without scrolling and still allow table-driven code. Raise a threshold only through an Exception ADR for the named file.

**Gaps:** none.

**Change size soft limit:** 400 changed lines, excluding `pnpm-lock.yaml`, snapshots, and generated files.

**Owner-run checks:** none declared.

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
- **Persisted entities:** declared by `VISION.md → Data and Permissions`.
- **Schema migration policy:** numbered migrations under `apps/api/db/migrations/` (or equivalent). Drizzle generates them; agents review them before applying.
- **Forbidden persistence:** anything declared forbidden in `VISION.md → Data and Permissions`.

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
| `fast-check`             | `^4`    | Property-based tests for critical pure logic          | (default) | (template) |
| `knip`                   | `^6`    | Dead-code gate (dev only)                             | (default) | (template) |
| `dependency-cruiser`     | `^18`   | Dependency-direction gate (dev only)                  | (default) | (template) |
| `@commitlint/cli` + `@commitlint/config-conventional` | `^21` | Commit-message gate (dev only)   | (default) | (template) |
| `@stryker-mutator/core` + `@stryker-mutator/vitest-runner` | `^10` | `$MUTATION_CMD` (dev only) | (default) | (template) |
| `gitleaks` (via `mise.toml`, not npm) | `8.x` | Secret-scan gate                       | (default) | (template) |

---

## 7. Stack-specific reject-list additions

- `any` (explicit or implicit via `@typescript-eslint/no-explicit-any`) without an inline `// reason: ...` justification.
- `as` casts that bypass type checking — use `satisfies` or a runtime guard.
- `// @ts-ignore` / `// @ts-expect-error` without an inline explanation that names the underlying constraint.
- `moment` / `moment.js` — use `Temporal` (native where the runtime ships it, else an approved polyfill).
- Mixing the time concepts: storing an *instant* in local time, storing a *local calendar time* as a precomputed UTC instant, or manual UTC-offset arithmetic. Conversion happens only at the boundary (see §10).
- `new Date(...)`-based local-component math; `Date.parse` on a local-format string; formatting to a local-time string anywhere except the display boundary; `number` floating-point arithmetic on money.
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

## 10. Base units & time

The operating contract's *Base units at the boundary* rule, pinned for this stack. Zod schemas at the HTTP, env, and storage boundaries convert to these forms; nothing between the boundaries holds another form.

| Concept | Internal base unit | Boundary conversion |
| ------- | ------------------ | ------------------- |
| Instant | `Temporal.Instant` or epoch milliseconds as a branded `number`; wire form is ISO-8601 with `Z` | Parse with `z.iso.datetime()` → instant; serialise with `.toString()` / `.toISOString()` |
| Local calendar time | `Temporal.PlainDateTime` / `PlainDate` / `PlainTime` **plus** an IANA zone string, stored together | Resolve to an instant with `.toZonedDateTime(zone)` only when an instant is needed (scheduling, comparison) |
| Duration | `Temporal.Duration`, or integer milliseconds as a branded `number` | Parse ISO-8601 durations at the boundary |
| Money | integer minor units (`bigint` or safe integer) + ISO-4217 currency code | Format with `Intl.NumberFormat` at the display edge only |

- **Clock:** inject a `Clock` interface (`now(): Temporal.Instant`); tests use a fixed clock or Vitest fake timers.
- **Display:** convert to the viewer's zone at the last moment with `Intl.DateTimeFormat` and an explicit `timeZone`.
- **Banned:** see §7 — local-component `Date` math, `Date.parse` on local strings, hand-written offset arithmetic, floating-point money.
- **Tests:** no time-zone-dependent assertions; cover a daylight-saving transition for every local-calendar-time feature.

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

`architect` and `product-guardian` consult current MDN and framework documentation before design and review verdicts on API-level questions, and cite the section. **Tool:** the `ctx7` CLI via Bash — `npx ctx7@latest library "<name>" "<question>"`, then `npx ctx7@latest docs <libraryId> "<question>"` (workflow in `~/.claude/rules/context7.md`) — with MDN via WebFetch as fallback. Training-data memory is not an acceptable source for API signatures or accessibility specifics.
