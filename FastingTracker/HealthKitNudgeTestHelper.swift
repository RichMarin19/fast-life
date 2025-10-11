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

        print("🧪 TEST: Simulated user who skipped HealthKit onboarding")
        print("   - onboardingCompleted = true")
        print("   - healthKitSkippedOnboarding = true")
        print("   - All nudges reset")
        print("   → Nudges should now appear in tracker views")
    }

    /// Simulate a user who enabled HealthKit during onboarding
    /// Nudges should NOT appear for this user
    static func simulateEnabledOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        UserDefaults.standard.set(false, forKey: "healthKitSkippedOnboarding")

        print("🧪 TEST: Simulated user who enabled HealthKit during onboarding")
        print("   - onboardingCompleted = true")
        print("   - healthKitSkippedOnboarding = false")
        print("   → Nudges should NOT appear in tracker views")
    }

    /// Reset to fresh onboarding state
    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "onboardingCompleted")
        UserDefaults.standard.removeObject(forKey: "healthKitSkippedOnboarding")
        HealthKitNudgeManager.shared.resetNudges()

        print("🧪 TEST: Reset to fresh onboarding state")
        print("   → User will see onboarding flow again")
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
        let timerPermanentlyDismissed = UserDefaults.standard
            .bool(forKey: "healthkit_nudge_timer_permanently_dismissed")

        print("🔍 NUDGE SYSTEM DEBUG STATE:")
        print("   onboardingCompleted: \(onboardingComplete)")
        print("   healthKitSkippedOnboarding: \(healthKitSkipped)")
        print("   weightAuthorized: \(weightAuthorized)")
        print("   waterAuthorized: \(waterAuthorized)")
        print("   sleepAuthorized: \(sleepAuthorized)")

        print("\n   Timer nudge state:")
        print("   visitCount: \(timerVisitCount)")
        print("   permanentlyDismissed: \(timerPermanentlyDismissed)")

        print("\n   Nudge visibility:")
        print("   Weight nudge should show: \(HealthKitNudgeManager.shared.shouldShowNudge(for: .weight))")
        print("   Hydration nudge should show: \(HealthKitNudgeManager.shared.shouldShowNudge(for: .hydration))")
        print("   Sleep nudge should show: \(HealthKitNudgeManager.shared.shouldShowNudge(for: .sleep))")
        print("   Fasting nudge should show: \(HealthKitNudgeManager.shared.shouldShowNudge(for: .fasting))")
    }
}

#if DEBUG
    extension HealthKitNudgeTestHelper {
        /// Quick test methods for use in debug console
        /// Usage: HealthKitNudgeTestHelper.quickTestSkip()
        static func quickTestSkip() {
            self.simulateSkipOnboarding()
            print("\n⚠️  Restart the app to see nudges in tracker views")
        }

        static func quickTestEnabled() {
            self.simulateEnabledOnboarding()
            print("\n⚠️  Restart the app - nudges should not appear")
        }

        static func quickDebug() {
            self.debugNudgeState()
        }
    }
#endif
