# STACK.md

> **Template — replace before running `/start-team`.** This file declares the technology stack: language, runtime, frameworks, build commands, performance budgets, persistence shape, and stack-specific reject-list additions. Agents consult this file for every technology choice.
>
> If you are starting from one of the bundled profiles (`profiles/swift-ios/`, `profiles/ts-node-react/`), copy that profile's `STACK.md` over this one and skip the placeholders.
>
> Replace every `<…>` placeholder. Delete italic guidance once the section is final.

---

## 1. Language & Runtime *(REQUIRED)*

- **Primary language:** `<e.g. Swift 6.1 / TypeScript 5.6 / Rust 1.84 / Go 1.23>`
- **Strictness mode:** `<e.g. SWIFT_STRICT_CONCURRENCY=complete / "strict": true + noUncheckedIndexedAccess + exactOptionalPropertyTypes / clippy::pedantic>`
- **Target runtime:** `<e.g. iOS 26+ / Node 22 LTS / Bun 1.x / Edge runtime / native binary>`
- **Minimum runtime version:** `<exact version, no back-deployment below this>`
- **Package manager:** `<SwiftPM / pnpm / cargo / go modules>`
- **Lockfile:** `<Package.resolved / pnpm-lock.yaml / Cargo.lock / go.sum>`

---

## 2. Frameworks *(REQUIRED)*

| Concern | Framework / library | Notes |
| ------- | ------------------- | ----- |
| UI / view layer | `<e.g. SwiftUI / React 19>` | `<one-line context>` |
| State / observation | `<e.g. Observation @Observable / Zustand / signals>` | |
| Routing / navigation | `<e.g. NavigationStack / TanStack Router>` | |
| Data fetching | `<e.g. URLSession / fetch + zod / TanStack Query>` | |
| Server framework *(if applicable)* | `<e.g. Hono / Fastify / Vapor>` | |
| Persistence | `<e.g. UserDefaults + Codable / SQLite via Drizzle / IndexedDB>` | |
| Testing | `<e.g. Swift Testing + XCUITest / Vitest + Playwright>` | |
| Logging | `<e.g. os.Logger / pino / structured tracing>` | |
| Telemetry | `<"none" or named>` | |

---

## 3. Build & verify commands *(REQUIRED)*

The agent workflow refers to these named commands. They are the **single source of truth** for verification — no agent invokes underlying tools (`swift-format`, `xcodebuild`, `eslint`, `tsc`, …) directly.

| Variable | Command |
| -------- | ------- |
| `$FORMAT_CMD` | `<e.g. make format / pnpm format>` |
| `$LINT_CMD` | `<e.g. make lint / pnpm lint>` |
| `$BUILD_CMD` | `<e.g. make build / pnpm build>` |
| `$TEST_CMD` | `<e.g. make test / pnpm test>` |
| `$VERIFY_CMD` | `<e.g. make test-all / pnpm run test-all — must run lint + build + test in one shot>` |

`$VERIFY_CMD` is the gate every agent runs before commits and PRs. CI runs the same command.

---

## 4. Performance budgets *(REQUIRED)*

Hot-path budgets. Anything that exceeds these in measurement is a `make`-style failure, not a polish item.

- **UI frame budget:** `<e.g. 16 ms baseline / 8.3 ms ProMotion — or "n/a (no UI)">`.
- **API request p99:** `<e.g. 100 ms / 250 ms — or "n/a (no API)">`.
- **Cold start:** `<e.g. < 1 s on iPhone 13 / < 2 s on Vercel cold edge>`.
- **Memory ceiling:** `<e.g. 200 MB resident / 512 MB container>`.
- **Battery / energy:** `<e.g. Live Activity-only background work / n/a>`.
- **Bundle size:** `<e.g. < 5 MB gzipped client bundle / n/a>`.

---

## 5. Persistence shape *(REQUIRED)*

State exactly what is persisted, where, and how schema changes are handled. `AGENTS.md §6.2` enforces this.

- **Storage primitive:** `<e.g. UserDefaults via a Codable wrapper / SQLite via Drizzle / IndexedDB>`.
- **Persisted entities:** `<exhaustive list>`.
- **Schema migration policy:** `<e.g. decode failures = "no value"; bump only on user-driven re-pick / numbered migrations under db/migrations/>`.
- **Forbidden persistence:** `<entities the product must never persist — mirror VISION.md → Persistence and Privacy Posture>`.

---

## 6. Approved dependencies *(REQUIRED)*

Default answer to "should we add a library?" is **no**. Anything beyond the platform's standard library and the entries in this list requires an entry here.

| Dependency | Version | Why it earns its place | Approver | Date |
| ---------- | ------- | ---------------------- | -------- | ---- |
| `<dep>`    | `<x.y.z>` | `<one-line rationale>` | `<name>` | `<YYYY-MM-DD>` |

---

## 7. Stack-specific reject-list additions *(REQUIRED)*

Anti-patterns specific to this stack that `AGENTS.md §13` does not cover by name. Agents reject changes that violate these on sight.

- `<e.g. SwiftData / @Model / @Query reintroduced where the chosen persistence is UserDefaults>`
- `<e.g. ObservableObject / @StateObject / @ObservedObject in new Swift code — Observation only>`
- `<e.g. any cast in TypeScript without inline justification>`
- `<e.g. moment.js / lodash full-import / raw fetch without zod validation>`
- `<…>`

---

## 8. Logging & privacy *(REQUIRED)*

- **Logger:** `<named logger from §2>`.
- **PII redaction:** `<how PII is kept out of logs — e.g. os.Logger .private interpolation / pino redact paths / structured logging with allowlist fields>`.
- **Crash / error reporter:** `<MetricKit / Sentry / "none">`.

---

## 9. Background & lifecycle *(OPTIONAL)*

If the product has a background mode, declare exactly what is allowed and forbidden. `AGENTS.md §6.3` enforces this.

- **Allowed background work:** `<e.g. Live Activity-bound location updates only / cron jobs only / n/a>`.
- **Forbidden background work:** `<e.g. allowsBackgroundLocationUpdates outside an active Live Activity / long-polling websockets / n/a>`.

---

## 10. Intentional Divergences *(OPTIONAL)*

Document any place where the project deliberately diverges from `AGENTS.md`. Each entry has a date, the diverging rule, the reason (with measurement when relevant), and the scope.

| Date | AGENTS.md rule | Divergence | Reason |
| ---- | -------------- | ---------- | ------ |
| `<YYYY-MM-DD>` | `<§ x.y>` | `<what is different>` | `<measurement-backed reason>` |
