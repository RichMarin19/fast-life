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

    private var showingAddWeightBinding: Binding<Bool> {
        Binding(
            get: { self.vm.showingAddWeight },
            set: { self.vm.showingAddWeight = $0 }
        )
    }

    private var showingSettingsBinding: Binding<Bool> {
        Binding(
            get: { self.vm.showingSettings },
            set: { self.vm.showingSettings = $0 }
        )
    }

    private var showingGoalEditorBinding: Binding<Bool> {
        Binding(
            get: { self.vm.showingGoalEditor },
            set: { self.vm.showingGoalEditor = $0 }
        )
    }

    private var showingTrendsBinding: Binding<Bool> {
        Binding(
            get: { self.vm.showingTrends },
            set: { self.vm.showingTrends = $0 }
        )
    }

    private var showingFirstTimeSetupBinding: Binding<Bool> {
        Binding(
            get: { self.vm.showingFirstTimeSetup },
            set: { self.vm.showingFirstTimeSetup = $0 }
        )
    }

    private var showGoalLineBinding: Binding<Bool> {
        Binding(
            get: { self.vm.showGoalLine },
            set: { self.vm.showGoalLine = $0 }
        )
    }

    private var weightGoalBinding: Binding<Double> {
        Binding(
            get: { self.vm.weightGoal },
            set: { self.vm.weightGoal = $0 }
        )
    }

    private var selectedTimeRangeBinding: Binding<WeightTimeRange> {
        Binding(
            get: { self.vm.selectedTimeRange },
            set: { self.vm.selectedTimeRange = $0 }
        )
    }

    private var draggedCardBinding: Binding<TrackerCardType?> {
        Binding(
            get: { self.vm.draggedCard },
            set: { self.vm.draggedCard = $0 }
        )
    }

    private var healthKitNudgeView: AnyView? {
        if vm.shouldShowHealthKitNudge {
            return AnyView(
                HealthKitNudgeView(
                    dataType: .weight,
                    onConnect: {
                        vm.handleHealthKitConnect()
                    },
                    onDismiss: {
                        vm.handleHealthKitDismiss()
                    }
                )
            )
        }
        return nil
    }

    /// Milestone Ring Card with computed data from weight manager
    /// TASK 1E PHASE 3: Replaced placeholder data with actual milestone calculations
    /// UPDATED: Migrated to DSCard pattern (Phase v1.3b) - uses cardManager for visibility control
    private var milestoneRingCard: some View {
        // Calculate milestone stats (all in internal pounds, converted for display)
        let totalMilestones = 10
        let stats = weightManager.milestoneStats(goalWeight: vm.weightGoal, totalMilestones: totalMilestones)

        return MilestoneRingCard(
            progress: stats?.progress ?? 0.0,  // Progress within current milestone (0.0-1.0)
            milestoneIndex: stats?.currentIndex ?? 1,  // Current milestone number (1-10)
            centerValue: weightManager.latestWeight.map { String(format: "%.1f", weightManager.displayWeight(for: $0)) } ?? "---",
            dateText: weightManager.latestWeight.map { $0.date.formatted(date: .abbreviated, time: .omitted) } ?? "",
            leftStat: weightManager.startWeight.map { String(format: "%.1f", weightManager.displayWeight(for: $0)) } ?? "---",
            midStat: stats.map { "\(Int($0.progress * 100))%" } ?? "0%",  // Progress % within current milestone
            rightStat: stats.map { "\(String(format: "%.1f", weightManager.convertWeightToDisplayUnit($0.remainingWeight))) to go" } ?? "Set goal",
            totalMilestones: totalMilestones,
            completedMilestones: stats?.completed ?? 0  // Number of fully completed milestones
            // REMOVED: cardManager parameter - DSCard wrapper moved to WeightTrackingView
        )
    }

    var body: some View {
        #if DEBUG
        // 🔍 FORENSIC: Log body render
        AppLogger.info("⏱️ WeightTrackingView.body rendering", category: AppLogger.ui)
        #endif

        return TrackerScreenShell(
            title: ("Weight Tr", "ac", "ker"),
            hasData: !weightManager.weightEntries.isEmpty,
            nudge: healthKitNudgeView,
            gradientStyle: .luxury,  // 🔥 LUXURY UI ACTIVATED
            settingsAction: { vm.showingSettings = true }
        ) {
            if weightManager.weightEntries.isEmpty {
                EmptyWeightStateView(
                    showingAddWeight: showingAddWeightBinding,
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
                        .onDrop(of: [.text], delegate: TrackerCardDropDelegate(
                            card: cardType,
                            draggedCard: draggedCardBinding,
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
        .sheet(isPresented: showingAddWeightBinding) {
            AddWeightView(weightManager: weightManager)
        }
        .sheet(isPresented: showingSettingsBinding) {
            WeightControlCenterView(
                weightManager: weightManager,
                showGoalLine: showGoalLineBinding,
                weightGoal: weightGoalBinding
            )
            .environmentObject(behavioralScheduler)
        }
        .sheet(isPresented: showingGoalEditorBinding) {
            FirstTimeWeightSetupView(
                weightManager: weightManager,
                weightGoal: weightGoalBinding,
                showGoalLine: showGoalLineBinding
            )
        }
        .sheet(isPresented: showingTrendsBinding) {
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
        .sheet(isPresented: showingFirstTimeSetupBinding) {
            FirstTimeWeightSetupView(
                weightManager: weightManager,
                weightGoal: weightGoalBinding,
                showGoalLine: showGoalLineBinding
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
                    showingGoalEditor: showingGoalEditorBinding,
                    showingAddWeight: showingAddWeightBinding,
                    showingTrends: showingTrendsBinding
                )
            }

        case .milestone:
            // Calculate milestone info for title
            let totalMilestones = 10
            let stats = weightManager.milestoneStats(goalWeight: vm.weightGoal, totalMilestones: totalMilestones)
            let milestoneIndex = stats?.currentIndex ?? 1

            DSCard(
                cardType: .milestone,
                title: "Milestone \(milestoneIndex)/\(totalMilestones)",
                cardManager: cardManager,
                canExpand: true
            ) {
                milestoneRingCard
            }

        case .chart:
            DSCard(
                cardType: .chart,
                cardManager: cardManager,
                canExpand: true
            ) {
                WeightChartView(
                    weightManager: weightManager,
                    selectedTimeRange: selectedTimeRangeBinding,
                    showGoalLine: showGoalLineBinding,
                    weightGoal: weightGoalBinding
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

// MARK: - Empty State View

struct EmptyWeightStateView: View {
    @Binding var showingAddWeight: Bool
    let healthKitManager: HealthKitManager
    let weightManager: WeightManager
    // Removed: @State private var showingHealthDataSelection - no longer needed

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "scalemass")
                .font(DSTypography.displayXXL)
                .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.6))

            Text("No Weight Data Yet")
                .font(DSTypography.displayM)
                .foregroundColor(Theme.ColorToken.textSecondary)

            Text("Add your first weight entry or sync with Apple Health")
                .font(DSTypography.cardBody)
                .foregroundColor(Theme.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button(action: { showingAddWeight = true }) {
                    Label("Add Weight Manually", systemImage: "plus.circle.fill")
                        .font(DSTypography.buttonPrimary)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.ColorToken.accentPrimary)
                        .cornerRadius(DSCornerRadius.button)
                }
                .accessibilityLabel("Add weight entry manually")

                Button(action: {
                    // DIRECT AUTHORIZATION: Apple HIG contextual permission pattern
                    // Request weight permissions immediately when user wants to sync weight data
                    AppLogger.info("EmptyState: Sync button tapped - requesting weight authorization", category: AppLogger.healthKit)

                    // CRITICAL FIX: Enable sync preference FIRST so syncFromHealthKit() doesn't early-return
                    // This ensures the sync actually runs and logs appear
                    weightManager.setSyncPreference(true)
                    AppLogger.info("EmptyState: Enabled sync preference", category: AppLogger.healthKit)

                    HealthKitManager.shared.requestWeightAuthorization { success, _ in
                        if success {
                            AppLogger.info("EmptyState: Weight authorization granted - starting sync", category: AppLogger.healthKit)
                            DispatchQueue.main.async {
                                // Use syncFromHealthKitWithReset to reset anchor and get all data fresh
                                let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
                                weightManager.syncFromHealthKitWithReset(startDate: startDate) { addedCount, error in
                                    if let error = error {
                                        AppLogger.error("EmptyState: Sync failed", category: AppLogger.healthKit, error: error)
                                    } else {
                                        AppLogger.info("EmptyState: Sync completed - added \(addedCount) entries", category: AppLogger.healthKit)
                                    }
                                }
                            }
                        } else {
                            AppLogger.info("EmptyState: Weight authorization denied", category: AppLogger.healthKit)
                        }
                    }
                }) {
                    Label("Sync with Apple Health", systemImage: "heart.fill")
                        .font(DSTypography.buttonPrimary)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.ColorToken.stateSuccess)
                        .cornerRadius(DSCornerRadius.button)
                }
                .accessibilityLabel("Sync weight data with Apple Health")
            }
            .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 60)
        // Removed: HealthDataSelectionView sheet - using direct authorization per Apple HIG
    }

    // Removed: handleHealthDataSelection - no longer needed with direct authorization
}

// MARK: - Tracker Card Drop Delegate (Layer 5)

/// Drop delegate for drag-and-drop tracker card reordering on main screen
/// Industry Pattern: Apple Health - Drag cards to customize dashboard order
/// Note: Different from ControlCenterCardDropDelegate (used in Control Center settings)
struct TrackerCardDropDelegate: DropDelegate {
    let card: TrackerCardType
    @Binding var draggedCard: TrackerCardType?
    let cardManager: CardManager<TrackerCardType>

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedCard = draggedCard else { return false }

        // Get current visible cards in order
        let visibleCards = cardManager.getVisibleCardsInOrder()

        // Find indices of dragged and target cards
        guard let fromIndex = visibleCards.firstIndex(of: draggedCard),
              let toIndex = visibleCards.firstIndex(of: card) else {
            return false
        }

        // Only reorder if indices are different
        if fromIndex != toIndex {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                cardManager.reorderCards(from: fromIndex, to: toIndex)
            }
        }

        self.draggedCard = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        // Optional: Add visual feedback during drag (e.g., scale effect)
    }

    func dropExited(info: DropInfo) {
        // Optional: Remove visual feedback
    }
}

// MARK: - View Modifier for Conditional X-Axis Scale

#Preview {
    WeightTrackingView()
}
