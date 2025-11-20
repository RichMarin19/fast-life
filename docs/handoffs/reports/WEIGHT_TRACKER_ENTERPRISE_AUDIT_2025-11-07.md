# Weight Tracker Enterprise Audit – 2025-11-07
_Last Updated: 2025-11-07 @ 20:35 ET_

## Executive Summary
- **Overall readiness: 4.8 / 10.** Secure persistence + structured logging give us a strong foundation, but the latest metric regression (goal weight stays at 170 when locale flips) proves the measurement pipeline is not yet deterministic, and observability/privacy automation still rely on manual enforcement.
- **Strengths:** `WeightManager.swift` centralises storage with AES-GCM (`WeightPersistenceAdapter.swift:1-120`), the Crash telemetry stack ships a sanitizer, and Progress Story cards already draw on locale-aware formatters (`WeightProgressStoryMilestoneCards.swift:1-115`).
- **Gaps blocking TestFlight readiness:** Control Center + Preferences still hard-code imperial paths (`WeightControlCenterGoalsCard.swift:152-195`, `WeightSettingsView.swift:86-115`), DI remains partially singleton-driven (`WeightControlCenterCoordinator.swift:8-74`), and `AppLoggerPrivacyTests.swift:6-45` only greps for `.public` strings without validating actual payloads. Crashlytics imports outside `CrashReportManager.swift` are still possible because the sanitizer lives inside the same file without enforcement.
- **Recommendation:** Stay on Phase 2 (privacy/observability + localization) until unit/QA evidence proves locale flips, telemetry sanitisation, and DI boundaries are solid. Do **not** resume Slice 3B/3C feature work until the prioritized fixes below are complete and Command‑U + manual QA pass in both unit systems.

## Scorecard
| Pillar | Score (0‑5) | Highlights |
| --- | --- | --- |
| Architecture & DI | 3.0 | Managers are @MainActor and persistence is protocol-based, but several coordinators/views still build singletons (`BehavioralNotificationScheduler()` in `WeightControlCenterView.swift:18-33`, `.shared` in `WeightTrendsViewModel.swift:53-66`). No protocols exist for measurement/locale providers at the Control Center boundary, so previews/tests cannot inject custom units.
| Privacy & Logging | 3.0 | `AppLogger` defaults to `.private`, `WeightTrackerMetrics` funnels through it, and `CrashTelemetrySanitizer` redacts obvious PHI (`CrashReportManager.swift:392-458`). However, `WeightTrackerMetrics.logMetric` emits arbitrary metadata via `AppLogger.debug(... privacy: .public)` without verifying payload contents, and there is no gate that blocks direct `Crashlytics` usage outside the manager.
| Observability | 2.5 | Signposts exist, but there is no KPI dashboard or automated alert. Metrics aren’t persisted; `WeightTrackerMetrics` simply logs to the console. No structured export proving Trend Snapshot/goal latency falls within targets.
| Localization & HIG | 3.5 | Progress Story components use locale-aware formatters + accessibility labels, but Control Center and legacy Weight Settings still display literal “lbs,” and VoiceOver copy does not refresh when preferences change. Dynamic Type coverage for the goal editor is unverified.
| Testing & Automation | 2.8 | Command‑U infrastructure exists, `CrashTelemetrySanitizerTests.swift` provide unit coverage, and `TestLocaleProvider` stabilises `WeightManagerTests`. Still missing targeted tests for Control Center conversion paths, no UIAutomation snapshots, and privacy harness only checks for `.public` token usage.

## Detailed Findings

### 1. Measurement Pipeline & Control Center
- `WeightControlCenterGoalsCard.swift:152-195` converts the text field string to `Double` and subtracts against the latest weight, but it assumes the string is already in the current unit. When the locale flips, `WeightGoalCoordinator.synchronizeGoalWeightDisplay()` (lines 318-335) relies on `WeightManager.formattedDisplayWeight`, yet there is no observer on `AppSettings` to force a refresh, so stale pounds remain even when the label switches to “kg.”
- `WeightSettingsView.swift:86-115` still hard-codes `Text("lbs")`, so Preferences cannot reflect system measurement changes—this undermines the “single source of truth” promise from `AppSettings.weightUnit`.
- `WeightControlCenterView.swift:18-33` instantiates a new `BehavioralNotificationScheduler()` instead of the environment-provided scheduler, so preview/test contexts can’t inject locale-aware schedulers or mocks.

**Impact:** Users in metric regions see mismatched values, QA caught regressions (screenshots 7:59 PM + 8:26 PM), and there’s no automated test preventing recurrence. This violates Apple HIG localization guidance (“Respect the user’s units of measure”) and undermines enterprise trust.

**Remediation:**
1. Introduce a `MeasurementSystemProviding` protocol surfaced via Environment; drive `WeightGoalCoordinator`, `WeightControlCenterGoalsCard`, `WeightSettingsView`, and Progress Story cards off this provider.
2. Emit a Combine publisher from `AppSettings` when `Locale.current` changes so coordinators can refresh values without re-instantiation.
3. Add targeted unit tests (one imperial, one metric) that instantiate `WeightControlCenterViewModel` + `WeightGoalCoordinator` with a fake locale provider to assert that `weightGoalString`/“weight to go” update immediately.

### 2. WeightManager & Storage
- Positive: `WeightManager.swift` is `@MainActor`, stores all weights internally in pounds, uses AES-GCM persistence (`WeightPersistenceAdapter.swift:1-118`), and exposes helpers (`formattedDisplayWeight`, `convertToInternalUnit`). This aligns with Apple’s “single source of truth” sample code.
- Gaps:
  - No instrumentation confirms that locale switches don’t mutate stored pounds; the latest metric regression indicates `weightGoalString` is treated as canonical when saving back to `WeightManager` (`WeightControlCenterView.swift:92-117`).
  - Thread-safety tests remain skipped in CI even though `WeightManager` still calls into asynchronous HealthKit closures. We need actor-based wrappers or dedicated tests to satisfy concurrency hygiene goals.

### 3. Observability & Logging
- `WeightTrackerMetrics.swift:14-83` logs metadata using `.public` privacy without sanitising values first. Today’s payloads are safe (duration, booleans, `source`), but there is no compile-time preventer ensuring future additions exclude PHI. `logMetric` should assert that payload keys come from an allowlist or pass through the sanitizer before logging publicly.
- `CrashTelemetrySanitizer` lives at the bottom of `CrashReportManager.swift`, but nothing prevents other files from calling `Crashlytics.crashlytics()` directly; `AppLoggerPrivacyTests.swift` only greps for the string `privacy: .public` and ignores `.infoPublic()` helpers and Crashlytics imports.
- No dashboards/alerting: metrics are emitted via `os_signpost`, yet we never publish them to Firebase/Datadog nor document SLOs. Enterprise readiness requires at least p95 Trend Snapshot render time + error rates accessible to QA/ops.

### 4. WeightProgressStory Components
- `WeightProgressStoryMilestoneCards.swift` handles localization internally, but each component queries `Locale.current` directly instead of consuming `WeightManager`/`AppSettings`, so a future measurement override (e.g., testing tool) would not propagate.
- `WeightTrendsViewModel.swift:12-66` stores a concrete `WeightManager` and custom card managers instead of protocols. This blocks preview/test injection and violates the DI guidelines captured in HANDOFF §3.112.
- Accessibility: Trend cards expose localized labels, yet `WeightControlCenterGoalsCard` and “weight to go” pill do not update VoiceOver strings when units change; there is no `accessibilityValue` recalculation triggered by locale notifications.

### 5. Tests & Automation
- `AppLoggerPrivacyTests.swift:6-45` ensures `.public` tokens appear only in `AppLogger.swift`, but it does not instantiate logging calls to confirm sanitized payloads. Developers can still emit `AppLogger.infoPublic` with PHI by mistake.
- `CrashTelemetrySanitizerTests.swift:4-65` provide good coverage for nested dictionaries/arrays but do not cover Crashlytics `setCustomValue` flows or ensure `containsSensitiveTelemetry` flags are set for metrics payloads.
- There are zero tests for `WeightControlCenterGoalsCard` or `WeightGoalCoordinator` verifying locale flips. Combine this with the asynchronous nature of `WeightManagerTests` (reliance on `DispatchQueue.main.asyncAfter`) and we lack determinism.

## Next Critical Improvements (Before New Feature Work)
1. **Ship a Measurement/Locale Provider Layer** (single source of truth, environment-driven) and refactor Control Center + Preferences to consume it. Add automated tests covering imperial ↔ metric toggles.
2. **Enforce Telemetry Privacy:** replace the current grep test with a script/test that fails when `Crashlytics` is imported outside `CrashReportManager.swift` and when `.infoPublic/.debugPublic` is called with unsanitized strings. Run Crash telemetry sanitizer tests against the weight goal/Progress Story contexts.
3. **Add Observability KPIs:** capture Trend Snapshot + Control Center load durations, surface them through Crashlytics custom keys or a metrics exporter, and document per-HIG performance targets. Provide at least one dashboard screenshot or log for executive review.
4. **Finish DI Retrofit:** introduce protocols for `WeightManager`, card managers, notification coordinator, and measurement provider so `WeightTrendsViewModel`/Control Center view models never construct concrete singletons. Update previews/tests accordingly.
5. **Expand QA Automation:** add UI tests or snapshot-based checks verifying localized strings, units, and accessibility labels for the two failing regions highlighted in the QA screenshots. Integrate them into the Command‑U regimen before any commit.

## References
- `FastingTracker/Core/Managers/WeightManager.swift`
- `FastingTracker/Core/Managers/Weight/WeightTrackerMetrics.swift`
- `FastingTracker/Core/Managers/CrashReportManager.swift`
- `FastingTracker/Core/Utilities/AppLogger.swift`
- `FastingTracker/UI/Views/WeightControlCenterGoalsCard.swift`
- `FastingTracker/UI/Views/WeightSettingsView.swift`
- `FastingTracker/UI/Components/WeightProgressStory/*`
- `FastingTracker/Core/ViewModels/Weight/WeightTrendsViewModel.swift`
- `FastingTrackerTests/Infrastructure/AppLoggerPrivacyTests.swift`
- `FastingTrackerTests/Managers/CrashTelemetrySanitizerTests.swift`

