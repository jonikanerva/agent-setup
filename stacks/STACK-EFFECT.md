# STACK.md — TypeScript + Effect stateless SPA profile

> Effect-backed TypeScript profile for a stateless web application: an `@effect/platform` HttpApi backend, generated OpenAPI, a React + Vite SPA, and a pnpm monorepo sharing Effect Schema across server and client through an explicit API contract package. Effect is used because correctness should be machine-checkable: typed errors, Schema boundaries, and Layer-provided dependencies maximise what the compiler and tests can prove.
>
> **Normative.** `MUST`, `MUST NOT`, `SHOULD`, and `MAY` are binding as written. `VISION.md` decides product intent; this file decides implementation mechanics. Surface conflicts before deviating.

---

## 0. Project shape

- **Shape:** backend service (`apps/server`, `@effect/platform` HttpApi) + browser SPA (`apps/web`, React + Vite), sharing one contract package.
- **Critical execution path:** server — request decode → scope narrowing → use case → typed response or typed error; web — route match → query/client cache → typed view model → React render.
- **Applicable states:** web surfaces handle awaiting-first-data, success, empty, degraded, offline, error (plus product-specific); API responses are typed success / typed error.
- **Intended for:** stateless, external-data-driven products where data is decoded, narrowed, and filtered at the schema boundary. **Not the default for:** SEO-first or SSR-required sites, or products needing durable business data, accounts, workflows, payments, or background jobs as core behaviour — those need a persistent variant of this profile, recorded in an ADR.

### Monorepo layout

```txt
repo/
  apps/
    server/src/        # main.ts, http/, layers/, adapters/, observability/
    web/src/           # routes/, components/, features/, api/, view-models/
  packages/
    api-contract/src/  # schemas/, errors/, http-api/, dtos/
    domain/src/        # use-cases/, rules/, invariants/
    config/            # eslint/, typescript/
  e2e/tests/
  STACK.md
  VISION.md
  CLAUDE.md
  mise.toml
  pnpm-workspace.yaml
  pnpm-lock.yaml
```

### Package boundaries (enforced by the dependency-cruiser gate, §3)

- `packages/api-contract` is the **only** package shared by server and web: Effect Schema definitions, HttpApi route/group definitions, DTOs, typed public errors, public enums/discriminated unions, generated OpenAPI artifacts. It MUST NOT import server runtime, React, browser APIs, Node-only APIs, cache implementations, or UI code.
- `packages/domain` contains pure business rules and use cases. It MUST NOT import React, browser APIs, server runtime, `fetch`, clock/time APIs, cache, filesystem, or HTTP modules directly — those capabilities are Effect services provided via `Layer` and declared in `R`.
- `apps/server` wires Effects, Layers, HttpApi handlers, platform runtime, upstream clients, cache, and logging.
- `apps/web` renders UI and maps typed API results into typed view models. It MUST NOT import server implementation code.

---

## 1. Language & Runtime

- **Primary language:** TypeScript 6.x stable line. The TypeScript 7 native preview MUST NOT be used in mainline; migrating requires an ADR after a CI compatibility trial.
- **Strictness mode:** ESLint with `@typescript-eslint/strict-type-checked`, plus this non-negotiable `tsconfig` baseline:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noPropertyAccessFromIndexSignature": true,
    "useUnknownInCatchVariables": true,
    "verbatimModuleSyntax": true,
    "moduleDetection": "force"
  }
}
```

- **Typing discipline:** model impossible states as impossible; discriminated unions over optional-field state bags; `satisfies` over casts; no `any`, no `as unknown as` (§7).
- **Target runtime:** Node.js 24 LTS; **minimum** 24.11.0. `mise.toml`, the Docker base image, the CI image, and the deployment runtime MUST agree on the same Node major line.
- **Package manager:** pnpm workspaces; `pnpm-lock.yaml` pins exact resolved versions. `package.json` MUST NOT use `latest`. Dependency upgrades happen in dedicated PRs; `effect`, `@effect/platform`, and `@effect/platform-node` upgrade together in a single PR.
- **Dev-environment provisioning:** [`mise`](https://mise.jdx.dev/) is the single bootstrap. `mise install` provisions **every pinned tool and runtime version** from `mise.toml` — the exact Node.js 24 LTS interpreter and `pnpm` — so a fresh checkout reaches a reproducible environment with one command. Wire dependency install as a mise task (e.g. `mise run setup` → `pnpm install`).
- **Pinning surfaces (two layers, each owns one):** `mise.toml` pins tool/runtime versions (Node, pnpm); `pnpm-lock.yaml` pins the resolved dependency graph. Never rely on a globally-installed Node or pnpm — go through mise so local and CI use identical versions.

---

## 2. Frameworks

| Concern                | Technology                              | Role                                                                   |
| ---------------------- | --------------------------------------- | ---------------------------------------------------------------------- |
| Backend core           | Effect v3                               | Side effects as values; typed errors; dependency injection via `Layer` |
| Schema / validation    | Effect Schema (`effect/Schema`)         | Decode, validate, transform, and narrow external data at the boundary  |
| REST layer             | `@effect/platform` HttpApi              | Typed REST routes and generated OpenAPI                                |
| Node runtime layer     | `@effect/platform-node`                 | Node-specific platform services and runtime wiring                     |
| Server cache           | Effect `Cache`                          | In-memory TTL cache, deterministic tests with `TestClock`              |
| Frontend UI            | React 19 + React DOM                    | Function components only                                               |
| Frontend build         | Vite                                    | SPA build and dev server                                               |
| Routing                | TanStack Router                         | Type-safe SPA routing                                                  |
| SSR escape hatch       | TanStack Start                          | Conditional only; requires an ADR (see §2.3)                           |
| Client cache           | TanStack Query                          | Query cache, background refetch, controlled technical persistence      |
| Styling                | Tailwind CSS v4 via `@tailwindcss/vite` | Utility-first styling with Vite integration                            |
| Unit/integration tests | Vitest                                  | Pure functions, Effects, Layers, API handlers                          |
| Property tests         | fast-check                              | Domain invariants, schema narrowing, cache and state behaviour         |
| Browser tests          | Playwright                              | E2E, smoke, offline/degraded/error state checks                        |
| Lint                   | ESLint + typescript-eslint              | Typed lint gates, no unsafe TypeScript                                 |
| Format                 | Prettier                                | Consistent formatting through `pnpm format`                            |

### 2.1 Effect conventions

**Functional core, imperative shell.** Pure functions compute; I/O lives at the edge. The core MUST NOT import `fetch`, filesystem APIs, cache implementations, clock/time APIs, HTTP framework modules, browser APIs, or process/env APIs directly — each is an Effect service provided as a `Layer` and declared in `R` (§0 package boundaries).

**Errors are values.** No `throw` in domain logic. Expected failures are tagged errors in the Effect error channel; defects remain defects — do not convert programmer errors into business errors. The shared taxonomy is deliberately small; add a new error type only when the existing ones cannot describe the failure:

```ts
type ApiError =
  | ScopeError
  | DecodeError
  | UpstreamUnavailable
  | UpstreamInvalidResponse
  | CacheUnavailable
  | RateLimited
  | InternalDefect;
```

Every API-facing error MUST provide this descriptor. Error mappings are centralized and tested; public error shapes are part of the API contract; `InternalDefect` maps to a generic public message; `safeMessage` MUST NOT contain PII, raw upstream payloads, secrets, identifiers, or stack traces:

```ts
type ErrorDescriptor = {
  readonly _tag: string;
  readonly status: 400 | 401 | 403 | 404 | 409 | 422 | 429 | 500 | 502 | 503;
  readonly retryable: boolean;
  readonly safeMessage: string;
  readonly logLevel: "debug" | "info" | "warn" | "error";
  readonly cacheable: boolean;
};
```

**External data boundary.** External data is untrusted until decoded. Decode and narrow with Effect Schema at the boundary; never pass, persist, or log raw upstream data. Product scope from `VISION.md` is enforced structurally at the Schema layer, not in React components — anything out of scope is dropped, rejected, or mapped to a typed error at the boundary.

**Thin handlers.** HttpApi handlers receive decoded input, call a use case or service, and return typed success or typed error. No business rules, no hand-rolled error-to-response glue, no ad hoc post-decode validation beyond use-case invariants.

**Contract checks.** Generated OpenAPI is a build artifact or test snapshot; public route changes update the snapshot. Every public endpoint requires a success test, at least one typed-error test, a decode/narrowing test, and contract snapshot coverage.

### 2.2 Frontend state and client cache

React components SHOULD render typed view models, not raw TanStack Query state:

```ts
type RemoteView<A, E> =
  | { readonly _tag: "AwaitingFirstData" }
  | { readonly _tag: "Success"; readonly data: A }
  | { readonly _tag: "Empty" }
  | { readonly _tag: "Degraded"; readonly data: A; readonly reason: E }
  | { readonly _tag: "Offline"; readonly staleData?: A }
  | { readonly _tag: "Error"; readonly error: E };
```

- The mapping from TanStack Query result to `RemoteView` is centralized and tested; components MUST NOT scatter ad hoc `isLoading` / `isError` / `data?.length === 0` branching when the shared view model exists.
- TanStack Query owns client data fetching — no `useEffect` for server-state fetching. Query keys are typed, stable, and derived from decoded route/search parameters; query functions call typed API clients, never raw `fetch` from components.
- Client persistence is **technical cache only**, never product state: opt-in per query; persisted keys MUST NOT contain user identifiers; persisted values MUST be schema-narrowed, in-scope public data with `maxAge` and `schemaVersion` (bust the cache on version change); never persist raw upstream responses, and never persist error objects unless explicitly safe and schema-defined. Must align with `VISION.md → Data and Permissions`.

### 2.3 TanStack Start (SSR) policy

TanStack Start is not a default dependency. Adopting it requires an ADR naming at least one explicit product need: SEO, social sharing previews, a first-render latency target the SPA cannot meet, edge rendering, a server-side session/auth model, or an SSR-required integration. Until then, TanStack Router runs in SPA mode.

### 2.4 `@effect/platform` HttpApi risk acceptance

Parts of the Effect platform ecosystem move faster than the core `effect` package; HttpApi is accepted with mitigations: exact versions pinned in `pnpm-lock.yaml`; `@effect/platform` / `@effect/platform-node` versions chosen for Effect v3 compatibility (do not assume they share `effect`'s major version); the three packages upgrade together in one dependency PR; OpenAPI output is snapshot-tested; every public endpoint has contract tests plus at least one golden-path test through the derived/generated client. Any HttpApi API-surface change gets an ADR.

### 2.5 Testing policy

| Test type         | Tool                           | Required for                                                                 |
| ----------------- | ------------------------------ | ---------------------------------------------------------------------------- |
| Unit              | Vitest                         | Pure functions, view-model mapping, simple use cases                         |
| Integration       | Vitest + Effect Layers         | HttpApi handlers, adapters, cache behaviour                                  |
| Property-based    | fast-check                     | Invariants, schema narrowing, transformations, status mapping                |
| Contract          | Vitest snapshots or equivalent | OpenAPI output, public DTOs, public error shapes                             |
| Browser smoke/e2e | Playwright                     | Route rendering, loading/error/offline/degraded states, critical user paths  |

Property-based tests are required for schema-narrowing rules, scope filtering, cache TTL and key behaviour, error/status mapping, invariant-preserving transformations, route/search-parameter parsing, and any logic where examples alone are likely to miss edge cases. Time-dependent behaviour (TTL, retries, timeouts, refresh windows) MUST be verified deterministically with Effect `TestClock` — no wall-clock waits or arbitrary sleeps.

---

## 3. Build & verify commands

Bootstrap the environment with `mise install` (provisions the pinned Node/pnpm versions — §1) before running any command below. The `package.json` scripts are the single source of truth. Do not invoke `tsc`, `eslint`, `vitest`, `playwright`, or `vite` directly from commits, CI, or agent scripts unless a script delegates to them.

| Variable             | Command              |
| -------------------- | -------------------- |
| `$FORMAT_CMD`        | `pnpm format`        |
| `$LINT_CMD`          | `pnpm lint`          |
| `$TYPECHECK_CMD`     | `pnpm typecheck`     |
| `$BUILD_CMD`         | `pnpm build`         |
| `$TEST_CMD`          | `pnpm test`          |
| `$UNIT_TEST_CMD`     | `pnpm test:unit`     |
| `$PROPERTY_TEST_CMD` | `pnpm test:property` |
| `$CONTRACT_TEST_CMD` | `pnpm test:contract` |
| `$E2E_CMD`           | `pnpm test:e2e`      |
| `$SMOKE_CMD`         | `pnpm test:smoke`    |
| `$VERIFY_CMD`        | `pnpm verify`        |
| `$VERIFY_CI_CMD`     | `pnpm verify:ci`     |
| `$MUTATION_CMD`      | `pnpm mutate -- --mutate <files>` (StrykerJS, incremental, critical logic only) |

**Narrowest test selector:** `pnpm test:unit -- <file> -t "<test name>"`.

Recommended script semantics:

```txt
pnpm verify     = format check → typecheck → lint (incl. complexity) → dead code → dependency direction
                  → secret scan → vulnerability scan → commit lint → build → unit tests
pnpm verify:ci  = verify → property tests → contract tests → selected browser smoke/e2e tests
```

### Gates in `$VERIFY_CMD`

| Gate | Tool and threshold | Contract rule |
| ---- | ------------------ | ------------- |
| Format check | `prettier --check .` | Code conventions |
| Strict types | `tsc -b` with the §1 baseline | Validate once, model the domain |
| Lint | ESLint flat config, `typescript-eslint` strict type-checked | Code conventions |
| Complexity | ESLint core: `complexity: 10`, `max-depth: 4`, `max-lines-per-function: 60` (blank lines and comments skipped; off for test describe blocks), `max-lines: 400` | Simple and deletable |
| Dead code | `knip` (unused files, exports, dependencies) | Code conventions |
| Dependency direction | `dependency-cruiser` encoding the §0 package boundaries (replaces hand-kept `no-restricted-imports` lists) | Architecture |
| Secret scan | `gitleaks git --log-opts=origin/main..HEAD` and `gitleaks dir .` | Privacy and security |
| Vulnerability scan | `pnpm audit --prod --audit-level high` | Dependencies |
| Commit messages | `commitlint --from origin/main` with `@commitlint/config-conventional` | Git and verification |
| Tests | `vitest run` (unit) | Testing |

Thresholds follow `STACK-TS.md`: the common defaults that flag code most reviewers find hard to follow. Raise one only through an Exception ADR for the named file.

**Gaps:** none.

**Change size soft limit:** 400 changed lines, excluding `pnpm-lock.yaml`, OpenAPI snapshots, and generated files.

**Owner-run checks:** none declared.

---

## 4. Performance budgets

Starting points; product-specific budgets in `VISION.md` or an ADR override them.

- **API handler overhead:** p99 < 100 ms, p50 < 30 ms (excluding upstream calls). End-to-end p95 including upstream calls is product-specific.
- **Every upstream call** MUST have: a timeout; a typed failure; a retry policy or an explicit no-retry rationale; bounded concurrency (no unbounded fan-out); structured logging without raw payloads.
- **Cold start (Node):** < 2 s.
- **Web:** initial JS bundle < 200 KB gzipped; Time to Interactive on slow 4G < 3 s. Loading, empty, degraded, offline, and error states must be testable and visible.

---

## 5. Persistence shape

- **Server default:** in-memory Effect `Cache` only — TTL-bounded, no manual invalidation without a documented reason, no database, no on-disk persistence, no per-visitor state. If durable persistence becomes necessary, this profile is no longer sufficient — create a persistent variant profile and record the change in an ADR.
- **Client default:** TanStack Query in-memory cache; optional technical persistence only per §2.2 and only if `VISION.md` allows it; no product state, no user preferences, no account/session state, no user identifiers in cache keys.
- **Forbidden persistence:** anything declared forbidden in `VISION.md → Data and Permissions` (accounts, per-user state, PII, device/session identifiers, telemetry, raw upstream payloads, …) — that list is product/privacy policy owned by `VISION.md`, not restated here.

---

## 6. Approved dependencies

Default answer to "should we add a library?" is **no**. New entries require a `STACK.md` PR with rationale, approver, and date. The Context7 ID column is a lookup aid for sessions where the Context7 MCP server is available (see "Documentation lookups" below).

| Dependency                               | Version policy                                             | Context7 ID                             | Why it earns its place                                      |
| ---------------------------------------- | ---------------------------------------------------------- | --------------------------------------- | ----------------------------------------------------------- |
| `effect`                                 | `3.x` stable                                               | `/llmstxt/effect_website_llms-full_txt` | Backbone: typed effects, errors, DI, Schema, Cache          |
| `@effect/platform`                       | Compatible line for Effect 3; package version may be `0.x` | `/llmstxt/effect_website_llms-full_txt` | HttpApi, OpenAPI, platform abstractions                     |
| `@effect/platform-node`                  | Compatible with `@effect/platform`                         | `/llmstxt/effect_website_llms-full_txt` | Node runtime and platform services                          |
| `typescript`                             | `6.x` stable                                               | `/microsoft/typescript`                 | Language                                                    |
| `react`                                  | `19.x`                                                     | `/facebook/react`                       | Frontend UI                                                 |
| `react-dom`                              | `19.x`                                                     | `/facebook/react`                       | DOM renderer                                                |
| `vite`                                   | stable, explicit semver                                    | `/vitejs/vite`                          | Frontend build tool                                         |
| `@vitejs/plugin-react`                   | stable, explicit semver                                    | `/vitejs/vite`                          | React integration for Vite                                  |
| `@tanstack/react-router`                 | `1.x`                                                      | `/tanstack/router`                      | Type-safe SPA routing                                       |
| `@tanstack/react-query`                  | `5.x`                                                      | `/tanstack/query`                       | Client server-state cache                                   |
| `@tanstack/react-query-persist-client`   | conditional                                                | `/tanstack/query`                       | Query persistence only when approved by `VISION.md`         |
| `@tanstack/query-sync-storage-persister` | conditional                                                | `/tanstack/query`                       | Browser storage persister only when approved by `VISION.md` |
| `@tanstack/start`                        | conditional (§2.3)                                         | `/tanstack/router`                      | SSR only when product requirements justify it               |
| `tailwindcss`                            | `4.x`                                                      | `/tailwindlabs/tailwindcss`             | Utility styling                                             |
| `@tailwindcss/vite`                      | `4.x` compatible                                           | `/tailwindlabs/tailwindcss`             | Tailwind v4 Vite plugin                                     |
| `vitest`                                 | stable, explicit semver                                    | `/vitest-dev/vitest`                    | Test runner                                                 |
| `fast-check`                             | stable, explicit semver                                    | `/dubzzz/fast-check`                    | Property-based tests                                        |
| `@playwright/test`                       | stable, explicit semver                                    | `/microsoft/playwright`                 | Browser e2e and smoke tests                                 |
| `eslint`                                 | stable, explicit semver                                    | `/eslint/eslint`                        | Lint runtime                                                |
| `typescript-eslint`                      | stable, explicit semver                                    | `/typescript-eslint/typescript-eslint`  | Typed lint gates                                            |
| `prettier`                               | stable, explicit semver                                    | `/prettier/prettier`                    | Formatter                                                   |
| `pnpm`                                   | stable, explicit semver                                    | `/pnpm/pnpm`                            | Package manager                                             |
| `knip`                                   | stable, explicit semver (dev)                              | —                                       | Dead-code gate                                              |
| `dependency-cruiser`                     | stable, explicit semver (dev)                              | —                                       | Dependency-direction gate                                   |
| `@commitlint/cli` + `@commitlint/config-conventional` | stable, explicit semver (dev)                 | —                                       | Commit-message gate                                         |
| `@stryker-mutator/core` + `@stryker-mutator/vitest-runner` | stable, explicit semver (dev)            | —                                       | `$MUTATION_CMD`                                             |
| `gitleaks` (via `mise.toml`, not npm)    | `8.x`                                                      | —                                       | Secret-scan gate                                            |

**Documentation lookups.** Model priors drift toward older or beta APIs — Effect APIs especially. Before writing integration-seam code (Layer wiring, HttpApi handlers, Query persistence, Router search-param validation, Vite/Tailwind plugin wiring) or doing a major upgrade, check the current official docs rather than writing from memory. When the Context7 MCP server is available, use it with targeted, version-pinned queries (the IDs above; target Effect v3). If the docs, this file, and local code disagree, stop and document the mismatch — if a package API differs from what this file expects, update this file before continuing.

---

## 7. Stack-specific reject-list additions

The following are forbidden unless an Exception ADR explicitly permits them:

- explicit or implicit `any`; `as unknown as`; casts that bypass type checking instead of Schema guards or `satisfies`;
- `// @ts-ignore` / `// @ts-expect-error` without a precise inline reason naming the underlying TypeScript limitation, and a tracking issue;
- `throw` in domain logic;
- direct I/O imports in pure core modules (§0 package boundaries, §2.1);
- untyped external data reaching code before Effect Schema decode/narrowing;
- `console.*` in shipped code;
- class-based React components;
- `useEffect` for server-state data fetching;
- reading wall-clock time directly (`Date.now()` / `new Date()`) in domain logic instead of the `Clock` capability; mixing the time concepts (an instant stored in local time, a local calendar time stored as a precomputed instant) or manual UTC-offset arithmetic (see §10);
- raw `fetch` from React components;
- hand-rolled error-to-response glue in HttpApi handlers;
- Effect v4 beta APIs; the TypeScript 7 preview in mainline;
- integration-seam code written against remembered package APIs without a current-docs check (§6 → Documentation lookups);
- background polling or long-lived connections without active user interaction;
- new production dependencies without a §6 entry approved in advance.

---

## 8. Logging & privacy

- **Logger:** Effect logging (`Effect.log*`) or a structured logger wired through Effect services. No `console.*` in shipped code.
- **Log content:** structured and redacted — no raw upstream payloads, secrets, PII, user identifiers, or device identifiers; no stack traces in public responses.
- **Telemetry / analytics:** policy is owned by `VISION.md → Data and Permissions`; anything approved there is wired as an approved dependency (§6) with redaction and retention configured in code.

---

## 9. Background & lifecycle

- **Allowed background work:** request-driven cache refresh through Effect `Cache`; TTL-bounded cache entries; deterministic cache tests with `TestClock`.
- **Forbidden background work:** background polling or long-lived connections without active user interaction; background work retaining data forbidden by `VISION.md`; background jobs that create durable state.

---

## 10. Base units & time

The operating contract's *Base units at the boundary* rule, pinned for this stack. Effect Schema at the HttpApi and upstream boundaries decodes into these forms (§2.1); nothing between the boundaries holds another form.

| Concept | Internal base unit | Boundary conversion |
| ------- | ------------------ | ------------------- |
| Instant | `DateTime.Utc`; wire form is ISO-8601 with `Z` | Decode with a UTC-normalising schema (`Schema.DateTimeUtc`); encode as ISO-8601 `Z` in the API contract |
| Local calendar time | a local date/time value **plus** an IANA zone (`DateTime.Zoned` when resolved) | Resolve to an instant with the stored zone only when an instant is needed |
| Duration | `Duration` (Effect) | Decode with `Schema.Duration`-family schemas at the boundary |
| Money | integer minor units + ISO-4217 currency code, as a branded schema | Format with `Intl.NumberFormat` in the SPA only |

- **Clock:** the clock is a capability. Read "now" through Effect's `Clock` / `DateTime.now` declared in `R`, never `Date.now()` / `new Date()` in domain code (§2.1).
- **Display:** convert to the viewer's zone at the last moment in the SPA with `Intl.DateTimeFormat` and an explicit `timeZone`.
- **Tests:** exercise TTL, retry, timeout, and refresh windows with `TestClock` (§2.5); no time-zone-dependent assertions; cover a daylight-saving transition for every local-calendar-time feature.
- **Never** hand-write offset arithmetic; go through `DateTime` / `Intl`.

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

`architect` and `product-guardian` consult current Effect, MDN, and framework documentation before design and review verdicts on API-level questions, and cite the section. **Tool:** the `ctx7` CLI via Bash — `npx ctx7@latest library "<name>" "<question>"`, then `npx ctx7@latest docs <libraryId> "<question>"` (workflow in `~/.claude/rules/context7.md`) — with `effect.website` / MDN via WebFetch as fallback. Training-data memory is not an acceptable source for API signatures or accessibility specifics.
