# STACK.md — Swift 6 / SwiftUI / Xcode profile

> Strict Swift 6 + SwiftUI iOS app, no third-party dependencies by default.

---

## 0. Project shape

- **Shape:** UI app (iOS / SwiftUI).
- **Critical execution path:** the main actor / UI thread (one display frame).
- **Applicable states:** every screen handles awaiting-first-data, success, empty, degraded, permission-blocked, offline, error (plus product-specific).

---

## 1. Language & Runtime

- **Primary language:** Swift 6.1
- **Strictness mode:** `SWIFT_VERSION = 6.0`, `SWIFT_STRICT_CONCURRENCY = complete`. No new warnings; no `@preconcurrency` ratchet-loosening.
- **Target runtime:** iOS 26+
- **Minimum runtime version:** iOS 26.0 (no back-deployment, no `#available` for older OSes)
- **Package manager:** Swift Package Manager (`Package.resolved`)
- **Lockfile:** `Adventure.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (or workspace equivalent)

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
| Formatting          | `swift-format` with repo `.swift-format`                                      | No SwiftLint                                                                                   |
| Build               | Xcode 26+, Swift 6 language mode, complete strict concurrency                 |                                                                                                |

---

## 3. Build & verify commands

| Variable      | Command                                     |
| ------------- | ------------------------------------------- |
| `$FORMAT_CMD` | `make format`                               |
| `$LINT_CMD`   | `make lint`                                 |
| `$BUILD_CMD`  | `make build`                                |
| `$TEST_CMD`   | `make test`                                 |
| `$VERIFY_CMD` | `make test-all` (lint → build → unit tests) |

The `Makefile` in this profile is the single source of truth. Never invoke `swift-format` or `xcodebuild` directly from commits, CI, or agent scripts.

---

## 4. Performance budgets

- **UI frame budget:** 16 ms baseline (iPhone 13+); 8.3 ms on ProMotion devices.
- **Cold start:** < 1 s on iPhone 13.
- **Memory ceiling:** < 200 MB resident in the journey / hot path.
- **Battery:** continuous outdoor use is acceptable only if the product explicitly demands it. Background work is allowed only while a Live Activity is live.
- **Bundle size:** < 50 MB IPA at launch.

---

## 5. Persistence shape

- **Storage primitive:** `UserDefaults` via a `Codable` wrapper.
- **Persisted entities:** declared by `VISION.md → Persistence and Privacy Posture`. Default is "as little as possible" — typically a single struct.
- **Schema migration policy:** decode failures = "no value". A future schema bump forces a re-pick rather than crashing.
- **Forbidden persistence:** anything declared forbidden in `VISION.md → Persistence and Privacy Posture`.

SwiftData is **not** the default. Reintroducing `@Model` / `ModelContainer` / `@Query` requires an Intentional Divergences entry below with measurement-backed justification.

---

## 6. Approved dependencies

| Dependency                       | Version | Why it earns its place | Approver | Date |
| -------------------------------- | ------- | ---------------------- | -------- | ---- |
| _(none — Apple frameworks only)_ | —       | —                      | —        | —    |

---

## 7. Stack-specific reject-list additions

- `ObservableObject`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@Published` in **new** code — Observation framework only.
- SwiftData primitives (`@Model`, `ModelContainer`, `@Query`) — not used unless an Intentional Divergence exists.
- `MKDirections`, `MKRoute`, `MKDirectionsRequest`, or any turn-by-turn / routing API — these are routing-product surfaces, not orientation surfaces.
- `kCLLocationAccuracyBestForNavigation` — it is for turn-by-turn navigation; this profile never builds turn-by-turn products.
- `allowsBackgroundLocationUpdates = true` outside an active Live Activity session.
- `@unchecked Sendable`, `nonisolated(unsafe)`, `@preconcurrency`, `MainActor.assumeIsolated` without an inline-justified, audited reason.
- `DispatchQueue.main.async` "to fix a warning" — fix isolation properly.
- `print()` in shipped code; `os.Logger` lines that interpolate coordinate-derived or other PII values without `.private`.
- `AnyView`, broad type erasure, reflection tricks unless there is a measured benefit.
- Force-unwraps (`!`) and `try!` outside tests and `#Preview`.
- New SwiftPM packages without a `Section 6 → Approved Dependencies` entry approved in advance.

---

## 8. Logging & privacy

- **Logger:** `os.Logger` with per-subsystem / category loggers; `OSSignposter` for hot-path measurement.
- **PII redaction:** `os.Logger` `.private` interpolation for any value derived from coordinates, identifiers, or other PII. In release builds the substituted value must not leak PII.
- **Crash reporter:** MetricKit. No Sentry / Crashlytics / equivalent third-party crash reporters.
- Maintain `PrivacyInfo.xcprivacy` accurately. Every required-reason API call is declared.

---

## 9. Background & lifecycle

- **Allowed background work:** Live Activity-bound location / sensor updates only, while the Live Activity is active.
- **Forbidden background work:** `allowsBackgroundLocationUpdates = true` outside an active Live Activity; long-running silent push-driven jobs; background fetch for coordinate-derived data.

---

## 10. Intentional Divergences

| Date     | CLAUDE.md rule | Divergence | Reason |
| -------- | -------------- | ---------- | ------ |
| _(none)_ | —              | —          | —      |
