# STACK.md — Python / Home Assistant custom integration (HACS) profile

Policy revision: 2

> A strict-typed Home Assistant **custom integration** distributed through HACS, written in async Python. The same correctness-first principles as the TypeScript/Effect and Swift profiles — model impossible states as impossible, validate at the boundary, keep the critical path unblocked, add no dependency without justification — expressed through Home Assistant's own idioms (asyncio event loop, `DataUpdateCoordinator`, config-entry lifecycle, `manifest.json` requirements) rather than against the grain of the ecosystem.
>
> **Normative.** `MUST`, `MUST NOT`, `SHOULD`, and `MAY` are binding as written. When this document conflicts with product scope, `VISION.md` decides product intent and this file decides implementation mechanics. When it conflicts with Home Assistant's own developer rules or the [Integration Quality Scale](https://developers.home-assistant.io/docs/core/integration-quality-scale/), **Home Assistant wins** — surface the conflict before deviating.

Use with `DOCTRINE.md` (P1–P9) and the selected host contract. This is an
example profile, not evidence that a project has implemented its checks. On
adoption, confirm its scope, pin versions, define each command, and complete
§14–15. Record exclusions and gaps. A profile does not grant merge or release
authority beyond the adopted project contract.

---

## 0. Project shape

- **Project risk rationale:** identify affected people, data, and dependent systems. Record failure consequences, material uncertainty, and reversibility.
- **Change risk:** assess the surfaces affected by each task against that project rationale. A risk label does not waive required checks or review.

- **Shape:** Home Assistant custom integration (a `custom_components/<domain>/` package), installed via HACS, not a standalone app.
- **Critical execution path:** the Home Assistant **asyncio event loop**. It is single-threaded and shared with the entire instance; blocking it degrades every integration and the UI. This is the direct analog of "the main actor / one display frame" (Swift) and "the per-request hot path" (TS) — the event loop is sacred and MUST NOT block.
- **Applicable states:** every entity handles awaiting-first-data, success, empty, degraded, offline, error (plus product-specific). In HA these map to coordinator status (`last_update_success`), entity `available`, and `unknown` / `unavailable` states — not to ad-hoc flags scattered across platforms.
- **Recommended repository layout:**

```txt
repo/
  custom_components/
    <domain>/
      __init__.py          # async_setup_entry / async_unload_entry, wiring only
      manifest.json        # domain, name, version, requirements (pinned), iot_class
      const.py             # DOMAIN, defaults, config keys — no logic
      config_flow.py       # boundary: user input validated with voluptuous / helpers
      coordinator.py       # DataUpdateCoordinator[T] — the polling + typed-data seam
      api.py               # thin async client wrapping the upstream (own PyPI lib preferred)
      models.py            # frozen dataclasses / TypedDict — the decoded domain shape
      entity.py            # shared CoordinatorEntity base
      sensor.py            # (and other platforms) — thin, render coordinator data
      diagnostics.py       # async_redact_data-backed diagnostics
      strings.json
      translations/en.json
      quality_scale.yaml   # tracked quality-scale rule status
  tests/                   # pytest + pytest-homeassistant-custom-component
  hacs.json                # HACS repository metadata
  mise.toml                # pinned tool/runtime versions (Python, uv, ruff, mypy)
  pyproject.toml           # ruff, mypy, pytest, uv dev tooling config
  .github/workflows/       # optional CI; existing required checks stay required
  STACK.md
  VISION.md
  DOCTRINE.md
  CLAUDE.md / AGENTS.md
```

- **Package boundaries (enforced structurally):**
  - `models.py` and any pure-logic module MUST NOT import `homeassistant.*` I/O, `aiohttp`, or perform I/O. Pure functions compute; the decoded domain shape is framework-free.
  - `api.py` is the only module that talks to the upstream service. Everything downstream consumes **decoded, narrowed** data, never raw payloads.
  - Platform files (`sensor.py`, …) render coordinator data into entities and contain no business rules and no I/O.

---

## 1. Language & Runtime

- **Primary language:** Python at the version required by the targeted Home Assistant release; pin it in `mise.toml` and any CI configuration. Use `from __future__ import annotations` in every module.
- **Runtime version is not freely chosen — it tracks the Home Assistant release you target.** Declare the supported HA release range in project metadata, then match the local test environment and any CI to its Python requirement. Do not invent a Python-version key in `manifest.json` or rely on a historical HA/Python pairing. When you bump the supported HA version, re-verify the Python floor first.
- **Strictness mode:** `mypy --strict` with zero errors. Additionally enable `disallow_any_explicit`, `warn_unreachable`, `warn_redundant_casts`, and `no_implicit_optional`. Type checking is **the first reviewer** — prefer designs where a mistake is a type error rather than a runtime surprise. Add the integration to a strict-typing gate; new warnings are not allowed.
- **Typing discipline:**
  - Model impossible states as impossible: frozen `@dataclass(frozen=True, slots=True)` for domain values, `enum.StrEnum` / `typing.Literal` for closed sets, tagged unions resolved with `match`.
  - `ConfigEntry` MUST be typed via a `type MyConfigEntry = ConfigEntry[MyData]` alias and `runtime_data` used for per-entry state — never module-level globals or `hass.data[DOMAIN]` dictionaries of untyped values for new code.
  - Prefer `TypedDict` for structured dict boundaries; prefer explicit narrowing over `cast`.
- **Dev-environment provisioning:** [`mise`](https://mise.jdx.dev/) is the single bootstrap. `mise install` provisions **every pinned tool and runtime version** from `mise.toml` — the exact compatible Python interpreter, `uv`, `ruff`, and `mypy` — so a fresh checkout reaches a reproducible environment with one command. `mise.toml` is the source of truth for tool/runtime versions.
- **Python dependency manager:** [`uv`](https://docs.astral.sh/uv/) (itself provisioned by mise) resolves and locks the dev/test dependencies. Wire it as a mise task (e.g. `mise run setup` → `uv sync`) so `mise install` followed by that task fully bootstraps. The **integration's own runtime dependencies** are declared in `manifest.json → requirements` (HA's contract), never in `pyproject.toml`; `pyproject.toml` + `uv.lock` govern the **development / test** environment only.
- **Pinning surfaces (three layers, each owns one):** `mise.toml` pins tool/runtime versions; `uv.lock` pins dev dependencies; `manifest.json → requirements` pins exact runtime versions with `==`.

---

## 2. Frameworks

| Concern                | Framework / library                                                              | Notes                                                                                     |
| ---------------------- | -------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Platform               | Home Assistant Core (integration APIs)                                           | Follow the Integration Quality Scale; do not fight core conventions                       |
| Concurrency            | `asyncio` — `async`/`await`, `async_add_executor_job` for unavoidable blocking   | Never block the event loop; no bare threads                                               |
| Polling / data seam    | `DataUpdateCoordinator[T]`                                                        | The single place that fetches + owns typed data; do not roll your own polling loop        |
| Entities               | `CoordinatorEntity` subclasses per platform                                      | Thin; render coordinator data; expose `available`                                         |
| Config / options       | Config flow (`ConfigFlow`, `SchemaConfigFlowHandler` where it fits)              | UI-based setup required; no YAML-only config for new integrations                         |
| Boundary validation    | `voluptuous` (HA's built-in) for config/service schemas                          | Validate every user input and service call payload before use                             |
| HTTP client            | `aiohttp` via `homeassistant.helpers.aiohttp_client.async_get_clientsession(hass)` | Use the **shared** session; never create your own; no blocking `requests`               |
| Upstream API wrapper   | A dedicated async PyPI library (yours or third-party), pinned in `requirements`   | HA prefers the protocol/device logic to live in a separate published package              |
| Persistence            | Config entry data/options; `homeassistant.helpers.storage.Store`; `RestoreEntity` | Minimal; see §5                                                                            |
| Logging                | stdlib `logging` — `_LOGGER = logging.getLogger(__name__)`                        | No `print()`; structured, level-appropriate                                               |
| Diagnostics            | `homeassistant.components.diagnostics` + `async_redact_data`                     | Redact secrets/PII from downloadable diagnostics                                          |
| Testing                | `pytest` + `pytest-homeassistant-custom-component` + `pytest-asyncio`             | Async tests, mock HA, snapshot with `syrupy`                                              |
| Time in tests          | `freezegun` / HA's `async_fire_time_changed`                                      | Deterministic — no wall-clock sleeps                                                       |
| Lint + format          | `ruff` (lint **and** format)                                                      | HA core's own choice; replaces black/isort/flake8/pylint                                  |
| Type checker           | `mypy --strict`                                                                   | The compiler-as-reviewer analog                                                           |
| Manifest / repo checks | `hassfest` + HACS validation | Declare supported local execution; existing required CI checks also pass |

---

## 3. Build & verify commands

Bootstrap the environment with `mise install` (provisions the pinned tools/runtime) before running any command below. `pyproject.toml` (via `uv`) is the single source of truth for tool configuration. Never invoke `ruff`, `mypy`, or `pytest` with ad-hoc flags from commits, CI, or agent scripts — go through the declared commands below so local and CI behaviour cannot drift.

| Variable      | Command                                                                       |
| ------------- | ----------------------------------------------------------------------------- |
| `$FORMAT_CMD` | `uv run ruff format .`                                                         |
| `$LINT_CMD`   | `uv run ruff check . && uv run mypy custom_components`                         |
| `$BUILD_CMD`  | `uv run python -m compileall -q custom_components` (syntax gate — there is no compile step) |
| `$TEST_CMD`   | `uv run pytest`                                                                |
| `$VERIFY_CMD` | `mise run verify` (format-check → lint/type checks → syntax gate → tests → security checks) |

> Python has no build artifact, so `$BUILD_CMD` maps to a **bytecode-compile syntax gate** over the integration package. Implement the local `verify` mise task with required tests and §14 checks. Define a supported local runner or container for applicable `hassfest` and HACS validation. If a required validator cannot run locally, record the gap and obtain an owner decision before acceptance; do not silently substitute hosted CI. Existing required CI jobs must also pass. This profile does not supply the task or validators.

---

## 4. Performance budgets

- **Event loop:** MUST NOT be blocked. Any call that does file/network/CPU-bound work synchronously runs via `hass.async_add_executor_job`. HA actively detects and warns on blocking calls inside the loop — treat such a warning as a build failure.
- **Setup latency:** `async_setup_entry` returns quickly; a slow or unreachable device raises `ConfigEntryNotReady` (HA retries with backoff) rather than blocking startup.
- **Polling interval:** `update_interval` MUST be justified against the upstream's cost and rate limits. Default no faster than the product genuinely needs; prefer push (webhooks/subscriptions) over aggressive polling where the device supports it.
- **Upstream calls** MUST have: a timeout, bounded concurrency (no unbounded fan-out), a typed failure, and a retry-or-explicit-no-retry decision. Coordinator failures surface as `UpdateFailed`, not silent empties.
- **Memory / entity count:** create only the entities the product needs; avoid per-poll object churn on the hot path.

---

## 5. Persistence shape

- **Storage primitives (in order of preference):**
  1. **Config entry** `data` (immutable connection details) and `options` (user-tunable) — the default home for configuration.
  2. **`Store`** (`homeassistant.helpers.storage.Store`, versioned JSON) for small integration-owned state that must survive restarts.
  3. **`RestoreEntity`** for restoring last known entity state across restarts.
- **Do not** write your own files, open databases, or persist to arbitrary paths. Do not stash mutable runtime state in module globals — use `entry.runtime_data`.
- **Persisted entities:** declared by `VISION.md → Persistence and Privacy Posture`. Default is "as little as possible."
- **Schema migration policy:** `Store` is versioned; provide an `async_migrate_func`. Config entries use `async_migrate_entry` with a bumped `entry.version`. A decode/migration failure surfaces an actionable error and preserves recoverable data. Do not silently reset durable user state; test upgrade and recovery before release.
- **Forbidden persistence:** anything declared forbidden in `VISION.md → Persistence and Privacy Posture`. Never persist raw upstream payloads, secrets in plaintext beyond the config-entry store, or PII the product does not need.

---

## 6. Approved dependencies

Prefer Home Assistant capabilities. Assess each added library's necessity, provenance, maintenance, licence, transitive cost, and replacement cost in the PR. Routine library choices are within lead authority; new providers, external data transfers, costs, or material lock-in need owner approval. For this profile, every runtime dependency MUST be listed in `manifest.json → requirements`, **version-pinned exactly** (`==`), published on PyPI, and ideally pure-Python (wheels for HA's platforms). `hassfest` validates the manifest; locally verify declared requirements and imported runtime dependencies.

**Runtime (`manifest.json → requirements`):**

| Dependency                | Pinning | Why it earns its place                                            | Approver  | Date       |
| ------------------------- | ------- | ---------------------------------------------------------------- | --------- | ---------- |
| `<upstream-client-lib>`   | `==x.y.z` | The async client for the target device/service (prefer your own published lib) | (project) | (fill in)  |

> `aiohttp`, `voluptuous`, and the HA helper APIs ship **with Home Assistant** — do not add them to `requirements`; depend on the versions HA provides.

**Development only (`pyproject.toml` dev group, `uv`):**

| Dependency                             | Version                 | Why it earns its place                          |
| -------------------------------------- | ----------------------- | ----------------------------------------------- |
| `homeassistant`                        | matches targeted core   | Type stubs + test harness against real core     |
| `pytest`                               | stable, explicit semver | Test runner                                     |
| `pytest-homeassistant-custom-component`| matches targeted core   | The standard custom-component test fixtures     |
| `pytest-asyncio`                       | stable, explicit semver | Async test support                              |
| `ruff`                                 | stable, explicit semver | Lint + format (HA core's choice)                |
| `mypy`                                 | stable, explicit semver | Strict type checking                            |
| `syrupy`                               | stable, explicit semver | Snapshot tests for diagnostics/entity states    |
| `freezegun`                            | stable, explicit semver | Deterministic time in tests                     |

New runtime entries require a `STACK.md` PR (or ADR) with rationale, owner, approver, and date — and a `hassfest`-clean manifest.

---

## 7. Stack-specific reject-list additions

- **Blocking the event loop:** synchronous `requests`, `open()`/file I/O, `time.sleep`, blocking device SDKs, or any CPU-bound loop called directly from a coroutine. Route blocking work through `hass.async_add_executor_job`.
- **Creating your own `aiohttp.ClientSession`** — use `async_get_clientsession(hass)`.
- **`typing.Any`** (explicit or implicit) without an inline `# reason: ...` justification; `cast()` that bypasses narrowing instead of a runtime guard or `TypedDict`.
- **`# type: ignore`** without a specific code and inline reason naming the underlying constraint.
- **Bare `except:` / `except Exception:` that swallows silently**, and `throw`-and-forget. Catch the upstream's specific exceptions and re-raise as the correct HA exception (`ConfigEntryNotReady`, `ConfigEntryAuthFailed`, `ConfigEntryError`, `UpdateFailed`, `HomeAssistantError`) — see §8 for the taxonomy.
- **`print()`** anywhere in shipped code — use `_LOGGER`.
- **Logging secrets/tokens/PII** at any level; logging raw upstream payloads.
- **Module-level mutable global state** for per-entry data — use `entry.runtime_data` (typed).
- **Rolling your own polling loop / `asyncio.create_task` for polling** — use `DataUpdateCoordinator`.
- **Untyped `hass.data[DOMAIN]` dictionaries** for new code where `runtime_data` fits.
- **YAML-only configuration** for a new integration — a UI config flow is required.
- **`ObservableObject`-equivalent anti-patterns:** ad-hoc `is_loading` / `has_error` flags scattered across entities instead of deriving availability/state from the coordinator.
- **Wildcard imports** (`from x import *`) and dependencies not listed + pinned in `manifest.json`.
- **Naive `datetime` values used as instants**; use `dt_util.utcnow()` or an explicit timezone. Local calendar values require distinct types and declared conversion rules (see §10).
- **Implicit conversion between local calendar values and instants, or manual UTC-offset arithmetic** — use `dt_util` and named timezone rules.

---

## 8. Logging & privacy

- **Logger:** one module-level `_LOGGER = logging.getLogger(__name__)` per module. Levels are meaningful: `debug` for developer detail, `info` sparingly (not per-poll), `warning`/`error` for actionable conditions. Never log inside a tight per-update path at `info`.
- **Typed error taxonomy → HA behaviour.** Every failure mode maps to exactly one HA outcome (this is the ecosystem's version of "errors are values with an explicit descriptor"):

  | Failure                          | Raise                        | HA behaviour                                  |
  | -------------------------------- | ---------------------------- | --------------------------------------------- |
  | Device/service offline at setup  | `ConfigEntryNotReady`        | Retry setup with backoff                      |
  | Bad/expired credentials          | `ConfigEntryAuthFailed`      | Start the reauth flow                         |
  | Unrecoverable config error       | `ConfigEntryError`           | Mark entry failed, surface to user            |
  | Coordinator fetch failed         | `UpdateFailed`               | Entities go `unavailable`, logged once        |
  | User-facing action failed        | `HomeAssistantError`         | Error shown in UI/service response            |

  Define the integration's own exceptions in one place and translate the upstream library's exceptions into this taxonomy at `api.py` — never let a raw upstream exception escape into HA.
- **PII redaction:** downloadable diagnostics MUST route through `async_redact_data` with an explicit `TO_REDACT` set (tokens, coordinates, emails, device identifiers). Default to redacting unknown-sensitive fields rather than exposing them.
- **Crash/telemetry reporting:** none. Home Assistant owns error reporting; do not add third-party analytics or crash reporters.

---

## 9. Background & lifecycle

- **Setup/teardown symmetry:** `async_setup_entry` wires the coordinator, client, and platforms; `async_unload_entry` MUST fully reverse it. Register every listener/unsub/cancel with `entry.async_on_unload(...)` so unload is leak-free. Return the platform-unload result honestly.
- **Allowed background work:** the coordinator's scheduled refresh; push subscriptions/websockets to the device **owned by the entry and cancelled on unload**; long-lived tasks created via `entry.async_create_background_task(hass, ...)` (tied to entry lifecycle), never orphaned `asyncio.create_task`.
- **Forbidden background work:** tasks that outlive the config entry, polling more aggressively than the product needs, background activity that retains data forbidden by `VISION.md`, and any loop that keeps the event loop busy without active need.
- **Reload:** support `async_reload_entry` / options-update reload so config changes apply without a HA restart.

---

## 10. Time & timezones

- **Instant:** timezone-aware UTC `datetime`; normalise validated inbound instants with `dt_util.as_utc()`. Use `dt_util.utcnow()` for current time. Timestamp sensors return aware UTC datetimes.
- **Calendar value:** use `date` for dates and separate `time` or validated component values for local schedules. Retain the configured IANA zone when a schedule resolves to an instant. A date-only entity must not be converted into an arbitrary midnight timestamp.
- **Duration:** `timedelta` for elapsed intervals. Use a monotonic clock for elapsed-time measurement. A local calendar day need not contain 24 elapsed hours.
- **Conversion:** use `homeassistant.util.dt` and supported timezone/calendar helpers. Validate timezone information before converting a parsed instant; define DST gaps and overlaps for schedules. Never hand-roll UTC offsets.
- **Tests:** use `freezegun` and HA time helpers to control clocks. Exercise timezone and DST changes where relevant; no wall-clock sleeps or host-timezone assumptions.

---

## 11. Design guidelines & UX thresholds

- **Design authority:** Home Assistant UX conventions. The integration owns no custom frontend — configuration renders through standard HA config-flow steps and selectors; entities follow HA naming and device-class conventions so HA's own UI thresholds apply.
- **Input paths:** whatever HA's frontend provides; nothing custom to verify beyond flow-step correctness.

---

## 12. Best practices source

Consult current, version-relevant [Home Assistant developer documentation](https://developers.home-assistant.io/), Python, and the targeted dependency documentation for uncertain APIs, platform rules,
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

On adoption, fill in local commands, environments, known gaps, and any
existing required CI jobs. P1–P9 refer to `DOCTRINE.md`. Run required tests
and the full `$VERIFY_CMD` locally for the exact mergeable version against
the current integration base. Failed or missing required local checks block
merge. Existing required CI must also pass; follow `DOCTRINE.md` P6 and
the local host contract for the full verification and CI policy.
Keep this matrix current. Assign each applicable check a phase:
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

For §14–15, a release, monitoring, migration, or recovery item may be
`not applicable` with a short reason tied to project purpose. A CLI or library
label does not waive these duties as a group. An unsupported tool is a gap,
not a reason to claim the requirement does not apply.

| Doctrine / applicability | Required evidence | Environment / gap to resolve |
| --- | --- | --- |
| P1, P6: every task | Acceptance criteria, material failure cases, assumptions, and their check mapping in the issue or PR | Lead prepares; independent review for material changes |
| P2–P5: changed code and dependencies | Strict types, format/lint, module-boundary checks, boundary validation, deterministic tests, dependency rationale | Required locally; existing required CI also passes; declare checks that rely on review |
| P5–P6: changed data boundaries | Meaning-preserving normalisation; declared independent-item or atomic failure containment; tests for transformations, mixed valid/invalid items, and atomic failures | Preserve decision-relevant distinctions, precision, and uncertainty; test containment per boundary, not a universal skip policy |
| P3, P7: security and dependencies | Gitleaks; vulnerability scans covering `uv.lock` and resolved runtime requirements; Ruff security rules plus applicable static-security analysis | Wire pinned tools into `mise run verify`; name scanners/rules and unsupported surfaces on adoption |
| P5–P7: HA integration | Setup/unload/reload, config and reauth flows, unavailable states, diagnostics redaction, migration/recovery tests; hassfest and HACS validation | Local pytest and applicable validators against declared HA versions; existing required CI also passes; record device-only evidence |
| P7: release and recovery | Before merge: release readiness and migration/recovery evidence. After release: deployed version and required health/smoke results (§15) | Target environment; a successful build does not prove release success |
| P8–P9: material changes | Current setup instructions, significant ADRs, independent review of the integrated result, explicit limitations | Separate reviewer context; no read-all-ADR prerequisite |

### Example check configuration

These tools and numeric limits are examples, not universal mandates. On
adoption, select and justify the applicable checks, scope, and acceptance
conditions. Record required checks in the §3 entry points; optional example
tools need the normal dependency assessment. Do not lower an adopted gate
merely to make a change pass. Existing §13 exception rules still apply.

| Check | Tool | Threshold / acceptance condition | Principle |
| --- | --- | --- | --- |
| Formatting | Ruff format check | No format differences | P3, P8 |
| Types | mypy with §1 strict settings | No type errors or new warnings | P3 |
| Lint | Ruff, including selected security rules | No violations of selected rules | P3, P7 |
| Complexity | [Ruff C901](https://docs.astral.sh/ruff/settings/#lint_mccabe_max-complexity) | Example: McCabe complexity ≤ 10 per function | P3, P4 |
| Dead code | Ruff F401/F841; [Vulture](https://github.com/jendrikseipp/vulture) if selected | No unexplained unused-code findings; retain verified HA callbacks | P3, P7 |
| Dependency directions | [Import Linter](https://import-linter.readthedocs.io/en/stable/contract_types/) if selected | No forbidden model/API/platform import edges | P4 |
| Secrets | Gitleaks over declared source/history scope | No confirmed exposed secrets | P3, P7 |
| Vulnerabilities | [pip-audit](https://github.com/pypa/pip-audit) on resolved dev and runtime environments | All findings triaged; none violate the project's declared security acceptance | P2, P7 |
| Tests | pytest with HA fixtures; local manifest/repository validators | Required lifecycle, config, redaction, data and failure cases pass for declared HA versions | P5, P6 |

Ruff's unused checks do not find every dead declaration. Dynamic HA discovery
can confuse dead-code and import analysis. Review registered entry points and
exercise setup/unload tests. Record unsupported local validator or device
checks as gaps; an unavailable required check still blocks merge.

Pin scanner versions and configuration with the project tools. Scanners must
redact findings. Do not send source or dependency data to a new
external provider without the required authorization. An unavailable scanner
is a recorded gap, not a successful check. Select proportionate property,
mutation, and coverage analysis when it tests a named risk; scores do not
replace behavioural evidence.

---

## 15. Release, recovery, and maintenance

Apply §14's purpose-based applicability assessment to each item below.
Record a short reason for each `not applicable` item; retain the relevant
distribution, compatibility, diagnosis, and data obligations.

- **Release:** declare the HACS/tag release process, supported HA range, release artifact, and required permissions. Record whether `main` triggers publication.
- **Observe:** test clean installation and upgrade, config-entry setup, a representative entity/action, and error diagnostics on the declared HA release.
- **Recover:** retain a compatible integration version and verify HA/config-entry backup restoration. Test migrations and downgrade limits; do not advise downgrading a schema without evidence.
- **Data:** document config-entry and Store retention/removal, credential handling, and diagnostic redaction. Owner device checks are exceptional; prefer a repeatable simulated service or fixture.

The responsible lead verifies the integrated release within the adopted
project authority. Main remains production-ready. Added cost, a new provider
or external data transfer, material lock-in or product change, and irreversible
production-data changes require owner approval unless already authorized by
an applicable policy. Required owner tests block merge. Stop after the agreed
task and release checks; report follow-up needs without taking new backlog
work. Apply the same evidence requirements to maintenance updates.
