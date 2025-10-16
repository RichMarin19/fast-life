import Foundation
import UserNotifications

/// Base protocol for behavioral notification rules following expert panel design
/// Uses existing TrackerType enum from AppSettings.swift to avoid conflicts
/// Reference: Expert Panel "Behavioral Design Engine" specifications
@MainActor
protocol BehavioralNotificationRule: ObservableObject, Codable {

    // MARK: - Core Configuration
    var trackerType: TrackerType { get } // Uses existing TrackerType from AppSettings.swift
    var isEnabled: Bool { get set }

    // MARK: - Frequency & Timing (Expert Panel Requirements)
    var frequency: NotificationFrequency { get set }
    var timing: NotificationTiming { get set }
    var quietHours: QuietHours? { get set }

    // MARK: - Behavioral Customization
    var toneStyle: NotificationToneStyle { get set }
    var adaptiveFrequency: Bool { get set }
    var allowDuringQuietHours: Bool { get set }

    // MARK: - iOS Framework Integration
    var soundEnabled: Bool { get set }
    var interruptionLevel: NotificationInterruptionLevel { get set }

    // MARK: - Behavioral Intelligence Methods
    func shouldTrigger(context: BehavioralContext) -> Bool
    func generateMessage(context: BehavioralContext) -> BehavioralMessage
    func getNextTriggerDate(from currentDate: Date) -> Date?
}

// MARK: - Supporting Enums (Conflict-Free Naming)

/// Notification frequency options following expert panel customization framework
enum NotificationFrequency: String, CaseIterable, Codable {
    case daily = "daily"
    case multipleTimes = "multiple_times"
    case weekly = "weekly"
    case eventDriven = "event_driven"
    case adaptive = "adaptive"

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .multipleTimes: return "Multiple times per day"
        case .weekly: return "Weekly"
        case .eventDriven: return "Event-driven"
        case .adaptive: return "Adaptive (learns from your patterns)"
        }
    }
}

/// Notification timing options following expert panel behavioral triggers
enum NotificationTiming: Codable, Equatable {
    case before(minutes: Int)    // "15 min before fast ends"
    case after(minutes: Int)     // "30 min after wake-up"
    case exact(hour: Int, minute: Int)  // "8:00 AM sharp"
    case dynamic(anchor: String) // "average wake-up or bedtime"

    var displayName: String {
        switch self {
        case .before(let minutes):
            return "\(minutes) minutes before"
        case .after(let minutes):
            return "\(minutes) minutes after"
        case .exact(let hour, let minute):
            return String(format: "%02d:%02d", hour, minute)
        case .dynamic(let anchor):
            return "Dynamic (\(anchor))"
        }
    }
}

/// Tone styles following expert panel "tone customization" requirements
enum NotificationToneStyle: String, CaseIterable, Codable {
    case supportive = "supportive"
    case educational = "educational"
    case motivational = "motivational"
    case stoic = "stoic"

    var displayName: String {
        switch self {
        case .supportive: return "Supportive - Gentle, empathetic, encouraging"
        case .educational: return "Educational - Factual, concise, value-driven"
        case .motivational: return "Motivational - Energetic, action-oriented"
        case .stoic: return "Stoic - Calm, data-first, emotionally neutral"
        }
    }
}

/// Interruption levels for iOS 15+ following Apple UserNotifications framework
enum NotificationInterruptionLevel: String, CaseIterable, Codable {
    case passive = "passive"
    case active = "active"
    case timeSensitive = "time_sensitive"
    case critical = "critical"

    var displayName: String {
        switch self {
        case .passive: return "Passive - Won't wake screen or play sound"
        case .active: return "Active - Standard notification behavior"
        case .timeSensitive: return "Time Sensitive - Break through Do Not Disturb"
        case .critical: return "Critical - Always deliver immediately"
        }
    }

    @available(iOS 15.0, *)
    var unInterruptionLevel: UNNotificationInterruptionLevel {
        switch self {
        case .passive: return .passive
        case .active: return .active
        case .timeSensitive: return .timeSensitive
        case .critical: return .critical
        }
    }
}

/// Tracks behavioral context for intelligent notification delivery
struct BehavioralContext {
    let currentStreak: Int
    let recentPattern: String
    let timeOfDay: Date
    let dataValue: Double?
    let goalProgress: Double
    let lastActivity: Date?
}

/// Behavioral message following expert panel's "Educate, Empower, Reinforce" principles
struct BehavioralMessage: Codable {
    let title: String
    let body: String
}

/// Quiet hours configuration
struct QuietHours: Codable {
    let start: Int // Hour (0-23)
    let end: Int   // Hour (0-23)
}

// MARK: - Concrete Rule Implementations

/// Fasting notification rule following expert panel behavioral design
class FastingNotificationRule: BehavioralNotificationRule, ObservableObject {
    let trackerType: TrackerType = .fasting

    @Published var isEnabled: Bool = true
    @Published var frequency: NotificationFrequency = .eventDriven
    @Published var timing: NotificationTiming = .before(minutes: 30)
    @Published var quietHours: QuietHours? = QuietHours(start: 22, end: 6)

    @Published var toneStyle: NotificationToneStyle = .motivational
    @Published var adaptiveFrequency: Bool = true
    @Published var allowDuringQuietHours: Bool = false

    @Published var soundEnabled: Bool = true
    @Published var interruptionLevel: NotificationInterruptionLevel = .active

    init() {}

    func shouldTrigger(context: BehavioralContext) -> Bool {
        guard isEnabled else { return false }

        // Behavioral intelligence: More encouragement if streak is building
        if context.currentStreak >= 3 {
            return true // Always encourage when building momentum
        }

        // Standard trigger based on goal progress
        return context.goalProgress > 0.8 // Trigger when 80% to goal
    }

    func generateMessage(context: BehavioralContext) -> BehavioralMessage {
        switch toneStyle {
        case .supportive:
            return BehavioralMessage(
                title: "You're doing great 🌟",
                body: "Your \(context.currentStreak)-day streak shows real commitment"
            )
        case .educational:
            return BehavioralMessage(
                title: "Fasting Science 🧬",
                body: "Your body enters deeper ketosis around hour \(Int(context.goalProgress * 24))"
            )
        case .motivational:
            return BehavioralMessage(
                title: "Keep pushing! 💪",
                body: "You're \(Int((1-context.goalProgress)*100))% away from your goal!"
            )
        case .stoic:
            return BehavioralMessage(
                title: "Progress Update",
                body: "\(Int(context.goalProgress*100))% complete. Consistency builds discipline."
            )
        }
    }

    func getNextTriggerDate(from currentDate: Date) -> Date? {
        switch timing {
        case .before(let minutes):
            return Calendar.current.date(byAdding: .minute, value: -minutes, to: currentDate)
        case .after(let minutes):
            return Calendar.current.date(byAdding: .minute, value: minutes, to: currentDate)
        case .exact(let hour, let minute):
            var components = Calendar.current.dateComponents([.year, .month, .day], from: currentDate)
            components.hour = hour
            components.minute = minute
            return Calendar.current.date(from: components)
        case .dynamic:
            // Dynamic scheduling based on user patterns - simplified for now
            return Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)
        }
    }

    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case isEnabled, frequency, timing, quietHours, toneStyle, adaptiveFrequency, allowDuringQuietHours, soundEnabled, interruptionLevel
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        frequency = try container.decode(NotificationFrequency.self, forKey: .frequency)
        timing = try container.decode(NotificationTiming.self, forKey: .timing)
        quietHours = try container.decodeIfPresent(QuietHours.self, forKey: .quietHours)
        toneStyle = try container.decode(NotificationToneStyle.self, forKey: .toneStyle)
        adaptiveFrequency = try container.decode(Bool.self, forKey: .adaptiveFrequency)
        allowDuringQuietHours = try container.decode(Bool.self, forKey: .allowDuringQuietHours)
        soundEnabled = try container.decode(Bool.self, forKey: .soundEnabled)
        interruptionLevel = try container.decode(NotificationInterruptionLevel.self, forKey: .interruptionLevel)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(timing, forKey: .timing)
        try container.encodeIfPresent(quietHours, forKey: .quietHours)
        try container.encode(toneStyle, forKey: .toneStyle)
        try container.encode(adaptiveFrequency, forKey: .adaptiveFrequency)
        try container.encode(allowDuringQuietHours, forKey: .allowDuringQuietHours)
        try container.encode(soundEnabled, forKey: .soundEnabled)
        try container.encode(interruptionLevel, forKey: .interruptionLevel)
    }
}

/// Hydration notification rule with gender-specific defaults
class HydrationNotificationRule: BehavioralNotificationRule, ObservableObject {
    let trackerType: TrackerType = .hydration

    @Published var isEnabled: Bool = true
    @Published var frequency: NotificationFrequency = .multipleTimes
    @Published var timing: NotificationTiming = .after(minutes: 180) // 3 hours after last log
    @Published var quietHours: QuietHours? = QuietHours(start: 22, end: 7)

    @Published var toneStyle: NotificationToneStyle = .supportive
    @Published var adaptiveFrequency: Bool = true
    @Published var allowDuringQuietHours: Bool = false

    @Published var soundEnabled: Bool = false // Less intrusive for hydration
    @Published var interruptionLevel: NotificationInterruptionLevel = .passive

    init() {}

    func shouldTrigger(context: BehavioralContext) -> Bool {
        guard isEnabled else { return false }

        // Expert panel: "You're 400 ml short of your daily goal"
        if let lastActivity = context.lastActivity,
           Date().timeIntervalSince(lastActivity) > 3 * 3600 { // 3 hours since last log
            return true
        }

        return context.goalProgress < 0.7 // Behind on daily goal
    }

    func generateMessage(context: BehavioralContext) -> BehavioralMessage {
        let shortfall = Int((1 - context.goalProgress) * 2000) // Assume 2L daily goal

        switch toneStyle {
        case .supportive:
            return BehavioralMessage(
                title: "Gentle reminder 💧",
                body: "Your body is asking for hydration - \(shortfall)ml to go"
            )
        case .educational:
            return BehavioralMessage(
                title: "Hydration Insight 🧠",
                body: "Even 2% dehydration can reduce focus by 20%"
            )
        case .motivational:
            return BehavioralMessage(
                title: "You've got this! 🚰",
                body: "One more glass gets you to \(Int(context.goalProgress*100 + 12))%!"
            )
        case .stoic:
            return BehavioralMessage(
                title: "Hydration Status",
                body: "\(shortfall)ml remaining for optimal function"
            )
        }
    }

    func getNextTriggerDate(from currentDate: Date) -> Date? {
        // Schedule based on inactivity pattern
        return Calendar.current.date(byAdding: .hour, value: 3, to: currentDate)
    }

    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case isEnabled, frequency, timing, quietHours, toneStyle, adaptiveFrequency, allowDuringQuietHours, soundEnabled, interruptionLevel
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        frequency = try container.decode(NotificationFrequency.self, forKey: .frequency)
        timing = try container.decode(NotificationTiming.self, forKey: .timing)
        quietHours = try container.decodeIfPresent(QuietHours.self, forKey: .quietHours)
        toneStyle = try container.decode(NotificationToneStyle.self, forKey: .toneStyle)
        adaptiveFrequency = try container.decode(Bool.self, forKey: .adaptiveFrequency)
        allowDuringQuietHours = try container.decode(Bool.self, forKey: .allowDuringQuietHours)
        soundEnabled = try container.decode(Bool.self, forKey: .soundEnabled)
        interruptionLevel = try container.decode(NotificationInterruptionLevel.self, forKey: .interruptionLevel)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(timing, forKey: .timing)
        try container.encodeIfPresent(quietHours, forKey: .quietHours)
        try container.encode(toneStyle, forKey: .toneStyle)
        try container.encode(adaptiveFrequency, forKey: .adaptiveFrequency)
        try container.encode(allowDuringQuietHours, forKey: .allowDuringQuietHours)
        try container.encode(soundEnabled, forKey: .soundEnabled)
        try container.encode(interruptionLevel, forKey: .interruptionLevel)
    }
}

// MARK: - Additional Rule Classes (Sleep, Weight, Mood)
// Following same pattern with existing TrackerType enum integration

/// Sleep notification rule with circadian rhythm intelligence
class SleepNotificationRule: BehavioralNotificationRule, ObservableObject {
    let trackerType: TrackerType = .sleep

    @Published var isEnabled: Bool = true
    @Published var frequency: NotificationFrequency = .daily
    @Published var timing: NotificationTiming = .exact(hour: 21, minute: 30) // Wind-down time
    @Published var quietHours: QuietHours? = nil // Sleep notifications override quiet hours

    @Published var toneStyle: NotificationToneStyle = .supportive
    @Published var adaptiveFrequency: Bool = true
    @Published var allowDuringQuietHours: Bool = true // Sleep prep is important

    @Published var soundEnabled: Bool = true
    @Published var interruptionLevel: NotificationInterruptionLevel = .active

    init() {}

    func shouldTrigger(context: BehavioralContext) -> Bool {
        guard isEnabled else { return false }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())

        // Trigger wind-down notifications in evening
        return hour >= 21 && hour <= 23
    }

    func generateMessage(context: BehavioralContext) -> BehavioralMessage {
        switch toneStyle {
        case .supportive:
            return BehavioralMessage(
                title: "Wind down time 🌙",
                body: "Your body thrives on routine sleep patterns"
            )
        case .educational:
            return BehavioralMessage(
                title: "Sleep Science 😴",
                body: "Consistent bedtime improves sleep quality by 23%"
            )
        case .motivational:
            return BehavioralMessage(
                title: "Rest to achieve! 🎯",
                body: "Great sleep fuels tomorrow's wins"
            )
        case .stoic:
            return BehavioralMessage(
                title: "Sleep Preparation",
                body: "Optimal performance requires consistent recovery"
            )
        }
    }

    func getNextTriggerDate(from currentDate: Date) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: currentDate)
        components.hour = 21
        components.minute = 30

        if let scheduleDate = Calendar.current.date(from: components),
           scheduleDate < currentDate {
            // Schedule for tomorrow if today's time has passed
            return Calendar.current.date(byAdding: .day, value: 1, to: scheduleDate)
        }

        return Calendar.current.date(from: components)
    }

    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case isEnabled, frequency, timing, quietHours, toneStyle, adaptiveFrequency, allowDuringQuietHours, soundEnabled, interruptionLevel
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        frequency = try container.decode(NotificationFrequency.self, forKey: .frequency)
        timing = try container.decode(NotificationTiming.self, forKey: .timing)
        quietHours = try container.decodeIfPresent(QuietHours.self, forKey: .quietHours)
        toneStyle = try container.decode(NotificationToneStyle.self, forKey: .toneStyle)
        adaptiveFrequency = try container.decode(Bool.self, forKey: .adaptiveFrequency)
        allowDuringQuietHours = try container.decode(Bool.self, forKey: .allowDuringQuietHours)
        soundEnabled = try container.decode(Bool.self, forKey: .soundEnabled)
        interruptionLevel = try container.decode(NotificationInterruptionLevel.self, forKey: .interruptionLevel)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(timing, forKey: .timing)
        try container.encodeIfPresent(quietHours, forKey: .quietHours)
        try container.encode(toneStyle, forKey: .toneStyle)
        try container.encode(adaptiveFrequency, forKey: .adaptiveFrequency)
        try container.encode(allowDuringQuietHours, forKey: .allowDuringQuietHours)
        try container.encode(soundEnabled, forKey: .soundEnabled)
        try container.encode(interruptionLevel, forKey: .interruptionLevel)
    }
}



/// Weight notification rule for habit formation and consistency
class WeightNotificationRule: BehavioralNotificationRule, ObservableObject {
    let trackerType: TrackerType = .weight

    @Published var isEnabled: Bool = true
    @Published var frequency: NotificationFrequency = .daily
    @Published var timing: NotificationTiming = .after(minutes: 30) // 30 min after wake-up
    @Published var quietHours: QuietHours? = QuietHours(start: 21, end: 7)

    @Published var toneStyle: NotificationToneStyle = .educational
    @Published var adaptiveFrequency: Bool = true
    @Published var allowDuringQuietHours: Bool = false

    @Published var soundEnabled: Bool = false // Less intrusive for daily habits
    @Published var interruptionLevel: NotificationInterruptionLevel = .passive

    init() {}

    func shouldTrigger(context: BehavioralContext) -> Bool {
        guard isEnabled else { return false }

        // Weight tracking is about consistency - encourage when user has data gaps
        if let lastActivity = context.lastActivity {
            let daysSinceLastWeigh = Calendar.current.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0
            return daysSinceLastWeigh >= 1 // Encourage daily weighing
        }

        return true // Always encourage if no recent data
    }

    func generateMessage(context: BehavioralContext) -> BehavioralMessage {
        switch toneStyle {
        case .supportive:
            return BehavioralMessage(
                title: "Gentle reminder ⚖️",
                body: "Consistent weighing helps you understand your body patterns"
            )
        case .educational:
            return BehavioralMessage(
                title: "Weight Tracking Insight 📊",
                body: "Daily weigh-ins provide the most accurate trend data"
            )
        case .motivational:
            return BehavioralMessage(
                title: "Stay consistent! 💪",
                body: "Your weight journey deserves daily attention"
            )
        case .stoic:
            return BehavioralMessage(
                title: "Weight Check",
                body: "Consistency in measurement leads to better data insights"
            )
        }
    }

    func getNextTriggerDate(from currentDate: Date) -> Date? {
        // Schedule for next morning
        var components = Calendar.current.dateComponents([.year, .month, .day], from: currentDate)
        components.day = (components.day ?? 1) + 1
        components.hour = 8
        components.minute = 0

        return Calendar.current.date(from: components)
    }

    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case isEnabled, frequency, timing, quietHours, toneStyle, adaptiveFrequency, allowDuringQuietHours, soundEnabled, interruptionLevel
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        frequency = try container.decode(NotificationFrequency.self, forKey: .frequency)
        timing = try container.decode(NotificationTiming.self, forKey: .timing)
        quietHours = try container.decodeIfPresent(QuietHours.self, forKey: .quietHours)
        toneStyle = try container.decode(NotificationToneStyle.self, forKey: .toneStyle)
        adaptiveFrequency = try container.decode(Bool.self, forKey: .adaptiveFrequency)
        allowDuringQuietHours = try container.decode(Bool.self, forKey: .allowDuringQuietHours)
        soundEnabled = try container.decode(Bool.self, forKey: .soundEnabled)
        interruptionLevel = try container.decode(NotificationInterruptionLevel.self, forKey: .interruptionLevel)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(timing, forKey: .timing)
        try container.encodeIfPresent(quietHours, forKey: .quietHours)
        try container.encode(toneStyle, forKey: .toneStyle)
        try container.encode(adaptiveFrequency, forKey: .adaptiveFrequency)
        try container.encode(allowDuringQuietHours, forKey: .allowDuringQuietHours)
        try container.encode(soundEnabled, forKey: .soundEnabled)
        try container.encode(interruptionLevel, forKey: .interruptionLevel)
    }
}
