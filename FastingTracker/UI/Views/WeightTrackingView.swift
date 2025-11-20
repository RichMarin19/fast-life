import SwiftUI
import Charts

struct WeightTrackingView: View {
    @Environment(\.weightDependencies) private var dependencies

    var body: some View {
        WeightTrackingExperienceView(dependencies: dependencies)
    }
}

@MainActor
private struct WeightTrackingExperienceView: View {
    private let dependencies: WeightDependencies
    private let behavioralScheduler: BehavioralNotificationScheduler
    private let optOutManager: ContentOptOutManaging
    private let healthKitManager: HealthKitManagerProtocol
    private let nudgeManager: HealthKitNudgeManaging
    private let progressStoryCardManager: ProgressStoryCardManaging
    private let measurementProvider: MeasurementSystemProviding
    private let syncCoordinator: WeightSyncCoordinating

    @StateObject private var viewModel: WeightTrackingViewModel
    @ObservedObject private var weightManager: WeightManager
    @ObservedObject private var cardManager: CardManager<TrackerCardType>
    @ObservedObject private var measurementObserver: MeasurementSystemObserver
    @State private var showingSyncStatusAlert = false
    @State private var latestSyncStatus: WeightSyncStatus?

    private var vm: WeightTrackingViewModel { viewModel }

    init(dependencies: WeightDependencies) {
        self.dependencies = dependencies
        self.behavioralScheduler = dependencies.behavioralScheduler
        self.optOutManager = dependencies.optOutManager
        self.healthKitManager = dependencies.healthKitManager
        self.nudgeManager = dependencies.nudgeManager
        self.progressStoryCardManager = dependencies.progressStoryCardManager
        self.measurementProvider = dependencies.measurementProvider
        self.syncCoordinator = dependencies.syncCoordinator
        _measurementObserver = ObservedObject(wrappedValue: dependencies.measurementObserver)
        _weightManager = ObservedObject(wrappedValue: dependencies.weightManager)
        _viewModel = StateObject(
            wrappedValue: dependencies.makeWeightTrackingViewModel()
        )
        _cardManager = ObservedObject(wrappedValue: dependencies.trackerCardManager)
    }

    var body: some View {
        #if DEBUG
        AppLogger.info("⏱️ WeightTrackingView.body rendering", category: AppLogger.ui)
        #endif

        return TrackerScreenShell(
            title: ("Weight Tr", "ac", "ker"),
            hasData: !weightManager.weightEntries.isEmpty,
            nudge: vm.shouldShowHealthKitNudge
                ? AnyView(
                    HealthKitNudgeView(
                        dataType: .weight,
                        onConnect: vm.handleHealthKitConnect,
                        onDismiss: vm.handleHealthKitDismiss
                    )
                )
                : nil,
            gradientStyle: .luxury,
            settingsAction: { vm.showingSettings = true }
        ) {
            if weightManager.weightEntries.isEmpty {
                EmptyWeightStateView(
                    showingAddWeight: binding(\.showingAddWeight),
                    healthKitManager: healthKitManager,
                    weightManager: weightManager,
                    syncCoordinator: syncCoordinator
                )
            } else {
                ForEach(cardManager.getVisibleCardsInOrder(), id: \.self) { cardType in
                    cardView(for: cardType)
                        .transition(.opacity.combined(with: .scale))
                        .onDrag {
                            vm.draggedCard = cardType
                            return NSItemProvider(object: cardType.rawValue as NSString)
                        }
                        .onDrop(of: [.text], delegate: WeightTrackerCardDropDelegate(
                            card: cardType,
                            draggedCard: binding(\.draggedCard),
                            cardManager: cardManager
                        ))
                }
            }
        }
        .sheet(isPresented: binding(\.showingAddWeight)) {
            AddWeightView(weightManager: weightManager)
        }
        .sheet(isPresented: binding(\.showingSettings)) {
            WeightControlCenterView(
                showGoalLine: binding(\.showGoalLine),
                weightGoal: binding(\.weightGoal)
            )
        }
        .sheet(isPresented: binding(\.showingGoalEditor)) {
            FirstTimeWeightSetupView(
                weightManager: weightManager,
                weightGoal: binding(\.weightGoal),
                showGoalLine: binding(\.showGoalLine),
                measurementObserver: measurementObserver
            )
        }
        .sheet(isPresented: binding(\.showingTrends)) {
            WeightTrendsView()
            .onAppear {
                #if DEBUG
                AppLogger.info("🎯 Progress Story sheet appeared", category: AppLogger.ui)
                #endif
            }
        }
        .onChange(of: vm.showingTrends) { oldValue, newValue in
            #if DEBUG
            AppLogger.info("🎯 showingTrends changed from \(oldValue) to \(newValue)", category: AppLogger.ui)
            #endif
        }
        .sheet(isPresented: binding(\.showingFirstTimeSetup)) {
            FirstTimeWeightSetupView(
                weightManager: weightManager,
                weightGoal: binding(\.weightGoal),
                showGoalLine: binding(\.showGoalLine),
                measurementObserver: measurementObserver
            )
        }
        .onAppear {
            #if DEBUG
            let providerSystem = measurementProvider.currentMeasurementSystem
            let observerSystem = measurementObserver.system
            let weightUnit = weightManager.currentUnitAbbreviation
            let latestPounds = weightManager.latestWeight?.weight
            let formattedLatest = latestPounds.map { weightManager.formattedDisplayWeight($0) } ?? "nil"
            AppLogger.debug(
                """
                🧪 WeightTrackingView.onAppear – measurement snapshot
                  providerSystem: \(describeMeasurementSystem(providerSystem))
                  providerUnit: \(measurementProvider.currentUnit.abbreviation)
                  observerSystem: \(describeMeasurementSystem(observerSystem))
                  weightManagerUnit: \(weightUnit)
                  latestEntryPounds: \(latestPounds.map { String(format: "%.3f", $0) } ?? "nil")
                  latestEntryDisplay: \(formattedLatest)
                """,
                category: AppLogger.weightTracking
            )
            #endif
            MeasurementSystemProvider.shared.refresh()
            vm.onViewAppear()
        }
        .task {
            await vm.handleProgressStoryAutoShow()
        }
        .onChange(of: vm.showGoalLine) { _, _ in
            vm.saveGoalSettings()
        }
        .onChange(of: vm.weightGoal) { _, _ in
            vm.saveGoalSettings()
        }
        .onReceive(syncCoordinator.statusPublisher) { status in
            switch status {
            case .success, .upToDate, .failure:
                latestSyncStatus = status
                showingSyncStatusAlert = true
            case .idle, .syncing:
                break
            }
        }
        .alert("Sync Status", isPresented: $showingSyncStatusAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(syncMessage(for: latestSyncStatus))
        })
    }

    private func binding<Value>(_ keyPath: ReferenceWritableKeyPath<WeightTrackingViewModel, Value>) -> Binding<Value> {
        Binding(
            get: { vm[keyPath: keyPath] },
            set: { vm[keyPath: keyPath] = $0 }
        )
    }

    @ViewBuilder
    private func cardView(for cardType: TrackerCardType) -> some View {
        switch cardType {
            case .currentWeight:
                DSCard(
                    cardType: .currentWeight,
                    cardManager: cardManager,
                    canExpand: true
                ) {
                    CurrentWeightCard(
                        weightManager: weightManager,
                        weightGoal: vm.weightGoal,
                        showingGoalEditor: binding(\.showingGoalEditor),
                        showingAddWeight: binding(\.showingAddWeight),
                        showingTrends: binding(\.showingTrends),
                        measurementObserver: measurementObserver
                    )
                }
            case .chart:
                DSCard(
                    cardType: .chart,
                cardManager: cardManager,
                canExpand: true
            ) {
                WeightChartView(
                    weightManager: weightManager,
                    selectedTimeRange: binding(\.selectedTimeRange),
                    showGoalLine: binding(\.showGoalLine),
                    weightGoal: binding(\.weightGoal)
                )
            }
            case .stats:
                DSCard(
                    cardType: .stats,
                    cardManager: cardManager,
                    canExpand: true
                ) {
                    WeightStatsView(
                        weightManager: weightManager,
                        measurementObserver: measurementObserver
                    )
                }
            case .history:
            EmptyView()
        }
    }

    private func syncMessage(for status: WeightSyncStatus?) -> String {
        guard let status else { return "" }
        switch status {
        case .success(let newEntries):
            return "Successfully synced \(newEntries) weight entries from Apple Health."
        case .upToDate:
            return "Weight data is up to date. No new entries found in Apple Health."
        case .failure(let message):
            return message
        case .idle:
            return ""
        case .syncing:
            return "Sync in progress..."
        }
    }
}

private func describeMeasurementSystem(_ system: Locale.MeasurementSystem) -> String {
    switch system {
    case .metric: return "metric"
    case .us: return "us"
    case .uk: return "uk"
    default: return "unknown"
    }
}

#Preview {
    WeightTrackingView()
        .environment(\.weightDependencies, .preview())
}
