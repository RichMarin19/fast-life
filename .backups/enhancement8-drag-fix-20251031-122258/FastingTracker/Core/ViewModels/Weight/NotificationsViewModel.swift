import SwiftUI

/// ViewModel for Weight Reminder Notifications
/// Handles notification scheduling, preferences, and timing modes
/// Extracted from WeightControlCenterViewModel as part of Phase 8.9 Phase 2
/// Reference: HANDOFF.md - Weight Tracker Refactoring
@MainActor
class NotificationsViewModel: ObservableObject {
    // MARK: - Enums

    /// Timing mode for weight reminders
    enum TimingMode: String, Codable, CaseIterable {
        case specificTime = "Specific Time"
        case beforeFastingGoal = "Before Fasting Goal"
        case afterWakingUp = "After Waking Up"
    }

    /// Notification frequency options for user-configurable scheduling
    enum NotificationFrequency: String, Codable, CaseIterable {
        case daily = "Daily"
        case everyOtherDay = "Every Other Day"
        case twiceWeek = "Twice a Week"
        case weekly = "Weekly"
    }

    // MARK: - Published State

    // Primary Reminder Settings
    @Published var weightRemindersEnabled: Bool = false
    @Published var timingMode: TimingMode = .specificTime
    @Published var minutesOffset: Int = 30 // For beforeFastingGoal / afterWakingUp modes
    @Published var preferredReminderTime: Date = Date()
    @Published var quietHoursEnabled: Bool = false
    @Published var quietHoursStart: Date = Date()
    @Published var quietHoursEnd: Date = Date()
    @Published var skipWeekdays: Set<Int> = []

    // New notification types (Phase 2a enhancement - variable messaging)
    @Published var didYouKnowEnabled: Bool = false
    @Published var didYouKnowFrequency: NotificationFrequency = .daily
    @Published var motivationalEnabled: Bool = false
    @Published var motivationalFrequency: NotificationFrequency = .daily
    @Published var actionStepsEnabled: Bool = false
    @Published var actionStepsFrequency: NotificationFrequency = .daily

    // MARK: - Constants

    /// Weekday display data for UI
    let weekdays: [(number: Int, name: String)] = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard

    // Phase 2a: Weight notification keys (reuse WeightNotificationManager keys for consistency)
    private let weightRemindersEnabledKey = "weightRemindersEnabled"
    private let timingModeKey = "weightReminderTimingMode"
    private let minutesOffsetKey = "weightReminderMinutesOffset"
    private let weightReminderTimeKey = "weightReminderTime"
    private let quietHoursEnabledKey = "quietHoursEnabled"
    private let quietHoursStartKey = "quietHoursStart"
    private let quietHoursEndKey = "quietHoursEnd"
    private let skipWeekdaysKey = "skipWeekdays"

    // New notification type keys (Phase 2a enhancement - variable messaging)
    private let didYouKnowEnabledKey = "didYouKnowEnabled"
    private let didYouKnowFrequencyKey = "didYouKnowFrequency"
    private let motivationalEnabledKey = "motivationalEnabled"
    private let motivationalFrequencyKey = "motivationalFrequency"
    private let actionStepsEnabledKey = "actionStepsEnabled"
    private let actionStepsFrequencyKey = "actionStepsFrequency"

    // MARK: - Initialization

    init() {
        loadWeightNotificationSettings()
    }

    // MARK: - Notification Management

    /// Handle reminder toggle (enable/disable)
    func handleReminderToggle(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: weightRemindersEnabledKey)

        if enabled {
            // Request authorization and schedule
            WeightNotificationManager.shared.requestAuthorization { granted in
                Task { @MainActor in
                    if granted {
                        self.scheduleNextReminder()
                        AppLogger.notifications.info("Weight reminders enabled")
                    } else {
                        // Authorization denied - reset toggle
                        self.weightRemindersEnabled = false
                        self.userDefaults.set(false, forKey: self.weightRemindersEnabledKey)
                        AppLogger.notifications.warning("User denied notification authorization")
                    }
                }
            }
        } else {
            // Disable - cancel all weight reminders
            Task {
                await WeightNotificationManager.shared.cancelAllWeightReminders()
                AppLogger.notifications.info("Weight reminders disabled")
            }
        }
    }

    /// Save timing mode to UserDefaults and reschedule
    func saveTimingMode() {
        userDefaults.set(timingMode.rawValue, forKey: timingModeKey)

        if weightRemindersEnabled {
            scheduleNextReminder()
            AppLogger.notifications.debug("Timing mode updated to \(self.timingMode.rawValue)")
        }
    }

    /// Save minutes offset to UserDefaults and reschedule
    func saveMinutesOffset() {
        userDefaults.set(minutesOffset, forKey: minutesOffsetKey)

        if weightRemindersEnabled {
            scheduleNextReminder()
            AppLogger.notifications.debug("Minutes offset updated to \(self.minutesOffset)")
        }
    }

    /// Save preferred reminder time to UserDefaults and reschedule
    func savePreferredTime() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: preferredReminderTime)

        if let timeData = try? JSONEncoder().encode(components) {
            userDefaults.set(timeData, forKey: weightReminderTimeKey)
        }

        if weightRemindersEnabled {
            scheduleNextReminder()
            AppLogger.notifications.debug("Preferred reminder time updated")
        }
    }

    /// Save quiet hours to UserDefaults and reschedule
    func saveQuietHours() {
        userDefaults.set(quietHoursEnabled, forKey: quietHoursEnabledKey)

        let calendar = Calendar.current

        let startComponents = calendar.dateComponents([.hour, .minute], from: quietHoursStart)
        if let startData = try? JSONEncoder().encode(startComponents) {
            userDefaults.set(startData, forKey: quietHoursStartKey)
        }

        let endComponents = calendar.dateComponents([.hour, .minute], from: quietHoursEnd)
        if let endData = try? JSONEncoder().encode(endComponents) {
            userDefaults.set(endData, forKey: quietHoursEndKey)
        }

        if weightRemindersEnabled {
            scheduleNextReminder()
            AppLogger.notifications.debug("Quiet hours updated")
        }
    }

    /// Save skip weekdays to UserDefaults and reschedule
    func saveSkipWeekdays() {
        let array = Array(skipWeekdays)
        userDefaults.set(array, forKey: skipWeekdaysKey)

        if weightRemindersEnabled {
            scheduleNextReminder()
            AppLogger.notifications.debug("Skip weekdays updated")
        }
    }

    // MARK: - New Notification Types Save Methods (Phase 2a enhancement)

    /// Save Did You Know notification settings
    func saveDidYouKnowSettings() {
        userDefaults.set(didYouKnowEnabled, forKey: didYouKnowEnabledKey)
        userDefaults.set(didYouKnowFrequency.rawValue, forKey: didYouKnowFrequencyKey)

        // TODO: Reschedule Did You Know notifications when WeightNotificationManager supports them
        AppLogger.notifications.debug("Did You Know settings updated: enabled=\(self.didYouKnowEnabled), frequency=\(self.didYouKnowFrequency.rawValue)")
    }

    /// Save Motivational notification settings
    func saveMotivationalSettings() {
        userDefaults.set(motivationalEnabled, forKey: motivationalEnabledKey)
        userDefaults.set(motivationalFrequency.rawValue, forKey: motivationalFrequencyKey)

        // TODO: Reschedule Motivational notifications when WeightNotificationManager supports them
        AppLogger.notifications.debug("Motivational settings updated: enabled=\(self.motivationalEnabled), frequency=\(self.motivationalFrequency.rawValue)")
    }

    /// Save Action Steps notification settings
    func saveActionStepsSettings() {
        userDefaults.set(actionStepsEnabled, forKey: actionStepsEnabledKey)
        userDefaults.set(actionStepsFrequency.rawValue, forKey: actionStepsFrequencyKey)

        // TODO: Reschedule Action Steps notifications when WeightNotificationManager supports them
        AppLogger.notifications.debug("Action Steps settings updated: enabled=\(self.actionStepsEnabled), frequency=\(self.actionStepsFrequency.rawValue)")
    }

    // MARK: - Scheduling

    /// Schedule next weight reminder using current settings
    private func scheduleNextReminder() {
        Task {
            let calendar = Calendar.current
            let preferredComponents = calendar.dateComponents([.hour, .minute], from: preferredReminderTime)

            // Build quiet hours if enabled (supports midnight-spanning)
            var quietHours: WeightQuietHours?
            if quietHoursEnabled {
                let start = calendar.dateComponents([.hour, .minute], from: quietHoursStart)
                let end = calendar.dateComponents([.hour, .minute], from: quietHoursEnd)
                quietHours = WeightQuietHours(start: start, end: end)
            }

            do {
                try await WeightNotificationManager.shared.scheduleNextReminder(
                    preferredTime: preferredComponents,
                    quietHours: quietHours,
                    skipWeekdays: skipWeekdays
                )
                AppLogger.notifications.info("Next weight reminder scheduled successfully")

                // Debug: Print notification status
                await debugPendingNotifications()
            } catch {
                AppLogger.notifications.error("Failed to schedule weight reminder: \(error.localizedDescription)")
            }
        }
    }

    /// Debug helper: Print pending notifications to help troubleshoot
    func debugPendingNotifications() async {
        await WeightNotificationManager.shared.debugPrintPendingWeightReminders()
    }

    // MARK: - Persistence

    /// Load weight notification settings from UserDefaults
    private func loadWeightNotificationSettings() {
        // Load enabled state
        weightRemindersEnabled = userDefaults.bool(forKey: weightRemindersEnabledKey)

        // Load timing mode (default: specificTime)
        if let modeString = userDefaults.string(forKey: timingModeKey),
           let mode = TimingMode(rawValue: modeString) {
            timingMode = mode
        } else {
            timingMode = .specificTime
        }

        // Load minutes offset (default: 30)
        let savedOffset = userDefaults.integer(forKey: minutesOffsetKey)
        minutesOffset = savedOffset > 0 ? savedOffset : 30

        // Load preferred time (default: 7:30 AM)
        if let timeData = userDefaults.data(forKey: weightReminderTimeKey),
           let components = try? JSONDecoder().decode(DateComponents.self, from: timeData),
           let hour = components.hour,
           let minute = components.minute {
            let calendar = Calendar.current
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            if let date = calendar.date(from: dateComponents) {
                preferredReminderTime = date
            } else {
                preferredReminderTime = makeDefaultTime(hour: 7, minute: 30)
            }
        } else {
            preferredReminderTime = makeDefaultTime(hour: 7, minute: 30)
        }

        // Load quiet hours
        quietHoursEnabled = userDefaults.bool(forKey: quietHoursEnabledKey)

        if let startData = userDefaults.data(forKey: quietHoursStartKey),
           let startComponents = try? JSONDecoder().decode(DateComponents.self, from: startData),
           let hour = startComponents.hour,
           let minute = startComponents.minute {
            quietHoursStart = makeDefaultTime(hour: hour, minute: minute)
        } else {
            quietHoursStart = makeDefaultTime(hour: 21, minute: 0) // Default: 9 PM
        }

        if let endData = userDefaults.data(forKey: quietHoursEndKey),
           let endComponents = try? JSONDecoder().decode(DateComponents.self, from: endData),
           let hour = endComponents.hour,
           let minute = endComponents.minute {
            quietHoursEnd = makeDefaultTime(hour: hour, minute: minute)
        } else {
            quietHoursEnd = makeDefaultTime(hour: 6, minute: 30) // Default: 6:30 AM
        }

        // Load skip weekdays
        if let array = userDefaults.array(forKey: skipWeekdaysKey) as? [Int] {
            skipWeekdays = Set(array)
        } else {
            skipWeekdays = []
        }

        // Load new notification types (Phase 2a enhancement)
        didYouKnowEnabled = userDefaults.bool(forKey: didYouKnowEnabledKey)
        if let frequencyString = userDefaults.string(forKey: didYouKnowFrequencyKey),
           let frequency = NotificationFrequency(rawValue: frequencyString) {
            didYouKnowFrequency = frequency
        } else {
            didYouKnowFrequency = .daily
        }

        motivationalEnabled = userDefaults.bool(forKey: motivationalEnabledKey)
        if let frequencyString = userDefaults.string(forKey: motivationalFrequencyKey),
           let frequency = NotificationFrequency(rawValue: frequencyString) {
            motivationalFrequency = frequency
        } else {
            motivationalFrequency = .daily
        }

        actionStepsEnabled = userDefaults.bool(forKey: actionStepsEnabledKey)
        if let frequencyString = userDefaults.string(forKey: actionStepsFrequencyKey),
           let frequency = NotificationFrequency(rawValue: frequencyString) {
            actionStepsFrequency = frequency
        } else {
            actionStepsFrequency = .daily
        }
    }

    /// Helper to create a Date from hour/minute for DatePicker binding
    private func makeDefaultTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? Date()
    }
}
