import Foundation

/// Weight Notification Message Content
/// Phase 2a enhancement: Variable messaging to reduce notification fatigue
/// Industry pattern: Rotating message content (Apple Fitness+, Headspace, Noom)
/// Reference: fastlife_notifications_plan.md
struct WeightNotificationMessages {

    // MARK: - Daily Weight Reminder Messages (Rotating)

    /// 10 variations for daily weight reminder
    /// Industry standard: 5-10 message variations to reduce habituation
    /// Tone: Neutral/professional (v1) - personality tones deferred to v1.1+
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

    // MARK: - Did You Know (Educational Facts)

    /// Educational facts about weight tracking and weight loss science
    /// Industry pattern: Micro-learning (Duolingo daily tips, Headspace wisdom)
    /// Based on science-backed weight loss principles
    static let didYouKnow = [
        "Did You Know? Weighing yourself daily is linked to better long-term weight maintenance.",
        "Did You Know? Morning weigh-ins are most accurate before eating or drinking.",
        "Did You Know? Water weight can fluctuate 2-4 lbs daily — that's completely normal.",
        "Did You Know? Consistent tracking helps you spot patterns and adjust your approach.",
        "Did You Know? Weight loss isn't linear — temporary plateaus are part of the process.",
        "Did You Know? Muscle weighs more than fat, so the scale doesn't tell the whole story.",
        "Did You Know? Sleep quality directly impacts weight regulation and metabolism.",
        "Did You Know? Stress hormones can cause temporary water retention and weight fluctuations.",
        "Did You Know? Tracking weight trends over weeks matters more than daily numbers.",
        "Did You Know? Small, consistent habits lead to bigger results than dramatic changes."
    ]

    // MARK: - Motivational Messages

    /// Encouragement messages to maintain momentum
    /// Industry pattern: Positive reinforcement (Apple Watch coaching, MyFitnessPal achievements)
    /// Behavioral science: Identity reinforcement + progress celebration
    static let motivational = [
        "Every weigh-in is progress — you're showing up!",
        "You're building a powerful habit, one day at a time.",
        "Consistency beats perfection. Keep going!",
        "Your commitment to tracking is already a win.",
        "Small steps today lead to big changes tomorrow.",
        "You're investing in your health — that's worth celebrating.",
        "Progress isn't always visible, but it's happening.",
        "You're creating lasting change through daily action.",
        "Your future self will thank you for today's effort.",
        "You're not just tracking weight — you're building discipline."
    ]

    // MARK: - Action Steps (Practical Tips)

    /// Practical, actionable tips for habit building
    /// Industry pattern: Micro-actions (Fabulous app, Streaks app)
    /// Behavioral science: Implementation intentions + tiny habits
    static let actionSteps = [
        "Action Step: Place your scale in the same spot for consistency.",
        "Action Step: Weigh yourself at the same time each morning.",
        "Action Step: Set a daily alarm as your weigh-in trigger.",
        "Action Step: Keep a glass of water by your scale as a reminder.",
        "Action Step: Pair weighing with an existing habit like brushing teeth.",
        "Action Step: Take 3 deep breaths before stepping on the scale.",
        "Action Step: Focus on trends, not daily numbers.",
        "Action Step: Celebrate logging streaks, not just weight changes.",
        "Action Step: Write down one small win after each weigh-in.",
        "Action Step: Track how you feel, not just what you weigh."
    ]

    // MARK: - Message Selection (Date-Based Rotation)

    /// Get message for a specific date using deterministic rotation
    /// Industry pattern: Date-based seed for consistent daily messaging (Apple Fitness+ daily quotes)
    /// Algorithm: Use day-of-year as index modulo array count
    /// Result: Same message shows all day, different message tomorrow
    /// - Parameters:
    ///   - messages: Array of messages to rotate through
    ///   - date: Date to use for rotation (default: today)
    /// - Returns: Selected message for the given date
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

    /// Get today's "Did You Know" message
    static func getDidYouKnow(for date: Date = Date()) -> String {
        return getMessage(from: didYouKnow, for: date)
    }

    /// Get today's motivational message
    static func getMotivational(for date: Date = Date()) -> String {
        return getMessage(from: motivational, for: date)
    }

    /// Get today's action step message
    static func getActionStep(for date: Date = Date()) -> String {
        return getMessage(from: actionSteps, for: date)
    }
}
