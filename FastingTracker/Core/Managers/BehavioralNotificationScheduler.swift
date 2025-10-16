import Foundation
import UserNotifications
import SwiftUI

/// Behavioral Notification Scheduler - Central scheduling engine
/// Following Apple UserNotifications framework + Expert Panel behavioral design
/// Uses existing TrackerType enum from AppSettings.swift for compatibility
@MainActor
final class BehavioralNotificationScheduler: ObservableObject {


    // MARK: - Core Dependencies
    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Rule Objects (Per-Tracker Behavioral Logic)
    @Published private(set) var rules: [TrackerType: any BehavioralNotificationRule] = [:]

    // MARK: - Configuration
    private let maxDailyNotifications = 8 // Prevent notification fatigue
    private let quietHoursDefault = QuietHours(start: 22, end: 6) // 10 PM - 6 AM

    init() {
        AppLogger.info("BehavioralNotificationScheduler initialized", category: AppLogger.notifications)
        setupDefaultRules()
    }

    // MARK: - Public Interface

    /// Schedule behavioral guidance notification for specific tracker
    /// Follows expert panel's "Educate, Empower, Reinforce" principles
    func scheduleGuidance(
        for trackerType: TrackerType,
        trigger: BehavioralTrigger,
        context: BehavioralContext
    ) async {
        guard let rule = self.rules[trackerType] else {
            AppLogger.notifications.warning("No rule found for tracker type: \(trackerType.rawValue))")
            return
        }

        // Check if notification should be delivered based on user preferences
        guard await shouldDeliverNotification(for: rule, context: context) else {
            AppLogger.notifications.debug("Notification filtered out by behavioral rules")
            return
        }

        // Generate behaviorally intelligent message
        let message = rule.generateMessage(context: context)

        // Schedule with Apple UserNotifications framework
        await scheduleNotification(
            identifier: self.generateIdentifier(tracker: trackerType, trigger: trigger),
            content: message,
            trigger: trigger,
            rule: rule
        )
    }

    /// Update rule configuration for specific tracker
    func updateRule<T: BehavioralNotificationRule>(_ rule: T) {
        self.rules[rule.trackerType] = rule
        AppLogger.notifications.info("Updated notification rule for \(rule.trackerType.rawValue))")

        // Reschedule existing notifications with new rule
        Task { [self] in
            await self.rescheduleNotifications(for: rule.trackerType)
        }
    }

    /// Get current rule for tracker type
    func getRule(for trackerType: TrackerType) -> (any BehavioralNotificationRule)? {
        return self.rules[trackerType]
    }

    // MARK: - Behavioral Intelligence Engine

    /// Determines if notification should be delivered based on behavioral context
    private func shouldDeliverNotification(
        for rule: any BehavioralNotificationRule,
        context: BehavioralContext
    ) async -> Bool {

        // Check if rule allows this notification
        let shouldTrigger = rule.shouldTrigger(context: context)
        AppLogger.notifications.debug("FILTER 1 - shouldTrigger: \(shouldTrigger)")
        guard shouldTrigger else {
            AppLogger.notifications.debug("BLOCKED BY: Rule shouldTrigger returned false")
            return false
        }

        // Check quiet hours
        let inQuietHours = self.isInQuietHours()
        let allowDuringQuiet = rule.allowDuringQuietHours
        AppLogger.notifications.debug("FILTER 2 - inQuietHours: \(inQuietHours), allowDuringQuiet: \(allowDuringQuiet)")
        if inQuietHours && !allowDuringQuiet {
            AppLogger.notifications.debug("BLOCKED BY: Quiet hours (current time in quiet period)")
            return false
        }

        // Check daily notification limit
        let todaysCount = await self.getTodaysNotificationCount()
        AppLogger.notifications.debug("FILTER 3 - todaysCount: \(todaysCount), maxDaily: \(self.maxDailyNotifications)")
        if todaysCount >= self.maxDailyNotifications {
            AppLogger.notifications.debug("BLOCKED BY: Daily notification limit exceeded")
            return false
        }

        AppLogger.notifications.debug("ALL FILTERS PASSED - notification should be delivered")
        return true
    }

    /// Schedule notification using Apple UserNotifications framework
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

        // Set interruption level based on rule configuration (iOS 15+)
        if #available(iOS 15.0, *) {
            notificationContent.interruptionLevel = rule.interruptionLevel.unInterruptionLevel
        }

        // Create trigger based on type
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

            AppLogger.notifications.info("Scheduled behavioral notification - ID: \(identifier), Title: \(content.title), Tracker: \(self.extractTrackerType(from: identifier).rawValue))")

        } catch {
            AppLogger.notifications.error("Failed to schedule notification: \(error.localizedDescription))")
        }
    }

    // MARK: - Helper Methods

    private func setupDefaultRules() {
        // Initialize with expert panel's behavioral rules
        self.rules = [
            .fasting: FastingNotificationRule(),
            .hydration: HydrationNotificationRule(),
            .sleep: SleepNotificationRule(),
            .weight: WeightNotificationRule()
            // Mood rules can be added when implemented
        ]

        AppLogger.notifications.debug("Initialized default notification rules")
    }

    private func isInQuietHours() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)

        let quietHours = self.quietHoursDefault
        if quietHours.start > quietHours.end {
            // Spans midnight (e.g., 22:00 - 06:00)
            return hour >= quietHours.start || hour < quietHours.end
        } else {
            return hour >= quietHours.start && hour < quietHours.end
        }
    }

    private func generateIdentifier(tracker: TrackerType, trigger: BehavioralTrigger) -> String {
        let timestamp = Date().timeIntervalSince1970
        return "behavioral_\(tracker.rawValue)_\(trigger.identifier())_\(Int(timestamp))"
    }

    private func extractTrackerType(from identifier: String) -> TrackerType {
        let components = identifier.split(separator: "_")
        guard components.count >= 2,
              let trackerType = TrackerType(rawValue: String(components[1])) else {
            return .fasting // Default fallback
        }
        return trackerType
    }

    private func rescheduleNotifications(for trackerType: TrackerType) async {
        // Cancel existing notifications for this tracker
        let pendingRequests = await self.notificationCenter.pendingNotificationRequests()
        let trackerPrefix = "behavioral_\(trackerType.rawValue)_"

        let identifiersToCancel = pendingRequests
            .filter { request in request.identifier.hasPrefix(trackerPrefix) }
            .map { request in request.identifier }

        self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)

        AppLogger.notifications.debug("Cancelled \(identifiersToCancel.count) notifications for \(trackerType.rawValue))")
    }

    // MARK: - Analytics Support Methods (Simplified)

    private func getTodaysNotificationCount() async -> Int {
        let pendingRequests = await self.notificationCenter.pendingNotificationRequests()

        // Simple count of today's scheduled notifications
        return pendingRequests.filter { request in
            request.identifier.hasPrefix("behavioral_")
        }.count
    }

    // MARK: - Public Testing Interface

    /// Send immediate test notification (for development/testing)
    func sendTestNotification(for trackerType: TrackerType) async {
        let context = BehavioralContext(
            currentStreak: 3,
            recentPattern: "consistent",
            timeOfDay: Date(),
            dataValue: 75.0,
            goalProgress: 0.8,
            lastActivity: Calendar.current.date(byAdding: .hour, value: -2, to: Date())
        )

        await scheduleGuidance(
            for: trackerType,
            trigger: .immediate,
            context: context
        )

        AppLogger.notifications.info("Sent test notification for \(trackerType.rawValue))")
    }

    // MARK: - Permission Management

    /// Request notification permissions following Apple UserNotifications framework
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

    /// Get current authorization status
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await self.notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

}

// MARK: - Supporting Types

/// Different types of notification triggers following Apple UserNotifications patterns
enum BehavioralTrigger {
    case timeInterval(TimeInterval)
    case calendar(DateComponents)
    case immediate

    func identifier() -> String {
        switch self {
        case .timeInterval(let interval): return "time_\(Int(interval))"
        case .calendar: return "calendar"
        case .immediate: return "immediate"
        }
    }
}

