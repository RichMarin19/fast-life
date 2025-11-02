import SwiftUI
import Charts

struct WeightTrackingView: View {
    // MARK: - Dependencies (SwiftUI EnvironmentObject Pattern)
    // Reference: ARCHITECTURE-AUDIT.md - Critical Task 1
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var behavioralScheduler: BehavioralNotificationScheduler

    // MVVM: ViewModel owns all state and business logic
    // CONSULTANT FIX: Access managers from @EnvironmentObject instead of creating duplicates
    // SwiftUI limitation: @StateObject init happens BEFORE @EnvironmentObject injection
    // Solution: ViewModel accesses managers passed from view's @EnvironmentObject
    @StateObject private var viewModel = WeightTrackingViewModel()

    // CRITICAL FIX (Task 1F Enhancement 6): Direct observation of cardManager
    // Problem: @ObservedObject in ViewModel doesn't propagate changes to View
    // Solution: View DIRECTLY observes cardManager for real-time UI updates
    // When cardManager updates @Published properties → View re-renders immediately
    // Industry Pattern: SwiftUI observation must be direct, not through intermediate objects
    @ObservedObject private var cardManager = TrackerCards.shared

    private var vm: WeightTrackingViewModel {
        return viewModel
    }

    // MARK: - Binding Helpers
    // SwiftUI requires Bindings to be created from @State/@Published properties
    // Since vm is a computed property, we create these helper bindings

    private func binding<Value>(_ keyPath: ReferenceWritableKeyPath<WeightTrackingViewModel, Value>) -> Binding<Value> {
        Binding(
            get: { vm[keyPath: keyPath] },
            set: { vm[keyPath: keyPath] = $0 }
        )
    }

    // REMOVED: milestoneRingCard property (Enhancement 7)
    // Milestone functionality already exists in Current Weight Card - no need for separate card
    // Cleaner UI: 3 cards (Current Weight, Chart, Stats) instead of 4
    // Industry Pattern: Minimize redundancy (Apple Health, Google Fit)

    var body: some View {
        #if DEBUG
        // 🔍 FORENSIC: Log body render
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
            gradientStyle: .luxury,  // 🔥 LUXURY UI ACTIVATED
            settingsAction: { vm.showingSettings = true }
        ) {
            if weightManager.weightEntries.isEmpty {
                EmptyWeightStateView(
                    showingAddWeight: binding(\.showingAddWeight),
                    healthKitManager: vm.healthKitManager,
                    weightManager: weightManager
                )
            } else {
                // LAYER 5: Drag-to-reorder cards
                // Cards displayed in user-customized order from TrackerCardManager
                // Industry Pattern: Apple Health - Long-press and drag to reorder
                ForEach(cardManager.getVisibleCardsInOrder(), id: \.self) { cardType in
                    cardView(for: cardType)
                        .transition(.opacity.combined(with: .scale))
                        .onDrag {
                            // Layer 5: Enable drag for reordering
                            vm.draggedCard = cardType
                            return NSItemProvider(object: cardType.rawValue as NSString)
                        }
                        .onDrop(of: [.text], delegate: WeightTrackerCardDropDelegate(
                            card: cardType,
                            draggedCard: binding(\.draggedCard),
                            cardManager: cardManager
                        ))
                }

                // Weight History List Card - MOVED TO CONTROL CENTER
                // History is now accessed via Control Center (gear icon → History section)
                // Reason: Better information architecture - History is data management, not dashboard
                // Industry Pattern: Apple Health - Detailed logs live in settings/management areas
                // Removed from main screen to reduce clutter (4 cards instead of 5)
                // TrackerCardType.history still exists for backwards compatibility

                // REMOVED: History card no longer shown on main Weight Tracker screen
                // Users access history via: Gear Icon → Control Center → History section
            }
        }
        .sheet(isPresented: binding(\.showingAddWeight)) {
            AddWeightView(weightManager: weightManager)
        }
        .sheet(isPresented: binding(\.showingSettings)) {
            WeightControlCenterView(
                weightManager: weightManager,
                showGoalLine: binding(\.showGoalLine),
                weightGoal: binding(\.weightGoal)
            )
            .environmentObject(behavioralScheduler)
        }
        .sheet(isPresented: binding(\.showingGoalEditor)) {
            FirstTimeWeightSetupView(
                weightManager: weightManager,
                weightGoal: binding(\.weightGoal),
                showGoalLine: binding(\.showGoalLine)
            )
        }
        .sheet(isPresented: binding(\.showingTrends)) {
            WeightTrendsView(weightManager: weightManager)
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
        // Removed: HealthDataSelectionView sheet - using direct authorization per Apple HIG
        .sheet(isPresented: binding(\.showingFirstTimeSetup)) {
            FirstTimeWeightSetupView(
                weightManager: weightManager,
                weightGoal: binding(\.weightGoal),
                showGoalLine: binding(\.showGoalLine)
            )
        }
        .onAppear {
            // CONSULTANT FIX: Inject @EnvironmentObject managers into ViewModel
            // Must happen AFTER SwiftUI @EnvironmentObject injection completes
            // This fixes duplicate WeightManager creation issue
            vm.configure(weightManager: weightManager, behavioralScheduler: behavioralScheduler)

            // MVVM: Delegate onAppear logic to ViewModel
            vm.onViewAppear()
        }
        .task {
            // MVVM: Delegate Progress Story auto-show to ViewModel
            await vm.handleProgressStoryAutoShow()
        }
        .onChange(of: vm.showGoalLine) { _, _ in
            vm.saveGoalSettings()
        }
        .onChange(of: vm.weightGoal) { _, _ in
            vm.saveGoalSettings()
        }
    }

    // MARK: - Card View Builder (Layer 5)

    /// Returns the appropriate card view for each card type
    /// Industry Pattern: Builder pattern for dynamic card rendering
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

        // REMOVED: milestone case (Enhancement 7)
        // Milestone functionality exists in Current Weight Card - no need for separate card
        // Cleaner dashboard: 3 cards instead of 4

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
            // History card is in Control Center, not on main screen
            EmptyView()
        }
    }

    // MARK: - Goal Settings Persistence
    // MOVED TO VIEWMODEL: loadGoalSettings() and saveGoalSettings()
    // Reference: ARCHITECTURE-AUDIT.md - Critical Task 1
    // Business logic now in WeightTrackingViewModel following MVVM pattern
}

// MARK: - Preview

#Preview {
    WeightTrackingView()
}
