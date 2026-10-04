# STACK.md — Swift 6 / SwiftUI / Xcode profile

> Strict Swift 6 + SwiftUI iOS app, no third-party dependencies by default.

---

## 0. Project shape

- **Shape:** UI app (iOS / SwiftUI).
- **Critical execution path:** the main actor / UI thread (one display frame).
- **Applicable states:** every screen handles awaiting-first-data, success, empty, degraded, offline, error (plus product-specific).

---

## 1. Language & Runtime

- **Primary language:** Swift 6.1
- **Strictness mode:** `SWIFT_VERSION = 6.0`, `SWIFT_STRICT_CONCURRENCY = complete`. No new warnings; no `@preconcurrency` ratchet-loosening.
- **Target runtime:** iOS 26+
- **Minimum runtime version:** iOS 26.0 (no back-deployment, no `#available` for older OSes)
- **Package manager:** Swift Package Manager (`Package.resolved`)
- **Lockfile:** `<AppName>.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (or workspace equivalent)

---

## 2. Frameworks

| Concern             | Framework / library                                                           | Notes                                                                                          |
| ------------------- | ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| UI / view layer     | SwiftUI                                                                       | UIKit only as a wrapped adapter                                                                |
| Design language     | iOS 26 system components + Liquid Glass / system materials                    | Do not reimplement chrome by hand                                                              |
| State / observation | Observation (`@Observable`, `@State`, `@Bindable`, `@Environment`)            | No `ObservableObject` / `@StateObject` / `@ObservedObject` / `@EnvironmentObject` for new code |
| Concurrency         | async / await, `AsyncSequence`, actors, structured concurrency                |                                                                                                |
| Navigation          | `NavigationStack`, `NavigationPath`, `sheet`, `fullScreenCover`               | No `NavigationView`                                                                            |
| Networking          | `URLSession` async / await                                                    |                                                                                                |
| Persistence         | `UserDefaults` via a `Codable` wrapper                                        | Single value at most; no SwiftData by default                                                  |
| Ephemeral cache     | `NSCache` wrapped in an actor                                                 |                                                                                                |
| Localization        | String Catalogs (`.xcstrings`) + `LocalizedStringResource`                    | No `.strings`                                                                                  |
| System integration  | WidgetKit, ActivityKit (Live Activity), TipKit                                | If the product needs them                                                                      |
| Haptics             | Core Haptics + `UIImpactFeedbackGenerator`                                    | If the product needs them                                                                      |
| Logging             | `os.Logger` per subsystem / category; `OSSignposter` for hot paths            | No `print()` in shipped code                                                                   |
| Telemetry           | MetricKit                                                                     | No third-party analytics                                                                       |
| Testing             | Swift Testing (`@Test`, `@Suite`, `#expect`); XCTest / XCUI for end-to-end UI |                                                                                                |
| Formatting          | `swift-format` with repo `.swift-format`                                      | SwiftLint only for complexity metrics (§3)                                                     |
| Build               | Xcode 26+, Swift 6 language mode, complete strict concurrency                 |                                                                                                |

---

## 3. Build & verify commands

| Variable        | Command                                                        |
| --------------- | -------------------------------------------------------------- |
| `$FORMAT_CMD`   | `make format`                                                  |
| `$LINT_CMD`     | `make lint`                                                    |
| `$BUILD_CMD`    | `make build`                                                   |
| `$TEST_CMD`     | `make test`                                                    |
| `$VERIFY_CMD`   | `make test-all` (every gate below, in table order)             |
| `$MUTATION_CMD` | `make mutate FILES=<files>` (Muter, critical logic only)       |

**Narrowest test selector:** `make test ONLY=<Target>/<Suite>/<test>` (maps to `xcodebuild test -only-testing:`).

The `Makefile` in this profile is the single source of truth. Never invoke `swift-format`, `swiftlint`, `xcodebuild`, `gitleaks`, or `muter` directly from commits, CI, or agent scripts.

### Gates in `$VERIFY_CMD`

| Gate | Tool and threshold | Contract rule |
| ---- | ------------------ | ------------- |
| Format check | `swift-format lint --strict` with the repo `.swift-format` | Code conventions |
| Strict types and concurrency | the §1 build settings; warnings are errors (`SWIFT_TREAT_WARNINGS_AS_ERRORS = YES`) | Validate once, model the domain |
| Lint | `swift-format` rules (no SwiftLint style rules) | Code conventions |
| Complexity | SwiftLint with `only_rules` limited to metrics: `cyclomatic_complexity` 10, `function_body_length` 60, `type_body_length` 300, `file_length` 400 (errors, not warnings) | Simple and deletable |
| Dead code | compiler unused-value and unreachable-code warnings as errors | Code conventions |
| Dependency direction | one SwiftPM target per layer; the domain target declares no dependency on UI or infrastructure targets, so the compiler rejects a wrong import | Architecture |
| Secret scan | `gitleaks git --log-opts=origin/main..HEAD` and `gitleaks dir .` | Privacy and security |
| Vulnerability scan | none in the ecosystem for SwiftPM; Approved dependencies is empty by default | Dependencies |
| Commit messages | `commitlint` is not part of this toolchain; see Gaps | Git and verification |
| Tests | `xcodebuild test` (Swift Testing) | Testing |

SwiftLint runs here for complexity metrics only; `swift-format` stays the formatter and style linter. The thresholds are the common defaults that flag code most reviewers find hard to follow. Raise one only through an Exception ADR for the named file.

**Gaps (covered by review):**

- **Project-wide dead code** (unused types and functions across files): no maintained open-source tool. The reviewer checks that changed code removes what it makes unused.
- **Vulnerability scan:** no SwiftPM advisory scanner; every dependency needs an approved entry and an ADR, and the reviewer checks advisories for any dependency the PR adds or updates.
- **Commit messages:** the reviewer checks Conventional Commits in `git log main..HEAD`.

**Change size soft limit:** 400 changed lines, excluding `Package.resolved`, `.xcstrings`, and generated project files.

**Owner-run checks:** on-device performance checks against §4 budgets — triggered by changes to the critical path; run by the owner on a physical device.

---

## 4. Performance budgets

- **UI frame budget:** 16 ms baseline (iPhone 13+); 8.3 ms on ProMotion devices.
- **Cold start:** < 1 s on iPhone 13.
- **Memory ceiling:** < 200 MB resident in the journey / hot path.
- **Battery:** sustained high-power usage is acceptable only if the product explicitly demands it. Background work is allowed only while a Live Activity is live.
- **Bundle size:** < 50 MB IPA at launch.

---

## 5. Persistence shape

- **Storage primitive:** `UserDefaults` via a `Codable` wrapper.
- **Persisted entities:** declared by `VISION.md → Data and Permissions`. Default is "as little as possible" — typically a single struct.
- **Schema migration policy:** decode failures = "no value". A future schema bump forces a re-pick rather than crashing.
- **Forbidden persistence:** anything declared forbidden in `VISION.md → Data and Permissions`.

SwiftData is **not** the default. Reintroducing `@Model` / `ModelContainer` / `@Query` requires an ADR with measurement-backed justification.

---

## 6. Approved dependencies

| Dependency                       | Version | Why it earns its place | Approver | Date |
| -------------------------------- | ------- | ---------------------- | -------- | ---- |
| _(none at runtime — Apple frameworks only)_ | —       | —                      | —        | —    |
| SwiftLint (dev tool, via `mise.toml` or Homebrew pin) | `0.6x` | Complexity-metrics gate | (default) | (template) |
| gitleaks (dev tool, via `mise.toml`) | `8.x` | Secret-scan gate | (default) | (template) |
| Muter (dev tool) | latest release | `$MUTATION_CMD` | (default) | (template) |

---

## 7. Stack-specific reject-list additions

- `ObservableObject`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@Published` in **new** code — Observation framework only.
- SwiftData primitives (`@Model`, `ModelContainer`, `@Query`) — not used unless an ADR permits them.
- `@unchecked Sendable`, `nonisolated(unsafe)`, `@preconcurrency`, `MainActor.assumeIsolated` without an inline-justified, audited reason.
- `DispatchQueue.main.async` "to fix a warning" — fix isolation properly.
- `print()` in shipped code; `os.Logger` lines that interpolate PII values without `.private`.
- `AnyView`, broad type erasure, reflection tricks unless there is a measured benefit.
- Force-unwraps (`!`) and `try!` outside tests and `#Preview`.
- Storing an *instant* as calendar components or a formatted local string; storing a *local calendar time* as a precomputed `Date`; manual UTC-offset arithmetic; a `DateFormatter` / `Calendar` without an explicit `timeZone` in logic (see §10).
- New SwiftPM packages without a `Section 6 → Approved Dependencies` entry approved in advance.

---

## 8. Logging & privacy

- **Logger:** `os.Logger` with per-subsystem / category loggers; `OSSignposter` for hot-path measurement.
- **PII redaction:** `os.Logger` `.private` interpolation for any value derived from identifiers or other PII. In release builds the substituted value must not leak PII.
- **Crash reporter:** MetricKit. No Sentry / Crashlytics / equivalent third-party crash reporters.
- Maintain `PrivacyInfo.xcprivacy` accurately. Every required-reason API call is declared.

---

## 9. Background & lifecycle

- **Allowed background work:** Live Activity-bound updates only, while the Live Activity is active.
- **Forbidden background work:** background execution outside an active Live Activity; long-running silent push-driven jobs; background fetch for data the product does not actively need.

---

## 10. Base units & time

The operating contract's *Base units at the boundary* rule, pinned for this stack. `Codable` decoding at the network and persistence boundaries produces these forms; nothing between the boundaries holds another form.

| Concept | Internal base unit | Boundary conversion |
| ------- | ------------------ | ------------------- |
| Instant | `Date` (an absolute point, zone-free) | Decode with `.iso8601` / `ISO8601DateFormatter` (GMT) or `Date(timeIntervalSince1970:)`; encode with `.iso8601` |
| Local calendar time | `DateComponents` (only the fields that matter, e.g. hour and minute) **plus** a `TimeZone` identifier, stored together | Resolve to a `Date` with `Calendar` and the stored `TimeZone` only when an instant is needed (scheduling a notification, comparing) |
| Duration | `Duration` (or `TimeInterval` in seconds where an API requires it) | Convert at the API that requires another unit |
| Money | `Decimal` minor units or `Int` minor units + ISO-4217 code — never `Double` | `FormatStyle.Currency` at the view layer only |

- **Clock:** inject a clock (`any Clock<Duration>` for sleeping and timing; a `() -> Date` provider for "now"). Tests use a fixed date and a test clock.
- **Display:** `Text(date, format:)` / `.formatted(...)` at the view layer, with an explicit or `.autoupdatingCurrent` time zone and calendar — never implicitly in logic.
- **Banned:** see §7 — calendar-component math on instants, zone-dependent `DateFormatter` for wire or stored strings, hand-written `TimeInterval` offset arithmetic.
- **Tests:** no time-zone-dependent assertions; cover a daylight-saving transition for every local-calendar-time feature.

---

## 11. Design guidelines & UX thresholds

- **Design authority:** Apple Human Interface Guidelines (iOS). System components and system behaviours win; no custom chrome.
- **Documented thresholds to exercise at the threshold** (examples — extend per product):
  - Alert / confirmation-dialog button count — truncation past ~10 buttons; use a sheet + picker beyond that.
  - `Picker` style — `.menu` above ~7 options, `.inline` below.
  - Sheet detents / minimum sizes per HIG → Sheets.
- **Input paths:** touch first-class; VoiceOver, Dynamic Type, and Reduced Motion honoured on every surface.

---

## 12. Best practices source

`architect` and `product-guardian` fetch Apple's current documentation and HIG before every design and review pass, and cite the doc / HIG section in their reports. **Tool:** the `ctx7` CLI via Bash — `npx ctx7@latest library "<name>" "<question>"`, then `npx ctx7@latest docs <libraryId> "<question>"` (workflow in `~/.claude/rules/context7.md`) — with `developer.apple.com` via WebFetch as fallback. Training-data memory is not an acceptable source for API syntax or HIG specifics.
