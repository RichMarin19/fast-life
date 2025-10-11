import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let milestoneIdentifierPrefix = "fastingMilestone_"
    private let hydrationIdentifierPrefix = "hydration_"
    private let didYouKnowIdentifierPrefix = "didyouknow_"
    private let stageIdentifierPrefix = "stage_"
    private let goalReminderIdentifierPrefix = "goalreminder_"

    override private init() {
        super.init()
        self.notificationCenter.delegate = self
        self.setupNotificationCategories()
    }

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        self.notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        self.notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - Notification Categories Setup

    // Reference: https://developer.apple.com/documentation/usernotifications/declaring_your_actionable_notification_types

    private func setupNotificationCategories() {
        // Action to disable a specific stage notification
        let disableAction = UNNotificationAction(
            identifier: "DISABLE_STAGE",
            title: "Disable This Stage",
            options: [.destructive]
        )

        // Category for stage transition notifications
        let stageCategory = UNNotificationCategory(
            identifier: "STAGE_NOTIFICATION",
            actions: [disableAction],
            intentIdentifiers: [],
            options: []
        )

        self.notificationCenter.setNotificationCategories([stageCategory])
    }

    // MARK: - Reschedule Notifications

    // Called when user edits start time or changes notification settings during active fast

    func rescheduleNotifications(
        for session: FastingSession,
        goalHours: Double,
        currentStreak: Int = 0,
        longestStreak: Int = 0
    ) {
        print("\n🔄 RESCHEDULING NOTIFICATIONS")
        print("  Reason: User edited start time")
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        print("  New start time: \(formatter.string(from: session.startTime))")
        print("  Goal: \(goalHours)h")

        // Cancel all existing notifications
        self.cancelAllNotifications()
        print("  • Cancelled all previous notifications")

        // Reschedule based on current settings
        self.scheduleAllNotifications(
            for: session,
            goalHours: goalHours,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )
    }

    // MARK: - Notification Delegate Methods

    // Reference: https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let notification = response.notification
        let identifier = notification.request.identifier

        // Handle "Disable This Stage" action button
        if response.actionIdentifier == "DISABLE_STAGE" {
            // Extract stage hour from notification identifier (e.g., "stage_12" -> 12)
            if let stageHourString = identifier.split(separator: "_").last,
               let stageHour = Int(stageHourString) {
                // Save disabled preference
                let stageKey = "disabledStage_\(stageHour)h"
                UserDefaults.standard.set(true, forKey: stageKey)
                print("Stage \(stageHour)h notifications disabled by user")
            }
        }
        // Handle tapping the notification itself (deep link to stage detail view)
        else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // Check if this is a stage transition notification
            if identifier.hasPrefix(self.stageIdentifierPrefix) {
                // Extract stage hour from userInfo
                if let stageHour = notification.request.content.userInfo["stageHour"] as? Int {
                    // Post notification to open stage detail view
                    // Reference: https://developer.apple.com/documentation/foundation/notificationcenter
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenStageDetail"),
                        object: nil,
                        userInfo: ["stageHour": stageHour]
                    )
                    print("Opening stage detail view for \(stageHour)h stage")
                }
            }
        }
        completionHandler()
    }

    // Allow notifications to show while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func scheduleGoalNotification(
        for session: FastingSession,
        goalHours: Double,
        currentStreak: Int = 0,
        longestStreak: Int = 0
    ) {
        self.cancelGoalNotification() // Clear any existing notifications

        let startTime = session.startTime

        // Schedule 12-hour milestone
        self.scheduleMilestone(
            at: 12,
            startTime: startTime,
            goalHours: goalHours,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )

        // Schedule 16-hour milestone
        self.scheduleMilestone(
            at: 16,
            startTime: startTime,
            goalHours: goalHours,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )

        // Schedule hourly milestones after 16 hours until goal
        if goalHours > 16 {
            for hour in 17 ... Int(goalHours) {
                self.scheduleMilestone(
                    at: Double(hour),
                    startTime: startTime,
                    goalHours: goalHours,
                    currentStreak: currentStreak,
                    longestStreak: longestStreak
                )
            }
        }

        // Final goal completion notification
        self.scheduleGoalCompletion(
            startTime: startTime,
            goalHours: goalHours,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )
    }

    private func scheduleMilestone(
        at hours: Double,
        startTime: Date,
        goalHours: Double,
        currentStreak: Int = 0,
        longestStreak: Int = 0
    ) {
        let identifier = "\(milestoneIdentifierPrefix)\(Int(hours))"
        let triggerDate = startTime.addingTimeInterval(hours * 3600)
        let timeInterval = triggerDate.timeIntervalSinceNow

        guard timeInterval > 0 else { return }

        let content = UNMutableNotificationContent()
        let hoursRemaining = Int(goalHours - hours)

        // Get motivational message with streak context
        let message = self.getMotivationalMessage(
            forHour: Int(hours),
            hoursRemaining: hoursRemaining,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )
        content.title = message.title
        content.body = message.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        self.notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling milestone notification: \(error)")
            }
        }
    }

    private func scheduleGoalCompletion(
        startTime: Date,
        goalHours: Double,
        currentStreak: Int = 0,
        longestStreak: Int = 0
    ) {
        let identifier = "\(milestoneIdentifierPrefix)complete"
        let triggerDate = startTime.addingTimeInterval(goalHours * 3600)
        let timeInterval = triggerDate.timeIntervalSinceNow

        guard timeInterval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "🎉 Goal Achieved!"

        // Add streak context to goal completion
        var bodyMessage = "Congratulations! You've completed your \(Int(goalHours))-hour fast! Your body thanks you! 💪"

        // Check if they're about to tie or break their PR
        let nextStreak = currentStreak + 1
        if nextStreak == longestStreak, longestStreak > 0 {
            bodyMessage += "\n\n🔥 You're about to TIE your longest streak of \(longestStreak) days! Keep it going!"
        } else if nextStreak > longestStreak, longestStreak > 0 {
            bodyMessage += "\n\n🏆 NEW PERSONAL RECORD! You're about to break your longest streak of \(longestStreak) days!"
        }

        content.body = bodyMessage
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        self.notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling goal completion: \(error)")
            }
        }
    }

    func cancelGoalNotification() {
        // Cancel all milestone notifications
        self.notificationCenter.getPendingNotificationRequests { requests in
            let identifiers = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(self.milestoneIdentifierPrefix) }
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    private func getMotivationalMessage(
        forHour hour: Int,
        hoursRemaining: Int,
        currentStreak: Int = 0,
        longestStreak: Int = 0
    ) -> (title: String, body: String) {
        // Check if they're approaching a PR
        let nextStreak = currentStreak + 1
        let isApproachingPR = nextStreak >= longestStreak && longestStreak > 0

        let motivationalQuotes: [String]
        if isApproachingPR {
            // Use PR-focused motivational messages
            motivationalQuotes = [
                "You're on track for a new record! 🏆",
                "Personal Record in sight! Keep pushing! 💪",
                "This could be your longest streak yet! 🔥",
                "You're making history today!",
                "Breaking records, one hour at a time! 🚀",
                "Your best streak is within reach!",
                "Champion mindset! You're crushing your PR!",
                "This is your moment to shine! ⭐",
                "Record-breaking performance! Keep it up!",
                "You're rewriting your own limits! 💫",
            ]
        } else {
            motivationalQuotes = [
                "You're stronger than you think! 💪",
                "Your willpower is incredible!",
                "Keep going, you're doing amazing!",
                "Every hour brings you closer to your goal!",
                "Your body is healing itself right now!",
                "You're making incredible progress!",
                "Stay strong, you've got this!",
                "Your dedication is inspiring!",
                "Mind over matter - you're crushing it!",
                "One step closer to a healthier you!",
            ]
        }

        let bodyScienceMessages: [Int: String] = [
            12: "Your body has depleted its glycogen stores and is now burning fat for fuel. Insulin levels are dropping significantly.",
            13: "Autophagy is beginning - your cells are cleaning out damaged components and regenerating.",
            14: "Human growth hormone production is increasing, helping preserve muscle mass while burning fat.",
            15: "Your body is deep in fat-burning mode. Mental clarity is often at its peak during this phase.",
            16: "You've entered deep autophagy. Your body is recycling old proteins and clearing out cellular debris.",
            17: "Ketone production is elevated, providing clean energy for your brain and body.",
            18: "Your immune system is strengthening as inflammatory markers decrease.",
            19: "Cellular repair processes are in full swing. Your body is working hard to renew itself.",
            20: "Maximum autophagy benefits! Your cells are regenerating and your metabolic health is improving.",
            21: "You're in an advanced fasting state. Mental clarity and focus are typically exceptional.",
            22: "Deep cellular cleansing is occurring. Your body is optimizing its internal systems.",
            23: "Stem cell regeneration is enhanced at this stage. Your body is renewing from within.",
            24: "You've reached a full day! Powerful metabolic changes are happening throughout your body.",
        ]

        // Select random motivational quote
        let randomQuote = motivationalQuotes.randomElement() ?? "Keep going strong!"

        // Get body science info if available for this hour
        let bodyInfo = bodyScienceMessages[hour] ?? ""

        // Build the body message
        var bodyMessage = randomQuote

        if !bodyInfo.isEmpty {
            bodyMessage += "\n\n\(bodyInfo)"
        }

        // Add streak PR information if approaching or breaking record
        if isApproachingPR {
            if nextStreak == longestStreak {
                bodyMessage += "\n\n🔥 Current streak: \(currentStreak) days. One more goal-met fast ties your record of \(longestStreak)!"
            } else if nextStreak > longestStreak {
                bodyMessage += "\n\n🏆 Current streak: \(currentStreak) days. You're breaking your personal record of \(longestStreak) days!"
            }
        }

        if hoursRemaining > 0 {
            bodyMessage += "\n\nOnly \(hoursRemaining) hour\(hoursRemaining == 1 ? "" : "s") till your goal! 🎯"
        }

        let title = "🔥 \(hour)-Hour Milestone!"

        return (title: title, body: bodyMessage)
    }

    // MARK: - New Notification System Based on User Settings

    /// Schedule all enabled notifications based on user settings and fasting session
    func scheduleAllNotifications(
        for session: FastingSession,
        goalHours: Double,
        currentStreak: Int = 0,
        longestStreak: Int = 0
    ) {
        // Cancel any existing notifications first
        self.cancelAllNotifications()

        // Check if notifications are enabled at all
        // Default to true if user hasn't set preference yet (first-time users)
        // Reference: https://developer.apple.com/documentation/foundation/userdefaults/1408805-bool
        let notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        guard notificationsEnabled else {
            print("Notifications disabled by user - skipping schedule")
            return
        }

        // Check and reset daily tracking if it's a new day
        self.checkAndResetDailyTracking()

        // Get notification mode to adjust frequency
        let mode = UserDefaults.standard.string(forKey: "notificationMode") ?? "balanced"

        // Schedule each enabled notification type (default to true for first-time users)
        let hydrationEnabled = UserDefaults.standard.object(forKey: "notif_hydration") as? Bool ?? true
        if hydrationEnabled {
            self.scheduleHydrationReminders(for: session, mode: mode, goalHours: goalHours)
        }

        let didYouKnowEnabled = UserDefaults.standard.object(forKey: "notif_didyouknow") as? Bool ?? true
        if didYouKnowEnabled {
            self.scheduleDidYouKnowFacts(for: session, mode: mode)
        }

        let milestonesEnabled = UserDefaults.standard.object(forKey: "notif_milestones") as? Bool ?? true
        if milestonesEnabled {
            self.scheduleMilestoneNotifications(
                for: session,
                goalHours: goalHours,
                currentStreak: currentStreak,
                longestStreak: longestStreak
            )
        }

        let stagesEnabled = UserDefaults.standard.object(forKey: "notif_stages") as? Bool ?? true
        if stagesEnabled {
            self.scheduleStageTransitions(for: session, mode: mode, goalHours: goalHours)
            print("Stage transitions scheduled for goal: \(goalHours)h")
        }

        let goalReminderEnabled = UserDefaults.standard.object(forKey: "notif_goalreminder") as? Bool ?? true
        if goalReminderEnabled {
            self.scheduleGoalReminders(for: session, goalHours: goalHours)
        }

        print("✅ All notifications scheduled successfully")

        // Debug: Print what's actually pending in the system
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.debugPrintPendingNotifications()
        }
    }

    // MARK: - Hydration Reminders

    private func scheduleHydrationReminders(for session: FastingSession, mode: String, goalHours: Double) {
        let triggerSetting = UserDefaults.standard.string(forKey: "trigger_hydration") ?? "every3h"
        let startTime = session.startTime

        // Get max per day limit from user settings
        // If user hasn't set a limit yet, default to 8 reminders (legacy behavior)
        let maxReminders: Int
        if let userSetMax = UserDefaults.standard.object(forKey: "maxHydrationNotificationsPerDay") as? Int {
            maxReminders = userSetMax
        } else {
            maxReminders = 8 // Default to allow reminders throughout the fast
        }

        // Determine interval based on trigger setting
        let intervalHours: Double
        switch triggerSetting {
        case "every2h": intervalHours = 2
        case "every3h": intervalHours = 3
        case "every4h": intervalHours = 4
        case "custom": intervalHours = 3 // TODO: Add custom interval UI
        default: intervalHours = 3
        }

        // Schedule hydration reminders throughout the fast, up to goal hours
        // Spread them evenly across the fast duration
        var currentHour = intervalHours
        var reminderCount = 0

        while currentHour <= goalHours, reminderCount < maxReminders {
            self.scheduleHydrationReminder(at: currentHour, startTime: startTime, reminderNumber: reminderCount + 1)
            currentHour += intervalHours
            reminderCount += 1
        }
    }

    private func scheduleHydrationReminder(at hours: Double, startTime: Date, reminderNumber: Int) {
        let identifier = "\(hydrationIdentifierPrefix)\(Int(hours))"
        let triggerDate = startTime.addingTimeInterval(hours * 3600)
        let timeInterval = triggerDate.timeIntervalSinceNow

        guard timeInterval > 0 else { return }
        guard !self.isQuietHours(date: triggerDate) else { return }

        let content = UNMutableNotificationContent()
        content.title = "💧 Stay Hydrated"
        content.body = self.getHydrationMessage()
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        self.notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling hydration reminder: \(error)")
            }
        }
    }

    private func getHydrationMessage() -> String {
        let messages = [
            "Time to drink some water! Staying hydrated helps your body process the fast more effectively.",
            "Hydration check! Water, electrolytes, or herbal tea keep you feeling your best during your fast.",
            "Don't forget to hydrate! Your body needs water to maximize the benefits of fasting.",
            "Water break! Proper hydration supports fat burning and mental clarity.",
            "Stay hydrated! Water helps flush toxins and keeps your metabolism running smoothly.",
        ]
        return messages.randomElement() ?? messages[0]
    }

    // MARK: - Did You Know Facts

    private func scheduleDidYouKnowFacts(for session: FastingSession, mode: String) {
        let triggerSetting = UserDefaults.standard.string(forKey: "trigger_didyouknow") ?? "midmorning"
        let wakeTimeString = UserDefaults.standard.string(forKey: "wakeTime") ?? "07:00"

        // Calculate notification time based on trigger
        var notificationDate = Calendar.current.startOfDay(for: Date())

        switch triggerSetting {
        case "afterwake":
            // 1 hour after wake time
            if let wakeTime = parseTime(wakeTimeString) {
                notificationDate = Calendar.current.date(byAdding: .hour, value: 1, to: wakeTime) ?? notificationDate
            }
        case "midmorning":
            notificationDate = Calendar.current
                .date(bySettingHour: 10, minute: 0, second: 0, of: notificationDate) ?? notificationDate
        case "afternoon":
            notificationDate = Calendar.current
                .date(bySettingHour: 14, minute: 0, second: 0, of: notificationDate) ?? notificationDate
        case "evening":
            notificationDate = Calendar.current
                .date(bySettingHour: 19, minute: 0, second: 0, of: notificationDate) ?? notificationDate
        default:
            notificationDate = Calendar.current
                .date(bySettingHour: 10, minute: 0, second: 0, of: notificationDate) ?? notificationDate
        }

        // Only schedule if it's in the future
        let timeInterval = notificationDate.timeIntervalSinceNow
        guard timeInterval > 0 else { return }

        let identifier = "\(didYouKnowIdentifierPrefix)today"
        let content = UNMutableNotificationContent()
        content.title = "💡 Did You Know?"
        content.body = self.getDidYouKnowFact()
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        self.notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling did you know fact: \(error)")
            }
        }
    }

    private func getDidYouKnowFact() -> String {
        let facts = [
            "Fasting for 12+ hours activates autophagy, your body's cellular cleanup process that removes damaged components.",
            "After 16 hours of fasting, your body shifts from burning glucose to burning fat for energy.",
            "Intermittent fasting can increase human growth hormone levels by up to 5x, helping preserve muscle mass.",
            "Fasting gives your digestive system a break, reducing inflammation and improving gut health.",
            "Studies show intermittent fasting can improve brain function and may protect against neurodegenerative diseases.",
            "During a fast, insulin levels drop significantly, making it easier for your body to access stored fat.",
            "Fasting activates genes that help your body resist stress, disease, and aging.",
            "Your body starts producing ketones after about 12 hours of fasting, providing clean energy for your brain.",
        ]
        return facts.randomElement() ?? facts[0]
    }

    // MARK: - Milestone Notifications (Enhanced)

    private func scheduleMilestoneNotifications(
        for session: FastingSession,
        goalHours: Double,
        currentStreak: Int,
        longestStreak: Int
    ) {
        print("\n🎯 === MILESTONE NOTIFICATION SCHEDULING ===")
        print(
            "Goal: \(goalHours)h | Trigger offset: \(UserDefaults.standard.string(forKey: "trigger_milestones") ?? "whenreached")"
        )

        let triggerSetting = UserDefaults.standard.string(forKey: "trigger_milestones") ?? "whenreached"
        let startTime = session.startTime

        // Get max per day limit from user settings
        // If user hasn't set a limit yet, default to all milestones (legacy behavior)
        let maxMilestones: Int
        if let userSetMax = UserDefaults.standard.object(forKey: "maxMilestoneNotificationsPerDay") as? Int {
            maxMilestones = userSetMax
        } else {
            maxMilestones = 20 // Default to allow all milestones
        }

        // Determine offset based on trigger
        let offsetMinutes: Int
        switch triggerSetting {
        case "15before": offsetMinutes = -15
        case "30before": offsetMinutes = -30
        case "1hbefore": offsetMinutes = -60
        case "whenreached": offsetMinutes = 0
        default: offsetMinutes = 0
        }

        // Schedule key milestones based on user's goal
        // Industry standard: Only notify for milestones user will actually reach
        // Reference: https://developer.apple.com/design/human-interface-guidelines/notifications
        // Key milestones: 4h, 8h, 12h, 16h, 18h, 20h, 24h
        let keyMilestones: [Double] = [4, 8, 12, 16, 18, 20, 24]
        let reachableMilestones = keyMilestones.filter { $0 <= goalHours }

        print("📋 Key milestones: \(keyMilestones.map { "\($0)h" }.joined(separator: ", "))")
        print("✅ Reachable milestones (≤ goal): \(reachableMilestones.map { "\($0)h" }.joined(separator: ", "))")

        let skippedMilestones = keyMilestones.filter { $0 > goalHours }
        if !skippedMilestones.isEmpty {
            print("⏭️  Skipped milestones (> goal): \(skippedMilestones.map { "\($0)h" }.joined(separator: ", "))")
        }

        // Add hourly milestones after 24h for extended fasts
        let hourlyMilestones = goalHours > 24 ? (25 ... Int(goalHours)).map { Double($0) } : []
        let allMilestones = reachableMilestones + hourlyMilestones

        // Limit to max per day, prioritizing the goal completion and key milestones
        var selectedMilestones: [Double] = []

        // Always include goal completion if it's a key milestone
        if allMilestones.contains(goalHours) {
            selectedMilestones.append(goalHours)
        }

        // Add other milestones up to the limit
        let remainingSlots = maxMilestones - selectedMilestones.count
        let otherMilestones = allMilestones.filter { $0 != goalHours && $0 <= goalHours }

        // Take evenly distributed milestones
        if remainingSlots > 0, !otherMilestones.isEmpty {
            let step = max(1, otherMilestones.count / remainingSlots)
            var count = 0
            for (index, milestone) in otherMilestones.enumerated() {
                if count >= remainingSlots { break }
                if index % step == 0 {
                    selectedMilestones.append(milestone)
                    count += 1
                }
            }
        }

        print("\n📍 Scheduling \(selectedMilestones.count) milestone notifications:")

        var scheduledCount = 0
        var skippedPast = 0
        var skippedQuiet = 0

        for milestone in selectedMilestones {
            let notificationTime = startTime.addingTimeInterval(milestone * 3600 + Double(offsetMinutes * 60))
            let timeInterval = notificationTime.timeIntervalSinceNow

            if timeInterval <= 0 {
                skippedPast += 1
                continue
            }

            if self.isQuietHours(date: notificationTime) {
                print("🔕 Skipped \(Int(milestone))h milestone (quiet hours)")
                skippedQuiet += 1
                continue
            }

            let identifier = "\(milestoneIdentifierPrefix)\(Int(milestone))"
            let content = UNMutableNotificationContent()

            let message = self.getMotivationalMessage(
                forHour: Int(milestone),
                hoursRemaining: Int(goalHours - milestone),
                currentStreak: currentStreak,
                longestStreak: longestStreak
            )
            content.title = message.title
            content.body = message.body
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("❌ Error scheduling \(Int(milestone))h milestone: \(error)")
                } else {
                    let hoursUntil = timeInterval / 3600
                    print("✅ Scheduled \(Int(milestone))h milestone - fires in \(String(format: "%.1f", hoursUntil))h")
                }
            }
            scheduledCount += 1
        }

        print("\n📊 Milestone Scheduling Summary:")
        print("   • Total scheduled: \(scheduledCount)")
        if skippedPast > 0 {
            print("   • Skipped (in past): \(skippedPast)")
        }
        if skippedQuiet > 0 {
            print("   • Skipped (quiet hours): \(skippedQuiet)")
        }
        print("===========================================\n")
    }

    // MARK: - Stage Transitions

    private func scheduleStageTransitions(for session: FastingSession, mode: String, goalHours: Double) {
        let triggerSetting = UserDefaults.standard.string(forKey: "trigger_stages") ?? "whenentering"
        let startTime = session.startTime

        // Get max per day limit from user settings
        // If user hasn't set a limit yet (new feature), default to 10 to schedule all stages (legacy behavior)
        // Reference: https://developer.apple.com/documentation/foundation/userdefaults/1410095-object
        let maxStages: Int
        if let userSetMax = UserDefaults.standard.object(forKey: "maxStageNotificationsPerDay") as? Int {
            maxStages = userSetMax // User explicitly set a limit
        } else {
            maxStages = 10 // Default to all stages until user sets a preference
        }

        // Determine offset based on trigger
        let offsetMinutes: Int
        switch triggerSetting {
        case "whenentering": offsetMinutes = 0
        case "30into": offsetMinutes = 30
        case "1hinto": offsetMinutes = 60
        default: offsetMinutes = 0
        }

        // Define complete fasting stage timeline
        // Reference: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3946160/ (Intermittent fasting metabolic effects)
        let allStages: [(hours: Double, name: String, description: String)] = [
            (
                4,
                "🌅 Post-Absorptive",
                "Your body has finished digesting food. Blood sugar stabilizing and insulin dropping. The real fasting begins now!"
            ),
            (
                6,
                "⚙️ Glycogen Burning",
                "Your body is tapping into stored glycogen. Fat burning is ramping up as your metabolism shifts gears."
            ),
            (
                8,
                "🔄 Metabolic Switch",
                "The metabolic switch is flipping! Your body is transitioning from burning glucose to burning fat for fuel."
            ),
            (
                10,
                "🎯 Fat Adaptation",
                "You're now burning fat efficiently. Growth hormone levels are rising to preserve muscle while burning fat."
            ),
            (
                12,
                "🔥 Fat Burning Peak",
                "Glycogen stores depleted! Your body is in full fat-burning mode. Insulin at its lowest point of the day."
            ),
            (
                14,
                "🧹 Autophagy Begins",
                "Cellular cleanup has started! Your cells are identifying and removing damaged components for renewal."
            ),
            (
                16,
                "🧬 Deep Autophagy",
                "Peak autophagy activated! Your body is recycling old proteins and clearing out cellular debris at maximum efficiency."
            ),
            (
                18,
                "⚡️ Ketosis Rising",
                "Ketone production is elevated! Your brain is running on clean ketone energy. Mental clarity often peaks here."
            ),
            (
                20,
                "💪 Full Ketosis",
                "Deep ketosis achieved! Maximum cellular repair, immune system boost, and inflammation reduction happening now."
            ),
            (
                24,
                "🏆 Extended Benefits",
                "You've hit 24 hours! Stem cell regeneration enhanced. Your body is in peak renewal and anti-aging mode."
            ),
        ]

        // Use smart selection algorithm to rotate stages daily
        let selectedStages = self.selectStagesToSchedule(
            allStages: allStages,
            maxPerDay: maxStages,
            goalHours: goalHours
        )

        print("📊 Stage Notifications Setup:")
        print("  • Max per day: \(maxStages)")
        print("  • Goal hours: \(goalHours)h")
        print("  • Trigger offset: \(offsetMinutes) min")
        print("  • Selected stages: \(selectedStages.map { "\(Int($0.hours))h" }.joined(separator: ", "))")

        // Schedule only the selected stages
        var scheduledCount = 0
        for stage in selectedStages {
            let notificationTime = startTime.addingTimeInterval(stage.hours * 3600 + Double(offsetMinutes * 60))
            let timeInterval = notificationTime.timeIntervalSinceNow

            if timeInterval <= 0 {
                print(
                    "  ⏭️  Skipped \(Int(stage.hours))h stage - already passed (was \(Int(-timeInterval / 60)) min ago)"
                )
                continue
            }

            if self.isQuietHours(date: notificationTime) {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                print(
                    "  🌙 Skipped \(Int(stage.hours))h stage - quiet hours (\(formatter.string(from: notificationTime)))"
                )
                continue
            }

            let identifier = "\(stageIdentifierPrefix)\(Int(stage.hours))"
            let content = UNMutableNotificationContent()
            content.title = stage.name
            content.body = stage.description

            // Use default notification sound
            // Reference: https://developer.apple.com/documentation/usernotifications/unnotificationsound
            content.sound = .default
            content.categoryIdentifier = "STAGE_NOTIFICATION" // For action buttons

            // Add stage hour to userInfo for deep linking
            content.userInfo = ["stageHour": Int(stage.hours)]

            // Make it time-sensitive so it breaks through Focus modes
            // Reference: https://developer.apple.com/documentation/usernotifications/unmutablenotificationcontent/3821031-interruptionlevel
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("  ❌ Error scheduling \(Int(stage.hours))h stage: \(error)")
                } else {
                    let hoursUntil = timeInterval / 3600
                    print("  ✅ Scheduled \(Int(stage.hours))h stage - fires in \(String(format: "%.1f", hoursUntil))h")
                }
            }
            scheduledCount += 1
        }

        print("📊 Stage Notifications Summary: \(scheduledCount)/\(selectedStages.count) scheduled successfully")
    }

    // MARK: - Goal Reminders

    private func scheduleGoalReminders(for session: FastingSession, goalHours: Double) {
        let triggerSetting = UserDefaults.standard.string(forKey: "trigger_goalreminder") ?? "15before"
        let startTime = session.startTime

        // Determine when to send based on trigger
        let offsetMinutes: Int
        let titlePrefix: String

        switch triggerSetting {
        case "15before":
            offsetMinutes = -15
            titlePrefix = "🎯 15 Minutes Until Goal"
        case "30before":
            offsetMinutes = -30
            titlePrefix = "🎯 30 Minutes Until Goal"
        case "1hbefore":
            offsetMinutes = -60
            titlePrefix = "🎯 1 Hour Until Goal"
        case "atgoal":
            offsetMinutes = 0
            titlePrefix = "🎉 Goal Achieved!"
        default:
            offsetMinutes = -15
            titlePrefix = "🎯 Almost There"
        }

        let notificationTime = startTime.addingTimeInterval(goalHours * 3600 + Double(offsetMinutes * 60))
        let timeInterval = notificationTime.timeIntervalSinceNow

        guard timeInterval > 0 else { return }

        let identifier = "\(goalReminderIdentifierPrefix)goal"
        let content = UNMutableNotificationContent()
        content.title = titlePrefix

        if offsetMinutes < 0 {
            content.body = "You're almost at your \(Int(goalHours))-hour goal! Perfect time to prepare for breaking your fast. Consider weighing in or planning your first meal. 💪"
        } else {
            content.body = "Congratulations! You've reached your \(Int(goalHours))-hour fasting goal! Your dedication is paying off! 🎊"
        }

        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        self.notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling goal reminder: \(error)")
            }
        }
    }

    // MARK: - Rotation Tracking System

    // Tracks which notifications were sent today to ensure variety tomorrow

    private func checkAndResetDailyTracking() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check last schedule date
        if let lastDate = UserDefaults.standard.object(forKey: "lastNotificationScheduleDate") as? Date {
            let lastScheduleDay = calendar.startOfDay(for: lastDate)

            // If it's a new day, reset tracking
            if today > lastScheduleDay {
                UserDefaults.standard.removeObject(forKey: "sentStageIndicesToday")
                UserDefaults.standard.removeObject(forKey: "sentHydrationIndicesToday")
                UserDefaults.standard.removeObject(forKey: "sentMilestoneIndicesToday")
                print("New day detected - reset daily notification tracking")
            }
        }

        // Update last schedule date to today
        UserDefaults.standard.set(today, forKey: "lastNotificationScheduleDate")
    }

    private func getSentStageIndicesToday() -> [Int] {
        UserDefaults.standard.array(forKey: "sentStageIndicesToday") as? [Int] ?? []
    }

    private func saveSentStageIndices(_ indices: [Int]) {
        UserDefaults.standard.set(indices, forKey: "sentStageIndicesToday")
    }

    /// Smart stage selection algorithm
    /// Rotates through stages based on user's typical fast duration and max per day setting
    private func selectStagesToSchedule(
        allStages: [(hours: Double, name: String, description: String)],
        maxPerDay: Int,
        goalHours: Double
    ) -> [(hours: Double, name: String, description: String)] {
        // Filter stages user will actually reach based on their goal
        let reachableStages = allStages.filter { $0.hours <= goalHours }

        // Filter out disabled stages
        let enabledStages = reachableStages.filter { stage in
            let stageKey = "disabledStage_\(Int(stage.hours))h"
            return !UserDefaults.standard.bool(forKey: stageKey)
        }

        // If we can send all enabled stages, do so
        if enabledStages.count <= maxPerDay {
            return enabledStages
        }

        // Get previously sent indices to avoid immediate repeats
        let previouslySent = self.getSentStageIndicesToday()

        // Create selection pool - prioritize stages not sent recently
        var availableIndices = Array(0 ..< enabledStages.count)

        // Remove previously sent from the pool if we have enough alternatives
        if availableIndices.count - previouslySent.count >= maxPerDay {
            availableIndices.removeAll { previouslySent.contains($0) }
        }

        // Smart rotation: alternate between early and late stages
        // This ensures users get both foundational knowledge and advanced benefits
        var selectedIndices: [Int] = []

        if maxPerDay >= 2 {
            // Always include one early stage (first half) and one late stage (second half)
            let midpoint = enabledStages.count / 2

            let earlyStages = availableIndices.filter { $0 < midpoint }
            let lateStages = availableIndices.filter { $0 >= midpoint }

            if !earlyStages.isEmpty {
                selectedIndices.append(earlyStages.randomElement()!)
            }

            if !lateStages.isEmpty {
                selectedIndices.append(lateStages.randomElement()!)
            }

            // Fill remaining slots randomly from available pool
            let remainingSlots = maxPerDay - selectedIndices.count
            if remainingSlots > 0 {
                let remainingPool = availableIndices.filter { !selectedIndices.contains($0) }
                let additionalIndices = remainingPool.shuffled().prefix(remainingSlots)
                selectedIndices.append(contentsOf: additionalIndices)
            }
        } else {
            // For maxPerDay = 1, just pick one randomly
            if let randomIndex = availableIndices.randomElement() {
                selectedIndices.append(randomIndex)
            }
        }

        // Save selected indices for tomorrow's rotation
        self.saveSentStageIndices(selectedIndices)

        // Return selected stages
        return selectedIndices.sorted().map { enabledStages[$0] }
    }

    // MARK: - Utility Methods

    /// Check if a given date falls within user-configured quiet hours
    /// Per Apple HIG: Respect user's sleep/quiet time preferences
    /// Reference: https://developer.apple.com/design/human-interface-guidelines/notifications
    private func isQuietHours(date: Date) -> Bool {
        // Check if quiet hours are enabled
        let quietHoursEnabled = UserDefaults.standard.object(forKey: "quietHoursEnabled") as? Bool ?? true

        guard quietHoursEnabled else {
            return false // Quiet hours disabled, notifications allowed anytime
        }

        // Get user's quiet hours settings (default to 9 PM - 6:30 AM)
        let quietHoursStart = UserDefaults.standard.string(forKey: "quietHoursStart") ?? "21:00"
        let quietHoursEnd = UserDefaults.standard.string(forKey: "quietHoursEnd") ?? "06:30"

        // Parse time strings to hour/minute components
        guard let startComponents = parseTimeComponents(quietHoursStart),
              let endComponents = parseTimeComponents(quietHoursEnd) else {
            // Fallback to default if parsing fails
            let hour = Calendar.current.component(.hour, from: date)
            return hour >= 21 || hour < 7
        }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

        let startHour = startComponents.hour
        let startMinute = startComponents.minute
        let endHour = endComponents.hour
        let endMinute = endComponents.minute

        // Handle quiet hours that span midnight (e.g., 9 PM to 6:30 AM)
        if startHour > endHour || (startHour == endHour && startMinute > endMinute) {
            // Overnight quiet hours: After start OR before end
            let afterStart = (hour > startHour) || (hour == startHour && minute >= startMinute)
            let beforeEnd = (hour < endHour) || (hour == endHour && minute < endMinute)
            return afterStart || beforeEnd
        } else {
            // Same-day quiet hours: Between start AND end
            let afterStart = (hour > startHour) || (hour == startHour && minute >= startMinute)
            let beforeEnd = (hour < endHour) || (hour == endHour && minute < endMinute)
            return afterStart && beforeEnd
        }
    }

    /// Parse time string "HH:mm" into hour and minute components
    private func parseTimeComponents(_ timeString: String) -> (hour: Int, minute: Int)? {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]),
              hour >= 0, hour < 24,
              minute >= 0, minute < 60 else {
            return nil
        }
        return (hour, minute)
    }

    private func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: timeString) else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: components.hour ?? 7, minute: components.minute ?? 0, second: 0, of: Date())
    }

    func cancelAllNotifications() {
        self.notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Debug Helper

    // Prints all pending notifications to console for troubleshooting

    func debugPrintPendingNotifications() {
        // First check authorization status
        self.notificationCenter.getNotificationSettings { settings in
            print("\n🔔 NOTIFICATION PERMISSIONS DEBUG:")
            print("  Authorization Status: \(settings.authorizationStatus.rawValue)")
            switch settings.authorizationStatus {
            case .notDetermined:
                print("  ⚠️  NOT DETERMINED - User hasn't been asked yet")
            case .denied:
                print("  ❌ DENIED - User blocked notifications in Settings")
            case .authorized:
                print("  ✅ AUTHORIZED - Notifications allowed")
            case .provisional:
                print("  ⚠️  PROVISIONAL - Quiet notifications only")
            case .ephemeral:
                print("  ⚠️  EPHEMERAL - App Clip temporary access")
            @unknown default:
                print("  ❓ UNKNOWN STATUS")
            }
            print("  Alert Style: \(settings.alertStyle.rawValue)")
            print("  Badge Enabled: \(settings.badgeSetting == .enabled)")
            print("  Sound Enabled: \(settings.soundSetting == .enabled)")
        }

        self.notificationCenter.getPendingNotificationRequests { requests in
            print("\n🔔 PENDING NOTIFICATIONS DEBUG:")
            print("  Total pending: \(requests.count)")

            if requests.isEmpty {
                print("  ⚠️  NO NOTIFICATIONS SCHEDULED!")
                return
            }

            let stageNotifications = requests.filter { $0.identifier.hasPrefix(self.stageIdentifierPrefix) }
            let milestoneNotifications = requests.filter { $0.identifier.hasPrefix(self.milestoneIdentifierPrefix) }
            let hydrationNotifications = requests.filter { $0.identifier.hasPrefix(self.hydrationIdentifierPrefix) }
            let didYouKnowNotifications = requests.filter { $0.identifier.hasPrefix(self.didYouKnowIdentifierPrefix) }
            let goalReminderNotifications = requests
                .filter { $0.identifier.hasPrefix(self.goalReminderIdentifierPrefix) }

            print("\n  📊 Breakdown:")
            print("    Stage Transitions: \(stageNotifications.count)")
            print("    Milestones: \(milestoneNotifications.count)")
            print("    Hydration: \(hydrationNotifications.count)")
            print("    Did You Know: \(didYouKnowNotifications.count)")
            print("    Goal Reminders: \(goalReminderNotifications.count)")

            print("\n  ⏰ Next 5 Notifications:")
            let sortedRequests = requests
                .compactMap { request -> (String, Date)? in
                    guard let trigger = request.trigger as? UNTimeIntervalNotificationTrigger else { return nil }
                    let fireDate = Date(timeIntervalSinceNow: trigger.timeInterval)
                    return (request.identifier, fireDate)
                }
                .sorted { $0.1 < $1.1 }
                .prefix(5)

            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short

            for (identifier, fireDate) in sortedRequests {
                let timeUntil = fireDate.timeIntervalSinceNow
                let hoursUntil = timeUntil / 3600
                print(
                    "    • \(identifier) → \(formatter.string(from: fireDate)) (in \(String(format: "%.1f", hoursUntil))h)"
                )
            }

            print("\n")
        }
    }
}
