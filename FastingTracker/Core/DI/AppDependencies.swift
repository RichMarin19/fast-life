import SwiftUI

@MainActor
struct AppDependencies {
    let weightManager: WeightManager
    let healthKitManager: HealthKitManagerProtocol
    let measurementProvider: MeasurementSystemProviding
    let measurementObserver: MeasurementSystemObserver
    let behavioralScheduler: BehavioralNotificationScheduler
    let trackerCardManager: CardManager<TrackerCardType>
    let progressStoryCardManager: ProgressStoryCardManaging
    let optOutManager: ContentOptOutManaging
    let nudgeManager: HealthKitNudgeManaging
    let healthKitServices: HealthKitServicing
    let notificationServices: NotificationServicing
    let weightSyncCoordinator: WeightSyncCoordinating
    private let weightDependencies: WeightDependencies

    @MainActor
    static func live(
        weightManager: WeightManager,
        healthKitManager: HealthKitManagerProtocol,
        measurementProvider: MeasurementSystemProviding,
        measurementObserver: MeasurementSystemObserver,
        behavioralScheduler: BehavioralNotificationScheduler,
        trackerCardManager: CardManager<TrackerCardType>,
        progressStoryCardManager: ProgressStoryCardManaging,
        optOutManager: ContentOptOutManaging,
        nudgeManager: HealthKitNudgeManaging
    ) -> AppDependencies {
        let notificationServices = NotificationServices()
        let healthKitServices = HealthKitServices(manager: healthKitManager)
        let weightSyncCoordinator = WeightSyncCoordinator(weightManager: weightManager, healthKitManager: healthKitManager)
        let weightDependencies = WeightDependencies.live(
            weightManager: weightManager,
            behavioralScheduler: behavioralScheduler,
            trackerCardManager: trackerCardManager,
            progressStoryCardManager: progressStoryCardManager,
            optOutManager: optOutManager,
            healthKitManager: healthKitManager,
            nudgeManager: nudgeManager,
            measurementProvider: measurementProvider,
            measurementObserver: measurementObserver
        )
        return AppDependencies(
            weightManager: weightManager,
            healthKitManager: healthKitManager,
            measurementProvider: measurementProvider,
            measurementObserver: measurementObserver,
            behavioralScheduler: behavioralScheduler,
            trackerCardManager: trackerCardManager,
            progressStoryCardManager: progressStoryCardManager,
            optOutManager: optOutManager,
            nudgeManager: nudgeManager,
            healthKitServices: healthKitServices,
            notificationServices: notificationServices,
            weightSyncCoordinator: weightSyncCoordinator,
            weightDependencies: weightDependencies
        )
    }

    @MainActor
    static func preview() -> AppDependencies {
        let weightManager = WeightManager()
        let healthKitManager = HealthKitManager.shared
        let measurementProvider = MeasurementSystemProvider.shared
        let measurementObserver = MeasurementSystemObserver(provider: measurementProvider)
        let behavioralScheduler = BehavioralNotificationScheduler.shared
        let trackerCardManager = MainActor.assumeIsolated { TrackerCards.shared }
        let progressStoryCardManager = MainActor.assumeIsolated { ProgressStoryCards.shared }
        let optOutManager = MainActor.assumeIsolated { ContentOptOutManager.shared }
        let nudgeManager = MainActor.assumeIsolated { HealthKitNudgeManager.shared }
        return .live(
            weightManager: weightManager,
            healthKitManager: healthKitManager,
            measurementProvider: measurementProvider,
            measurementObserver: measurementObserver,
            behavioralScheduler: behavioralScheduler,
            trackerCardManager: trackerCardManager,
            progressStoryCardManager: progressStoryCardManager,
            optOutManager: optOutManager,
            nudgeManager: nudgeManager
        )
    }

    func makeWeightDependencies() -> WeightDependencies {
        weightDependencies
    }


    func makeOnboardingView(isOnboardingComplete: Binding<Bool>) -> OnboardingView {
        OnboardingView(
            isOnboardingComplete: isOnboardingComplete,
            weightManager: weightManager,
            healthKitServices: healthKitServices,
            notificationServices: notificationServices,
            weightSyncCoordinator: weightSyncCoordinator,
            measurementProvider: measurementProvider
        )
    }
}
private struct AppDependenciesKey: EnvironmentKey {
    @MainActor
    static var defaultValue: AppDependencies = .preview()
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
