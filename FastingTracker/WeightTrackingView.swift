import SwiftUI
import Charts

struct WeightTrackingView: View {
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var behavioralScheduler: BehavioralNotificationScheduler
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject private var nudgeManager = HealthKitNudgeManager.shared

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

    // UserDefaults keys for persistence
    private let showGoalLineKey = "showGoalLine"
    private let weightGoalKey = "goalWeight"  // MUST match onboarding key (OnboardingView.swift line 686)

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

    var body: some View {
        TrackerScreenShell(
            title: ("Weight Tr", "ac", "ker"),
            hasData: !weightManager.weightEntries.isEmpty,
            nudge: healthKitNudgeView,
            settingsAction: { showingSettings = true }
        ) {
            if weightManager.weightEntries.isEmpty {
                EmptyWeightStateView(
                    showingAddWeight: $showingAddWeight,
                    healthKitManager: healthKitManager,
                    weightManager: weightManager
                )
            } else {
                // Current Weight Card
                CurrentWeightCard(
                    weightManager: weightManager,
                    weightGoal: weightGoal,
                    showingGoalEditor: $showingGoalEditor,
                    showingAddWeight: $showingAddWeight,
                    showingTrends: $showingTrends
                )
                .padding(.horizontal)

                // Weight Chart
                WeightChartView(
                    weightManager: weightManager,
                    selectedTimeRange: $selectedTimeRange,
                    showGoalLine: $showGoalLine,
                    weightGoal: $weightGoal
                )
                .padding(.horizontal)

                // Weight Statistics
                WeightStatsView(weightManager: weightManager)
                    .padding(.horizontal)

                // Weight History List
                WeightHistoryListView(weightManager: weightManager)
                    .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingAddWeight) {
            AddWeightView(weightManager: weightManager)
        }
        .sheet(isPresented: $showingSettings) {
            WeightSettingsView(
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
            // Load saved goal settings from UserDefaults
            loadGoalSettings()

            // Show first-time setup if user has no weight data
            // No delay needed - weightManager loads synchronously in init
            if weightManager.weightEntries.isEmpty {
                showingFirstTimeSetup = true
            }

            // Show HealthKit nudge for first-time users who skipped onboarding
            // Following Lose It pattern - contextual reminder on first tracker access
            showHealthKitNudge = nudgeManager.shouldShowNudge(for: .weight)
            if showHealthKitNudge {
                AppLogger.info("Showing HealthKit nudge for first-time user", category: AppLogger.ui)
            }

            // Note: Removed auto-authorization logic - now uses nudge banner pattern like HydrationTrackingView
            // User must explicitly tap "Connect" in nudge banner to authorize
            // This follows Lose It app pattern and Apple HIG contextual permission guidelines
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
    }

    func saveGoalSettings() {
        UserDefaults.standard.set(showGoalLine, forKey: showGoalLineKey)
        UserDefaults.standard.set(weightGoal, forKey: weightGoalKey)
    }

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
