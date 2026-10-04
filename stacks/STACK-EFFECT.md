# STACK.md — TypeScript + Effect stateless SPA profile

Policy revision: 2

> Effect-backed TypeScript profile for a stateless web application: an `@effect/platform` HttpApi backend, generated OpenAPI, a React + Vite SPA, and a pnpm monorepo sharing Effect Schema across server and client through an explicit API contract package. Effect is used because correctness should be machine-checkable: typed errors, Schema boundaries, and Layer-provided dependencies maximise what the compiler and tests can prove.
>
> **Normative.** `MUST`, `MUST NOT`, `SHOULD`, and `MAY` are binding as written. `VISION.md` decides product intent; this file decides implementation mechanics. Surface conflicts before deviating.

Use with `DOCTRINE.md` (P1–P9) and the selected host contract. This is an
example profile, not evidence that a project has implemented its checks. On
adoption, confirm its scope, pin versions, define each command, and complete
§14–15. Record exclusions and gaps. A profile does not grant merge or release
authority beyond the adopted project contract.

---

## 0. Project shape

- **Project risk rationale:** identify affected people, data, and dependent systems. Record failure consequences, material uncertainty, and reversibility.
- **Change risk:** assess the surfaces affected by each task against that project rationale. A risk label does not waive required checks or review.

- **Shape:** backend service (`apps/server`, `@effect/platform` HttpApi) + browser SPA (`apps/web`, React + Vite), sharing one contract package.
- **Critical execution path:** server — request decode → scope narrowing → use case → typed response or typed error; web — route match → query/client cache → typed view model → React render.
- **Applicable states:** web surfaces handle awaiting-first-data, success, empty, degraded, offline, error (plus product-specific); API responses are typed success / typed error.
- **Intended for:** stateless, external-data-driven products where data is decoded, narrowed, and filtered at the schema boundary. **Not the default for:** SEO-first or SSR-required sites, or products needing durable business data, accounts, workflows, payments, or background jobs as core behaviour — those need an adapted profile and a significant decision recorded in `docs/adr/`; use §13 only for actual rule exceptions.

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
  DOCTRINE.md
  CLAUDE.md / AGENTS.md
  mise.toml
  pnpm-workspace.yaml
  pnpm-lock.yaml
```

### Package boundaries (enforced with `no-restricted-imports` lint rules)

- `packages/api-contract` is the **only** package shared by server and web: Effect Schema definitions, HttpApi route/group definitions, DTOs, typed public errors, public enums/discriminated unions, generated OpenAPI artifacts. It MUST NOT import server runtime, React, browser APIs, Node-only APIs, cache implementations, or UI code.
- `packages/domain` contains pure business rules and use cases. It MUST NOT import React, browser APIs, server runtime, `fetch`, ambient clock/time APIs, cache, filesystem, or HTTP modules directly — those capabilities use Effect services. Provide application services through `Layer`; account for runtime-provided default services.
- `apps/server` wires Effects, Layers, HttpApi handlers, platform runtime, upstream clients, cache, and logging.
- `apps/web` renders UI and maps typed API results into typed view models. It MUST NOT import server implementation code.

---

## 1. Language & Runtime

- **Primary language:** TypeScript 6.x profile baseline. A major upgrade needs current compatibility evidence, a CI trial, and an updated profile. Do not introduce preview toolchains without a reviewed §13 exception.
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
| SSR escape hatch       | TanStack Start                          | Conditional only; justify in an ADR (see §2.3)                      |
| Client cache           | TanStack Query                          | Query cache, background refetch, controlled technical persistence      |
| Styling                | Tailwind CSS v4 via `@tailwindcss/vite` | Utility-first styling with Vite integration                            |
| Unit/integration tests | Vitest                                  | Pure functions, Effects, Layers, API handlers                          |
| Property tests         | fast-check                              | Domain invariants, schema narrowing, cache and state behaviour         |
| Browser tests          | Playwright                              | E2E, smoke, offline/degraded/error state checks                        |
| Lint                   | ESLint + typescript-eslint              | Typed lint gates, no unsafe TypeScript                                 |
| Format                 | Prettier                                | Consistent formatting through `pnpm format`                            |

### 2.1 Effect conventions

**Functional core, imperative shell.** Pure functions compute; I/O lives at the edge. The core MUST NOT import `fetch`, filesystem APIs, cache implementations, ambient clock/time APIs, HTTP framework modules, browser APIs, or process/env APIs directly — use Effect services, with application services provided by `Layer` (§0 package boundaries).

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

**External data boundary.** External data is untrusted until decoded. Decode
and narrow with Effect Schema before passing data under internal contracts.
Do not persist or log raw upstream data. Enforce established product scope at
the boundary. Decoding, narrowing, defaults, and dropping fields must not
invent product rules or lose decision-relevant precision or uncertainty (P5).
Any deliberate change in meaning needs a requirement-based reason. Missing
information must not become an asserted fact.

Declare failure containment per boundary. Exclude a malformed independent
item with a safe recorded reason only when partial success meets the contract.
Reject the operation when an envelope, atomic input, or shared invariant is
invalid. Do not apply a universal skip rule. Test these decisions and
material transformations with P6 challenge cases beyond supplied examples.

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
- Client persistence is **technical cache only**, never product state: opt-in per query; persisted keys MUST NOT contain user identifiers; persisted values MUST be schema-narrowed, in-scope public data with `maxAge` and `schemaVersion` (bust the cache on version change); never persist raw upstream responses, and never persist error objects unless explicitly safe and schema-defined. Must align with `VISION.md → Persistence and Privacy Posture`.

### 2.3 TanStack Start (SSR) policy

TanStack Start is not a default dependency. Adopting it requires an ADR naming at least one explicit product need: SEO, social sharing previews, a first-render latency target the SPA cannot meet, edge rendering, a server-side session/auth model, or an SSR-required integration. Until then, TanStack Router runs in SPA mode.

### 2.4 `@effect/platform` HttpApi risk acceptance

Parts of the Effect platform ecosystem move faster than the core `effect` package; HttpApi is accepted with mitigations: exact versions pinned in `pnpm-lock.yaml`; `@effect/platform` / `@effect/platform-node` versions chosen for Effect v3 compatibility (do not assume they share `effect`'s major version); the three packages upgrade together in one dependency PR; OpenAPI output is snapshot-tested; every public endpoint has contract tests plus at least one golden-path test through the derived/generated client. Record significant API-surface decisions in `docs/adr/`; ordinary compatible updates belong in the PR.

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

| Variable | Command |
| --- | --- |
| `$FORMAT_CMD` | `pnpm format` |
| `$LINT_CMD` | `pnpm lint` |
| `$BUILD_CMD` | `pnpm build` |
| `$TEST_CMD` | `pnpm test` |
| `$VERIFY_CMD` | `pnpm verify:ci` |

Implement these script semantics in the adopting project:

```txt
pnpm verify    = format check → typecheck → lint → build → unit tests
pnpm test      = unit → required property and contract tests
pnpm verify:ci = verify → required property and contract tests → required browser tests → security checks
```

`verify` is a quick local subset. It cannot establish acceptance. The full
`$VERIFY_CMD` includes the §14 evidence. If a required job needs CI or another
environment, record its command and result for the same commit. Missing
results block acceptance. This profile does not supply those scripts.

---

## 4. Performance budgets

Starting points. On adoption, set product-specific budgets here from `VISION.md`; later exceptions use §13.

- **API handler overhead:** p99 < 100 ms, p50 < 30 ms (excluding upstream calls). End-to-end p95 including upstream calls is product-specific.
- **Every upstream call** MUST have: a timeout; a typed failure; a retry policy or an explicit no-retry rationale; bounded concurrency (no unbounded fan-out); structured logging without raw payloads.
- **Cold start (Node):** < 2 s.
- **Web:** initial JS bundle < 200 KB gzipped; Time to Interactive on slow 4G < 3 s. Loading, empty, degraded, offline, and error states must be testable and visible.

---

## 5. Persistence shape

- **Server default:** in-memory Effect `Cache` only — TTL-bounded, no manual invalidation without a documented reason, no database, no on-disk persistence, no per-visitor state. If durable persistence becomes necessary, this profile is no longer sufficient — create a persistent variant profile and record the decision in `docs/adr/`.
- **Client default:** TanStack Query in-memory cache; optional technical persistence only per §2.2 and only if `VISION.md` allows it; no product state, no user preferences, no account/session state, no user identifiers in cache keys.
- **Forbidden persistence:** anything declared forbidden in `VISION.md → Persistence and Privacy Posture` (accounts, per-user state, PII, device/session identifiers, telemetry, raw upstream payloads, …) — that list is product/privacy policy owned by `VISION.md`, not restated here.

---

## 6. Approved dependencies

Prefer supported platform capabilities. New entries need a PR rationale for necessity, provenance, maintenance, licence, transitive cost, and replacement cost. The lead can approve routine libraries within project authority. New providers, external data transfers, costs, or material lock-in need owner approval. The Context7 ID column is a lookup aid for sessions where the Context7 MCP server is available (see "Documentation lookups" below).

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

**Documentation lookups.** Model priors drift toward older or beta APIs — Effect APIs especially. Before writing integration-seam code (Layer wiring, HttpApi handlers, Query persistence, Router search-param validation, Vite/Tailwind plugin wiring) or doing a major upgrade, check the current official docs rather than writing from memory. When the Context7 MCP server is available, use it with targeted, version-pinned queries (the IDs above; target Effect v3). If the docs, this file, and local code disagree, stop and document the mismatch — if a package API differs from what this file expects, update this file before continuing.

---

## 7. Stack-specific reject-list additions

The following are forbidden unless a §13 entry explicitly permits them:

- explicit or implicit `any`; `as unknown as`; casts that bypass type checking instead of Schema guards or `satisfies`;
- `// @ts-ignore` / `// @ts-expect-error` without a precise inline reason naming the underlying TypeScript limitation, and a tracking issue;
- `throw` in domain logic;
- direct I/O imports in pure core modules (§0 package boundaries, §2.1);
- untyped external data reaching code before Effect Schema decode/narrowing;
- `console.*` in shipped code;
- class-based React components;
- `useEffect` for server-state data fetching;
- reading wall-clock time directly (`Date.now()` / `new Date()`) in domain logic instead of the `Clock` capability; naive/local-time instants or manual UTC-offset arithmetic (see §10);
- raw `fetch` from React components;
- hand-rolled error-to-response glue in HttpApi handlers;
- preview packages or incompatible major versions without the required compatibility evidence;
- integration-seam code written against remembered package APIs without a current-docs check (§6 → Documentation lookups);
- background polling or long-lived connections without active user interaction;
- new production dependencies without a §6 entry approved in advance.

---

## 8. Logging & privacy

- **Logger:** Effect logging (`Effect.log*`) or a structured logger wired through Effect services. No `console.*` in shipped code.
- **Log content:** structured and redacted — no raw upstream payloads, secrets, PII, user identifiers, or device identifiers; no stack traces in public responses.
- **Telemetry / analytics:** policy is owned by `VISION.md → Persistence and Privacy Posture`; anything approved there is wired as an approved dependency (§6) with redaction and retention configured in code.

---

## 9. Background & lifecycle

- **Allowed background work:** request-driven cache refresh through Effect `Cache`; TTL-bounded cache entries; deterministic cache tests with `TestClock`.
- **Forbidden background work:** background polling or long-lived connections without active user interaction; background work retaining data forbidden by `VISION.md`; background jobs that create durable state.

---

## 10. Time & timezones

- **Instant:** Effect `DateTime.Utc` for absolute times; decode at the Schema boundary and exchange UTC ISO-8601 (`Z`) or explicitly typed epoch values.
- **Calendar value:** validated date-only / local-time schemas retain their meaning. Use `DateTime.Zoned` when a concrete date-time needs a named zone. A recurring local schedule retains its calendar rule and IANA zone instead of a single UTC instant.
- **Duration:** Effect `Duration` for elapsed intervals such as TTL and timeout. Do not equate an elapsed duration with a calendar period.
- **Clock:** use Effect clock services and `TestClock` for repeatable tests. Effect v3 provides its built-in Clock through default services; application-specific dependencies remain explicit.
- **Conversion:** use Effect `DateTime` or a selected calendar library; use explicit `timeZone` in `Intl` for display. Define DST gap/overlap behaviour for schedules. Never hand-roll timezone offsets.
- **Tests:** cover TTL, retries, timeouts, and refresh with `TestClock`. Cover calendar/DST cases when applicable, without host-timezone assumptions.

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

Consult current, version-relevant [Effect v3 documentation](https://github.com/Effect-TS/effect/tree/v3), MDN, and the selected framework documentation for uncertain APIs, platform rules,
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
| P3, P7: security and dependencies | Gitleaks for changed files/history; locked-dependency vulnerability scan; supported static-security rules | Wire pinned tools into `pnpm verify:ci`; name scanner/rules and uncovered surfaces on adoption |
| P4–P6: schemas, API and SPA | Import-boundary lint, applicable §2.5 unit/property/contract tests, Playwright critical flows and supported accessibility checks | Full `pnpm verify:ci`, including browser dependencies; quick `verify` is insufficient |
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

- **Release:** declare server/SPA jobs, target environments, immutable version identifiers, and whether `main` deploys automatically. Validate startup configuration.
- **Observe:** verify server/client contract compatibility, deployed versions, health, and a critical SPA journey. Define the observation window and diagnostic source.
- **Recover:** retain a known working server/SPA pair. Test cache invalidation/version handling and rollback. Durable-data migrations are excluded by this stateless profile; reassess recovery if persistence is added.
- **Data:** declare TTL, cache removal, permissions, and retention for any approved client cache or telemetry. Confirm no forbidden data reaches logs or persistence.

The responsible lead verifies the integrated release within the adopted
project authority. Main remains production-ready. Added cost, a new provider
or external data transfer, material lock-in or product change, and irreversible
production-data changes require owner approval unless already authorized by
an applicable policy. Required owner tests block merge. Stop after the agreed
task and release checks; report follow-up needs without taking new backlog
work. Apply the same evidence requirements to maintenance updates.
