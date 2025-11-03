# Phase 2 Code Quality Audit – November 2, 2025

**Last Updated:** November 2, 2025  
**Auditor:** Codex (GPT-5) – Senior iOS Consultant  
**Scope:** Phase 2 deliverables (unit tests, design-system tokens, performance optimizations)

---

## Executive Summary
- Phase 2 successfully increased coverage and removed the ad-hoc magic numbers, but several regressions and test-quality gaps remain.
- The `progressToGoal` API and its new tests disagree on expected behaviour, so Command‑U pauses on device as soon as the suite runs.
- Locale-sensitive tests rely on the host region rather than deterministic fixtures, limiting their value and violating the project’s “zero guesswork” testing philosophy.
- The reusable formatter introduced for performance gains holds onto the launch-time locale, so users who change region settings mid-session will see stale formatting until the app restarts.

---

## Strengths Observed
- `DSSpacing` now owns the progress-ring dimensions (`DSSpacing.swift:48-74`), keeping the Weight UI consistent with the design-token playbook.
- Additional `WeightManagerTests` cover persistence, milestone clamping, and duplicate detection, catching several prior regressions (`FastingTrackerTests/Managers/WeightManagerTests.swift:36-940`).
- The formatter reuse genuinely reduces allocations; Instruments shows fewer formatter creations during Control Center sessions.

---

## Findings & Recommendations

### 1. `progressToGoal` Contract Mismatch (High Severity)
- **Where:** `FastingTracker/Core/Managers/WeightManager.swift:819-836` vs. `FastingTrackerTests/Managers/WeightManagerTests.swift:997-1008`
- **Issue:** The production method returns `nil` when no progress has been logged (`progressMade > 0` guard), but the new test now unwraps it and expects `0.0`. This triggers a fatal crash (`unexpectedly found nil`) when Command‑U runs on-device, blocking the suite.
- **Recommendation:** Decide on the canonical contract (Apple Activity rings return `nil` when a metric is unavailable). Either (a) update `progressToGoal` to return `0.0` and adjust downstream `nil` checks, or (b) change the tests to expect `nil`/use optional assertions. Whichever route you choose, add regression tests for both weight-loss and weight-gain journeys before proceeding to Phase 3.

### 2. Asynchronous Tests Use Timers Instead of Deterministic Await (Medium Severity)
- **Where:** `FastingTrackerTests/Managers/WeightManagerTests.swift:45-117`
- **Issue:** The new tests rely on `DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)` to give the manager time to update its arrays. These sleeping expectations introduce flakiness and extend suite runtime, especially on slower CI devices.
- **Recommendation:** Since `WeightManager` is `@MainActor`, replace the timer pattern with `await MainActor.run` or inject a test scheduler into the manager. Alternatively, expose `addWeightEntry`/`deleteWeightEntry` synchronously for test builds to avoid arbitrary delays.

### 3. Locale Tests Depend on Host Region (Medium Severity)
- **Where:** `FastingTrackerTests/Configuration/AppSettingsTests.swift:26-80`
- **Issue:** Tests branch on `Locale.current.measurementSystem` and merely `print` a warning when the environment doesn’t match the expectation. On non-US hosts they silently skip assertions, so regressions can slip through unnoticed.
- **Recommendation:** Add a lightweight injectable locale (e.g., `AppSettingsProtocol`) or wrap the logic in a helper that accepts a `Locale`. In tests, supply deterministic locales (`Locale(identifier: "en_US")`, `"en_GB"`) and assert both code paths without resorting to `print`. Use `throw XCTSkip` if the environment truly blocks a path.

### 4. Static Formatter Freezes Locale at Launch (Low Severity)
- **Where:** `FastingTracker/Core/Managers/WeightManager.swift:24-36`
- **Issue:** `WeightManager.weightFormatter` captures `Locale.current` at static initialization. Users who switch measurement systems or regions while the app is running will still see the old decimal separators until the app restarts.
- **Recommendation:** Observe `NSLocale.currentLocaleDidChangeNotification` (Apple HIG) and refresh the formatter’s `locale`, or simply set `weightFormatter.locale = Locale.current` inside `formattedDisplayWeight` before formatting.

---

## Next Steps Before Entering Phase 3
1. Resolve the `progressToGoal` contract (code + test alignment) and re-run the full 313-test suite on-device.
2. Refactor asynchronous tests to remove timer-based waits and ensure the suite remains fast/stable.
3. Introduce locale injection/mocking so the new AppSettings tests provide deterministic coverage.
4. Update the formatter to respond to locale changes, then smoke-test metric/imperial switching on hardware.

Addressing the above keeps the Phase 2 foundation tight and prevents the same issues from compounding when Phase 3 refactors begin.

