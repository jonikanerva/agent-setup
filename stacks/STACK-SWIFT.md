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
- **Battery:** sustained high-power usage is acceptable only if the product explicitly demands it. Background work is allowed only while a Live Activity is live.
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
- `@unchecked Sendable`, `nonisolated(unsafe)`, `@preconcurrency`, `MainActor.assumeIsolated` without an inline-justified, audited reason.
- `DispatchQueue.main.async` "to fix a warning" — fix isolation properly.
- `print()` in shipped code; `os.Logger` lines that interpolate PII values without `.private`.
- `AnyView`, broad type erasure, reflection tricks unless there is a measured benefit.
- Force-unwraps (`!`) and `try!` outside tests and `#Preview`.
- Persisting or computing with local-time / calendar-component values instead of a `Date` instant; manual UTC-offset arithmetic; a `DateFormatter` / `Calendar` without an explicit `timeZone` in logic (see §10).
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

## 10. Time & timezones

Time is treated exactly like any other external input: **UTC everywhere internally, converted only at the boundary.** This is the same "validate/narrow at the edge" discipline the rest of this profile applies to data, applied to instants.

- **Internal representation:** all timestamps in logic, `UserDefaults`/persistence, caches, and logs are `Date` **instants** — an absolute point on the timeline, timezone-free by construction. Never store or compute with calendar components (year/month/day/hour) or formatted local-time strings; those carry an implicit zone.
- **Conversion happens only at the two edges:** decoding an inbound value → parse to a `Date` immediately (`ISO8601DateFormatter`, which defaults to GMT, or `Date(timeIntervalSince1970:)`); building a user-facing value → convert to the display timezone at the last moment. Nothing in between holds local time.
- **Serialization:** `Codable` encodes `Date` deterministically (`.iso8601` strategy, which is UTC). For any hand-built wire/persisted string use `ISO8601DateFormatter` (GMT) — never a locale/zone-dependent `DateFormatter`.
- **Display boundary only:** `Calendar`, `TimeZone`, and `Date.FormatStyle` / `DateFormatter` are used **only** when producing a value for the UI, and always with an explicit `timeZone` (usually `.current` / `.autoupdatingCurrent`) and `Calendar` — never implicitly in logic. Prefer SwiftUI's `Text(date, format:)` / `.formatted(...)` at the view layer.
- **"Now":** `Date.now` / `Date()`. Never hand-roll `TimeInterval` offset math to fake a timezone.
- **Tests:** inject a clock or a fixed `Date` rather than reading `Date.now`; no timezone-dependent assertions (a test that passes only in one region is a bug).

> The language-neutral UTC-in-logic / convert-at-edges rule lives in `CLAUDE.md → Time`; this section pins the concrete Swift mechanics.

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

`architect` and `ux-guardian` fetch Apple's current documentation and HIG before every design and review pass, and cite the doc / HIG section in their reports. **Tool:** the `ctx7` CLI via Bash — `npx ctx7@latest library "<name>" "<question>"`, then `npx ctx7@latest docs <libraryId> "<question>"` (workflow in `~/.claude/rules/context7.md`) — with `developer.apple.com` via WebFetch as fallback. Training-data memory is not an acceptable source for API syntax or HIG specifics.

---

## 13. Intentional Divergences

| Date     | CLAUDE.md rule | Divergence | Reason |
| -------- | -------------- | ---------- | ------ |
| _(none)_ | —              | —          | —      |
