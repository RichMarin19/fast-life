# Weight Dependency Container Plan (2025-11-10)

## Goals
1. Remove manual `configure(...)` calls and residual `.shared` usage across Weight Tracking + Control Center flows.
2. Provide a single, testable source of truth for all weight-related dependencies that aligns with Apple’s SwiftUI environment guidance and enterprise DI standards.
3. Enable previews/tests to swap dependencies deterministically while keeping production code ergonomic.

## Requirements & Constraints
- Must follow Apple HIG + SwiftUI MVVM patterns; use environment keys (`@Environment(\.key)`) instead of global singletons.
- Support three contexts: production (live services), previews (mock data), and tests (XCTest-managed fakes).
- Preserve existing analytics/privacy guarantees (AppLogger, CrashReportManager, secure persistence).
- Container must inject only `Sendable`/`ObservableObject` types expected on the main actor, avoiding race conditions.

## Current Pain Points
1. **Manual configuration:** `WeightTrackingView`/`ViewModel` call `configure(...)` in `onAppear`, risking missed injections if lifecycle changes.
2. **Singleton leaks:** `MeasurementSystemObserver.shared`, `WeightNotificationManager.shared`, and convenience inits still create singletons internally.
3. **Coordinator drift:** Control Center coordinators each wire dependencies differently, complicating DI enforcement.
4. **Preview friction:** SwiftUI previews manually construct mocks per file, increasing chances of inconsistencies.

## Proposed Architecture

### 1. `WeightDependencies` Struct
- Define a `WeightDependencies` value wrapping all required services (managers, coordinators, formatters, observers).
- Example fields:
  - `weightManager: WeightManager`
  - `cardManager: CardManager<TrackerCardType>`
  - `behavioralScheduler: BehavioralNotificationScheduler`
  - `healthKit: HealthKitManagerProtocol`
  - `notificationPlanner: WeightNotificationPlanning`
  - `measurementSystem: MeasurementSystemProviding`
  - `analytics: WeightAnalyticsServicing`
  - `persistence: WeightPersistenceManaging`
- Provide factory methods: `.live(appContext:)`, `.preview()`, `.test(mocks:)`.

### 2. Environment Registration
- Create `private struct WeightDependenciesKey: EnvironmentKey` with default `.preview()` to keep previews compiling.
- Extend `EnvironmentValues` with `var weightDependencies: WeightDependencies`.
- Inject `WeightDependencies.live` at the App entry (e.g., `FastingTrackerApp` or scene delegate) via `.environment(\.weightDependencies, .live())`.

### 3. View/Coordinator Access
- Replace `@EnvironmentObject` + manual `configure` with `@Environment(\.weightDependencies)` inside views.
- For ViewModels/coordinators:
  - Provide `init(dependencies: WeightDependencies)` or narrower `WeightControlCenterDependencies`.
  - Views pass `env.weightDependencies` (or `env.weightDependencies.makeControlCenterBundle()`).
- Measurement observer becomes a dependency (`MeasurementSystemObserverProtocol`), allowing tests to mock.

### 4. Migration Order
1. **Infrastructure:** Add container files + environment key; update app entry to inject `.live`.
2. **WeightTrackingView stack:** move `configure` logic into new initializer using container; ensure `@StateObject` ViewModel receives dependencies once.
3. **Control Center coordinators/views:** provide factory helpers `WeightDependencies.controlCenter()` returning `WeightControlCenterCoordinatorFactory`.
4. **Progress Story components:** update to consume container-supplied managers instead of `.shared`.
5. **Cleanup:** deprecate convenience singletons, replace `MeasurementSystemObserver.shared` and `WeightNotificationManager.shared`.

### 5. Validation & Testing
- Update existing XCTest suites to instantiate `WeightDependencies.test(...)` with mocks; ensures compile-time coverage.
- Add snapshot/preview sanity using `.preview()` container to guarantee UI compiles without globals.
- Run regression: `Command-U` + key suites (WeightControlCenterViewModelTests, WeightManagerTests).
- Add guardrails: `#if DEBUG` assert when `WeightTrackingViewModel` sees nil dependency injection.

## Next Steps
1. Draft the actual `WeightDependencies` implementation + environment key.
2. Update WeightTrackingView + ViewModel to use the container.
3. Create Control Center-specific factory helpers, migrate coordinators.
4. Remove/mark deprecated singleton convenience APIs once container adoption hits 100%.
5. Document the change inside HANDOFF (W/H/E/A) plus QA/test instructions.
