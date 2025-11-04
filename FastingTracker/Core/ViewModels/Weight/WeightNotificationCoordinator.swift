
import Foundation
import UserNotifications

enum WeightReminderTimingMode: String, Codable, CaseIterable {
    case specificTime = "Specific Time"
    case beforeFastingGoal = "Before Fasting Goal"
    case afterWakingUp = "After Waking Up"
}

enum WeightNotificationFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case everyOtherDay = "Every Other Day"
    case twiceWeek = "Twice a Week"
    case weekly = "Weekly"
}

@MainActor
protocol WeightNotificationManaging: AnyObject {
    func requestAuthorization(completion: @escaping (Bool) -> Void)
    func cancelAllWeightReminders() async
    func scheduleNextReminder(
        preferredTime: DateComponents,
        quietHours: WeightQuietHours?,
        skipWeekdays: Set<Int>
    ) async throws
    func debugPrintPendingWeightReminders() async
}

@MainActor
protocol WeightNotificationCoordinating: ObservableObject {
    var weightRemindersEnabled: Bool { get set }
    var timingMode: WeightReminderTimingMode { get set }
    var minutesOffset: Int { get set }
    var preferredReminderTime: Date { get set }
    var quietHoursEnabled: Bool { get set }
    var quietHoursStart: Date { get set }
    var quietHoursEnd: Date { get set }
    var skipWeekdays: Set<Int> { get set }
    var didYouKnowEnabled: Bool { get set }
    var didYouKnowFrequency: WeightNotificationFrequency { get set }
    var motivationalEnabled: Bool { get set }
    var motivationalFrequency: WeightNotificationFrequency { get set }
    var actionStepsEnabled: Bool { get set }
    var actionStepsFrequency: WeightNotificationFrequency { get set }

    func loadSettings()
    func handleReminderToggle(_ enabled: Bool)
    func saveTimingMode()
    func saveMinutesOffset()
    func savePreferredTime()
    func saveQuietHours()
    func saveSkipWeekdays()
    func saveDidYouKnowSettings()
    func saveMotivationalSettings()
    func saveActionStepsSettings()
    func scheduleNextReminder()
    func debugPendingNotifications() async
}

@MainActor
final class WeightNotificationCoordinator: WeightNotificationCoordinating {

    @Published var weightRemindersEnabled: Bool = false
    @Published var timingMode: WeightReminderTimingMode = .specificTime
    @Published var minutesOffset: Int = 30
    @Published var preferredReminderTime: Date = Date()
    @Published var quietHoursEnabled: Bool = false
    @Published var quietHoursStart: Date = Date()
    @Published var quietHoursEnd: Date = Date()
    @Published var skipWeekdays: Set<Int> = []

    @Published var didYouKnowEnabled: Bool = false
    @Published var didYouKnowFrequency: WeightNotificationFrequency = .daily
    @Published var motivationalEnabled: Bool = false
    @Published var motivationalFrequency: WeightNotificationFrequency = .daily
    @Published var actionStepsEnabled: Bool = false
    @Published var actionStepsFrequency: WeightNotificationFrequency = .daily

    private let userDefaults: UserDefaults
    private let notificationManager: WeightNotificationManaging

    private let weightRemindersEnabledKey = "weightRemindersEnabled"
    private let timingModeKey = "weightReminderTimingMode"
    private let minutesOffsetKey = "weightReminderMinutesOffset"
    private let weightReminderTimeKey = "weightReminderTime"
    private let quietHoursEnabledKey = "quietHoursEnabled"
    private let quietHoursStartKey = "quietHoursStart"
    private let quietHoursEndKey = "quietHoursEnd"
    private let skipWeekdaysKey = "skipWeekdays"

    private let didYouKnowEnabledKey = "didYouKnowEnabled"
    private let didYouKnowFrequencyKey = "didYouKnowFrequency"
    private let motivationalEnabledKey = "motivationalEnabled"
    private let motivationalFrequencyKey = "motivationalFrequency"
    private let actionStepsEnabledKey = "actionStepsEnabled"
    private let actionStepsFrequencyKey = "actionStepsFrequency"

    init(weightManager: WeightManager,
         userDefaults: UserDefaults = .standard,
         notificationManager: WeightNotificationManaging? = nil) {
        _ = weightManager  // Reserved for future integrations (HealthKit sync hooks)
        self.userDefaults = userDefaults
        self.notificationManager = notificationManager ?? WeightNotificationManager.shared
        loadSettings()
    }

    func loadSettings() {
        weightRemindersEnabled = userDefaults.bool(forKey: weightRemindersEnabledKey)
        if let rawTiming = userDefaults.string(forKey: timingModeKey),
           let mode = WeightReminderTimingMode(rawValue: rawTiming) {
            timingMode = mode
        }
        minutesOffset = userDefaults.integer(forKey: minutesOffsetKey)
        if let reminderDate = userDefaults.object(forKey: weightReminderTimeKey) as? Date {
            preferredReminderTime = reminderDate
        }
        quietHoursEnabled = userDefaults.bool(forKey: quietHoursEnabledKey)
        if let start = userDefaults.object(forKey: quietHoursStartKey) as? Date {
            quietHoursStart = start
        }
        if let end = userDefaults.object(forKey: quietHoursEndKey) as? Date {
            quietHoursEnd = end
        }
        if let savedSkip = userDefaults.array(forKey: skipWeekdaysKey) as? [Int] {
            skipWeekdays = Set(savedSkip)
        }

        didYouKnowEnabled = userDefaults.bool(forKey: didYouKnowEnabledKey)
        if let rawDidYouKnow = userDefaults.string(forKey: didYouKnowFrequencyKey),
           let frequency = WeightNotificationFrequency(rawValue: rawDidYouKnow) {
            didYouKnowFrequency = frequency
        }
        motivationalEnabled = userDefaults.bool(forKey: motivationalEnabledKey)
        if let rawMotivation = userDefaults.string(forKey: motivationalFrequencyKey),
           let frequency = WeightNotificationFrequency(rawValue: rawMotivation) {
            motivationalFrequency = frequency
        }
        actionStepsEnabled = userDefaults.bool(forKey: actionStepsEnabledKey)
        if let rawActionSteps = userDefaults.string(forKey: actionStepsFrequencyKey),
           let frequency = WeightNotificationFrequency(rawValue: rawActionSteps) {
            actionStepsFrequency = frequency
        }
    }

    func handleReminderToggle(_ enabled: Bool) {
        self.userDefaults.set(enabled, forKey: weightRemindersEnabledKey)
        self.weightRemindersEnabled = enabled

        if enabled {
            self.notificationManager.requestAuthorization { granted in
                Task { @MainActor in
                    if granted {
                        self.scheduleNextReminder()
                        AppLogger.notifications.info("Weight reminders enabled")
                    } else {
                        self.weightRemindersEnabled = false
                        self.userDefaults.set(false, forKey: self.weightRemindersEnabledKey)
                        AppLogger.notifications.warning("User denied notification authorization")
                    }
                }
            }
        } else {
            Task {
                await self.notificationManager.cancelAllWeightReminders()
                AppLogger.notifications.info("Weight reminders disabled")
            }
        }
    }

    func saveTimingMode() {
        self.userDefaults.set(self.timingMode.rawValue, forKey: timingModeKey)

        if self.weightRemindersEnabled {
            self.scheduleNextReminder()
            AppLogger.notifications.debug("Timing mode updated to \(self.timingMode.rawValue)")
        }
    }

    func saveMinutesOffset() {
        self.userDefaults.set(self.minutesOffset, forKey: minutesOffsetKey)

        if self.weightRemindersEnabled {
            self.scheduleNextReminder()
            AppLogger.notifications.debug("Minutes offset updated to \(self.minutesOffset)")
        }
    }

    func savePreferredTime() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: self.preferredReminderTime)

        if let timeData = try? JSONEncoder().encode(components) {
            self.userDefaults.set(timeData, forKey: weightReminderTimeKey)
        }

        if self.weightRemindersEnabled {
            self.scheduleNextReminder()
            AppLogger.notifications.debug("Preferred reminder time updated")
        }
    }

    func saveQuietHours() {
        self.userDefaults.set(self.quietHoursEnabled, forKey: quietHoursEnabledKey)
        self.userDefaults.set(self.quietHoursStart, forKey: quietHoursStartKey)
        self.userDefaults.set(self.quietHoursEnd, forKey: quietHoursEndKey)
        self.userDefaults.set(Array(self.skipWeekdays), forKey: skipWeekdaysKey)

        if self.weightRemindersEnabled {
            self.scheduleNextReminder()
            AppLogger.notifications.debug("Quiet hours updated")
        }
    }

    func saveSkipWeekdays() {
        let array = Array(self.skipWeekdays)
        self.userDefaults.set(array, forKey: skipWeekdaysKey)

        if self.weightRemindersEnabled {
            self.scheduleNextReminder()
            AppLogger.notifications.debug("Skip weekdays updated")
        }
    }

    func saveDidYouKnowSettings() {
        self.userDefaults.set(self.didYouKnowEnabled, forKey: didYouKnowEnabledKey)
        self.userDefaults.set(self.didYouKnowFrequency.rawValue, forKey: didYouKnowFrequencyKey)
        AppLogger.notifications.debug("Did You Know settings updated: enabled=\(self.didYouKnowEnabled), frequency=\(self.didYouKnowFrequency.rawValue)")
    }

    func saveMotivationalSettings() {
        self.userDefaults.set(self.motivationalEnabled, forKey: motivationalEnabledKey)
        self.userDefaults.set(self.motivationalFrequency.rawValue, forKey: motivationalFrequencyKey)
        AppLogger.notifications.debug("Motivational settings updated: enabled=\(self.motivationalEnabled), frequency=\(self.motivationalFrequency.rawValue)")
    }

    func saveActionStepsSettings() {
        self.userDefaults.set(self.actionStepsEnabled, forKey: actionStepsEnabledKey)
        self.userDefaults.set(self.actionStepsFrequency.rawValue, forKey: actionStepsFrequencyKey)
        AppLogger.notifications.debug("Action Steps settings updated: enabled=\(self.actionStepsEnabled), frequency=\(self.actionStepsFrequency.rawValue)")
    }

    func scheduleNextReminder() {
        guard weightRemindersEnabled else { return }

        Task {
            let calendar = Calendar.current
            let preferredComponents = calendar.dateComponents([.hour, .minute], from: self.preferredReminderTime)

            var quietHours: WeightQuietHours?
            if self.quietHoursEnabled {
                let start = calendar.dateComponents([.hour, .minute], from: self.quietHoursStart)
                let end = calendar.dateComponents([.hour, .minute], from: self.quietHoursEnd)
                quietHours = WeightQuietHours(start: start, end: end)
            }

            do {
                try await self.notificationManager.scheduleNextReminder(
                    preferredTime: preferredComponents,
                    quietHours: quietHours,
                    skipWeekdays: self.skipWeekdays
                )
                AppLogger.notifications.info("Next weight reminder scheduled successfully")
                await self.debugPendingNotifications()
            } catch {
                AppLogger.notifications.error("Failed to schedule weight reminder: \(error.localizedDescription)")
            }
        }
    }

    func debugPendingNotifications() async {
        await self.notificationManager.debugPrintPendingWeightReminders()
    }
}
