import SwiftUI
import Combine

/// ViewModel for Weight Tracking View
/// Industry Pattern: MVVM (Apple WWDC 2023 recommendation)
/// Extracts state and business logic from WeightTrackingView
/// Reference: ARCHITECTURE-AUDIT.md - Critical Task 1
/// Gold Standard: WeightControlCenterViewModel (903 LOC)
@MainActor
class WeightTrackingViewModel: ObservableObject {
    // MARK: - Dependencies (Injected via configure())
    // CONSULTANT FIX: Managers injected AFTER init to work with SwiftUI @EnvironmentObject
    // SwiftUI limitation: @StateObject init happens BEFORE @EnvironmentObject injection
    // Solution: Empty init(), then configure() called from view's .onAppear with environment managers

    var weightManager: WeightManager!
    var behavioralScheduler: BehavioralNotificationScheduler!

    // Singleton managers (pass-through)
    let healthKitManager = HealthKitManager.shared
    let nudgeManager = HealthKitNudgeManager.shared
    private var optOutManager: ContentOptOutManaging!

    // CRITICAL FIX: cardManager must be @ObservedObject to propagate state changes
    // When CardManager updates @Published cardPreferences, ViewModel must re-publish
    // This triggers SwiftUI view updates for real-time card hide/expand
    // Industry Pattern: Observation chain (View → ViewModel → CardManager)
    @ObservedObject var cardManager = TrackerCards.shared

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
    private let legacyWeightGoalKey = "goalWeight"  // Legacy UserDefaults key (OnboardingView.swift line 686)

    // MARK: - Initialization

    /// Empty init - managers injected later via configure()
    /// CONSULTANT FIX: SwiftUI @StateObject init happens BEFORE @EnvironmentObject injection
    init() {
        // Managers will be set via configure() after @EnvironmentObject becomes available
    }

    /// Configure ViewModel with injected dependencies
    /// Must be called from view's .onAppear with @EnvironmentObject managers
    /// CONSULTANT FIX: Fixes duplicate WeightManager creation issue
    func configure(weightManager: WeightManager,
                   behavioralScheduler: BehavioralNotificationScheduler,
                   optOutManager: ContentOptOutManaging? = nil) {
        self.weightManager = weightManager
        self.behavioralScheduler = behavioralScheduler
        self.optOutManager = optOutManager ?? ContentOptOutManager.shared

        // Load persisted state after managers are set
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

    /// Load goal settings from persisted manager + view preferences
    func loadGoalSettings() {
        // Load show goal line preference (default: false)
        showGoalLine = userDefaults.bool(forKey: showGoalLineKey)

        // Load goal weight from WeightManager (single source of truth)
        let storedGoal = weightManager.goalWeight
        if storedGoal > 0 {
            weightGoal = storedGoal
        } else if let legacyGoal = userDefaults.object(forKey: legacyWeightGoalKey) as? Double, legacyGoal > 0 {
            weightGoal = legacyGoal
            weightManager.setGoalWeight(legacyGoal)
            userDefaults.removeObject(forKey: legacyWeightGoalKey)
        }
    }

    /// Persist goal settings
    func saveGoalSettings() {
        userDefaults.set(showGoalLine, forKey: showGoalLineKey)
        weightManager.setGoalWeight(weightGoal)
    }

    // MARK: - View Lifecycle Methods

    /// Handle view appearance (replaces onAppear logic in view)
    func onViewAppear() {
        #if DEBUG
        // 🔍 FORENSIC: Track onAppear start time
        let startTime = CFAbsoluteTimeGetCurrent()
        AppLogger.info("⏱️ WeightTrackingViewModel.onViewAppear START", category: AppLogger.ui)
        #endif

        // Load saved goal settings from UserDefaults
        #if DEBUG
        let loadSettingsStart = CFAbsoluteTimeGetCurrent()
        #endif
        loadGoalSettings()
        #if DEBUG
        let loadSettingsDuration = (CFAbsoluteTimeGetCurrent() - loadSettingsStart) * 1000
        AppLogger.info("⏱️ loadGoalSettings took \(String(format: "%.2f", loadSettingsDuration))ms", category: AppLogger.ui)
        #endif

        // Show first-time setup if user has no weight data
        // No delay needed - weightManager loads synchronously in init
        if weightManager.weightEntries.isEmpty {
            showingFirstTimeSetup = true
        }

        // Show HealthKit nudge for first-time users who skipped onboarding
        // Following Lose It pattern - contextual reminder on first tracker access
        #if DEBUG
        let nudgeStart = CFAbsoluteTimeGetCurrent()
        #endif
        showHealthKitNudge = nudgeManager.shouldShowNudge(for: .weight)
        #if DEBUG
        let nudgeDuration = (CFAbsoluteTimeGetCurrent() - nudgeStart) * 1000
        AppLogger.info("⏱️ shouldShowNudge took \(String(format: "%.2f", nudgeDuration))ms", category: AppLogger.ui)

        if showHealthKitNudge {
            AppLogger.info("Showing HealthKit nudge for first-time user", category: AppLogger.ui)
        }
        #endif

        // Note: Removed auto-authorization logic - now uses nudge banner pattern like HydrationTrackingView
        // User must explicitly tap "Connect" in nudge banner to authorize
        // This follows Lose It app pattern and Apple HIG contextual permission guidelines

        #if DEBUG
        // 🔍 FORENSIC: Track total onAppear duration
        let totalDuration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        AppLogger.info("⏱️ WeightTrackingViewModel.onViewAppear TOTAL: \(String(format: "%.2f", totalDuration))ms", category: AppLogger.ui)
        #endif
    }

    /// Handle Progress Story auto-show task (replaces .task in view)
    func handleProgressStoryAutoShow() async {
        // Auto-show Progress Story with delay to prevent cold start freeze
        // Delay allows Weight Tracker view to render fully before presenting sheet
        // Industry pattern: Deferred engagement to prevent UI blocking
        // Reference: Apple HIG - Launching (avoid blocking UI on startup)
        guard !weightManager.weightEntries.isEmpty else { return }

        let contentID = "progress_story_trends_v1"
        let isOptedOut = optOutManager.isContentOptedOut(id: contentID)

        guard !isOptedOut else {
            #if DEBUG
            AppLogger.info("🎯 Progress Story opted out - skipping auto-show", category: AppLogger.ui)
            #endif
            return
        }

        // Delay 0.6 seconds to let view render + animations settle
        try? await Task.sleep(nanoseconds: 600_000_000)  // 0.6 seconds

        await MainActor.run {
            #if DEBUG
            AppLogger.info("🎯 Auto-showing Progress Story on Weight Tracker open (delayed)", category: AppLogger.ui)
            #endif
            showingTrends = true
        }
    }

    // MARK: - HealthKit Actions

    /// Handle HealthKit nudge "Connect" button tap
    func handleHealthKitConnect() {
        #if DEBUG
        AppLogger.info("HealthKit nudge - requesting weight authorization", category: AppLogger.healthKit)
        #endif
        HealthKitManager.shared.requestWeightAuthorization { success, _ in
            DispatchQueue.main.async {
                if success {
                    #if DEBUG
                    AppLogger.info("Weight authorization granted from nudge", category: AppLogger.healthKit)
                    #endif
                    self.weightManager.syncWithHealthKit = true
                    self.showHealthKitNudge = false
                } else {
                    #if DEBUG
                    AppLogger.info("Weight authorization denied from nudge", category: AppLogger.healthKit)
                    #endif
                }
            }
        }
    }

    /// Handle HealthKit nudge "Dismiss" button tap
    func handleHealthKitDismiss() {
        #if DEBUG
        AppLogger.info("HealthKit nudge dismissed", category: AppLogger.ui)
        #endif
        showHealthKitNudge = false
        nudgeManager.dismissNudge(for: .weight)
    }
}
