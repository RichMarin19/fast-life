import Foundation
import UserNotifications

// MARK: - Weight Notification Messages

/// Weight Notification Message Content
/// Phase 2a enhancement: Variable messaging to reduce notification fatigue
/// Industry pattern: Rotating message content (Apple Fitness+, Headspace, Noom)
/// Reference: fastlife_notifications_plan.md
struct WeightNotificationMessages {

    /// 10 variations for daily weight reminder
    /// Industry standard: 5-10 message variations to reduce habituation
    static let dailyReminders = [
        "Time for your weigh-in",
        "Ready to step on the scale?",
        "Let's track today's progress",
        "Your daily weigh-in awaits",
        "Time to log your weight",
        "Step on the scale when ready",
        "Track your weight today",
        "Your weigh-in is ready",
        "Time to update your progress",
        "Let's capture today's weight"
    ]

    /// Get message for a specific date using deterministic rotation
    /// Algorithm: Use day-of-year as index modulo array count
    static func getMessage(from messages: [String], for date: Date = Date()) -> String {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % messages.count
        return messages[index]
    }

    /// Get today's daily reminder message
    static func getDailyReminder(for date: Date = Date()) -> String {
        return getMessage(from: dailyReminders, for: date)
    }
}

// MARK: - Weight Quiet Hours Time Range

/// Represents quiet hours time range for weight notifications (can span midnight)
/// Industry pattern: Custom struct for time ranges (Stack Overflow #49611634, Apple Do Not Disturb)
/// Replaces Range<DateComponents> which can't handle midnight-spanning (start > end)
/// Note: Named WeightQuietHours to avoid conflict with BehavioralNotificationRule.QuietHours
public struct WeightQuietHours {
    public let start: DateComponents
    public let end: DateComponents

    public init(start: DateComponents, end: DateComponents) {
        self.start = start
        self.end = end
    }

    /// Check if this represents midnight-spanning quiet hours
    public var spansMidnight: Bool {
        let startHour = start.hour ?? 0
        let endHour = end.hour ?? 0
        return startHour > endHour || (startHour == endHour && (start.minute ?? 0) > (end.minute ?? 0))
    }
}

// MARK: - Weight Notification Manager

/// Weight Tracker Notification Manager
/// Handles scheduling/cancellation for daily weight reminders
/// Delegates authorization to NotificationManager.shared (reuses Fasting auth)
/// Uses WeightNotificationPlanner for pure scheduling logic
///
/// Following technical plan: fastlife_notifications_plan.md
/// Architecture: Separate from Fasting notification system
/// Reference: .claude/PHASE-2-NOTIFICATION-ARCHITECTURE-ANALYSIS.md

@MainActor
class WeightNotificationManager {

    // MARK: - Singleton

    static let shared = WeightNotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let category = "WEIGHT_REMINDER"

    private init() {}

    // MARK: - Scheduling

    /// Schedule next daily weight reminder
    /// Uses WeightNotificationPlanner for deterministic scheduling logic
    ///
    /// - Parameters:
    ///   - preferredTime: User's preferred reminder time (DateComponents with hour/minute)
    ///   - quietHours: Optional quiet hours range (can span midnight)
    ///   - skipWeekdays: Weekdays to skip (1=Sunday, 2=Monday, ..., 7=Saturday)
    ///
    /// - Throws: If notification scheduling fails
    func scheduleNextReminder(
        preferredTime: DateComponents,
        quietHours: WeightQuietHours? = nil,
        skipWeekdays: Set<Int> = []
    ) async throws {

        // Step 1: Check authorization
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            AppLogger.notifications.warning("Cannot schedule weight reminder - notifications not authorized")
            return
        }

        // Step 2: Compute next plan using pure planner
        guard let plan = WeightNotificationPlanner.nextPlan(
            from: Date(),
            preferred: preferredTime,
            tz: .current,
            quietHours: quietHours,
            skipWeekdays: skipWeekdays
        ) else {
            AppLogger.notifications.error("Failed to compute weight reminder plan")
            return
        }

        // Step 3: Cancel any existing weight reminders (de-dupe by date-based ID)
        await cancelAllWeightReminders()

        // Step 4: Create notification content with rotating message
        let content = UNMutableNotificationContent()
        content.title = WeightNotificationMessages.getDailyReminder(for: plan.fireDate)
        content.body = "Logging now keeps your trend accurate."
        content.sound = .default
        content.categoryIdentifier = category
        content.userInfo = ["type": "weight_reminder", "date": plan.id]

        // Step 5: Create trigger
        let timeInterval = plan.fireDate.timeIntervalSinceNow
        guard timeInterval > 0 else {
            AppLogger.notifications.warning("Fire date is in past, skipping schedule")
            return
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

        // Step 6: Create and add request
        let request = UNNotificationRequest(identifier: plan.id, content: content, trigger: trigger)

        try await notificationCenter.add(request)

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        AppLogger.notifications.info("Weight reminder scheduled: \(plan.id) at \(formatter.string(from: plan.fireDate))")
    }

    // MARK: - Cancellation

    /// Cancel today's weight reminder (called after successful weigh-in)
    /// Uses deterministic ID based on current date
    func cancelTodayReminder() async {
        let todayID = WeightReminderID.forDate(Date(), tz: .current)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [todayID])
        AppLogger.notifications.info("Cancelled today's weight reminder: \(todayID)")
    }

    /// Cancel all pending weight reminders
    /// Filters by "weight-" prefix to avoid affecting Fasting notifications
    func cancelAllWeightReminders() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let weightIDs = requests
            .filter { $0.identifier.hasPrefix("weight-") }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: weightIDs)
        AppLogger.notifications.info("Cancelled \(weightIDs.count) weight reminders")
    }

    // MARK: - Authorization (Delegated to NotificationManager)

    /// Request notification authorization
    /// Delegates to NotificationManager.shared (reuses Fasting auth)
    ///
    /// - Parameter completion: Called with result (granted or denied)
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        NotificationManager.shared.requestAuthorization(completion: completion)
    }

    /// Get current authorization status
    /// Delegates to NotificationManager.shared
    ///
    /// - Parameter completion: Called with current status
    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        NotificationManager.shared.getAuthorizationStatus(completion: completion)
    }

    // MARK: - Debug Helpers

    /// Print all pending weight reminders (debug only)
    func debugPrintPendingWeightReminders() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let weightRequests = requests.filter { $0.identifier.hasPrefix("weight-") }

        AppLogger.notifications.debug("Pending Weight Reminders: \(weightRequests.count)")

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        for request in weightRequests {
            if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                let fireDate = Date(timeIntervalSinceNow: trigger.timeInterval)
                AppLogger.notifications.debug("  \(request.identifier) → \(formatter.string(from: fireDate))")
            }
        }
    }

    /// Check if weight reminders are enabled in user settings
    /// Convenience helper for UI state
    ///
    /// - Returns: True if user has enabled weight reminders
    static func areRemindersEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "weightRemindersEnabled")
    }

    /// Get preferred reminder time from user settings
    /// Convenience helper for UI state
    ///
    /// - Returns: DateComponents with hour/minute, or default (7:30 AM)
    static func getPreferredTime() -> DateComponents {
        if let timeData = UserDefaults.standard.data(forKey: "weightReminderTime"),
           let components = try? JSONDecoder().decode(DateComponents.self, from: timeData) {
            return components
        }

        // Default: 7:30 AM
        var components = DateComponents()
        components.hour = 7
        components.minute = 30
        return components
    }

    /// Save preferred reminder time to user settings
    /// Convenience helper for settings UI
    ///
    /// - Parameter components: DateComponents with hour/minute
    static func savePreferredTime(_ components: DateComponents) {
        if let timeData = try? JSONEncoder().encode(components) {
            UserDefaults.standard.set(timeData, forKey: "weightReminderTime")
        }
    }

    /// Get quiet hours from user settings
    /// Convenience helper for UI state
    ///
    /// - Returns: Quiet hours if enabled, otherwise nil (can span midnight)
    static func getQuietHours() -> WeightQuietHours? {
        guard UserDefaults.standard.bool(forKey: "quietHoursEnabled") else {
            return nil
        }

        if let startData = UserDefaults.standard.data(forKey: "quietHoursStart"),
           let endData = UserDefaults.standard.data(forKey: "quietHoursEnd"),
           let start = try? JSONDecoder().decode(DateComponents.self, from: startData),
           let end = try? JSONDecoder().decode(DateComponents.self, from: endData) {
            return WeightQuietHours(start: start, end: end)
        }

        // Default: 9 PM - 6:30 AM
        var start = DateComponents()
        start.hour = 21
        start.minute = 0

        var end = DateComponents()
        end.hour = 6
        end.minute = 30

        return WeightQuietHours(start: start, end: end)
    }

    /// Get skip weekdays from user settings
    /// Convenience helper for UI state
    ///
    /// - Returns: Set of weekdays to skip (1=Sunday, 7=Saturday)
    static func getSkipWeekdays() -> Set<Int> {
        if let array = UserDefaults.standard.array(forKey: "skipWeekdays") as? [Int] {
            return Set(array)
        }
        return []
    }

    // MARK: - Additional Notification Types (Phase 2a enhancement)
    // TODO: Implement scheduling for new notification types when ready
    // The UI settings and message content are ready, but scheduling logic needs:
    // 1. Separate notification categories for each type
    // 2. Frequency-based scheduling (daily, every other day, twice a week, weekly)
    // 3. Unique identifiers for each notification type
    // 4. Coordination with existing weight reminder scheduling
    //
    // For now, the infrastructure is in place:
    // - WeightControlCenterViewModel has the @Published properties and save methods
    // - WeightNotificationMessages has the content arrays
    // - UI controls exist in WeightControlCenterView
    //
    // Next steps:
    // - Add scheduleDidYouKnow(), scheduleMotivational(), scheduleActionSteps() methods
    // - Integrate frequency-based scheduling logic
    // - Update ViewModel save methods to call scheduling functions
}
