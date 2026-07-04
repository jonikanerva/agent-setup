# STACK.md — TypeScript + Effect stateless SPA profile

> Effect-backed TypeScript profile for a stateless web application: an `@effect/platform` HttpApi backend, generated OpenAPI, a React + Vite SPA, and a pnpm monorepo sharing Effect Schema across server and client through an explicit API contract package. Effect is used because correctness should be machine-checkable: typed errors, Schema boundaries, and Layer-provided dependencies maximise what the compiler and tests can prove.
>
> **Normative.** `MUST`, `MUST NOT`, `SHOULD`, and `MAY` are binding as written. When this document conflicts with product scope, `VISION.md` decides product intent and this file decides implementation mechanics. Surface conflicts before deviating.

---

## 0. Profile scope

This file defines the **technical stack and engineering rules**. Product scope, privacy posture, allowed data, forbidden persistence, and user-facing behaviour belong in `VISION.md`.

This profile is intended for:

- a backend service exposing typed REST via `@effect/platform` HttpApi;
- a browser SPA built with React, Vite, and TanStack Router;
- external-data-driven products where data is decoded, narrowed, and filtered at the schema boundary;
- agent-assisted development where correctness must be validated by compiler, tests, contract checks, and browser smoke tests.

This profile is **not** the default choice for:

- SEO-first or content-heavy sites;
- products requiring SSR by default;
- products requiring durable business data, accounts, workflows, payments, or user-generated content;
- products where background jobs are part of core behaviour.

If those needs appear, create either:

- a `STACK-EFFECT-PERSISTENT.md` variant, or
- an ADR documenting the divergence from this stateless SPA profile.

---

## 1. Project shape

### 1.1 Runtime shape

- **Backend:** Node.js service using `@effect/platform` HttpApi.
- **Frontend:** React SPA built by Vite.
- **Routing:** TanStack Router in SPA mode.
- **Client cache:** TanStack Query.
- **Server cache:** Effect `Cache`, in memory, TTL-bounded.
- **Contract:** Effect Schema and HttpApi definitions shared through `packages/api-contract`.
- **Validation:** all external input is decoded and narrowed before touching domain, cache, UI, or logs.

### 1.2 Critical execution paths

- Server hot path: request decode → scope narrowing → use case → typed response or typed error.
- Browser hot path: route match → query/client cache → typed view model → React render.

### 1.3 Recommended monorepo structure

```txt
repo/
  apps/
    server/
      src/
        main.ts
        http/
        layers/
        adapters/
        observability/
    web/
      src/
        routes/
        components/
        features/
        api/
        view-models/
  packages/
    api-contract/
      src/
        schemas/
        errors/
        http-api/
        dtos/
    domain/
      src/
        use-cases/
        rules/
        invariants/
    config/
      eslint/
      typescript/
  e2e/
    tests/
  docs/
    adr/
  STACK-EFFECT-STATELESS-SPA.md
  VISION.md
  AGENTS.md
  mise.toml
  package.json
  pnpm-workspace.yaml
  pnpm-lock.yaml
```

### 1.4 Package boundaries

- `packages/api-contract` is the only package shared by server and web.
- `packages/api-contract` MAY contain Effect Schema, HttpApi definitions, DTOs, typed public errors, and generated contract artifacts.
- `packages/api-contract` MUST NOT import server runtime, React, browser APIs, Node-only APIs, cache implementations, or product UI code.
- `packages/domain` contains pure business rules and use cases.
- `packages/domain` MUST NOT import React, browser APIs, server runtime, fetch, clock, cache, filesystem, or HTTP modules directly.
- `apps/server` wires Effects, Layers, HttpApi handlers, platform runtime, upstream clients, cache, and logging.
- `apps/web` renders UI and maps typed API results into typed view models.
- `apps/web` MUST NOT import server implementation code.

Use lint rules such as `no-restricted-imports` to enforce these boundaries.

---

## 2. Language, runtime, and package policy

### 2.1 TypeScript

- **Primary language:** TypeScript 6.x stable line.
- **TypeScript 7 native preview:** MUST NOT be used in mainline.
- **TS7 migration:** requires ADR after stable release and CI compatibility trial.

Non-negotiable `tsconfig` baseline:

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

Rules:

- Do not use `any`.
- Do not use `as unknown as`.
- Do not suppress type errors unless the inline reason names the underlying TypeScript limitation and there is a tracking issue.
- Prefer discriminated unions over optional-field state bags.
- Prefer `satisfies` over casts.
- Model impossible states as impossible.

### 2.2 Node.js

- **Target runtime:** Node.js 24 LTS.
- **Minimum runtime version:** Node.js 24.11.0.
- **Recommended runtime:** latest Node.js 24 LTS patch.
- `.node-version`, Docker base image, CI image, and deployment runtime MUST use the same Node major line.

### 2.3 Package manager

- **Package manager:** pnpm workspaces.
- **Lockfile:** `pnpm-lock.yaml`.
- `package.json` MUST NOT use `latest`.
- Lockfile pins exact resolved versions.
- Dependency upgrades happen in dedicated PRs.
- Major upgrades require Context7 docs retrieval and a changelog summary.
- New production dependencies require a `STACK` or ADR entry with rationale, owner, approver, and date.

### 2.4 Dev-environment provisioning

- **Bootstrap:** [`mise`](https://mise.jdx.dev/) is the single bootstrap. `mise install` provisions **every pinned tool and runtime version** from `mise.toml` — the exact Node.js 24 LTS interpreter and `pnpm` — so a fresh checkout reaches a reproducible environment with one command.
- Wire dependency install as a mise task (e.g. `mise run setup` → `pnpm install`) so `mise install` followed by that task fully bootstraps.
- **Pinning surfaces (two layers, each owns one):** `mise.toml` pins tool/runtime versions (Node, pnpm); `pnpm-lock.yaml` pins the resolved dependency graph. `mise.toml`, `.node-version`, the Docker base image, the CI image, and the deployment runtime MUST agree on the same Node major line. Never rely on a globally-installed Node or pnpm — go through mise so local and CI use identical versions.

---

## 3. Frameworks and tools

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
| SSR escape hatch       | TanStack Start                          | Conditional only; requires ADR                                         |
| Client cache           | TanStack Query                          | Query cache, background refetch, controlled technical persistence      |
| Styling                | Tailwind CSS v4 via `@tailwindcss/vite` | Utility-first styling with Vite integration                            |
| Unit/integration tests | Vitest                                  | Pure functions, Effects, Layers, API handlers                          |
| Property tests         | fast-check                              | Domain invariants, schema narrowing, cache and state behaviour         |
| Browser tests          | Playwright                              | E2E, smoke, offline/degraded/error state checks                        |
| Lint                   | ESLint + typescript-eslint              | Typed lint gates, no unsafe TypeScript                                 |
| Format                 | Prettier                                | Consistent formatting through `pnpm format`                            |

### 3.1 TanStack Start policy

TanStack Start is **not** a default dependency in this profile. It requires an ADR with at least one explicit product need:

- SEO;
- social sharing previews;
- first render latency target that SPA cannot meet;
- edge rendering;
- server-side session/auth model;
- SSR-required integration.

Until such an ADR exists, use TanStack Router in SPA mode.

### 3.2 `@effect/platform` HttpApi risk acceptance

`@effect/platform` HttpApi is the selected API framework for this profile. Because parts of the Effect platform ecosystem may move faster than the core `effect` package, this choice is accepted with mitigations.

Mitigations:

- Pin exact resolved package versions in `pnpm-lock.yaml`.
- Use compatible `@effect/platform` and `@effect/platform-node` versions for Effect v3.
- Do not assume `@effect/platform` shares the same major version as `effect`.
- Upgrade `effect`, `@effect/platform`, and `@effect/platform-node` deliberately in a single dependency PR.
- Snapshot generated OpenAPI output in tests.
- Add contract tests for every public endpoint.
- Add at least one golden-path client test using the derived/generated client path.
- Any HttpApi API-surface change requires a `STACK` divergence entry or ADR.

---

## 4. Effect conventions

### 4.1 Functional core, imperative shell

Pure functions compute. I/O lives at the edge.

The core MUST NOT import directly:

- `fetch`;
- filesystem APIs;
- cache implementation modules;
- clock/time APIs;
- HTTP framework modules;
- browser APIs;
- process/env APIs.

Those capabilities are provided as Effect services and `Layer`s and declared in `R`.

### 4.2 Errors are values

- No `throw` in domain logic.
- Expected failures are represented in the Effect error channel as tagged errors.
- Defects remain defects; do not convert programmer errors into business errors.
- Every typed API error MUST have an HTTP mapping, retryability flag, safe public message, and log level.

### 4.3 Compiler is the first reviewer

Prefer designs where mistakes become compile errors instead of relying on discipline or runtime checks.

However, the compiler is not the only reviewer. It cannot prove product intent, accessibility, UX copy, operational safety, or whether an abstraction is necessary. For production-bound changes, semantic review is required unless the change is purely mechanical and covered by tests.

When no human review is available, the agent MUST add stronger executable evidence:

- contract tests;
- property tests;
- OpenAPI snapshots;
- browser smoke tests;
- screenshot or accessibility checks when UI behaviour changes.

### 4.4 External data boundary

External data is untrusted until decoded.

Rules:

- Decode and narrow with Effect Schema at the boundary.
- Do not pass raw upstream data into domain logic.
- Do not persist raw upstream data.
- Do not log raw upstream data.
- Product scope from `VISION.md` is enforced structurally at the Schema layer, not in React components.
- Anything outside product scope is dropped, rejected, or mapped to a typed error at the boundary.

### 4.5 Thin handlers

HttpApi handlers:

- receive decoded input;
- call a use case or service;
- return typed success or typed error;
- do not contain business rules;
- do not contain hand-rolled error-to-response glue;
- do not perform ad hoc validation after decode except for use-case invariants.

### 4.6 Time and timezones

Time is treated exactly like any other external input: **UTC everywhere internally, converted only at the boundary** — the same decode/narrow-at-the-edge discipline §4.4 applies to data, applied to instants.

- **Internal representation:** all instants in domain logic, cache entries, API payloads, and logs are **UTC** — `DateTime.Utc` (Effect's `DateTime` module) or a UTC ISO-8601 string with a `Z` offset. Values carrying an implicit local offset are forbidden.
- **Conversion happens only at the two edges:** decode inbound values to UTC at the Schema boundary (`Schema.Date` / a UTC-normalising schema); serialise outbound values as UTC ISO-8601 (`Z` suffix) in the API contract; convert to the target timezone only when rendering a user-facing value in the SPA (`Intl.DateTimeFormat` with an explicit `timeZone`). Nothing in between holds local time.
- **The clock is a capability, not ambient.** Read "now" through Effect's `Clock` (`DateTime.now`, `Clock.currentTimeMillis`) declared in `R`, never `Date.now()` / `new Date()` in domain code — see §4.1. This is what makes time deterministic under test.
- **Tests:** exercise TTL, retry, timeout, and refresh windows with `TestClock` (already required by §9.3) rather than wall-clock waits; no timezone-dependent assertions.
- **Never** hand-roll offset/`timedelta` arithmetic for timezone conversion; go through `DateTime` / `Intl`.

---

## 5. API contract and typed errors

### 5.1 `packages/api-contract`

`packages/api-contract` owns the public contract.

Allowed:

- Effect Schema definitions;
- DTOs;
- HttpApi route/group definitions;
- public error types;
- public enums and discriminated unions;
- generated OpenAPI output or snapshot fixtures.

Forbidden:

- React imports;
- server runtime imports;
- direct database/cache/upstream imports;
- browser storage imports;
- product rendering logic.

### 5.2 Error taxonomy

Use a small shared taxonomy. Add new error types only when the existing taxonomy cannot describe the failure.

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

Every API-facing error MUST provide this descriptor:

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

Rules:

- `safeMessage` MUST NOT contain PII, raw upstream payloads, secrets, identifiers, or stack traces.
- `InternalDefect` maps to a generic public message.
- Retryability MUST be explicit.
- Error mappings are centralized and tested.
- Public error shapes are part of the API contract.

### 5.3 OpenAPI and contract checks

- Generated OpenAPI is a build artifact or test snapshot.
- Public route changes require OpenAPI snapshot updates.
- Every public endpoint requires:
  - success test;
  - at least one typed error test;
  - decode/narrowing test;
  - generated contract snapshot coverage.

---

## 6. Frontend state and client cache

### 6.1 Typed view model

React components SHOULD render typed view models, not raw TanStack Query state.

Preferred model:

```ts
type RemoteView<A, E> =
  | { readonly _tag: "AwaitingFirstData" }
  | { readonly _tag: "Success"; readonly data: A }
  | { readonly _tag: "Empty" }
  | { readonly _tag: "Degraded"; readonly data: A; readonly reason: E }
  | { readonly _tag: "Offline"; readonly staleData?: A }
  | { readonly _tag: "Error"; readonly error: E };
```

Rules:

- Mapping from TanStack Query result to `RemoteView` is centralized and tested.
- Components MUST NOT scatter ad hoc `isLoading`, `isError`, `data?.length === 0` branching when a shared view model exists.
- UI must represent awaiting-first-data, success, empty, degraded, offline, and error states.

### 6.2 Data fetching

- Use TanStack Query for client data fetching.
- Do not use `useEffect` for normal server-state fetching.
- Query keys must be typed, stable, and derived from decoded route/search parameters.
- Query functions must call typed API clients, not raw `fetch` from components.

### 6.3 Client cache persistence

Client persistence is allowed only as **technical cache**, not product state.

Rules:

- Persistence is opt-in per query.
- Persisted query keys MUST NOT contain user identifiers.
- Persisted query values MUST contain only schema-narrowed, in-scope public data.
- Persisted data MUST have `maxAge` and `schemaVersion`.
- Raw upstream responses MUST NOT be persisted.
- Error objects MUST NOT be persisted unless explicitly safe and schema-defined.
- Cache busting is required when `schemaVersion` changes.
- Persistence rules must align with `VISION.md → Persistence and Privacy Posture`.

---

## 7. Documentation protocol: Context7

Hard rule: never write or modify code that uses an approved package from memory. Retrieve version-pinned docs via Context7 first.

1. **Resolve, do not guess.** If a Context7 ID fails, use the resolver and take the canonical ID it returns.
2. **Pin version in the query.** Especially Effect: target v3 docs. Model priors may drift toward older or beta APIs.
3. **Use targeted queries.** Retrieve the docs needed for the task, not entire libraries speculatively.
4. **Retrieve before integrating.** Integration seams are the riskiest code: Effect Layer wiring, HttpApi handlers, TanStack Query persistence, Router search param validation, Vite/Tailwind plugin wiring.
5. **Prefer official docs.** If Context7, official docs, and local code disagree, stop and document the mismatch.
6. **Document drift.** If a package API differs from the current stack expectation, update this file or create an ADR before continuing.

---

## 8. Build and verify commands

Bootstrap the environment with `mise install` (provisions the pinned Node/pnpm versions — see §2.4) before running any command below. The `package.json` scripts are the single source of truth. Do not invoke `tsc`, `eslint`, `vitest`, `playwright`, or `vite` directly from commits, CI, or agent scripts unless a script delegates to them.

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

Recommended script semantics:

```txt
pnpm verify
  = format check → typecheck → lint → build → unit tests

pnpm verify:ci
  = verify → property tests → contract tests → selected browser smoke/e2e tests
```

Any agent claiming completion MUST report which verification commands were run and whether they passed.

---

## 9. Testing policy

### 9.1 Required test types

| Test type         | Tool                           | Required for                                                                |
| ----------------- | ------------------------------ | --------------------------------------------------------------------------- |
| Unit              | Vitest                         | Pure functions, view-model mapping, simple use cases                        |
| Integration       | Vitest + Effect Layers         | HttpApi handlers, adapters, cache behaviour                                 |
| Property-based    | fast-check                     | Invariants, schema narrowing, transformations, status mapping               |
| Contract          | Vitest snapshots or equivalent | OpenAPI output, public DTOs, public error shapes                            |
| Browser smoke/e2e | Playwright                     | Route rendering, loading/error/offline/degraded states, critical user paths |

### 9.2 Property-based tests are required for

- schema narrowing rules;
- scope filtering;
- cache TTL and cache key behaviour;
- error/status mapping;
- transformations that claim to preserve invariants;
- parsing of route/search parameters;
- any logic where examples alone are likely to miss edge cases.

### 9.3 Deterministic time

- Cache TTL behaviour MUST be verified with Effect `TestClock`, not wall-clock waits.
- Tests MUST NOT rely on arbitrary sleeps.
- Retries, timeouts, and refresh windows MUST be testable deterministically.

---

## 10. Performance budgets

Starting points. Product-specific budgets may override these in `VISION.md` or an ADR.

### 10.1 API

- **Handler overhead p99:** < 100 ms, excluding upstream calls.
- **Handler overhead p50:** < 30 ms, excluding upstream calls.
- **End-to-end API p95:** product-specific, including upstream calls.
- Every upstream call MUST have:
  - timeout;
  - typed failure;
  - retry policy or explicit no-retry rationale;
  - bounded concurrency;
  - structured logging without raw payloads.

### 10.2 Runtime

- **Cold start, Node:** < 2 s.
- **No unbounded concurrency.** Use explicit concurrency limits for fan-out.
- **No background polling** unless allowed by `VISION.md` and ADR.

### 10.3 Web

- **Initial JS bundle:** < 200 KB gzipped unless ADR justifies more.
- **Time to Interactive on slow 4G:** < 3 s starting target.
- Loading, empty, degraded, offline, and error states must be testable and visible.

---

## 11. Persistence shape

### 11.1 Server

Default:

- in-memory Effect `Cache` only;
- TTL built in;
- no manual invalidation unless an ADR explains why;
- no database;
- no on-disk persistence;
- no per-visitor state.

If durable persistence becomes necessary, this profile is no longer sufficient. Create `STACK-EFFECT-PERSISTENT.md` or an ADR.

### 11.2 Client

Default:

- TanStack Query in-memory cache;
- optional technical persistence only if allowed by `VISION.md`;
- no product state;
- no user preferences;
- no account/session state;
- no user identifiers in cache keys.

### 11.3 Forbidden persistence

Anything declared forbidden in `VISION.md → Persistence and Privacy Posture`. The set of forbidden categories (accounts, per-user state, PII, device/session identifiers, telemetry, raw upstream payloads, …) is product/privacy policy owned by `VISION.md`, not restated here.

---

## 12. Approved dependencies

Default answer to "should we add a library?" is **no**.

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
| `@tanstack/start`                        | conditional, ADR-only                                      | `/tanstack/router`                      | SSR only when product requirements justify it               |
| `tailwindcss`                            | `4.x`                                                      | `/tailwindlabs/tailwindcss`             | Utility styling                                             |
| `@tailwindcss/vite`                      | `4.x` compatible                                           | `/tailwindlabs/tailwindcss`             | Tailwind v4 Vite plugin                                     |
| `vitest`                                 | stable, explicit semver                                    | `/vitest-dev/vitest`                    | Test runner                                                 |
| `fast-check`                             | stable, explicit semver                                    | `/dubzzz/fast-check`                    | Property-based tests                                        |
| `@playwright/test`                       | stable, explicit semver                                    | `/microsoft/playwright`                 | Browser e2e and smoke tests                                 |
| `eslint`                                 | stable, explicit semver                                    | `/eslint/eslint`                        | Lint runtime                                                |
| `typescript-eslint`                      | stable, explicit semver                                    | `/typescript-eslint/typescript-eslint`  | Typed lint gates                                            |
| `prettier`                               | stable, explicit semver                                    | `/prettier/prettier`                    | Formatter                                                   |
| `pnpm`                                   | stable, explicit semver                                    | `/pnpm/pnpm`                            | Package manager                                             |

New entries require a `STACK` PR or ADR with rationale, owner, approver, and date.

---

## 13. Stack-specific reject list

The following are forbidden unless an ADR explicitly permits them:

- explicit or implicit `any`;
- `as unknown as`;
- casts that bypass type checking instead of using Schema guards or `satisfies`;
- `throw` in domain logic;
- direct I/O imports in pure core modules;
- untyped external data reaching code before Effect Schema decode/narrowing;
- `// @ts-ignore` without a precise inline reason and tracking issue;
- `// @ts-expect-error` without a precise inline reason and tracking issue;
- `console.*` in shipped code;
- class-based React components;
- `useEffect` for server-state data fetching;
- reading wall-clock time directly (`Date.now()` / `new Date()`) in domain logic instead of the `Clock` capability; naive/local-time instants or manual UTC-offset arithmetic (see §4.6);
- raw `fetch` from React components;
- hand-rolled error-to-response glue in HttpApi handlers;
- Effect v4 beta APIs;
- package code written from memory without Context7 retrieval;
- background polling or long-lived connections without active user interaction;
- adding production dependencies without approval.

---

## 14. Logging, observability, and privacy mechanics

Privacy policy belongs in `VISION.md`. This section defines implementation mechanics.

Server logging:

- Use Effect logging (`Effect.log*`) or a structured logger wired through Effect services.
- Do not use `console.*` in shipped code.
- Logs must be structured.
- Logs must be redacted.
- Logs must not include raw upstream payloads.
- Logs must not include secrets, PII, user identifiers, device identifiers, or stack traces in public responses.

Telemetry:

- Telemetry and analytics policy is owned by `VISION.md → Telemetry and analytics`; this file does not restate it.
- Any telemetry, metrics, or crash/error reporter approved there is wired here as an approved dependency (`Section 12`), with redaction and retention configured in code.

---

## 15. Background and lifecycle

Allowed by default:

- request-driven cache refresh through Effect `Cache`;
- TTL-bounded cache entries;
- deterministic cache tests with `TestClock`.

Forbidden by default:

- background polling without active user interaction;
- long-lived connections without active user interaction;
- background work retaining data forbidden by `VISION.md`;
- background jobs that create durable state.

---

## 16. Definition of done additions

In addition to repository-wide `AGENTS.md` or `CLAUDE.md` rules, this stack requires:

- `pnpm typecheck` passes with zero errors;
- `pnpm lint` passes with zero errors;
- `pnpm build` passes;
- relevant Vitest unit/integration tests pass;
- relevant property tests exist and pass when invariants or schemas changed;
- public API changes update contract tests and OpenAPI snapshots;
- browser-facing behaviour changes include Playwright smoke/e2e coverage when appropriate;
- no I/O imports into pure core modules;
- no `throw` in domain logic;
- no unvalidated external data past the boundary;
- new package usage is grounded in version-pinned Context7 docs;
- verification commands run are listed in the final task report;
- known risks and intentional divergences are documented.

---

## 17. Intentional divergences

| Date     | Rule | Divergence | Reason | Owner |
| -------- | ---- | ---------- | ------ | ----- |
| _(none)_ | —    | —          | —      | —     |

---

## 18. Reference links

These are documentation anchors for humans and agents. Use Context7 for task-specific, version-pinned retrieval before writing package code.

- Node.js 24.11.0 LTS release: https://nodejs.org/en/blog/release/v24.11.0
- TypeScript 6.0 announcement: https://devblogs.microsoft.com/typescript/announcing-typescript-6-0/
- Effect Platform documentation: https://effect.website/docs/platform/introduction/
- Effect Schema documentation: https://effect.website/docs/schema/introduction/
- TanStack Router type safety: https://tanstack.com/router/latest/docs/guide/type-safety
- TanStack Query documentation: https://tanstack.com/query/latest
- Tailwind CSS with Vite: https://tailwindcss.com/docs/installation/using-vite
- Vitest documentation: https://vitest.dev/
- Playwright documentation: https://playwright.dev/docs/intro
- fast-check documentation: https://fast-check.dev/
