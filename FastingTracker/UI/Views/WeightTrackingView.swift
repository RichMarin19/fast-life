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
    private let weightManager: WeightManager
    private let behavioralScheduler: BehavioralNotificationScheduler
    private let optOutManager: ContentOptOutManaging
    private let healthKitManager: HealthKitManagerProtocol
    private let nudgeManager: HealthKitNudgeManaging
    private let progressStoryCardManager: ProgressStoryCardManaging

    @StateObject private var viewModel: WeightTrackingViewModel
    @ObservedObject private var cardManager: CardManager<TrackerCardType>

    private var vm: WeightTrackingViewModel { viewModel }

    init(dependencies: WeightDependencies) {
        self.dependencies = dependencies
        self.weightManager = dependencies.weightManager
        self.behavioralScheduler = dependencies.behavioralScheduler
        self.optOutManager = dependencies.optOutManager
        self.healthKitManager = dependencies.healthKitManager
        self.nudgeManager = dependencies.nudgeManager
        self.progressStoryCardManager = dependencies.progressStoryCardManager
        _viewModel = StateObject(
            wrappedValue: WeightTrackingViewModel(
                dependencies: .init(
                    weightManager: dependencies.weightManager,
                    behavioralScheduler: dependencies.behavioralScheduler,
                    optOutManager: dependencies.optOutManager,
                    healthKitManager: dependencies.healthKitManager,
                    nudgeManager: dependencies.nudgeManager
                )
            )
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
                    weightManager: weightManager
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
                showGoalLine: binding(\.showGoalLine)
            )
        }
        .sheet(isPresented: binding(\.showingTrends)) {
            WeightTrendsView(
                weightManager: weightManager,
                optOutManager: optOutManager,
                cardManager: progressStoryCardManager
            )
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
                showGoalLine: binding(\.showGoalLine)
            )
        }
        .onAppear {
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
                    showingTrends: binding(\.showingTrends)
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
                WeightStatsView(weightManager: weightManager)
            }
        case .history:
            EmptyView()
        }
    }
}

#Preview {
    WeightTrackingView()
        .environment(\.weightDependencies, .preview())
}
