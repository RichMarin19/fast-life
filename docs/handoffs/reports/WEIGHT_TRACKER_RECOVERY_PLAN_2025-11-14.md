# Weight Tracker Recovery Roadmap – 2025-11-14

> **Context:** Repo rolled back to the Nov 10 commit (before the Nov 13 project-file corruption). This plan rebuilds the weight tracker to the previously agreed “North Star” benchmark—enterprise-grade DI, instant measurement propagation, and auditable observability—before we resume other trackers.

## Phase Overview

| Phase | Focus | Status | Output | Owners/Inputs |
| --- | --- | --- | --- | --- |
| Phase 0 | Guardrails & crash prevention | ✅ Complete (Nov 13) | `scripts/guardrails/*`, recovery notes, stash catalog | POST-CRASH docs, guardrail scripts |
| Phase 1 | DI restoration + secure preference state | 🚧 In progress | Control Center/Onboarding DI, preference store brief, updated guardrail baselines | WeightDependencies.swift, WeightControlCenterViewModel.swift |
| Phase 2 | Measurement system + Progress Story UX | ⏳ Not started (waiting on Phase 1) | Deterministic Progress Story, instant unit propagation, updated tests | Measurement providers, WeightTrendsViewModel.swift |
| Phase 3 | Observability & Crashlytics evidence | ⏳ Blocked on slicing | METRIC filter artifacts, runbook updates, telemetry sink tests | Firebase Console + CLI context, CrashReportManager.swift |
| Phase 4 | Automation, QA playbooks, North Star template | ⏳ Finalization stage | Test suites, QA checklist, tracker template doc | WeightControlCenterViewModelTests.swift, QA docs |

Each phase assumes Apple HIG + SwiftUI MVVM compliance, AppLogger privacy rules, and Firebase Crashlytics console-only evidence capture per `docs/runbooks/OBSERVABILITY_RUNBOOK.md`.

---

## Phase 0 – Guardrails & Crash Prevention (Complete)

- **Deliverables:**
  - `docs/handoffs/reports/LOST_WORK_SUMMARY_2025-11-13.md`, `POST-CRASH-RECOVERY_NOTES_2025-11-13.md`, and `PHASE0_GUARDRAILS_2025-11-13.md` anchor the forensic record.
  - `scripts/guardrails/check_singletons.sh` + baselines enforce “no new `.shared` / `UserDefaults.standard` in UI or view models.”
  - `scripts/guardrails/check_pbxproj_changes.sh` blocks accidental `project.pbxproj` edits unless `ALLOW_PBXPROJ=1` is set and documented.
- **Prevention Playbook:**
  - Only use Xcode UI for project-file changes; document reasons in HANDOFF before staging.
  - Treat Crashlytics console as the single source for METRIC log exports (REST endpoints respond 404 per `CRASHLYTICS_WEIGHT_METRIC_LOGS_2025-11-11.json`).
  - Archive nightly tags or zipped artifacts so we always have a rolling backup newer than Nov 10.

---

## Phase 1 – Dependency Injection & Secure State (Enterprise Foundations)

**Objectives**
1. Eliminate hidden singleton fallbacks from Weight Tracker surfaces (WeightTrackingView, Control Center, Progress Story, onboarding).
2. Move goal-line/opt-out toggles into an injectable preference store or `WeightPersistenceManaging` adapter so we can test on simulators without leaking to `UserDefaults.standard`.

**Workstreams**
- **1A – WeightDependencies reboot:** Reapply `.live / .preview / .test` factories and ensure every SwiftUI surface pulls dependencies from `Environment(\.weightDependencies)`.
- **1B – Control Center DI enforcement:** Require `WeightControlCenterViewModel` initializers to receive `UserDefaults`, measurement providers, and coordinators explicitly. Remove the `init(… measurementProvider: MeasurementSystemProviding? = nil)` convenience overload once callers migrate.
- **1C – Preference store abstraction:** Wrap goal-line toggles, card order, and onboarding flags in a single `WeightPreferencesStore` injected via `WeightDependencies`. Back it with `WeightPersistenceAdapter` so we can later swap in encrypted storage.
- **1D – Test scaffolding:** Restore `MockHealthKitManager`, `MockHealthKitNudgeManager`, and add a fake `WeightNotificationCoordinator` so concurrency tests no longer rely on singletons.

**Exit Criteria**
- `rg -n '\.shared' FastingTracker/UI FastingTracker/Core/ViewModels` matches guardrail baseline.
- `WeightTrackingViewModel` no longer owns a `UserDefaults.standard` instance (`FastingTracker/Core/ViewModels/WeightTrackingViewModel.swift:49`).
- Control Center, onboarding, WeightHistory, and Progress Story previews/tests compile with `.preview()` dependency bundles only.

---

## Phase 2 – Measurement System & Progress Story UX

**Objectives**
1. Reflect measurement-system flips instantly across onboarding, Control Center goals, Trend Snapshot metrics, and Tracker cards without requiring navigation resets.
2. Deliver deterministic, VoiceOver-friendly Progress Story experiences (no `randomElement()`, accessible reorder actions, deterministic screenshot flows).

**Key Tasks**
- **2A – Measurement propagation:**
  - Teach `WeightTrackingViewModel` and `WeightGoalCoordinator` to observe `MeasurementSystemObserver` rather than caching pounds-only values (user defect: start weight showed 82.5 kg until view reload).
  - Pass the observer into `WeightHistoryListView` (already wired in §1.103) and finish plumbing through stats/insights cards.
- **2B – Onboarding unit parity:** Onboarding weight/goal steps already respect `MeasurementSystemObserver`, but they still require manual navigation to refresh; attach `.onReceive(observer.$system)` to regenerate placeholders immediately.
- **2C – Progress Story polish:** Replace `WeightProgressStoryMetricsProvider.random*` (lines 46‑73) with deterministic cyclers keyed off stored sequence indices; persist reorder state via DI; add VoiceOver reorder descriptions per Apple HIG.
- **2D – Opt-out resilience:** Guarantee Trend Snapshot + banner restoration logic can replay after locale/unit switches and that opt-out resets remain idempotent.

**Exit Criteria**
- Manual QA: toggling Settings → Measurement System while Weight Tracker, Control Center, and Progress Story are on-screen updates values without dismissing modals.
- Automated coverage: new unit tests verifying `WeightGoalCoordinator` and `WeightTrendsViewModel` convert weights correctly for both `.us` and `.metric` settings.

---

## Phase 3 – Observability & Crashlytics Evidence

**Objectives**
1. Produce the “Weight Metrics – METRIC Logs” evidence bundle mandated in HANDOFF §1.71.
2. Abstract telemetry sinks so we can test Crashlytics logging behavior locally.

**Key Tasks**
- **3A – Evidence capture:** On Rich’s networked Mac, sign into Firebase Console → Crashlytics → Issues, search `log:"METRIC"`, save as filter “Weight Metrics – METRIC Logs,” export CSV + screenshot, store under `docs/handoffs/reports/CRASHLYTICS_WEIGHT_METRICS_2025-11-XX.*`, and link paths in HANDOFF + runbook.
- **3B – Runbook update:** Expand `docs/runbooks/OBSERVABILITY_RUNBOOK.md` to include the console-only export steps, CLI limitations, and the new guardrail script for Crashlytics evidence naming.
- **3C – Telemetry sink abstraction:** Introduce `WeightTelemetryClient` protocol with `CrashlyticsTelemetryClient` and `TestTelemetryClient` implementations; inject via `WeightDependencies` so unit tests can assert sanitization without hitting Firebase.

**Exit Criteria**
- Evidence files referenced in HANDOFF & runbook; QA can reproduce the export without direct coaching.
- Unit tests cover `CrashReportManager.recordMetricEvent` metadata redaction by swapping in the fake sink.

---

## Phase 4 – Automation, QA Assets & North Star Template

**Objectives**
1. Guarantee our DI/measurement/observability patterns are regression-tested and easily cloned for other trackers (Hydration, Sleep, etc.).
2. Provide QA + leadership with a reusable playbook documenting measurement flips, Crashlytics checks, and deterministic screenshots.

**Key Tasks**
- **4A – Unit/UI coverage:** Expand `WeightControlCenterViewModelTests`, `WeightTrackingViewModelTests`, and Progress Story tests to cover dependency injection, opt-out persistence, measurement conversions, and reorder operations. Target ≥ 70 % coverage in the weight module.
- **4B – QA playbook:** Update `docs/handoffs/reports/WEIGHT_TRACKER_ENTERPRISE_AUDIT_*.md` or create `QA_PLAYBOOK_WEIGHT_TRACKER.md` with checklists for measurement flips, Crashlytics test button flow, BMI/body-fat sync verification, and accessibility rotors.
- **4C – North Star template:** Document how to spin up a new tracker using `WeightDependencies` scaffolding (diagram + checklists). Include guardrail script usage and Telemetry sink wiring instructions.
- **4D – Automation hooks:** Wrap guardrail + targeted test runs in Fastlane or GitHub Actions so future sessions can trigger validations without waiting for manual instructions.

**Exit Criteria**
- Codified template reduces new tracker bring-up to configuration + copy tweaks.
- QA can execute the playbook without engineer assistance; Crashlytics verification is part of the release gate.

---

## Cross-Cutting Considerations

- **BMI & Body-Fat Sync:** `WeightManager.addWeightEntry` already forwards BMI/body-fat into HealthKit (lines 98‑121). Document this in the QA playbook and ensure HealthKit sync tests assert the values propagate; add UI affordances (later feature) only after Phase 2 completes.
- **Automation Backlog:** Evaluate lightweight Swift scripts or Tuist tasks to regenerate dependency bundles and measurement observers automatically; script ideas captured in `POST-CRASH-RECOVERY_NOTES_2025-11-13.md` §2.
- **Documentation Hygiene:** Any new slice must update HANDOFF (W/H/E/A), reference this roadmap, and archive detailed notes once size exceeds ~500 LOC.

---

## References
- `docs/handoffs/reports/LOST_WORK_SUMMARY_2025-11-13.md` – detailed inventory of missing work post-crash.
- `docs/handoffs/reports/POST-CRASH-RECOVERY_NOTES_2025-11-13.md` – automation ideas + crash prevention checklist.
- `docs/handoffs/reports/WEIGHT_TRACKER_ENTERPRISE_AUDIT_2025-11-07_CODEX.md` – scoring rubric we’ll use for the next audit.
- `docs/runbooks/OBSERVABILITY_RUNBOOK.md` – Crashlytics + telemetry procedures (to be updated in Phase 3).
- `scripts/guardrails/` – enforcement tools mentioned throughout this plan.
