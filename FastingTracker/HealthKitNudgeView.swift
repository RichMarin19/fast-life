import SwiftUI

/// Contextual nudge for users who skipped HealthKit during onboarding
/// Following Lose It app pattern and Apple HIG for onboarding
/// Reference: https://developer.apple.com/design/human-interface-guidelines/onboarding
struct HealthKitNudgeView: View {
    let dataType: HealthDataType
    let onConnect: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "heart.fill")
                    .font(.title3)
                    .foregroundColor(.red)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sync with Apple Health")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(nudgeMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Action buttons
                HStack(spacing: 8) {
                    Button("Connect") {
                        onConnect()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 24, height: 24)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var nudgeMessage: String {
        switch dataType {
        case .weight:
            return "Keep your weight data in sync across all your health apps"
        case .hydration:
            return "Track all your water intake in one place"
        case .sleep:
            return "Consolidate sleep data from your Apple Watch and other apps"
        case .fasting:
            return "Export your fasting progress automatically"
        }
    }
}

// MARK: - Nudge State Manager

/// Manages display state of health data nudges per tracker
/// Follows Apple's contextual permission pattern with smart persistence
/// Industry standard: Remind every N visits until resolved (Strava, MyFitnessPal pattern)
class HealthKitNudgeManager: ObservableObject {
    static let shared = HealthKitNudgeManager()

    private let userDefaults = UserDefaults.standard
    private let nudgeDismissedPrefix = "healthkit_nudge_dismissed_"
    private let timerVisitCountKey = "healthkit_nudge_timer_visit_count"
    private let timerNudgePermanentlyDismissedKey = "healthkit_nudge_timer_permanently_dismissed"

    // Show nudge every 5 Timer tab visits (industry standard frequency)
    private let visitThreshold = 5

    private init() {}

    /// Check if user should see nudge for specific data type
    /// Special logic for fasting (Timer tab): Smart persistence every 5 visits
    /// Other trackers: Show once until dismissed or authorized
    func shouldShowNudge(for dataType: HealthDataType) -> Bool {
        // Only show if onboarding is complete
        guard UserDefaults.standard.bool(forKey: "onboardingCompleted") else {
            return false
        }

        // Only show if user skipped HealthKit during onboarding
        // Following Lose It pattern - only nudge users who explicitly skipped initially
        guard UserDefaults.standard.bool(forKey: "healthKitSkippedOnboarding") else {
            return false
        }

        // Auto-dismiss if already authorized for this data type
        // Following Apple HIG - don't show permission requests for granted permissions
        if isAlreadyAuthorized(for: dataType) {
            return false
        }

        // Special logic for fasting (Timer tab) - smart persistence
        if dataType == .fasting {
            return shouldShowTimerNudge()
        }

        // Standard logic for other trackers (weight, hydration, sleep)
        let dismissKey = nudgeDismissedPrefix + dataType.rawValue
        if userDefaults.bool(forKey: dismissKey) {
            return false
        }

        return true
    }

    /// Smart persistence logic for Timer tab nudge
    /// Show every 5 visits until user enables HealthKit or permanently dismisses
    private func shouldShowTimerNudge() -> Bool {
        // Don't show if permanently dismissed
        if userDefaults.bool(forKey: timerNudgePermanentlyDismissedKey) {
            return false
        }

        // Increment visit count
        let currentCount = userDefaults.integer(forKey: timerVisitCountKey)
        let newCount = currentCount + 1
        userDefaults.set(newCount, forKey: timerVisitCountKey)

        // Show every 5th visit
        let shouldShow = (newCount % visitThreshold) == 0

        if shouldShow {
            AppLogger.info("Timer nudge: Showing on visit #\(newCount) (every \(visitThreshold) visits)", category: AppLogger.general)
        }

        return shouldShow
    }

    /// Mark nudge as dismissed for specific data type
    /// For fasting (Timer tab): Temporary dismiss - will show again in 5 visits
    /// For other trackers: Permanent dismiss
    func dismissNudge(for dataType: HealthDataType) {
        if dataType == .fasting {
            // For Timer tab: Just temporary dismiss - no permanent flag set
            // Will show again after 5 more visits
            AppLogger.info("Timer nudge temporarily dismissed - will show again in \(visitThreshold) visits", category: AppLogger.general)
        } else {
            // For other trackers: Permanent dismiss
            let dismissKey = nudgeDismissedPrefix + dataType.rawValue
            userDefaults.set(true, forKey: dismissKey)
            AppLogger.info("Nudge permanently dismissed for \(dataType.rawValue)", category: AppLogger.general)
        }
    }

    /// Permanently dismiss Timer nudge (stop showing forever)
    /// Used when user explicitly chooses "Don't show again"
    func permanentlyDismissTimerNudge() {
        userDefaults.set(true, forKey: timerNudgePermanentlyDismissedKey)
        AppLogger.info("Timer nudge permanently dismissed by user", category: AppLogger.general)
    }

    /// Reset visit counter when user enables HealthKit (auto-dismiss)
    /// Following Apple HIG - don't continue nagging after user grants permission
    func handleAuthorizationGranted(for dataType: HealthDataType) {
        if dataType == .fasting {
            // Reset visit counter - no longer need to show nudges
            userDefaults.removeObject(forKey: timerVisitCountKey)
            AppLogger.info("Timer nudge auto-dismissed - HealthKit enabled", category: AppLogger.general)
        }
    }

    /// Reset nudge display state (for testing)
    func resetNudges() {
        for dataType in HealthDataType.allCases {
            let dismissKey = nudgeDismissedPrefix + dataType.rawValue
            userDefaults.removeObject(forKey: dismissKey)
        }
        AppLogger.info("All health nudges reset", category: AppLogger.general)
    }

    private func isAlreadyAuthorized(for dataType: HealthDataType) -> Bool {
        switch dataType {
        case .weight:
            return HealthKitManager.shared.isWeightAuthorized()
        case .hydration:
            return HealthKitManager.shared.isWaterAuthorized()
        case .sleep:
            return HealthKitManager.shared.isSleepAuthorized()
        case .fasting:
            // Fasting authorization check not yet implemented
            return false
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HealthKitNudgeView(
            dataType: .weight,
            onConnect: { print("Connect tapped") },
            onDismiss: { print("Dismiss tapped") }
        )

        HealthKitNudgeView(
            dataType: .hydration,
            onConnect: { print("Connect tapped") },
            onDismiss: { print("Dismiss tapped") }
        )
    }
    .padding()
    .background(Color(.systemGray6))
}