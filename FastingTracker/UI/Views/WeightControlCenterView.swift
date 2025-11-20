import SwiftUI

// MARK: - Weight Control Center View

/// Weight Control Center - Premium card-based settings with reorderable cards
/// Reference: FAST-LIFe_Control_Center_Vision.md
/// Behavioral psychology: User personalization (IKEA effect)
/// Pattern: MVVM (ViewModel handles state and business logic)
struct WeightControlCenterView: View {
    @Environment(\.weightDependencies) private var dependencies
    @Binding private var showGoalLine: Bool
    @Binding private var weightGoal: Double

    init(showGoalLine: Binding<Bool>,
         weightGoal: Binding<Double>) {
        _showGoalLine = showGoalLine
        _weightGoal = weightGoal
    }

    var body: some View {
        WeightControlCenterExperienceView(
            showGoalLine: $showGoalLine,
            weightGoal: $weightGoal,
            dependencies: dependencies
        )
    }
}

@MainActor
private struct WeightControlCenterExperienceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WeightControlCenterViewModel
    @Binding var showGoalLine: Bool
    @Binding var weightGoal: Double
    @State private var showDeleteAllConfirmation = false
    @State private var originalGoalWeightPounds: Double?
    @State private var showUnsavedChangesAlert = false

    init(showGoalLine: Binding<Bool>,
         weightGoal: Binding<Double>,
         dependencies: WeightDependencies) {
        _showGoalLine = showGoalLine
        _weightGoal = weightGoal
        _viewModel = StateObject(
            wrappedValue: dependencies.makeControlCenterViewModel()
        )
    }

    var body: some View {
        ZStack {
            WeightControlCenterGradientBackground()

            VStack(spacing: 0) {
                WeightControlCenterHeaderView(onDone: handleDoneButtonTap)
                ScrollView {
                    WeightControlCenterCardList(
                        viewModel: viewModel,
                        showGoalLine: $showGoalLine,
                        weightGoal: $weightGoal,
                        showDeleteAllConfirmation: $showDeleteAllConfirmation
                    )
                }
                .simultaneousGesture(
                    TapGesture().onEnded { _ in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done", action: dismissDirect)
                    .foregroundColor(Theme.ColorToken.textPrimary)
                    .fontWeight(.semibold)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundColor(Theme.ColorToken.accentPrimary)
                .fontWeight(.semibold)
            }
        }
        .onAppear(perform: prepareView)
        .alert("Sync Status", isPresented: $viewModel.showingSyncAlert, actions: syncAlertActions, message: { Text(viewModel.syncMessage) })
        .alert("Import Weight Data", isPresented: $viewModel.showingSyncPreferenceDialog, actions: importDialogActions, message: {
            Text("Choose how to sync your weight data with Apple Health. You can import all your historical weight entries or start fresh with only future entries.")
        })
        .alert("Restore All Content", isPresented: $viewModel.showingRestoreAllAlert, actions: restoreAllActions, message: {
            Text("This will restore all hidden tracker cards and opted-out content to default. Are you sure?")
        })
        .confirmationDialog("Delete All Weight Data?", isPresented: $showDeleteAllConfirmation, actions: deleteAllActions, message: {
            Text("This will delete all \(viewModel.weightManager.weightEntries.count) weight entries from Fast LIFe. You can resync from HealthKit afterward. This action cannot be undone.")
        })
        .alert("Save Goal Weight Changes?", isPresented: $showUnsavedChangesAlert, actions: saveChangesActions, message: {
            Text("You've changed your goal weight. Would you like to save this change?")
        })
    }

    private func dismissDirect() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        dismiss()
    }

    private func prepareView() {
        viewModel.loadCardOrder()
        viewModel.loadExpandedCards()
        viewModel.loadOptedOutContent()
        viewModel.goalCoordinator.synchronizeGoalWeightDisplay()
        originalGoalWeightPounds = viewModel.weightManager.goalWeight > 0 ? viewModel.weightManager.goalWeight : nil
        viewModel.userSyncPreference = viewModel.weightManager.syncWithHealthKit
        viewModel.updatePermissionStatus()
        viewModel.loadLastSyncStatus()
        viewModel.updateToggleState()
    }

    @ViewBuilder
    private func syncAlertActions() -> some View {
        Group {
            if viewModel.syncMessage.contains("Permission denied") || viewModel.syncMessage.contains("enable weight access") {
                let authStatus = viewModel.healthKitManager.getWeightAuthorizationStatus()
                if authStatus == .notDetermined {
                    Button("Try Again") { viewModel.syncWithHealthKit() }
                } else {
                    Button("OK") { }
                }
                Button("Cancel", role: .cancel) { }
            } else {
                Button("OK", role: .cancel) { }
            }
        }
    }

    @ViewBuilder
    private func importDialogActions() -> some View {
        Group {
            Button("Import All Historical Data") { viewModel.performHistoricalSync() }
            Button("Future Data Only") { viewModel.performFutureOnlySync() }
            Button("Cancel", role: .cancel) {
                viewModel.userSyncPreference = false
                viewModel.localSyncEnabled = false
                viewModel.updateToggleState()
            }
        }
    }

    @ViewBuilder
    private func restoreAllActions() -> some View {
        Group {
            Button("Yes, Restore All", role: .destructive) { viewModel.restoreAllToDefault() }
            Button("Cancel", role: .cancel) { }
        }
    }

    @ViewBuilder
    private func deleteAllActions() -> some View {
        Group {
            Button("Delete All Data", role: .destructive) { viewModel.deleteAllWeightData() }
            Button("Cancel", role: .cancel) { }
        }
    }

    @ViewBuilder
    private func saveChangesActions() -> some View {
        Group {
            Button("Don't Save", role: .destructive) {
                viewModel.goalCoordinator.weightGoalString = storedGoalDisplayString()
                WeightTrackerMetrics.recordGoalEvent(.goalWeightDiscarded, metadata: ["source": "control_center"])
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if let newGoal = Double(viewModel.goalCoordinator.weightGoalString), newGoal > 0 {
                    let goalWeightPounds = viewModel.weightManager.convertToInternalUnit(newGoal)
                    viewModel.weightManager.setGoalWeight(goalWeightPounds)
                    originalGoalWeightPounds = goalWeightPounds
                    weightGoal = newGoal
                    AppLogger.info("Goal weight saved via Control Center", category: AppLogger.weightTracking)
                    WeightTrackerMetrics.recordGoalEvent(.goalWeightSaved, metadata: ["source": "control_center"])
                }
                dismiss()
            }
        }
    }

    private func storedGoalDisplayString() -> String {
        guard let stored = originalGoalWeightPounds, stored > 0 else { return "" }
        return viewModel.weightManager.formattedDisplayWeight(stored)
    }

    private func handleDoneButtonTap() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        if viewModel.goalCoordinator.weightGoalString != storedGoalDisplayString() {
            showUnsavedChangesAlert = true
        } else {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        WeightControlCenterView(
            showGoalLine: .constant(true),
            weightGoal: .constant(150.0)
        )
        .environment(\.weightDependencies, .preview())
    }
}
