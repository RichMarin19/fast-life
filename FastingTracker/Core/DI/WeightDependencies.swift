import SwiftUI

/// Strongly typed bundle of dependencies required by Weight Tracking + Control Center experiences.
/// Aligns with Apple’s EnvironmentKey guidance so views can receive managers without touching singletons.
@MainActor
struct WeightDependencies {
    let weightManager: WeightManager
    let behavioralScheduler: BehavioralNotificationScheduler
    let trackerCardManager: CardManager<TrackerCardType>
    let progressStoryCardManager: ProgressStoryCardManaging
    let optOutManager: ContentOptOutManaging
    let healthKitManager: HealthKitManagerProtocol
    let nudgeManager: HealthKitNudgeManaging
    let measurementProvider: MeasurementSystemProviding
    let measurementObserver: MeasurementSystemObserver
    let notificationCoordinatorFactory: @MainActor (WeightManager, WeightDependencies) -> WeightNotificationCoordinator
    let preferencesFactory: @MainActor (WeightDependencies) -> PreferencesViewModel
    let controlCenterCoordinatorFactory: @MainActor (WeightDependencies) -> WeightControlCenterCoordinator

    /// Production factory used at runtime so the container reuses the app’s @StateObject instances.
    @MainActor
    static func live(
        weightManager: WeightManager,
        behavioralScheduler: BehavioralNotificationScheduler,
        trackerCardManager: CardManager<TrackerCardType> = MainActor.assumeIsolated { TrackerCards.shared },
        progressStoryCardManager: ProgressStoryCardManaging = MainActor.assumeIsolated { ProgressStoryCards.shared },
        optOutManager: ContentOptOutManaging = MainActor.assumeIsolated { ContentOptOutManager.shared },
        healthKitManager: HealthKitManagerProtocol = MainActor.assumeIsolated { HealthKitManager.shared },
        nudgeManager: HealthKitNudgeManaging = MainActor.assumeIsolated { HealthKitNudgeManager.shared },
        measurementProvider: MeasurementSystemProviding = MainActor.assumeIsolated { MeasurementSystemProvider.shared },
        measurementObserver: MeasurementSystemObserver = MainActor.assumeIsolated { MeasurementSystemObserver.shared },
        notificationCoordinatorFactory: @MainActor @escaping (WeightManager, WeightDependencies) -> WeightNotificationCoordinator = { manager, _ in
            WeightNotificationCoordinator.live(
                weightManager: manager,
                userDefaults: .standard,
                notificationManager: WeightNotificationManager.shared
            )
        },
        preferencesFactory: @MainActor @escaping (WeightDependencies) -> PreferencesViewModel = { deps in
            PreferencesViewModel(
                optOutManager: deps.optOutManager,
                cardManager: deps.trackerCardManager,
                progressStoryCardManager: deps.progressStoryCardManager
            )
        },
        controlCenterCoordinatorFactory: @MainActor @escaping (WeightDependencies) -> WeightControlCenterCoordinator = { deps in
            WeightControlCenterCoordinator(
                weightManager: deps.weightManager,
                behavioralScheduler: deps.behavioralScheduler,
                healthKitManager: deps.healthKitManager,
                trackerCardManager: deps.trackerCardManager,
                progressStoryCardManager: deps.progressStoryCardManager,
                optOutManager: deps.optOutManager,
                preferencesViewModel: deps.preferencesFactory(deps)
            )
        }
    ) -> WeightDependencies {
        WeightDependencies(
            weightManager: weightManager,
            behavioralScheduler: behavioralScheduler,
            trackerCardManager: trackerCardManager,
            progressStoryCardManager: progressStoryCardManager,
            optOutManager: optOutManager,
            healthKitManager: healthKitManager,
            nudgeManager: nudgeManager,
            measurementProvider: measurementProvider,
            measurementObserver: measurementObserver,
            notificationCoordinatorFactory: notificationCoordinatorFactory,
            preferencesFactory: preferencesFactory,
            controlCenterCoordinatorFactory: controlCenterCoordinatorFactory
        )
    }

    /// Convenience factory for SwiftUI previews.
    @MainActor
    static func preview() -> WeightDependencies {
        let weightManager = WeightManager()
        let scheduler = BehavioralNotificationScheduler.shared
        return .live(
            weightManager: weightManager,
            behavioralScheduler: scheduler,
            trackerCardManager: CardManager<TrackerCardType>(preferencesKey: "preview.trackerCards.\(UUID().uuidString)"),
            progressStoryCardManager: CardManager<ProgressStoryCardType>(preferencesKey: "preview.progressCards.\(UUID().uuidString)"),
            notificationCoordinatorFactory: { manager, _ in
                let suite = "WeightDependencies.preview.\(UUID().uuidString)"
                let defaults = UserDefaults(suiteName: suite) ?? .standard
                defaults.removePersistentDomain(forName: suite)
                return WeightNotificationCoordinator(
                    weightManager: manager,
                    userDefaults: defaults,
                    notificationManager: WeightNotificationManager.shared
                )
            }
        )
    }

    /// Testing helper to inject fully mocked dependencies.
    @MainActor
    static func test(
        weightManager: WeightManager,
        behavioralScheduler: BehavioralNotificationScheduler,
        trackerCardManager: CardManager<TrackerCardType>,
        progressStoryCardManager: ProgressStoryCardManaging,
        optOutManager: ContentOptOutManaging,
        healthKitManager: HealthKitManagerProtocol,
        nudgeManager: HealthKitNudgeManaging,
        measurementProvider: MeasurementSystemProviding,
        measurementObserver: MeasurementSystemObserver,
        notificationCoordinatorFactory: @MainActor @escaping (WeightManager, WeightDependencies) -> WeightNotificationCoordinator,
        preferencesFactory: @MainActor @escaping (WeightDependencies) -> PreferencesViewModel = { deps in
            PreferencesViewModel(
                optOutManager: deps.optOutManager,
                cardManager: deps.trackerCardManager,
                progressStoryCardManager: deps.progressStoryCardManager
            )
        },
        controlCenterCoordinatorFactory: @MainActor @escaping (WeightDependencies) -> WeightControlCenterCoordinator = { deps in
            WeightControlCenterCoordinator(
                weightManager: deps.weightManager,
                behavioralScheduler: deps.behavioralScheduler,
                healthKitManager: deps.healthKitManager,
                trackerCardManager: deps.trackerCardManager,
                progressStoryCardManager: deps.progressStoryCardManager,
                optOutManager: deps.optOutManager,
                preferencesViewModel: deps.preferencesFactory(deps)
            )
        }
    ) -> WeightDependencies {
        WeightDependencies(
            weightManager: weightManager,
            behavioralScheduler: behavioralScheduler,
            trackerCardManager: trackerCardManager,
            progressStoryCardManager: progressStoryCardManager,
            optOutManager: optOutManager,
            healthKitManager: healthKitManager,
            nudgeManager: nudgeManager,
            measurementProvider: measurementProvider,
            measurementObserver: measurementObserver,
            notificationCoordinatorFactory: notificationCoordinatorFactory,
            preferencesFactory: preferencesFactory,
            controlCenterCoordinatorFactory: controlCenterCoordinatorFactory
        )
    }
}

// MARK: - Environment Integration

private struct WeightDependenciesKey: EnvironmentKey {
    @MainActor
    static var defaultValue: WeightDependencies = .preview()
}

extension EnvironmentValues {
    var weightDependencies: WeightDependencies {
        get { self[WeightDependenciesKey.self] }
        set { self[WeightDependenciesKey.self] = newValue }
    }
}

// MARK: - Helpers

extension WeightDependencies {
    @MainActor
    func makeControlCenterDependencies(userDefaults: UserDefaults = .standard) -> WeightControlCenterViewModel.Dependencies {
        WeightControlCenterViewModel.Dependencies(
            measurementProvider: measurementProvider,
            measurementObserver: measurementObserver,
            healthKitManager: healthKitManager,
            notificationCoordinator: notificationCoordinatorFactory(weightManager, self),
            optOutManager: optOutManager,
            trackerCardManager: trackerCardManager,
            progressStoryCardManager: progressStoryCardManager,
            userDefaults: userDefaults
        )
    }

    @MainActor
    func makeControlCenterViewModel(userDefaults: UserDefaults = .standard, locale: Locale = .current) -> WeightControlCenterViewModel {
        let deps = makeControlCenterDependencies(userDefaults: userDefaults)
        return WeightControlCenterViewModel(
            weightManager: weightManager,
            behavioralScheduler: behavioralScheduler,
            locale: locale,
            measurementProvider: deps.measurementProvider,
            measurementObserver: deps.measurementObserver,
            notificationCoordinator: deps.notificationCoordinator,
            optOutManager: deps.optOutManager,
            cardManager: deps.trackerCardManager,
            progressStoryCardManager: deps.progressStoryCardManager,
            healthKitManager: deps.healthKitManager,
            userDefaults: deps.userDefaults
        )
    }

    @MainActor
    func makePreferencesViewModel(userDefaults: UserDefaults = .standard) -> PreferencesViewModel {
        preferencesFactory(self)
    }

    @MainActor
    func makeWeightTrackingViewModel(userDefaults: UserDefaults = .standard) -> WeightTrackingViewModel {
        let deps = WeightTrackingViewModel.Dependencies(
            weightManager: weightManager,
            behavioralScheduler: behavioralScheduler,
            optOutManager: optOutManager,
            healthKitManager: healthKitManager,
            nudgeManager: nudgeManager,
            userDefaults: userDefaults
        )
        return WeightTrackingViewModel(dependencies: deps)
    }

    @MainActor
    func makeWeightTrendsViewModel(
        metricsProvider: WeightProgressStoryMetricsProviding? = nil
    ) -> WeightTrendsViewModel {
        let deps = WeightTrendsViewModel.Dependencies(
            weightManager: weightManager,
            optOutManager: optOutManager,
            cardManager: progressStoryCardManager,
            metricsProvider: metricsProvider ?? WeightProgressStoryMetricsProvider(weightManager: weightManager),
            measurementObserver: measurementObserver
        )
        return WeightTrendsViewModel(dependencies: deps)
    }

    @MainActor
    func makeControlCenterCoordinator(userDefaults: UserDefaults = .standard) -> WeightControlCenterCoordinator {
        controlCenterCoordinatorFactory(self)
    }
}
