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

    // MARK: - Throttle State Management
    private let lastNotificationKey = "lastNotificationTimes" // UserDefaults key for persistence

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

        // Schedule with Apple UserNotifications framework (Expert Panel Task #6: Use IdentifierBuilder)
        await scheduleNotification(
            identifier: NotificationIdentifierBuilder.buildBehavioralIdentifier(tracker: trackerType, trigger: trigger),
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
    /// Expert Panel Task #3: QuietHours-then-Throttle precedence implementation
    private func shouldDeliverNotification(
        for rule: any BehavioralNotificationRule,
        context: BehavioralContext
    ) async -> Bool {

        // FILTER 1: Check if rule allows this notification
        let shouldTrigger = rule.shouldTrigger(context: context)
        AppLogger.notifications.debug("FILTER 1 - shouldTrigger: \(shouldTrigger)")
        guard shouldTrigger else {
            AppLogger.notifications.debug("BLOCKED BY: Rule shouldTrigger returned false")
            return false
        }

        // FILTER 2: Check quiet hours (FIRST PRECEDENCE - Expert Panel requirement)
        let inQuietHours = self.isInQuietHours()
        let allowDuringQuiet = rule.allowDuringQuietHours
        AppLogger.notifications.debug("FILTER 2 - inQuietHours: \(inQuietHours), allowDuringQuiet: \(allowDuringQuiet)")
        if inQuietHours && !allowDuringQuiet {
            AppLogger.notifications.debug("BLOCKED BY: Quiet hours (PRECEDENCE: Quiet hours override throttle)")
            return false
        }

        // FILTER 3: Check throttle (SECOND PRECEDENCE - only if not blocked by quiet hours)
        let isThrottled = await self.isThrottled(for: rule.trackerType, throttleMinutes: rule.throttleMinutes)
        AppLogger.notifications.debug("FILTER 3 - isThrottled: \(isThrottled), throttleMinutes: \(rule.throttleMinutes)")
        if isThrottled {
            AppLogger.notifications.debug("BLOCKED BY: Throttle (too soon since last notification)")
            return false
        }

        // FILTER 4: Check daily notification limit
        let todaysCount = await self.getTodaysNotificationCount()
        AppLogger.notifications.debug("FILTER 4 - todaysCount: \(todaysCount), maxDaily: \(self.maxDailyNotifications)")
        if todaysCount >= self.maxDailyNotifications {
            AppLogger.notifications.debug("BLOCKED BY: Daily notification limit exceeded")
            return false
        }

        AppLogger.notifications.debug("ALL FILTERS PASSED - notification should be delivered (QuietHours->Throttle precedence respected)")
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

            // Record delivery time for throttling (Expert Panel Task #3 & #6: Use IdentifierBuilder)
            if let trackerType = NotificationIdentifierBuilder.extractTrackerType(from: identifier) {
                self.recordNotificationDelivery(for: trackerType)
            }

            AppLogger.notifications.info("Scheduled behavioral notification - ID: \(identifier), Title: \(content.title), Tracker: \(NotificationIdentifierBuilder.extractTrackerType(from: identifier)?.rawValue ?? "unknown")")

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

    // MARK: - Legacy Methods Removed (Expert Panel Task #6)
    // generateIdentifier() -> Use NotificationIdentifierBuilder.buildBehavioralIdentifier()
    // extractTrackerType() -> Use NotificationIdentifierBuilder.extractTrackerType()

    private func rescheduleNotifications(for trackerType: TrackerType) async {
        // Cancel existing notifications for this tracker (Expert Panel Task #6: Use IdentifierBuilder)
        let pendingRequests = await self.notificationCenter.pendingNotificationRequests()
        let trackerPrefix = NotificationIdentifierBuilder.buildTrackerIdentifierPrefix(for: trackerType)

        let identifiersToCancel = pendingRequests
            .filter { request in request.identifier.hasPrefix(trackerPrefix) }
            .map { request in request.identifier }

        self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)

        AppLogger.notifications.debug("Cancelled \(identifiersToCancel.count) notifications for \(trackerType.rawValue))")
    }

    // MARK: - Throttle Management Methods (Expert Panel Task #3)

    /// Check if a tracker type is throttled based on last notification time
    /// Expert Panel requirement: Defer to Quiet Hours first, then throttle
    private func isThrottled(for trackerType: TrackerType, throttleMinutes: Int) async -> Bool {
        guard throttleMinutes > 0 else { return false } // No throttling if set to 0

        let lastNotificationTimes = getLastNotificationTimes()
        guard let lastTime = lastNotificationTimes[trackerType.rawValue] else {
            return false // No previous notification, not throttled
        }

        let minutesSinceLastNotification = Date().timeIntervalSince(lastTime) / 60
        let isThrottled = minutesSinceLastNotification < Double(throttleMinutes)

        AppLogger.notifications.debug("THROTTLE CHECK - \(trackerType.rawValue): \(String(format: "%.1f", minutesSinceLastNotification)) min since last, throttle: \(throttleMinutes) min, blocked: \(isThrottled)")

        return isThrottled
    }

    /// Record successful notification delivery for throttling
    private func recordNotificationDelivery(for trackerType: TrackerType) {
        var lastNotificationTimes = getLastNotificationTimes()
        lastNotificationTimes[trackerType.rawValue] = Date()
        saveLastNotificationTimes(lastNotificationTimes)

        AppLogger.notifications.debug("THROTTLE RECORD - \(trackerType.rawValue): Updated last notification time")
    }

    /// Get last notification times from persistent storage
    private func getLastNotificationTimes() -> [String: Date] {
        guard let data = UserDefaults.standard.data(forKey: lastNotificationKey),
              let times = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return [:]
        }
        return times
    }

    /// Save last notification times to persistent storage
    private func saveLastNotificationTimes(_ times: [String: Date]) {
        if let data = try? JSONEncoder().encode(times) {
            UserDefaults.standard.set(data, forKey: lastNotificationKey)
        }
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
    /// Expert Panel Task #6: Uses IdentifierBuilder for consistent test notification IDs
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
// BehavioralTrigger moved to BehavioralNotificationRule.swift to avoid circular dependency

