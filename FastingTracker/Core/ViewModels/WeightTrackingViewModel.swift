import SwiftUI
import Combine

/// ViewModel for Weight Tracking View
/// Industry Pattern: MVVM (Apple WWDC 2023 recommendation)
/// Extracts state and business logic from WeightTrackingView
/// Reference: ARCHITECTURE-AUDIT.md - Critical Task 1
/// Gold Standard: WeightControlCenterViewModel (903 LOC)
@MainActor
class WeightTrackingViewModel: ObservableObject {
    // MARK: - Dependencies (Injected)

    let weightManager: WeightManager
    let behavioralScheduler: BehavioralNotificationScheduler

    // Singleton managers (pass-through)
    let healthKitManager = HealthKitManager.shared
    let nudgeManager = HealthKitNudgeManager.shared
    let cardManager = TrackerCards.shared

    // MARK: - Published State (was @State in View)

    // Sheet presentation
    @Published var showingAddWeight = false
    @Published var showingSettings = false
    @Published var showingFirstTimeSetup = false
    @Published var showingGoalEditor = false
    @Published var showingTrends = false

    // Goal settings
    @Published var showGoalLine = false
    @Published var weightGoal: Double = 180.0

    // HealthKit nudge
    @Published var showHealthKitNudge = false

    // Time range selection
    @Published var selectedTimeRange: WeightTimeRange = .month

    // Drag-to-reorder state
    @Published var draggedCard: TrackerCardType?

    // MARK: - Private Properties (UserDefaults persistence)

    private let userDefaults = UserDefaults.standard

    // UserDefaults keys for persistence
    private let showGoalLineKey = "showGoalLine"
    private let weightGoalKey = "goalWeight"  // MUST match onboarding key (OnboardingView.swift line 686)

    // MARK: - Initialization

    init(weightManager: WeightManager, behavioralScheduler: BehavioralNotificationScheduler) {
        self.weightManager = weightManager
        self.behavioralScheduler = behavioralScheduler

        // Load persisted state
        loadGoalSettings()
    }

    // MARK: - Computed Properties

    /// Check if we should show HealthKit nudge banner
    var shouldShowHealthKitNudge: Bool {
        return showHealthKitNudge && nudgeManager.shouldShowNudge(for: .weight)
    }

    /// Check if weight data is empty (for first-time setup)
    var hasNoWeightData: Bool {
        return weightManager.weightEntries.isEmpty
    }

    // MARK: - Goal Settings Persistence

    /// Load goal settings from UserDefaults
    func loadGoalSettings() {
        // Load show goal line preference (default: false)
        showGoalLine = userDefaults.bool(forKey: showGoalLineKey)

        // Load weight goal (default: 180.0 if not set)
        if let savedGoal = userDefaults.object(forKey: weightGoalKey) as? Double {
            weightGoal = savedGoal
        }
    }

    /// Save goal settings to UserDefaults
    func saveGoalSettings() {
        userDefaults.set(showGoalLine, forKey: showGoalLineKey)
        userDefaults.set(weightGoal, forKey: weightGoalKey)
    }

    // MARK: - View Lifecycle Methods

    /// Handle view appearance (replaces onAppear logic in view)
    func onViewAppear() {
        // 🔍 FORENSIC: Track onAppear start time
        let startTime = CFAbsoluteTimeGetCurrent()
        AppLogger.info("⏱️ WeightTrackingViewModel.onViewAppear START", category: AppLogger.ui)

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
        AppLogger.info("⏱️ WeightTrackingViewModel.onViewAppear TOTAL: \(String(format: "%.2f", totalDuration))ms", category: AppLogger.ui)
    }

    /// Handle Progress Story auto-show task (replaces .task in view)
    func handleProgressStoryAutoShow() async {
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

    // MARK: - HealthKit Actions

    /// Handle HealthKit nudge "Connect" button tap
    func handleHealthKitConnect() {
        AppLogger.info("HealthKit nudge - requesting weight authorization", category: AppLogger.healthKit)
        HealthKitManager.shared.requestWeightAuthorization { success, _ in
            DispatchQueue.main.async {
                if success {
                    AppLogger.info("Weight authorization granted from nudge", category: AppLogger.healthKit)
                    self.weightManager.syncWithHealthKit = true
                    self.showHealthKitNudge = false
                } else {
                    AppLogger.info("Weight authorization denied from nudge", category: AppLogger.healthKit)
                }
            }
        }
    }

    /// Handle HealthKit nudge "Dismiss" button tap
    func handleHealthKitDismiss() {
        AppLogger.info("HealthKit nudge dismissed", category: AppLogger.ui)
        showHealthKitNudge = false
        nudgeManager.dismissNudge(for: .weight)
    }
}
