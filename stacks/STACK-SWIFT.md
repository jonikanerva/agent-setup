# STACK.md — Swift 6 / SwiftUI / Xcode profile

Policy revision: 2

> Native Swift 6 + SwiftUI applications for iOS and macOS. Use Apple frameworks by default. Select the applicable targets when adopting this profile.

Use with `DOCTRINE.md` (P1–P9) and the selected host contract. This is an
example profile, not evidence that a project has implemented its checks. On
adoption, confirm its scope, pin versions, define each command, and complete
§14–15. Record exclusions and gaps. A profile does not grant merge or release
authority beyond the adopted project contract.

---

## 0. Project shape

- **Project risk rationale:** identify affected people, data, and dependent systems. Record failure consequences, material uncertainty, and reversibility.
- **Change risk:** assess the surfaces affected by each task against that project rationale. A risk label does not waive required checks or review.

- **Shape:** native iOS and/or macOS UI app. Declare the supported targets; remove inapplicable platform examples.
- **Critical execution path:** the main actor / UI thread (one display frame).
- **Applicable states:** every screen handles awaiting-first-data, success, empty, degraded, offline, error (plus product-specific).

---

## 1. Language & Runtime

- **Primary language:** Swift 6 language mode with the compiler bundled in the project-pinned Xcode release
- **Strictness mode:** `SWIFT_VERSION = 6.0`, `SWIFT_STRICT_CONCURRENCY = complete`. No new warnings; no `@preconcurrency` ratchet-loosening.
- **Target runtime:** selected iOS 26+ and/or macOS 26+ targets
- **Minimum runtime version:** declare the floor per selected target; defaults are iOS 26.0 and macOS 26.0. Do not lower an adopted floor without assessing compatibility and product impact.
- **Package manager:** Swift Package Manager (`Package.resolved`)
- **Lockfile:** `<AppName>.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (or workspace equivalent), when packages exist.
- **Environment:** pin the Xcode version/build and required SDKs, simulator runtimes, and formatter in the project setup instructions. Provide `make setup` to check prerequisites and resolve pinned packages. Document signing requirements without storing credentials.

---

## 2. Frameworks

| Concern             | Framework / library                                                           | Notes                                                                                          |
| ------------------- | ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| UI / view layer     | SwiftUI                                                                       | AppKit (macOS) or UIKit (iOS) adapters when needed                                                                |
| Design language     | Platform system components and materials                    | Do not reimplement chrome by hand                                                              |
| State / observation | Observation (`@Observable`, `@State`, `@Bindable`, `@Environment`)            | No `ObservableObject` / `@StateObject` / `@ObservedObject` / `@EnvironmentObject` for new code |
| Concurrency         | async / await, `AsyncSequence`, actors, structured concurrency                |                                                                                                |
| Navigation          | `NavigationStack`, `NavigationSplitView`, windows and sheets as supported               | No `NavigationView`                                                                            |
| Networking          | `URLSession` async / await                                                    |                                                                                                |
| Persistence         | Platform storage selected for the data                                      | UserDefaults for preferences; SwiftData/files when justified                                                  |
| Ephemeral cache     | `NSCache` wrapped in an actor                                                 |                                                                                                |
| Localization        | String Catalogs (`.xcstrings`) + `LocalizedStringResource`                    | No `.strings`                                                                                  |
| System integration  | WidgetKit, TipKit; ActivityKit where supported                                | If the product needs them                                                                      |
| Haptics             | Platform haptics; `UIImpactFeedbackGenerator` on iOS                                    | If the product needs them                                                                      |
| Logging             | `os.Logger` per subsystem / category; `OSSignposter` for hot paths            | No `print()` in shipped code                                                                   |
| Telemetry           | MetricKit where supported                                                     | Declare availability and collection/retention needs                                                                       |
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
| `$VERIFY_CMD` | `make test-all` (format-check → lint/build → required unit/UI tests → security checks) |

Implement these targets in the adopting project's `Makefile`; this profile does not supply one. Set schemes and destinations for all supported targets. `$VERIFY_CMD` runs all applicable §14 checks. Record required CI or hardware results for the same commit if they cannot run locally. Invoke the build tools through these targets.

---

## 4. Performance budgets

Set budgets for representative supported hardware on adoption. These are
starting examples, not universal limits:

- **UI frame:** 16.7 ms at 60 Hz; 8.3 ms at 120 Hz where supported.
- **iOS example:** cold start < 1 s on iPhone 13; journey memory < 200 MB; launch IPA < 50 MB.
- **macOS:** declare cold-start, resident-memory, and bundle-size limits for the minimum supported Mac.
- **Energy:** define allowed sustained work from product needs. Measure demanding or background paths on representative hardware; an active Live Activity is not a general background-execution grant.

---

## 5. Persistence shape

- **Storage primitive:** choose from the data contract. Use `UserDefaults` for small preferences, Keychain for credentials, and a justified platform store such as SwiftData or files for durable records. Do not force all products into one stored value.
- **Persisted entities:** declared by `VISION.md → Persistence and Privacy Posture`. Record purpose, retention, deletion, and ownership.
- **Schema migration:** version stored formats. Test upgrades and recovery. Decode errors must preserve recoverable user data and produce an actionable state. Reset only disposable caches or data covered by an approved reset policy.
- **Forbidden persistence:** anything declared forbidden in `VISION.md → Persistence and Privacy Posture`.

Record significant storage choices in a concise `docs/adr/` decision. Adding
a store is a technical choice within authority; external providers, material
product changes, and irreversible production-data changes still escalate.

---

## 6. Approved dependencies

Prefer Apple frameworks. A new package needs a PR rationale for its need,
provenance, maintenance, licence, transitive cost, and replacement cost. The
lead can approve routine packages within project authority. New providers,
external data transfers, costs, or material lock-in need owner approval.

| Dependency                       | Version | Why it earns its place | Approver | Date |
| -------------------------------- | ------- | ---------------------- | -------- | ---- |
| _(none — Apple frameworks only)_ | —       | —                      | —        | —    |

---

## 7. Stack-specific reject-list additions

- `ObservableObject`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@Published` in **new** code — Observation framework only.
- `@unchecked Sendable`, `nonisolated(unsafe)`, `@preconcurrency`, `MainActor.assumeIsolated` without an inline-justified, audited reason.
- `DispatchQueue.main.async` "to fix a warning" — fix isolation properly.
- `print()` in shipped code; `os.Logger` lines that interpolate PII values without `.private`.
- `AnyView`, broad type erasure, reflection tricks unless there is a measured benefit.
- Force-unwraps (`!`) and `try!` outside tests and `#Preview`.
- Using a `Date` instant for a date-only value or recurring calendar rule; implicit timezone conversion or manual UTC-offset arithmetic (see §10).
- New SwiftPM packages without the §6 assessment and an updated resolved dependency graph.

---

## 8. Logging & privacy

- **Logger:** `os.Logger` with per-subsystem / category loggers; `OSSignposter` for hot-path measurement.
- **PII redaction:** `os.Logger` `.private` interpolation for any value derived from identifiers or other PII. In release builds the substituted value must not leak PII.
- **Crash diagnostics:** use platform crash reports and MetricKit where supported. Document platform coverage gaps. A new external crash reporter requires owner approval for the provider and data transfer.
- Maintain `PrivacyInfo.xcprivacy` accurately. Every required-reason API call is declared.

---

## 9. Background & lifecycle

- **Ownership:** tie tasks, observers, and subscriptions to an explicit app, scene, document, or operation lifecycle. Cancel or close them when that owner ends.
- **iOS:** use supported background capabilities only for a declared product need. Respect expiration and cancellation. A Live Activity can display updates; it does not itself authorize continuous app execution.
- **macOS:** define behaviour when windows close, the app quits, or the system sleeps. Helpers, login items, and persistent background work need an explicit product purpose and minimum permissions.
- **Forbidden:** orphan tasks, silent long-running work without a product need, and work that retains data forbidden by `VISION.md`.

---

## 10. Time & timezones

- **Instant:** Foundation `Date` represents an absolute point in time. Use explicit UTC ISO-8601 or epoch encoding for instant wire/storage values.
- **Calendar value:** validated `DateComponents` or dedicated date-only/local-time value types preserve the intended fields. Use explicit `Calendar` and `TimeZone` when resolving them to an instant. A birthday or recurring local schedule is not a fixed `Date`.
- **Duration:** Swift `Duration` for elapsed time, or explicitly named units where platform APIs use `TimeInterval`. Use a monotonic `Clock` for timeouts and elapsed-time tests.
- **Conversion:** use Foundation calendar/zone APIs, including declared handling for repeated and missing local times. Set the target zone for display. Never hand-roll timezone offset arithmetic.
- **Tests:** inject current time and clocks. Cover DST, zone changes, and calendar boundaries where relevant without host-locale assumptions.

---

## 11. Design guidelines & UX thresholds

- **Design authority:** Apple Human Interface Guidelines for each supported platform. Use system components and platform interaction patterns.
- **Thresholds:** record product-specific limits with a current platform source or measured evidence. Test the limit and the next case. Do not invent universal picker-option or alert-button counts.
- **iOS input:** touch, VoiceOver, Dynamic Type, and Reduced Motion.
- **macOS input:** keyboard, pointer, focus, menus, window resizing, VoiceOver, and Reduced Motion.
- **Verification:** automate accessible names, navigation, state transitions, and supported accessibility audits in UI tests. Use a manual device check only for a material gap that automation cannot cover; required owner tests block merge.

---

## 12. Best practices source

Consult current, version-relevant [Apple developer documentation](https://developer.apple.com/documentation/) and [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) for uncertain APIs, platform rules,
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
| P3, P7: security and dependencies | Gitleaks, dependency vulnerability review/scan for `Package.resolved` when present, applicable static-security analysis, entitlement and privacy-manifest checks | Wire supported pinned tools into `make test-all`; record scanner coverage gaps and independent security review |
| P5–P7: app journeys | Swift Testing, required XCUI flows/accessibility audits, migration/recovery and cancellation tests for each supported platform | macOS runner and declared simulators; hardware only for behaviour that these cannot verify, with exact device/OS results |
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

- **Release:** declare per-target archive/signing and distribution jobs, channels, version identifiers, entitlements, and any store review dependency. Keep credentials outside the repository.
- **Observe:** verify the delivered build on the declared target, a critical launch/journey, and available crash diagnostics. Define the observation window; upload success does not prove store availability.
- **Recover:** declare available rollback or expedited forward-fix paths for each channel. Test store migrations and recovery from a backup; App Store distribution may not permit immediate rollback.
- **Data:** record each stored field's purpose, retention/removal, privacy declarations, and migration limits. Preserve recoverable records on decode failure.

The responsible lead verifies the integrated release within the adopted
project authority. Main remains production-ready. Added cost, a new provider
or external data transfer, material lock-in or product change, and irreversible
production-data changes require owner approval unless already authorized by
an applicable policy. Required owner tests block merge. Stop after the agreed
task and release checks; report follow-up needs without taking new backlog
work. Apply the same evidence requirements to maintenance updates.
