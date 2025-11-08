import SwiftUI

// MARK: - Weight Control Center View

/// Weight Control Center - Premium card-based settings with reorderable cards
/// Reference: FAST-LIFe_Control_Center_Vision.md
/// Behavioral psychology: User personalization (IKEA effect)
/// Pattern: MVVM (ViewModel handles state and business logic)
struct WeightControlCenterView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: WeightControlCenterViewModel
    @Binding var showGoalLine: Bool
    @Binding var weightGoal: Double
    @State private var showDeleteAllConfirmation = false

    // ISSUE #5: Track goal weight changes for save confirmation
    @State private var originalGoalWeight: String = ""
    @State private var showUnsavedChangesAlert = false

    // MARK: - Initialization

    init(weightManager: WeightManager,
         showGoalLine: Binding<Bool>,
         weightGoal: Binding<Double>) {
        // TEMPORARY: Using temporary BehavioralNotificationScheduler instance
        // The real instance is passed via .environmentObject in WeightTrackingView.swift:139
        // This temporary instance is only used for ViewModel initialization and won't be used
        _viewModel = StateObject(wrappedValue: WeightControlCenterViewModel(
            weightManager: weightManager,
            behavioralScheduler: BehavioralNotificationScheduler()
        ))
        _showGoalLine = showGoalLine
        _weightGoal = weightGoal
    }

    var body: some View {
        ZStack {
            WeightControlCenterGradientBackground()

            VStack(spacing: 0) {
                WeightControlCenterHeaderView(onDone: handleDoneButtonTap)

                // ScrollView with reorderable cards (Hub pattern - perfect alignment)
                // WeightControlCenterCardList owns the ScrollViewReader + drag/drop wiring
                // ISSUE #4 FIX: Add tap gesture to dismiss keyboard (Apple Health pattern)
                ScrollView {
                    WeightControlCenterCardList(
                        viewModel: viewModel,
                        showGoalLine: $showGoalLine,
                        weightGoal: $weightGoal,
                        showDeleteAllConfirmation: $showDeleteAllConfirmation
                    )
                }
                // ISSUE #4 FIX: Dismiss keyboard when tapping content
                // Following Apple Health pattern - keyboard dismisses on content tap
                // Reference: Apple HIG - Keyboard Dismissal Best Practices
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    // Dismiss keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

                    // Update weight goal if valid
                    if let displayGoal = Double(viewModel.goalCoordinator.weightGoalString), displayGoal > 0 {
                        let internalGoal = viewModel.weightManager.convertToInternalUnit(displayGoal)
                        weightGoal = internalGoal
                        viewModel.goalCoordinator.synchronizeGoalWeightDisplay()
                    }
                    dismiss()
                }
                .foregroundColor(Theme.ColorToken.textPrimary)
                .fontWeight(.semibold)
            }

            // Keyboard toolbar for decimal pad
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundColor(Theme.ColorToken.accentPrimary)
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            viewModel.loadCardOrder()
            viewModel.loadExpandedCards()
            viewModel.loadOptedOutContent()
            viewModel.goalCoordinator.synchronizeGoalWeightDisplay()
            // ISSUE #5: Store original goal weight for change detection
            originalGoalWeight = viewModel.goalCoordinator.weightGoalString
            viewModel.userSyncPreference = viewModel.weightManager.syncWithHealthKit
            viewModel.updatePermissionStatus()
            viewModel.loadLastSyncStatus()
            viewModel.updateToggleState()
        }
        .alert("Sync Status", isPresented: $viewModel.showingSyncAlert) {
            if viewModel.syncMessage.contains("Permission denied") || viewModel.syncMessage.contains("enable weight access") {
                let authStatus = HealthKitManager.shared.getWeightAuthorizationStatus()

                if authStatus == .notDetermined {
                    Button("Try Again") {
                        viewModel.syncWithHealthKit()
                    }
                } else {
                    Button("OK") { }
                }
                Button("Cancel", role: .cancel) { }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            Text(viewModel.syncMessage)
        }
        .alert("Import Weight Data", isPresented: $viewModel.showingSyncPreferenceDialog) {
            Button("Import All Historical Data") {
                viewModel.performHistoricalSync()
            }
            Button("Future Data Only") {
                viewModel.performFutureOnlySync()
            }
            Button("Cancel", role: .cancel) {
                viewModel.userSyncPreference = false
                viewModel.localSyncEnabled = false
                viewModel.updateToggleState()
            }
        } message: {
            Text("Choose how to sync your weight data with Apple Health. You can import all your historical weight entries or start fresh with only future entries.")
        }
        .alert("Restore All Content", isPresented: $viewModel.showingRestoreAllAlert) {
            Button("Yes, Restore All", role: .destructive) {
                viewModel.restoreAllToDefault()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will restore all hidden tracker cards and opted-out content to default. Are you sure?")
        }
        .confirmationDialog("Delete All Weight Data?", isPresented: $showDeleteAllConfirmation) {
            Button("Delete All Data", role: .destructive) {
                viewModel.weightManager.deleteAllWeightData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will delete all \(viewModel.weightManager.weightEntries.count) weight entries from Fast LIFe. You can resync from HealthKit afterward. This action cannot be undone.")
        }
        .alert("Save Goal Weight Changes?", isPresented: $showUnsavedChangesAlert) {
            // ISSUE #5: Save confirmation dialog following Apple Settings app pattern
            // Reference: Apple HIG - Alerts (three-button confirmation for data loss prevention)
            Button("Don't Save", role: .destructive) {
                // Revert to original value
                viewModel.goalCoordinator.weightGoalString = originalGoalWeight
                WeightTrackerMetrics.recordGoalEvent(.goalWeightDiscarded, metadata: ["source": "control_center"])
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                // Stay in Control Center with edited value
            }
            Button("Save") {
                // Persist via WeightManager and dismiss
                if let newGoal = Double(viewModel.goalCoordinator.weightGoalString), newGoal > 0 {
                    let goalWeightPounds = viewModel.weightManager.convertToInternalUnit(newGoal)
                    viewModel.weightManager.setGoalWeight(goalWeightPounds)
                    weightGoal = newGoal
                    AppLogger.info("Goal weight saved via Control Center", category: AppLogger.weightTracking)
                    WeightTrackerMetrics.recordGoalEvent(.goalWeightSaved, metadata: ["source": "control_center"])
                }
                dismiss()
            }
        } message: {
            Text("You've changed your goal weight. Would you like to save this change?")
        }
    }

    // MARK: - Actions

    /// Handle Done button tap - check for unsaved goal weight changes
    /// Following Apple Settings app pattern for unsaved changes confirmation
    private func handleDoneButtonTap() {
        // Dismiss keyboard first
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        // Check if goal weight has changed
        if viewModel.goalCoordinator.weightGoalString != originalGoalWeight {
            // Show save confirmation alert
            showUnsavedChangesAlert = true
        } else {
            // No changes, dismiss directly
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        WeightControlCenterView(
            weightManager: WeightManager(),
            showGoalLine: .constant(true),
            weightGoal: .constant(150.0)
        )
        .environmentObject(BehavioralNotificationScheduler())
    }
}
