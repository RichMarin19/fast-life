# Weight Tracker North Star Recovery Plan (Post 11/1 Backup)

> **Purpose:** Rebuild the Weight Tracker to enterprise-grade / “North Star” quality after rolling back to the November 1 snapshot.  
> **Scope:** Only the weight tracker domain (Control Center, Progress Story, onboarding, telemetry). Other trackers will inherit these patterns once this plan is complete.

## Phase 1 – Re‑establish DI & Secure State (Enterprise Foundations)

**Goals**
- Remove all `.shared` fallbacks from live production paths (views, view models, coordinators).
- Route tracker preferences/flags through encrypted storage or an injectable `UserPreferencesStore`.

**Key Tasks**
1. **WeightDependencies reboot**
   - Reapply the `WeightDependencies.live/preview` factories that require explicit injections for tracker card managers, opt-out managers, measurement providers, and notification services.
   - Provide `.preview()` bundles for SwiftUI previews/tests to avoid global state.
2. **Control Center / ViewModel DI**
   - Restore the `WeightControlCenterViewModel.Dependencies` struct and update call sites/tests so nothing grabs `UserDefaults.standard` or `.shared` managers implicitly.
3. **Secure preference store**
   - Introduce a `WeightPreferencesStore` backed by `WeightPersistenceAdapter` (or a dedicated encrypted blob) to track goal-line toggles, onboarding flags, opt-outs.
   - Update `WeightTrackingViewModel`, onboarding, and settings flows to use this store instead of `UserDefaults.standard`.

**Exit Criteria**
- Search for `.shared` inside `FastingTracker/UI` and `Core/ViewModels` returns only intentional manager-level singletons.
- `rg -n "UserDefaults.standard" FastingTracker/Core` shows no weight-tracker logic (only legacy/testing helpers).
- Swift 6 builds without main-actor warnings tied to singleton defaults.

## Phase 2 – Measurement System & Progress Story Experience

**Goals**
- Make unit switches immediately reflect across Weight Tracker, Control Center, onboarding, and Progress Story.
- Deliver deterministic, accessible Progress Story surfaces suitable for QA reuse.

**Key Tasks**
1. **Measurement propagation**
   - Ensure onboarding weight pages, Control Center goal editors, and `WeightTrackingViewModel` observe `MeasurementSystemProvider` rather than caching `@State` values.
   - Add unit-switch tests (imperial ↔ metric) for these surfaces.
2. **Progress Story polish**
   - Reintroduce deterministic copy cycling for tips/reflection prompts (no `randomElement()`).
   - Add `accessibilityAction(.move, …)` + focus states to the card stack.
   - Confirm measurement-system changes trigger `objectWillChange` updates for the Trend Snapshot cards without manual refreshes.

**Exit Criteria**
- Switching the device/unit preference updates Control Center, Progress Story, and onboarding pages instantly (verified via manual QA + new unit tests).
- Progress Story cards produce repeatable text/screenshots and pass VoiceOver drag/reorder checks.

## Phase 3 – Observability & Evidence

**Goals**
- Recreate the Crashlytics “Weight Metrics – METRIC Logs” evidence package.
- Prove metrics routing can be tested without touching production Crashlytics.

**Key Tasks**
1. **Crashlytics evidence**
   - Using Rich’s networked machine, export `log:"METRIC"` entries from the Crashlytics Issues search (CSV + screenshot) and save to `docs/handoffs/reports/`.
   - Update `HANDOFF.md` §1.71 with file paths + the permanent `issuesQuery` URL.
   - Document the workflow in `docs/runbooks/OBSERVABILITY_RUNBOOK.md` (CLI limitations + UI steps).
2. **Telemetry abstraction**
   - Add a protocol-backed telemetry sink so `WeightTrackerMetrics` can be unit tested (fake sink in tests, Crashlytics sink in production).
   - Write tests ensuring metadata never includes unit values or PHI prior to hitting Crashlytics.

**Exit Criteria**
- Evidence files exist (`CRASHLYTICS_WEIGHT_METRICS_YYYY-MM-DD.csv/png`) and are referenced in HANDOFF + runbook.
- Unit tests cover telemetry redaction via the fake sink.

## Phase 4 – Automation, Tests & Documentation

**Goals**
- Reinstate automated coverage for DI wiring, Progress Story ordering, and measurement-system flows.
- Document the “North Star” template so future trackers reuse it verbatim.

**Key Tasks**
1. **Unit/snapshot tests**
   - Add tests for `WeightControlCenterViewModel`, `WeightTrackingViewModel`, and `WeightTrendsViewModel` covering:
     - Dependency injection (mocks only).
     - Measurement-system switching.
     - Progress Story card ordering/opt-outs.
2. **QA playbook updates**
   - Extend the existing QA checklist with measurement flip steps, deterministic screenshot instructions, and Crashlytics verification.
3. **North Star template doc**
   - Summarize how to bootstrap a tracker via `WeightDependencies` (diagram + steps) so hydration/sleep/fasting teams follow the same blueprint.

**Exit Criteria**
- Command‑U suites include the new DI/measurement/unit tests.
- QA playbook + documentation explicitly reference the new flow.
- Leadership sign-off that Weight Tracker meets enterprise/North Star standards (scores ≥ 9/10 on the next audit).
