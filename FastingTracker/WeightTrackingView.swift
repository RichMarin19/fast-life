import Charts
import SwiftUI

struct WeightTrackingView: View {
    @StateObject private var weightManager = WeightManager()
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject private var nudgeManager = HealthKitNudgeManager.shared

    // PHASE 1: Unit preferences integration
    // Following Apple's reactive UI pattern for settings changes
    // Reference: https://developer.apple.com/documentation/swiftui/observedobject
    // Unit preferences removed for v1.0 - will add in v1.1
    @State private var showingAddWeight = false
    @State private var showingSettings = false
    @State private var showingFirstTimeSetup = false
    @State private var showingGoalEditor = false // Quick access goal editor
    @State private var showingTrends = false // Weight trends detail view
    @State private var selectedTimeRange: WeightTimeRange = .month
    @State private var showGoalLine = false
    @State private var weightGoal: Double = 180.0
    @State private var showHealthKitNudge = false

    // UserDefaults keys for persistence
    private let showGoalLineKey = "showGoalLine"
    private let weightGoalKey = "goalWeight" // MUST match onboarding key (OnboardingView.swift line 686)

    private var healthKitNudgeView: AnyView? {
        if self.showHealthKitNudge, self.nudgeManager.shouldShowNudge(for: .weight) {
            return AnyView(
                HealthKitNudgeView(
                    dataType: .weight,
                    onConnect: {
                        print("📱 WeightTrackingView: HealthKit nudge - requesting weight authorization")
                        HealthKitManager.shared.requestWeightAuthorization { success, error in
                            DispatchQueue.main.async {
                                if success {
                                    print("✅ WeightTrackingView: Weight authorization granted from nudge")
                                    self.weightManager.syncWithHealthKit = true
                                    self.showHealthKitNudge = false
                                } else {
                                    print("❌ WeightTrackingView: Weight authorization denied from nudge")
                                }
                            }
                        }
                    },
                    onDismiss: {
                        print("📱 WeightTrackingView: HealthKit nudge dismissed")
                        self.showHealthKitNudge = false
                        self.nudgeManager.dismissNudge(for: .weight)
                    }
                )
            )
        }
        return nil
    }

    var body: some View {
        TrackerScreenShell(
            title: ("Weight Tr", "ac", "ker"),
            hasData: !self.weightManager.weightEntries.isEmpty,
            nudge: self.healthKitNudgeView,
            settingsAction: { self.showingSettings = true }
        ) {
            if self.weightManager.weightEntries.isEmpty {
                EmptyWeightStateView(
                    showingAddWeight: self.$showingAddWeight,
                    healthKitManager: self.healthKitManager,
                    weightManager: self.weightManager
                )
            } else {
                // Current Weight Card
                CurrentWeightCard(
                    weightManager: self.weightManager,
                    weightGoal: self.weightGoal,
                    showingGoalEditor: self.$showingGoalEditor,
                    showingAddWeight: self.$showingAddWeight,
                    showingTrends: self.$showingTrends
                )
                .padding(.horizontal)

                // Weight Chart
                WeightChartView(
                    weightManager: self.weightManager,
                    selectedTimeRange: self.$selectedTimeRange,
                    showGoalLine: self.$showGoalLine,
                    weightGoal: self.$weightGoal
                )
                .padding(.horizontal)

                // Weight Statistics
                WeightStatsView(weightManager: self.weightManager)
                    .padding(.horizontal)

                // Weight History List
                WeightHistoryListView(weightManager: self.weightManager)
                    .padding(.horizontal)
            }
        }
        .sheet(isPresented: self.$showingAddWeight) {
            AddWeightView(weightManager: self.weightManager)
        }
        .sheet(isPresented: self.$showingSettings) {
            WeightSettingsView(
                weightManager: self.weightManager,
                showGoalLine: self.$showGoalLine,
                weightGoal: self.$weightGoal
            )
        }
        .sheet(isPresented: self.$showingGoalEditor) {
            FirstTimeWeightSetupView(
                weightManager: self.weightManager,
                weightGoal: self.$weightGoal,
                showGoalLine: self.$showGoalLine
            )
        }
        .sheet(isPresented: self.$showingTrends) {
            WeightTrendsView(weightManager: self.weightManager)
        }
        // Removed: HealthDataSelectionView sheet - using direct authorization per Apple HIG
        .sheet(isPresented: self.$showingFirstTimeSetup) {
            FirstTimeWeightSetupView(
                weightManager: self.weightManager,
                weightGoal: self.$weightGoal,
                showGoalLine: self.$showGoalLine
            )
        }
        .onAppear {
            // Load saved goal settings from UserDefaults
            self.loadGoalSettings()

            // Show first-time setup if user has no weight data
            // No delay needed - weightManager loads synchronously in init
            if self.weightManager.weightEntries.isEmpty {
                self.showingFirstTimeSetup = true
            }

            // Show HealthKit nudge for first-time users who skipped onboarding
            // Following Lose It pattern - contextual reminder on first tracker access
            self.showHealthKitNudge = self.nudgeManager.shouldShowNudge(for: .weight)
            if self.showHealthKitNudge {
                print("📱 WeightTrackingView: Showing HealthKit nudge for first-time user")
            }

            // Note: Removed auto-authorization logic - now uses nudge banner pattern like HydrationTrackingView
            // User must explicitly tap "Connect" in nudge banner to authorize
            // This follows Lose It app pattern and Apple HIG contextual permission guidelines
        }
        .onChange(of: self.showGoalLine) { _, _ in
            self.saveGoalSettings()
        }
        .onChange(of: self.weightGoal) { _, _ in
            self.saveGoalSettings()
        }
    }

    // MARK: - Goal Settings Persistence

    private func loadGoalSettings() {
        // Load show goal line preference (default: false)
        self.showGoalLine = UserDefaults.standard.bool(forKey: self.showGoalLineKey)

        // Load weight goal (default: 180.0 if not set)
        if let savedGoal = UserDefaults.standard.object(forKey: weightGoalKey) as? Double {
            self.weightGoal = savedGoal
        }
    }

    func saveGoalSettings() {
        UserDefaults.standard.set(self.showGoalLine, forKey: self.showGoalLineKey)
        UserDefaults.standard.set(self.weightGoal, forKey: self.weightGoalKey)
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
                Button(action: { self.showingAddWeight = true }) {
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
                    print(
                        "📱 WeightTrackingView (EmptyState): Sync button tapped - requesting weight authorization directly"
                    )
                    HealthKitManager.shared.requestWeightAuthorization { success, error in
                        if success {
                            print("✅ WeightTrackingView (EmptyState): Weight authorization granted - starting sync")
                            DispatchQueue.main.async {
                                self.weightManager.syncFromHealthKit()
                            }
                        } else {
                            print("❌ WeightTrackingView (EmptyState): Weight authorization denied")
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
