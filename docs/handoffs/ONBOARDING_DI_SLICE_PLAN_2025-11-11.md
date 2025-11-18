# Onboarding & Legacy Weight DI Slice Plan (2025-11-11)

## Objective
Eliminate the remaining `.shared` usage across the onboarding + legacy weight setup surfaces so every production weight flow consumes managers through `WeightDependencies`. This preserves SwiftUI MVVM boundaries, keeps HealthKit/notification services mockable, and finishes the DI slicing before we return to Crashlytics evidence.

## Scope
1. **OnboardingView.swift** – `HealthKitServices` and `NotificationServices` still default to `HealthKitManager.shared` / `NotificationManager.shared`.
2. **WeightSetupComponents.swift** – Direct calls to `HealthKitManager.shared` for authorization + queries during onboarding.
3. **WeightHistoryComponents.swift** – Uses `MeasurementSystemObserver.shared` instead of the injected observer from the dependency bundle.
4. **WeightProgressStory/WeightTrendsViewModel.swift** – Convenience initializer leaks `MeasurementSystemProvider.shared`; tighten to dependency-only usage.
5. **Tests/Previews** – Ensure all previews/tests pull dependencies from `WeightDependencies.preview()` or explicit mocks.

## Current Singleton Usage Snapshot
| File | Singleton | Impact |
| --- | --- | --- |
| `Onboarding/OnboardingView.swift` | `HealthKitManager.shared`, `NotificationManager.shared` | Breaks DI guarantees, hard to unit test onboarding flow. |
| `UI/Components/WeightSetupComponents.swift` | `HealthKitManager.shared` (auth + fetch) | HealthKit access happens on `.shared`, preventing deterministic onboarding tests. |
| `UI/Components/WeightHistoryComponents.swift` | `MeasurementSystemObserver.shared` | History list doesn’t respond to injected measurement providers, complicating previews/tests. |
| `UI/Components/WeightProgressStory/WeightTrendsViewModel.swift` | `MeasurementSystemProvider.shared` via convenience init | Reintroduces `.shared` if callers forget to pass dependencies, undermining DI enforcement. |

## Plan of Record
1. **Add onboarding factories to `WeightDependencies`**
   - Introduce `func makeOnboardingServices() -> OnboardingView.Dependencies` (or similar) bundling `HealthKitServicing`, `NotificationServicing`, `WeightManager`, and `MeasurementSystemProviding`.
   - Keep factories `@MainActor` and reuse existing live instances from the container.
2. **Refactor `OnboardingView`**
   - Replace ad-hoc protocol defaults with a `Dependencies` struct that is provided either via initializer or `@Environment(\.weightDependencies)`.
   - Remove direct `.shared` usage; use the injected `HealthKitManagerProtocol`/`NotificationAuthorizationManaging`.
3. **Update supporting components**
   - `WeightSetupView` + helpers receive `HealthKitManagerProtocol` via initializer (likely passed from onboarding view model).
   - `WeightHistoryListView` takes `MeasurementSystemObserver` or a lighter publisher provided by dependencies.
4. **Clamp the convenience APIs**
   - Delete the `WeightTrendsViewModel` convenience initializer or mark it `@available(*, deprecated)` to enforce dependency struct usage.
   - Ensure previews/tests request a mock view model from `WeightDependencies.preview().makeProgressStoryViewModel()`.
5. **Entry-point wiring**
   - `FastingTrackerApp` should request `weightDependencies.makeOnboardingDependencies()` and pass the result into `OnboardingView`.
   - Confirm `MainTabView` continues to inject `.environment(\.weightDependencies, weightManagerProvider)`.
6. **Testing + validation hooks**
   - Update existing tests to construct onboarding dependencies with mocks.
   - Smoke test on device (Command‑U via Rich) once wiring compiles.
7. **Documentation + observability**
   - Update `HANDOFF.md` (W/H/E/A) after coding/testing.
   - Capture any telemetry adjustments in `docs/runbooks/OBSERVABILITY_RUNBOOK.md` if needed.

## Deliverables
- Refactored Swift files (`OnboardingView.swift`, `WeightSetupComponents.swift`, `WeightHistoryComponents.swift`, `WeightTrendsViewModel.swift`, `WeightDependencies.swift`, entry point wiring).
- Updated unit tests/previews demonstrating dependency injection.
- Session notes + verification steps appended to HANDOFF.
- Confirmation that Crashlytics filter work stays queued until this slice lands.
