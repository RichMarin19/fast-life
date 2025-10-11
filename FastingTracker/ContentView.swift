import SwiftUI

struct ContentView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @StateObject private var nudgeManager = HealthKitNudgeManager.shared
    @State private var showingGoalSettings = false
    @State private var showingStopConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEditTimes = false
    @State private var showingEditStartTime = false
    @State private var selectedStage: FastingStage?
    @State private var showHealthKitNudge = false
    @State private var showingSyncOptions = false
    @State private var selectedDate: Date?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 30)

                    // HealthKit Nudge for first-time users who skipped onboarding
                    if showHealthKitNudge && nudgeManager.shouldShowNudge(for: .fasting) {
                        FastingHealthKitNudgeView(
                            onConnect: { requestBasicHealthKitAccess() },
                            onDismiss: {
                                nudgeManager.dismissNudge(for: .fasting)
                                showHealthKitNudge = false
                            },
                            onPermanentDismiss: {
                                nudgeManager.permanentlyDismissTimerNudge()
                                showHealthKitNudge = false
                            }
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }

                    // Fast LIFe Title
                    FastingTrackerTitleView()

                    // Fast State Display
                    FastingStateView(
                        showingStopConfirmation: $showingStopConfirmation,
                        showingGoalSettings: $showingGoalSettings,
                        showingSyncOptions: $showingSyncOptions,
                        selectedStage: $selectedStage
                    )

                    // History Content
                    FastingHistoryContentView(selectedDate: $selectedDate)
                }
            }
            .onAppear {
                handleViewAppearance()
            }
            .sheet(isPresented: $showingGoalSettings) {
                GoalSettingsView()
            }
            .sheet(isPresented: $showingStopConfirmation) {
                StopFastConfirmationView(
                    onEditTimes: {
                        showingStopConfirmation = false
                        showingEditTimes = true
                    },
                    onStop: { handleStopFast() },
                    onDelete: { handleDeleteFast() },
                    onCancel: { showingStopConfirmation = false }
                )
            }
            .sheet(isPresented: $showingEditTimes) {
                EditFastTimesView()
            }
            .sheet(isPresented: $showingSyncOptions) {
                FastingSyncOptionsView()
            }
            .sheet(item: $selectedStage) { stage in
                FastingStageDetailView(stage: stage)
            }
        }
    }

    // MARK: - Helper Methods

    private func handleViewAppearance() {
        // Check if we should show HealthKit nudge
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if nudgeManager.shouldShowNudge(for: .fasting) {
                showHealthKitNudge = true
            }
        }
    }

    private func requestBasicHealthKitAccess() {
        Task {
            do {
                try await HealthKitManager.shared.requestFastingAuthorization()
                nudgeManager.markPermissionGranted(for: .fasting)
                showHealthKitNudge = false
            } catch {
                AppLogger.error("Failed to request HealthKit authorization", category: AppLogger.healthKit, error: error)
            }
        }
    }

    private func handleStopFast() {
        showingStopConfirmation = false
        fastingManager.stopFast()
    }

    private func handleDeleteFast() {
        showingStopConfirmation = false
        fastingManager.deleteCurrentFast()
    }
}