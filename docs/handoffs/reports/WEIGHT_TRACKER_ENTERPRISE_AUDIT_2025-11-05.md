# Weight Tracker Enterprise Audit (2025-11-05)

## Snapshot Score
- **Overall:** **6.8 / 10**  
  Solid foundations (MainActor adoption, formatter reuse, unit tests) but still short of “enterprise-grade” due to oversized modules, singleton coupling, localization gaps, and limited instrumentation.

## The Good
1. **Thread-safe core logic** – `WeightManager` is `@MainActor`, and formatter hot paths are cached (`FastingTracker/Core/Managers/WeightManager.swift:1-120`), meeting Apple’s concurrency guidance.
2. **Robust test battery** – `WeightManagerTests` and `WeightChartViewModelTests` cover duplicates, conversions, progress, and zoom math (see `FastingTrackerTests/Managers/WeightManagerTests.swift`, `FastingTrackerTests/ViewModels/WeightChartViewModelTests.swift`).
3. **Design-system adoption** – Progress Story cards and chart annotations now lean on `Theme.ColorToken` and DS typography; opt-out flows route through the coordinator (HANDOFF.md §3.25).

## The Bad
1. **Monolithic files** – `WeightManager.swift` (936 LOC) owns analytics, persistence, HealthKit sync, and notifications; `WeightChartView.swift` remains 564 LOC with gesture logic embedded. Large files hurt readability, onboarding, and automated review.
2. **Singleton coupling** – `WeightTrendsViewModel` grabs `ContentOptOutManager.shared` and `ProgressStoryCards.shared` internally, blocking dependency injection and preview/unit isolation.
3. **Localization debt** – Strings like “7-Day Change” / “No data for selected time range” are hard-coded; no `.strings` files means the tracker feels unfinished outside en-US.
4. **Token drift** – Some chart elements still use literal colors (`Color("FLSuccess")`, `.green`, `.gray.opacity(0.5)`), bypassing the design system and risking contrast failures in dark mode.
5. **Lack of UI instrumentation/tests** – We rely solely on manual QA for chart gestures, drag handles, and Manage My Experience toggles—no snapshot/UI tests or telemetry to detect regressions early.

## The Ugly (Highest Risk)
1. **Progress Story state gaps** – Slice 3B isn’t fully closed; `ProgressStoryCardType` still lists cards we plan to retire, and Manage My Experience shows legacy entries. Until the UX decision is executed, card order migrations and opt-out defaults remain misleading.
2. **HealthKit/Notifications intertwined** – HealthKit delete logic and reminder cancellation live inside `WeightManager.deleteWeightEntry`, interspersed with crash-report hooks. A bug here can cascade into health sync or notification regressions with no containment.
3. **No telemetry on gesture-heavy features** – Chart zoom/pan and Progress Story drag/restore lack os_log signposts or analytics, so we cannot measure adoption or detect regressions without Rich manually testing every build.

## Path to 9+/10
1. **Modularize WeightManager**  
   - Extract `WeightPersistenceAdapter`, `WeightAnalyticsService`, and `HealthKitSyncCoordinator` (we already started with adapters—finish the split).  
   - Define protocols for each so tests can mock them and UI layers depend on narrow interfaces.

2. **Componentize WeightChart**  
   - Break `WeightChartView` into `WeightChartHeader`, `WeightChartSurface`, `WeightChartOverlay`, and `WeightChartDetail` components.  
   - Keep gestures + overlay logic in a coordinator struct so future interactions (zoom reset, multi-touch) are testable.

3. **Dependency Injection for Progress Story**  
   - Allow `WeightTrendsViewModel` to accept opt-out + card managers via init parameters; stop reaching for singletons directly.  
   - Once UX confirms the card shortlist, update `ProgressStoryCardType`, migrations, and `Manage My Experience` copy in one slice.

4. **Localization + Token Cleanup**  
   - Move chart/stat strings to `.strings` files using `LocalizedStringKey`.  
   - Replace leftover asset colors with `Theme.ColorToken` equivalents and document contrast ratios.

5. **Telemetry & UI Tests**  
   - Add `os_signpost` hooks around chart zoom/reset, Progress Story drag/drop, and Manage My Experience restores.  
   - Introduce snapshot/UI tests (e.g., using ViewInspector or screenshots) for the chart and card stacks to guard layouts during refactors.

Execute these steps slice-by-slice (per HANDOFF §6), re-running Command‑U on device plus manual gesture smoke after each slice. Once modularization, localization, and telemetry land, the Weight Tracker will comfortably score 9+/10 by enterprise standards.
