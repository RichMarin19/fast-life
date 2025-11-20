# Fast LIFe — Weight Tracker Enterprise Upgrade Plan

Audience: mobile engineers, QA, and platform stakeholders  
Goal: transform the Weight Tracker into the enterprise-grade “North Star” for all trackers.

---

## Phase 0 — Immediate Stabilization (Week 0–1)
**Objective:** Remove App Store blockers and stop sensitive-data risk.

- **Secure storage & privacy**
  - ✅ Replace `UserDefaults` weight persistence with encrypted storage (CryptoKit + `NSFileProtectionComplete`) via `WeightPersistenceAdapter` + `SecureWeightStorage`.
  - ✅ Ship `PrivacyInfo.xcprivacy` enumerating the new encrypted data categories.
  - ⚠️ Add a GDPR/CCPA data-export/delete handler that reuses `DataExportManager` after encryption (**pending** — `AdvancedView.exportData()` is still a stub and no deletion pipeline exists).
- **Testing & CI bootstrap**
  - ✅ Stand up `FastingTrackerTests` (e.g., `WeightManagerTests.swift`) and wire GitHub Actions (`.github/workflows/ci.yml`) for lint → build → test.
  - ✅ Block merges on failing tests/lints (SwiftLint + LOC gate jobs now required before build/test).
- **Accessibility triage**
  - 🚧 Labels/hints were added for a few controls (e.g., Control Center restore button), but toolbar/chart coverage and Dynamic Type/VoiceOver verification are still outstanding. Expand accessibility work to match the enterprise checklist.

Deliverables: encrypted persistence adapter, privacy manifest, CI workflow, first test suite, accessibility verification evidence (export/delete + a11y items remain open).

---

## Phase 1 — Architecture & Layering (Weeks 2–4)
**Objective:** Establish clean seams so other trackers can reuse the pattern.

- **Module boundaries**
  - Introduce `WeightTrackerFeature` package split into Presentation (SwiftUI), ViewModels, Domain (use cases/entities), and Data (repositories, mappers).
  - Replace global singletons with dependency-injected protocols via `WeightDependencies`.
- **ViewModel & coordinator refactor**
  - Move chart math, goal/notification logic, and HealthKit orchestration into ViewModels/coordinators that are testable and free of UI types.
  - Define `TrackerScreenShell` scaffold once and reuse for weight/hydration/etc.
- **Feature flag & killswitch**
  - Wrap the redesigned tracker in remote config/flag with a killswitch path for phased rollout.

Deliverables: new module folders, protocol-based repositories, updated SwiftUI views consuming ViewModels, architecture diagram/ADR.

---

## Phase 2 — Data Lifecycle, Observability, Performance (Weeks 5–7)
**Objective:** Make the tracker resilient, observable, and budgeted.

- **Persistence & migrations**
  - Add schema versioning/migration tests for weight entries, goals, and anchors; wire `BGTaskScheduler` jobs for background sync.
- **Telemetry**
  - Replace `print` with `AppLogger`, instrument analytics events (add/edit/delete weight, sync errors, goal changes), and integrate Crashlytics/Sentry with correlation IDs.
- **Performance budgets**
  - Define cold-start/scroll/memory budgets; add Instruments baselines run in CI and fail PRs regressing hot paths.
- **Offline & retry**
  - Implement idempotent write strategy, conflict resolution, and retry/backoff for HealthKit sync flows.

Deliverables: migration test suite, BG tasks, analytics dashboards, perf gate scripts, incident/runbook docs.

---

## Phase 3 — Compliance, Standardization, and Developer Experience (Weeks 8–10)
**Objective:** Turn Weight Tracker into the reusable blueprint for Hydration/Sleep/Mood/Fasting.

- **Compliance & localization**
  - Document GDPR/CCPA/HIPAA handling, add localization hooks (strings, number formats), and publish consent + rights flows.
- **Standardization blueprint**
  - Author `TRACKER_BLUEPRINT.md` describing folder layout, protocols, analytics taxonomy, test expectations, and onboarding steps for new trackers.
- **Documentation & release engineering**
  - Update `ARCHITECTURE.md`, `SECURITY.md`, `OBSERVABILITY.md`, PR template, CODEOWNERS, and establish trunk-based release checkpoints with metric gates.

Deliverables: compliance checklist, localized strings, blueprint doc, refreshed runbooks, code-owner enforced PR process.

---

## Ongoing Investments
- Accessibility audits each release; automated a11y tests in CI.
- Quarterly dependency/SBOM reviews and penetration tests.
- Continuous refinement of shared tracker components (cards, nudges, analytics IDs) to keep all trackers in lockstep.

---

## Tracking & Ownership
- **Phase captains** (suggested):
  - Phase 0: Security + iOS Platform leads
  - Phase 1: Feature Architecture squad
  - Phase 2: Data Platform + Observability
  - Phase 3: Compliance + Developer Experience
- Use a program board (Jira/Linear) with exit criteria per phase; no phase considers “done” until associated documentation/tests ship.
