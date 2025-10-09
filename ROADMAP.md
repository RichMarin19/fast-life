# Fast LIFe — Updated Scope & Roadmap

> **Status:** Phase 1 Complete ✅ | **Next:** Phase 0 - Foundation 🎯

## Versioning Plan
- **v0.8** — Foundation hardening (crash/data safety, persistence fixes)
- **v0.9** — Design system + shared components + **Onboarding Revamp** + Reference Implementation (Weight)
- **v1.0 (Beta)** — Rollout to all trackers, standardized settings, unified sync, accessibility pass, smoke tests
- **v1.1** — Post-beta polish (biometric lock, JSON export, copy refinements from tester feedback)

## Phase Status Tracker

### ✅ Phase 0 — Foundation (Stability First) (COMPLETED)

### ✅ Phase 1 — Persistence & Edge Cases (COMPLETED)
**Files:** HydrationManager.swift, MoodManager.swift, SleepManager.swift, WeightManager.swift
- ✅ Fixed hydration unit preference persistence
- ✅ Added duplicate guards to mood/sleep entries
- ✅ Added validation to weight entries
- ✅ Unit preferences removed for v1.0 launch (clean build achieved)

**Definition of Done:** ✅ Units persist after relaunch; duplicates prevented; clean build for launch

---

### 🎯 Phase 0 — Foundation (Stability First) (CURRENT)
**Files:** HealthKitManager.swift, DataStore.swift, CrashReportManager.swift, NotificationManager.swift

**Scope:**
- [ ] Add HKError handling to all HK reads/writes (map errors to user-friendly messages)
- [ ] Persist crash logs to Application Support with NSFileProtectionComplete
- [ ] Set UNUserNotificationCenter.current().delegate during app launch
- [ ] Ensure Core Data writes happen off the main thread; merge on completion

**Definition of Done:** No crashes on permission revoke; notifications operating from cold/warm start; no main-thread stalls during heavy writes

---

### 🎯 Phase 2 — Design System & Shared Components (CURRENT)
**Files:** Add Theme.swift; add colors to Asset Catalog (Light/Dark)

**Components to Create:**
- ToolbarSettingsButton
- FLPrimary/Secondary buttons
- FLCard
- StateBadge
- SyncStatusView
- TrackerScreenShell
- Chart wrapper

**Scope:** Replace raw Color(...) usage with tokens; unify cards/buttons/typography/spacing; establish one chart style

**Definition of Done:** No raw hex or system color literals in views; components compile; Dark/Light variants pass contrast

---

### 🔮 Phase 3 — Reference Implementation (Weight) + Onboarding Revamp
**Files:** WeightTrackingView.swift (+ WeightSettingsView.swift), AddWeightView.swift; OnboardingView.swift

**Weight Scope:**
- Adopt TrackerScreenShell
- Header with Today + trend badge + SyncStatusView
- Chart via wrapper
- Actions row
- Tracker-scoped settings (Units, Notifications, Sync, Clear Data)

**Onboarding Revamp:**
- **Goals:** Boost conversion, clarity, and trust; reduce first-session drop-off
- **Flow (7–9 lightweight steps):**
  1. Welcome + value prop
  2. Personal goals (fasting, weight, hydration)
  3. HealthKit connect (layered permissions with previews)
  4. Unit preferences
  5. Notification preferences (concise, opt-in)
  6. Sample preview of Insights
  7. Privacy summary
  8. Review + confirm
  9. Success (start first action)

**Definition of Done:** Weight refactor becomes the reference; Onboarding uses Theme tokens/components; passes contrast; funnels and opt-ins recorded; HealthKit permission UX verified

---

### 🔮 Phase 4 — Rollout to Remaining Trackers
**Files:** Fasting/Hydration/Sleep/Mood tracking + their settings views

**Scope:** Apply shell/components; implement tracker-scoped settings (Sync, Clear Data, Notifications) with link to Global hub; unify error/empty/loading states; retain unit persistence and dedupe logic

**Definition of Done:** Each tracker file ≤ 300 LOC; settings accessible from gear; sync affordances identical with retry + timestamp

---

### 🔮 Phase 5 — Insights & Global Settings Alignment
**Scope:** Standardize charts and cards in Insights; ensure Settings hub mirrors section structure; implement SettingsRouter.open(for:) and openGlobal()

**Definition of Done:** Charts consistent; deep links work from each tracker settings to Global hub

---

### 🔮 Phase 6 — QA & Beta Readiness
**Scope:** Add breadcrumbs (HK status, sync attempts, unit changes); smoke tests; beta pack (what-to-test, feedback link, KPIs)

**Definition of Done:** Crash-free sessions hit target; golden paths all pass; testers can easily submit feedback; dashboards show KPIs

## LOC Reduction Strategy (Target ≤ 250–300 LOC per view)

**Current State:**
- WeightTrackingView.swift = 2,589 LOC 🔴
- ContentView.swift = 1,658 LOC 🔴
- OnboardingView.swift = 984 LOC 🔴

**Strategy:**
- Split giant views into: HeaderView, ChartSection, ActionRow, ListSection, and SettingsSheet components
- Move view-only formatting and constants into Theme tokens
- Centralize duplication: charts, sync, settings sections
- Enforce function size ≤ 50 LOC; prefer small helpers

**Success Metric:** Weight/Content/History/Onboarding files trimmed >50%; all tracker views ≤ 300 LOC

## Developer Order-of-Operations

1. ✅ **Phase 1:** Persistence & Edge Cases (COMPLETED)
2. 🎯 **Phase 0:** Foundation & Stability (CURRENT)
3. 🔮 **Phase 2:** Design System & Components
4. 🔮 **Phase 3a:** Weight Reference Implementation
5. 🔮 **Phase 3b:** Onboarding Revamp
6. 🔮 **Phase 4:** Rollout to All Trackers
7. 🔮 **Phase 5:** Insights & Settings Alignment
8. 🔮 **Phase 6:** QA & Beta Readiness