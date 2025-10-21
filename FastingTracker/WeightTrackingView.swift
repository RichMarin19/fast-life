import SwiftUI
import Charts

struct WeightTrackingView: View {
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var behavioralScheduler: BehavioralNotificationScheduler
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject private var nudgeManager = HealthKitNudgeManager.shared
    @ObservedObject private var cardManager = TrackerCardManager.shared  // Layer 3: Card visibility management

    // PHASE 1: Unit preferences integration
    // Following Apple's reactive UI pattern for settings changes
    // Reference: https://developer.apple.com/documentation/swiftui/observedobject
    // Unit preferences removed for v1.0 - will add in v1.1
    @State private var showingAddWeight = false
    @State private var showingSettings = false
    @State private var showingFirstTimeSetup = false
    @State private var showingGoalEditor = false  // Quick access goal editor
    @State private var showingTrends = false  // Weight trends detail view
    @State private var selectedTimeRange: WeightTimeRange = .month
    @State private var showGoalLine = false
    @State private var weightGoal: Double = 180.0
    @State private var showHealthKitNudge = false
    // REMOVED: @State private var showMilestoneCard - now managed by TrackerCardManager

    // UserDefaults keys for persistence
    private let showGoalLineKey = "showGoalLine"
    private let weightGoalKey = "goalWeight"  // MUST match onboarding key (OnboardingView.swift line 686)
    // REMOVED: showMilestoneCardKey - now managed by TrackerCardManager

    private var healthKitNudgeView: AnyView? {
        if showHealthKitNudge && nudgeManager.shouldShowNudge(for: .weight) {
            return AnyView(
                HealthKitNudgeView(
                    dataType: .weight,
                    onConnect: {
                        AppLogger.info("HealthKit nudge - requesting weight authorization", category: AppLogger.healthKit)
                        HealthKitManager.shared.requestWeightAuthorization { success, error in
                            DispatchQueue.main.async {
                                if success {
                                    AppLogger.info("Weight authorization granted from nudge", category: AppLogger.healthKit)
                                    weightManager.syncWithHealthKit = true
                                    showHealthKitNudge = false
                                } else {
                                    AppLogger.info("Weight authorization denied from nudge", category: AppLogger.healthKit)
                                }
                            }
                        }
                    },
                    onDismiss: {
                        AppLogger.info("HealthKit nudge dismissed", category: AppLogger.ui)
                        showHealthKitNudge = false
                        nudgeManager.dismissNudge(for: .weight)
                    }
                )
            )
        }
        return nil
    }

    /// Milestone Ring Card with computed data from weight manager
    /// TODO: Replace placeholder data with actual milestone calculations
    /// UPDATED: Removed onOptOut - now uses DSCard eye-slash dismiss (TrackerCardManager)
    private var milestoneRingCard: some View {
        MilestoneRingCard(
            progress: 0.65,  // TODO: Calculate actual progress to next milestone
            milestoneIndex: 6,  // TODO: Calculate current milestone number
            centerValue: weightManager.latestWeight.map { String(format: "%.1f", weightManager.displayWeight(for: $0)) } ?? "---",
            dateText: weightManager.latestWeight.map { $0.date.formatted(date: .abbreviated, time: .omitted) } ?? "",
            leftStat: "Start weight",  // TODO: Get actual start weight
            midStat: "Progress",  // TODO: Calculate % complete
            rightStat: weightGoal > 0 ? "\(String(format: "%.1f", max(0, (weightManager.latestWeight?.weight ?? weightGoal) - weightGoal))) to go" : "Set goal",
            totalMilestones: 10,
            completedMilestones: 6,  // TODO: Calculate actual milestones completed
            onOptOut: nil  // REMOVED: Now uses DSCard eye-slash dismiss
        )
    }

    var body: some View {
        // 🔍 FORENSIC: Log body render
        let _ = AppLogger.info("⏱️ WeightTrackingView.body rendering", category: AppLogger.ui)

        return TrackerScreenShell(
            title: ("Weight Tr", "ac", "ker"),
            hasData: !weightManager.weightEntries.isEmpty,
            nudge: healthKitNudgeView,
            gradientStyle: .luxury,  // 🔥 LUXURY UI ACTIVATED
            settingsAction: { showingSettings = true }
        ) {
            if weightManager.weightEntries.isEmpty {
                EmptyWeightStateView(
                    showingAddWeight: $showingAddWeight,
                    healthKitManager: healthKitManager,
                    weightManager: weightManager
                )
            } else {
                // Current Weight Card - Using DSCard (Layer 3: Design System)
                // DSCard provides: standardized padding, background, shadow, corners, header with eye-slash
                // Layer 4: Added canExpand for expand/collapse functionality
                // Industry Pattern: Apple Health-style card container with pure content component
                if cardManager.isCardVisible(.currentWeight) {
                    DSCard(
                        cardType: .currentWeight,
                        cardManager: cardManager,
                        canExpand: true  // Layer 4: Enable expand/collapse
                    ) {
                        CurrentWeightCard(
                            weightManager: weightManager,
                            weightGoal: weightGoal,
                            showingGoalEditor: $showingGoalEditor,
                            showingAddWeight: $showingAddWeight,
                            showingTrends: $showingTrends
                        )
                    }
                    .padding(.horizontal, DSSpacing.screenEdgePadding)
                    .transition(.opacity.combined(with: .scale))  // Smooth hide animation
                }

                // Milestone Ring Card - Using DSCard (Layer 3: Design System)
                // DSCard provides: standardized padding, background, shadow, corners, header with eye-slash
                // Layer 4: Added canExpand for expand/collapse functionality
                // Industry Pattern: Apple Health-style card container with pure content component
                // Reference: FastLIFe_WeightTracker_Consolidated_Spec.md §6
                if cardManager.isCardVisible(.milestone) {
                    DSCard(
                        cardType: .milestone,
                        cardManager: cardManager,
                        canExpand: true  // Layer 4: Enable expand/collapse
                    ) {
                        milestoneRingCard
                    }
                    .padding(.horizontal, DSSpacing.screenEdgePadding)
                    .transition(.opacity.combined(with: .scale))
                }

                // Weight Chart Card - Using DSCard (Layer 3: Design System)
                // DSCard provides: standardized padding, background, shadow, corners, header with eye-slash
                // Layer 4: Added canExpand for expand/collapse functionality
                // Industry Pattern: Apple Health-style card container with pure content component
                // UX Fix: Picker relocated to align with time range label (no longer conflicts with eye-slash)
                if cardManager.isCardVisible(.chart) {
                    DSCard(
                        cardType: .chart,
                        cardManager: cardManager,
                        canExpand: true  // Layer 4: Enable expand/collapse
                    ) {
                        WeightChartView(
                            weightManager: weightManager,
                            selectedTimeRange: $selectedTimeRange,
                            showGoalLine: $showGoalLine,
                            weightGoal: $weightGoal
                        )
                    }
                    .padding(.horizontal, DSSpacing.screenEdgePadding)
                    .transition(.opacity.combined(with: .scale))
                }

                // Weight Statistics Card - Using DSCard (Layer 3: Design System)
                // DSCard provides: standardized padding, background, shadow, corners, header with eye-slash
                // Layer 4: Added canExpand for expand/collapse functionality
                // Industry Pattern: Apple Health-style card container with pure content component
                if cardManager.isCardVisible(.stats) {
                    DSCard(
                        cardType: .stats,
                        cardManager: cardManager,
                        canExpand: true  // Layer 4: Enable expand/collapse
                    ) {
                        WeightStatsView(weightManager: weightManager)
                    }
                    .padding(.horizontal, DSSpacing.screenEdgePadding)
                    .transition(.opacity.combined(with: .scale))
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
        .sheet(isPresented: $showingAddWeight) {
            AddWeightView(weightManager: weightManager)
        }
        .sheet(isPresented: $showingSettings) {
            WeightControlCenterView(
                weightManager: weightManager,
                showGoalLine: $showGoalLine,
                weightGoal: $weightGoal
            )
            .environmentObject(behavioralScheduler)
        }
        .sheet(isPresented: $showingGoalEditor) {
            FirstTimeWeightSetupView(
                weightManager: weightManager,
                weightGoal: $weightGoal,
                showGoalLine: $showGoalLine
            )
        }
        .sheet(isPresented: $showingTrends) {
            WeightTrendsView(weightManager: weightManager)
                .onAppear {
                    AppLogger.info("🎯 Progress Story sheet appeared", category: AppLogger.ui)
                }
        }
        .onChange(of: showingTrends) { oldValue, newValue in
            AppLogger.info("🎯 showingTrends changed from \(oldValue) to \(newValue)", category: AppLogger.ui)
        }
        // Removed: HealthDataSelectionView sheet - using direct authorization per Apple HIG
        .sheet(isPresented: $showingFirstTimeSetup) {
            FirstTimeWeightSetupView(
                weightManager: weightManager,
                weightGoal: $weightGoal,
                showGoalLine: $showGoalLine
            )
        }
        .onAppear {
            // 🔍 FORENSIC: Track onAppear start time
            let startTime = CFAbsoluteTimeGetCurrent()
            AppLogger.info("⏱️ WeightTrackingView.onAppear START", category: AppLogger.ui)

            // Load saved goal settings from UserDefaults
            let loadSettingsStart = CFAbsoluteTimeGetCurrent()
            loadGoalSettings()
            let loadSettingsDuration = (CFAbsoluteTimeGetCurrent() - loadSettingsStart) * 1000
            AppLogger.info("⏱️ loadGoalSettings took \(String(format: "%.2f", loadSettingsDuration))ms", category: AppLogger.ui)

            // Show first-time setup if user has no weight data
            // No delay needed - weightManager loads synchronously in init
            if weightManager.weightEntries.isEmpty {
                showingFirstTimeSetup = true
            }

            // Show HealthKit nudge for first-time users who skipped onboarding
            // Following Lose It pattern - contextual reminder on first tracker access
            let nudgeStart = CFAbsoluteTimeGetCurrent()
            showHealthKitNudge = nudgeManager.shouldShowNudge(for: .weight)
            let nudgeDuration = (CFAbsoluteTimeGetCurrent() - nudgeStart) * 1000
            AppLogger.info("⏱️ shouldShowNudge took \(String(format: "%.2f", nudgeDuration))ms", category: AppLogger.ui)

            if showHealthKitNudge {
                AppLogger.info("Showing HealthKit nudge for first-time user", category: AppLogger.ui)
            }

            // Note: Removed auto-authorization logic - now uses nudge banner pattern like HydrationTrackingView
            // User must explicitly tap "Connect" in nudge banner to authorize
            // This follows Lose It app pattern and Apple HIG contextual permission guidelines

            // 🔍 FORENSIC: Track total onAppear duration
            let totalDuration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            AppLogger.info("⏱️ WeightTrackingView.onAppear TOTAL: \(String(format: "%.2f", totalDuration))ms", category: AppLogger.ui)
        }
        .task {
            // Auto-show Progress Story with delay to prevent cold start freeze
            // Delay allows Weight Tracker view to render fully before presenting sheet
            // Industry pattern: Deferred engagement to prevent UI blocking
            // Reference: Apple HIG - Launching (avoid blocking UI on startup)
            guard !weightManager.weightEntries.isEmpty else { return }

            let contentID = "progress_story_trends_v1"
            let isOptedOut = ContentOptOutManager.shared.isContentOptedOut(id: contentID)

            guard !isOptedOut else {
                AppLogger.info("🎯 Progress Story opted out - skipping auto-show", category: AppLogger.ui)
                return
            }

            // Delay 0.6 seconds to let view render + animations settle
            try? await Task.sleep(nanoseconds: 600_000_000)  // 0.6 seconds

            await MainActor.run {
                AppLogger.info("🎯 Auto-showing Progress Story on Weight Tracker open (delayed)", category: AppLogger.ui)
                showingTrends = true
            }
        }
        .onChange(of: showGoalLine) { _, _ in
            saveGoalSettings()
        }
        .onChange(of: weightGoal) { _, _ in
            saveGoalSettings()
        }
    }

    // MARK: - Goal Settings Persistence

    private func loadGoalSettings() {
        // Load show goal line preference (default: false)
        showGoalLine = UserDefaults.standard.bool(forKey: showGoalLineKey)

        // Load weight goal (default: 180.0 if not set)
        if let savedGoal = UserDefaults.standard.object(forKey: weightGoalKey) as? Double {
            weightGoal = savedGoal
        }

        // REMOVED: Milestone card visibility - now managed by TrackerCardManager
    }

    func saveGoalSettings() {
        UserDefaults.standard.set(showGoalLine, forKey: showGoalLineKey)
        UserDefaults.standard.set(weightGoal, forKey: weightGoalKey)
    }

    // REMOVED: saveMilestoneVisibility() - now managed by TrackerCardManager

    // Removed: handleHealthDataSelection - no longer needed with direct authorization
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
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Weight Data Yet")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("Add your first weight entry or sync with Apple Health")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button(action: { showingAddWeight = true }) {
                    Label("Add Weight Manually", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("FLPrimary"))
                        .cornerRadius(8)
                }

                Button(action: {
                    // DIRECT AUTHORIZATION: Apple HIG contextual permission pattern
                    // Request weight permissions immediately when user wants to sync weight data
                    AppLogger.info("EmptyState: Sync button tapped - requesting weight authorization", category: AppLogger.healthKit)
                    HealthKitManager.shared.requestWeightAuthorization { success, error in
                        if success {
                            AppLogger.info("EmptyState: Weight authorization granted - starting sync", category: AppLogger.healthKit)
                            DispatchQueue.main.async {
                                weightManager.syncFromHealthKit()
                            }
                        } else {
                            AppLogger.info("EmptyState: Weight authorization denied", category: AppLogger.healthKit)
                        }
                    }
                }) {
                    Label("Sync with Apple Health", systemImage: "heart.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("FLSuccess"))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 60)
        // Removed: HealthDataSelectionView sheet - using direct authorization per Apple HIG
    }

    // Removed: handleHealthDataSelection - no longer needed with direct authorization
}




// MARK: - View Modifier for Conditional X-Axis Scale




#Preview {
    WeightTrackingView()
}
