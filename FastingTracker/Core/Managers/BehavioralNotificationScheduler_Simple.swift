import Foundation
import UserNotifications
import SwiftUI

/// Simplified Behavioral Notification Scheduler for testing
@MainActor
final class BehavioralNotificationSchedulerSimple: ObservableObject {

    // MARK: - Core Dependencies
    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Rule Objects
    @Published private(set) var rules: [TrackerType: any BehavioralNotificationRule] = [:]

    // MARK: - Configuration
    private let maxDailyNotifications = 8
    private let quietHoursDefault = QuietHours(start: 22, end: 6)

    init() {
        AppLogger.info("BehavioralNotificationSchedulerSimple initialized", category: AppLogger.notifications)
        setupDefaultRules()
    }

    // MARK: - Public Interface

    /// Schedule behavioral guidance notification
    func scheduleGuidance(
        for trackerType: TrackerType,
        trigger: BehavioralTrigger,
        context: BehavioralContext
    ) async {
        guard let rule = self.rules[trackerType] else {
            AppLogger.notifications.warning("No rule found for tracker type: \(trackerType.rawValue)")
            return
        }

        // Generate message
        let message = rule.generateMessage(context: context)

        // Schedule notification
        await scheduleNotification(
            identifier: generateIdentifier(tracker: trackerType, trigger: trigger),
            content: message,
            trigger: trigger,
            rule: rule
        )
    }

    /// Update rule configuration
    func updateRule<T: BehavioralNotificationRule>(_ rule: T) {
        self.rules[rule.trackerType] = rule
        AppLogger.notifications.info("Updated notification rule for \(rule.trackerType.rawValue)")
    }

    /// Get current rule
    func getRule(for trackerType: TrackerType) -> (any BehavioralNotificationRule)? {
        return self.rules[trackerType]
    }

    // MARK: - Private Methods

    private func scheduleNotification(
        identifier: String,
        content: BehavioralMessage,
        trigger: BehavioralTrigger,
        rule: any BehavioralNotificationRule
    ) async {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = content.title
        notificationContent.body = content.body
        notificationContent.sound = rule.soundEnabled ? .default : nil

        // Create trigger
        let unTrigger: UNNotificationTrigger
        switch trigger {
        case .timeInterval(let interval):
            unTrigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        case .calendar(let dateComponents):
            unTrigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        case .immediate:
            unTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: identifier,
            content: notificationContent,
            trigger: unTrigger
        )

        do {
            try await self.notificationCenter.add(request)
            AppLogger.notifications.info("Scheduled behavioral notification - ID: \(identifier)")
        } catch {
            AppLogger.notifications.error("Failed to schedule notification: \(error.localizedDescription)")
        }
    }

    private func setupDefaultRules() {
        self.rules = [
            .fasting: FastingNotificationRule(),
            .hydration: HydrationNotificationRule(),
            .sleep: SleepNotificationRule()
        ]

        AppLogger.notifications.debug("Initialized default notification rules")
    }

    private func generateIdentifier(tracker: TrackerType, trigger: BehavioralTrigger) -> String {
        let timestamp = Date().timeIntervalSince1970
        return "behavioral_\(tracker.rawValue)_\(trigger.identifier())_\(Int(timestamp))"
    }

    /// Request notification permissions
    func requestPermissions() async -> Bool {
        do {
            let granted = try await self.notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge, .provisional]
            )

            if granted {
                AppLogger.notifications.info("Notification permissions granted")
            } else {
                AppLogger.notifications.warning("Notification permissions denied")
            }

            return granted

        } catch {
            AppLogger.error("Failed to request notification permissions", category: AppLogger.notifications, error: error)
            return false
        }
    }
}
