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
            // Luxury gradient background (matches Weight Tracker)
            LinearGradient(
                colors: [
                    Theme.ColorToken.bgDeepStart,
                    Theme.ColorToken.bgDeepMid
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header section (fixed at top)
                VStack(spacing: DSSpacing.cardExtraSmallSpacing) {
                    // ISSUE #5 FIX: Add visible Done button in header
                    // Toolbar buttons don't render reliably in sheet presentations
                    // Following Apple Health pattern - prominent action button in header
                    HStack {
                        Spacer()

                        // UX/UI Fix #3: Match Weight Tracker title size (34pt)
                        // Issue #1: Center title + apply Weight Tracker cyan gradient styling
                        Text("Control Center")
                            .font(DSTypography.screenTitle)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Theme.ColorToken.accentCyan,
                                        Theme.ColorToken.accentLightBlue
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Spacer()

                        // Visible Done button (replaces unreliable toolbar button)
                        Button(action: handleDoneButtonTap) {
                            Text("Done")
                                .font(DSTypography.buttonPrimary)
                                .foregroundColor(Theme.ColorToken.accentCyan)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, DSSpacing.cardSectionSpacing)
                    .padding(.top, DSSpacing.cardSmallSpacing)

                    // REFINEMENT #1: Split instructions into 2 lines
                    // Behavioral Science: Chunking for cognitive fluency
                    // UX/UI Fix #4: Increased subtitle font sizes for accessibility
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Customize your Weight Tracker experience.")
                            .font(DSTypography.subtitleLarge)  // Increased from 17
                            .foregroundColor(Theme.ColorToken.textSecondary)

                        Text("Drag cards to reorder.")
                            .font(DSTypography.subtitleEmphasized)  // Increased from 16
                            .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DSSpacing.cardSectionSpacing)
                    .padding(.bottom, DSSpacing.cardElementSpacing)
                }

                // ScrollView with reorderable cards (Hub pattern - perfect alignment)
                // Using .onDrag/.onDrop instead of List+.onMove to avoid layout issues
                // Reference: HubView.swift lines 65-88
                // Layer 3: Wrapped in ScrollViewReader for smooth scroll-to-item functionality
                // ISSUE #4 FIX: Add tap gesture to dismiss keyboard (Apple Health pattern)
                ScrollView {
                    ScrollViewReader { proxy in
                        LazyVStack(spacing: DSSpacing.cardSectionSpacing) {
                            ForEach(viewModel.cardOrder) { cardType in
                                cardView(for: cardType)
                            }

                            // About section (fixed at bottom)
                            WeightControlCenterAboutCard(viewModel: viewModel)
                        }
                        .padding(.horizontal, DSSpacing.cardSectionSpacing)  // Single container padding (Hub pattern)
                        .padding(.top, DSSpacing.cardSmallSpacing)
                        .onAppear {
                            // Capture ScrollViewProxy for badge interaction
                            viewModel.scrollViewProxy = proxy
                        }
                    }
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
                    if let newGoal = Double(viewModel.weightGoalString), newGoal > 0 {
                        weightGoal = newGoal
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
            viewModel.weightGoalString = String(format: "%.1f", weightGoal)
            // ISSUE #5: Store original goal weight for change detection
            originalGoalWeight = viewModel.weightGoalString
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
                viewModel.weightGoalString = originalGoalWeight
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                // Stay in Control Center with edited value
            }
            Button("Save") {
                // Persist via WeightManager and dismiss
                if let newGoal = Double(viewModel.weightGoalString), newGoal > 0 {
                    let goalWeightPounds = viewModel.weightManager.convertToInternalUnit(newGoal)
                    viewModel.weightManager.setGoalWeight(goalWeightPounds)
                    weightGoal = newGoal
                    AppLogger.info("Goal weight saved: \(goalWeightPounds) lbs (displayed as \(newGoal) \(viewModel.unitAbbreviation))", category: AppLogger.weightTracking)
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
        if viewModel.weightGoalString != originalGoalWeight {
            // Show save confirmation alert
            showUnsavedChangesAlert = true
        } else {
            // No changes, dismiss directly
            dismiss()
        }
    }

    // MARK: - Card Views

    @ViewBuilder
    private func cardView(for cardType: ControlCenterCardType) -> some View {
        WeightControlCenterCard(
            cardType: cardType,
            viewModel: viewModel,
            title: cardType.title,
            subtitle: cardSubtitle(for: cardType),
            icon: cardType.icon
        ) {
            switch cardType {
            case .goals:
                WeightControlCenterGoalsCard(
                    viewModel: viewModel,
                    showGoalLine: $showGoalLine,
                    weightGoal: $weightGoal
                )
            case .notifications:
                WeightControlCenterNotificationsCard(viewModel: viewModel)
            case .sync:
                WeightControlCenterSyncCard(
                    viewModel: viewModel,
                    showDeleteAllConfirmation: $showDeleteAllConfirmation
                )
            case .insights:
                WeightControlCenterInsightsCard()
            case .experience:
                WeightControlCenterExperienceCard(viewModel: viewModel)
            case .history:
                WeightControlCenterHistoryCard(viewModel: viewModel)
            }
        }
    }

    private func cardSubtitle(for type: ControlCenterCardType) -> String? {
        switch type {
        case .goals:
            return "Set your start point, goal, and milestones"
        case .notifications:
            return "Fine-tune reminders so they feel personal"
        case .insights:
            return "Choose the guidance you want to see most"
        case .sync:
            return "Control how Apple Health powers your data"
        case .history:
            return "Review and manage logged weight entries"
        case .experience:
            return "Opt in to the motivation styles that work for you"
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
