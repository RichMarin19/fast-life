import Foundation

/// Helper for testing the HealthKit nudge system
/// Use this in debug mode to simulate different user states
class HealthKitNudgeTestHelper {

    /// Simulate a user who skipped HealthKit during onboarding
    /// Call this to test the nudge system
    static func simulateSkipOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        UserDefaults.standard.set(true, forKey: "healthKitSkippedOnboarding")

        // Reset all nudge dismissal states
        HealthKitNudgeManager.shared.resetNudges()

        Log.debug("🧪 TEST: Simulated user who skipped HealthKit onboarding", category: .general)
        Log.debug("   - onboardingCompleted = true", category: .general)
        Log.debug("   - healthKitSkippedOnboarding = true", category: .general)
        Log.debug("   - All nudges reset", category: .general)
        Log.debug("   → Nudges should now appear in tracker views", category: .general)
    }

    /// Simulate a user who enabled HealthKit during onboarding
    /// Nudges should NOT appear for this user
    static func simulateEnabledOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        UserDefaults.standard.set(false, forKey: "healthKitSkippedOnboarding")

        Log.debug("🧪 TEST: Simulated user who enabled HealthKit during onboarding", category: .general)
        Log.debug("   - onboardingCompleted = true", category: .general)
        Log.debug("   - healthKitSkippedOnboarding = false", category: .general)
        Log.debug("   → Nudges should NOT appear in tracker views", category: .general)
    }

    /// Reset to fresh onboarding state
    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "onboardingCompleted")
        UserDefaults.standard.removeObject(forKey: "healthKitSkippedOnboarding")
        HealthKitNudgeManager.shared.resetNudges()

        Log.debug("🧪 TEST: Reset to fresh onboarding state", category: .general)
        Log.debug("   → User will see onboarding flow again", category: .general)
    }

    /// Print current nudge system state for debugging
    static func debugNudgeState() {
        let onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingCompleted")
        let healthKitSkipped = UserDefaults.standard.bool(forKey: "healthKitSkippedOnboarding")
        let weightAuthorized = HealthKitManager.shared.isWeightAuthorized()
        let waterAuthorized = HealthKitManager.shared.isWaterAuthorized()
        let sleepAuthorized = HealthKitManager.shared.isSleepAuthorized()

        // Timer-specific state
        let timerVisitCount = UserDefaults.standard.integer(forKey: "healthkit_nudge_timer_visit_count")
        let timerPermanentlyDismissed = UserDefaults.standard.bool(forKey: "healthkit_nudge_timer_permanently_dismissed")

        Log.debug("🔍 NUDGE SYSTEM DEBUG STATE:", category: .general)
        Log.debug("   onboardingCompleted: \(onboardingComplete)", category: .general)
        Log.debug("   healthKitSkippedOnboarding: \(healthKitSkipped)", category: .general)
        Log.debug("   weightAuthorized: \(weightAuthorized)", category: .general)
        Log.debug("   waterAuthorized: \(waterAuthorized)", category: .general)
        Log.debug("   sleepAuthorized: \(sleepAuthorized)", category: .general)

        Log.debug("\n   Timer nudge state:", category: .general)
        Log.debug("   visitCount: \(timerVisitCount)", category: .general)
        Log.debug("   permanentlyDismissed: \(timerPermanentlyDismissed)", category: .general)

        Log.debug("\n   Nudge visibility:", category: .general)
        Log.debug("   Weight nudge should show: \(HealthKitNudgeManager.shared.shouldShowNudge(for: .weight))", category: .general)
        Log.debug("   Hydration nudge should show: \(HealthKitNudgeManager.shared.shouldShowNudge(for: .hydration))", category: .general)
        Log.debug("   Sleep nudge should show: \(HealthKitNudgeManager.shared.shouldShowNudge(for: .sleep))", category: .general)
        Log.debug("   Fasting nudge should show: \(HealthKitNudgeManager.shared.shouldShowNudge(for: .fasting))", category: .general)
    }
}

#if DEBUG
extension HealthKitNudgeTestHelper {
    /// Quick test methods for use in debug console
    /// Usage: HealthKitNudgeTestHelper.quickTestSkip()
    static func quickTestSkip() {
        simulateSkipOnboarding()
        Log.debug("\n⚠️  Restart the app to see nudges in tracker views", category: .general)
    }

    static func quickTestEnabled() {
        simulateEnabledOnboarding()
        Log.debug("\n⚠️  Restart the app - nudges should not appear", category: .general)
    }

    static func quickDebug() {
        debugNudgeState()
    }
}
#endif