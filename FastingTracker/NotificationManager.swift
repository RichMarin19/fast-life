import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let milestoneIdentifierPrefix = "fastingMilestone_"

    private init() {}

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    func scheduleGoalNotification(for session: FastingSession, goalHours: Double, currentStreak: Int = 0, longestStreak: Int = 0) {
        cancelGoalNotification() // Clear any existing notifications

        let startTime = session.startTime

        // Schedule 12-hour milestone
        scheduleMilestone(at: 12, startTime: startTime, goalHours: goalHours, currentStreak: currentStreak, longestStreak: longestStreak)

        // Schedule 16-hour milestone
        scheduleMilestone(at: 16, startTime: startTime, goalHours: goalHours, currentStreak: currentStreak, longestStreak: longestStreak)

        // Schedule hourly milestones after 16 hours until goal
        if goalHours > 16 {
            for hour in 17...Int(goalHours) {
                scheduleMilestone(at: Double(hour), startTime: startTime, goalHours: goalHours, currentStreak: currentStreak, longestStreak: longestStreak)
            }
        }

        // Final goal completion notification
        scheduleGoalCompletion(startTime: startTime, goalHours: goalHours, currentStreak: currentStreak, longestStreak: longestStreak)
    }

    private func scheduleMilestone(at hours: Double, startTime: Date, goalHours: Double, currentStreak: Int = 0, longestStreak: Int = 0) {
        let identifier = "\(milestoneIdentifierPrefix)\(Int(hours))"
        let triggerDate = startTime.addingTimeInterval(hours * 3600)
        let timeInterval = triggerDate.timeIntervalSinceNow

        guard timeInterval > 0 else { return }

        let content = UNMutableNotificationContent()
        let hoursRemaining = Int(goalHours - hours)

        // Get motivational message with streak context
        let message = getMotivationalMessage(forHour: Int(hours), hoursRemaining: hoursRemaining, currentStreak: currentStreak, longestStreak: longestStreak)
        content.title = message.title
        content.body = message.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling milestone notification: \(error)")
            }
        }
    }

    private func scheduleGoalCompletion(startTime: Date, goalHours: Double, currentStreak: Int = 0, longestStreak: Int = 0) {
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
        if nextStreak == longestStreak && longestStreak > 0 {
            bodyMessage += "\n\n🔥 You're about to TIE your longest streak of \(longestStreak) days! Keep it going!"
        } else if nextStreak > longestStreak && longestStreak > 0 {
            bodyMessage += "\n\n🏆 NEW PERSONAL RECORD! You're about to break your longest streak of \(longestStreak) days!"
        }

        content.body = bodyMessage
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling goal completion: \(error)")
            }
        }
    }

    func cancelGoalNotification() {
        // Cancel all milestone notifications
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiers = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix(self.milestoneIdentifierPrefix) }
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    private func getMotivationalMessage(forHour hour: Int, hoursRemaining: Int, currentStreak: Int = 0, longestStreak: Int = 0) -> (title: String, body: String) {
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
                "You're rewriting your own limits! 💫"
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
                "One step closer to a healthier you!"
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
            24: "You've reached a full day! Powerful metabolic changes are happening throughout your body."
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
}
