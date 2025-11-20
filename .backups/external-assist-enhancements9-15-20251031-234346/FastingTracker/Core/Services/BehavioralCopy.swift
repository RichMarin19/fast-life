//
// BehavioralCopy.swift
// FastingTracker
//
// Created for LifeGPT Feature - Phase 1 Hour 3
// Behavioral copy system with ES-5 × day-part adaptive messaging
// Reference: FastLIFe_LIFeGPT_UI_Behavioral_Spec_Hour3.md (Section 9)
//

import Foundation

// MARK: - Behavioral Copy Service

/// Service providing emotion-aware, day-part-adaptive copy
/// **Industry Pattern:** Behavioral design (BJ Fogg), contextual prompts (Duolingo, Calm)
///
/// **Usage:**
/// ```swift
/// let copy = BehavioralCopy.shared
/// let prompt = copy.getPrompt(emotion: .energized, dayPart: .morning)
/// // Returns: "Momentum looks great — next best action?"
/// ```
class BehavioralCopy {
    /// Shared instance
    static let shared = BehavioralCopy()

    private init() {}

    // MARK: - Public API

    /// Get prompt for Hub card or input bar placeholder
    /// **Rotating prompts** based on emotion state and time of day
    ///
    /// - Parameters:
    ///   - emotion: Current emotion state (ES-5)
    ///   - dayPart: Time of day (morning/afternoon/evening)
    /// - Returns: Contextual prompt string
    func getPrompt(emotion: EmotionState, dayPart: DayPart) -> String {
        return prompts[emotion]?[dayPart] ?? defaultPrompt
    }

    /// Get welcome message for first-run or empty chat state
    /// - Parameter dayPart: Time of day
    /// - Returns: Welcome message with day-part-appropriate greeting
    func getWelcomeMessage(dayPart: DayPart) -> String {
        switch dayPart {
        case .morning:
            return """
            Good morning! ☀️

            I'm LifeGPT, your AI health coach. I can help you understand your health data and build sustainable habits.

            **Try asking:**
            • "What's my weight trend?"
            • "How many fasts this week?"
            • "Today's summary"
            """
        case .afternoon:
            return """
            Good afternoon! 👋

            I'm LifeGPT, your AI health coach. I can help you understand your health data and build sustainable habits.

            **Try asking:**
            • "How's my progress today?"
            • "Current fast status"
            • "Water intake today"
            """
        case .evening:
            return """
            Good evening! 🌙

            I'm LifeGPT, your AI health coach. I can help you understand your health data and build sustainable habits.

            **Try asking:**
            • "Today's summary"
            • "How's my sleep been?"
            • "This week's progress"
            """
        }
    }

    /// Get empty state message (72h idle)
    /// - Parameter emotion: Current emotion state
    /// - Returns: Re-engagement message with no guilt
    func getReEngagementMessage(emotion: EmotionState) -> String {
        switch emotion {
        case .energized, .stable:
            return "Ready to pick up where you left off? Let's see what's changed."
        case .stressed:
            return "No pressure. Start with one small win today."
        case .tired:
            return "Rest is part of progress. What feels doable right now?"
        case .offtrack:
            return "Zero guilt. Just one small choice today makes a difference."
        }
    }

    // MARK: - Day Part Detection

    /// Detect current day part based on time
    /// **Time ranges:**
    /// - Morning: 4 AM - 12 PM
    /// - Afternoon: 12 PM - 6 PM
    /// - Evening: 6 PM - 4 AM
    ///
    /// - Returns: Current day part
    static func currentDayPart() -> DayPart {
        let hour = Calendar.current.component(.hour, from: Date())

        if hour >= 4 && hour < 12 {
            return .morning
        } else if hour >= 12 && hour < 18 {
            return .afternoon
        } else {
            return .evening
        }
    }

    // MARK: - Private Copy Matrix

    /// ES-5 × DayPart copy matrix
    /// Source: UI/UX Spec Section 9 (Copy System)
    private let prompts: [EmotionState: [DayPart: String]] = [
        .energized: [
            .morning: "Momentum looks great — next best action?",
            .afternoon: "Consistency shows — curious what changed?",
            .evening: "Lock in recovery — sleep powers results."
        ],
        .stable: [
            .morning: "Rhythm is working — keep simple wins.",
            .afternoon: "Steady is powerful — mix it up?",
            .evening: "Reflect: what felt easy today?"
        ],
        .stressed: [
            .morning: "One thing at a time — hydrate first?",
            .afternoon: "Short walks lower stress fast — want a plan?",
            .evening: "Let's wind down together."
        ],
        .tired: [
            .morning: "Gentle start — protein helps.",
            .afternoon: "Sunlight break or micro-nap?",
            .evening: "Wind-down checklist ready?"
        ],
        .offtrack: [
            .morning: "Zero guilt — one small choice now.",
            .afternoon: "Want a 5-minute reset?",
            .evening: "Tomorrow's anchor: sleep / steps / water."
        ]
    ]

    /// Default fallback prompt
    private let defaultPrompt = "Ask about your health data"
}

// MARK: - Day Part

/// Time of day for contextual messaging
enum DayPart: String, Codable {
    /// Morning: 4 AM - 12 PM
    case morning

    /// Afternoon: 12 PM - 6 PM
    case afternoon

    /// Evening: 6 PM - 4 AM
    case evening

    /// Display name for debugging
    var displayName: String {
        rawValue.capitalized
    }

    /// Icon for UI display
    var icon: String {
        switch self {
        case .morning: return "☀️"
        case .afternoon: return "👋"
        case .evening: return "🌙"
        }
    }
}

// MARK: - Extended Copy Helpers

extension BehavioralCopy {
    /// Get input bar placeholder based on emotion and day part
    /// Rotates through prompt variations
    /// - Parameters:
    ///   - emotion: Current emotion state
    ///   - dayPart: Time of day
    /// - Returns: Placeholder text for input bar
    func getInputPlaceholder(emotion: EmotionState, dayPart: DayPart) -> String {
        return getPrompt(emotion: emotion, dayPart: dayPart)
    }

    /// Get micro-tip for behavioral nudging
    /// Shown below input bar or as toast
    /// - Parameter emotion: Current emotion state
    /// - Returns: Micro-tip text
    func getMicroTip(emotion: EmotionState) -> String {
        switch emotion {
        case .energized:
            return "Coaching works best with specifics."
        case .stable:
            return "Ask about patterns to unlock insights."
        case .stressed:
            return "Focus on one metric at a time."
        case .tired:
            return "Start with sleep or hydration."
        case .offtrack:
            return "Small questions lead to big wins."
        }
    }

    /// Get toast message after user sends query
    /// Positive reinforcement for engagement
    /// - Parameter queryType: Type of query sent
    /// - Returns: Toast message
    func getReflectionToast(queryType: QueryType) -> String {
        switch queryType {
        case .weight:
            return "Reflection logged: Weight awareness"
        case .fasting:
            return "Reflection logged: Fasting consistency"
        case .sleep:
            return "Reflection logged: Sleep quality"
        case .hydration:
            return "Reflection logged: Hydration"
        case .mood:
            return "Reflection logged: Mood check-in"
        case .summary:
            return "Reflection logged: Daily review"
        case .general, .unknown:
            return "Reflection logged"
        }
    }
}

// MARK: - Sample Data (Preview/Testing)

#if DEBUG
extension BehavioralCopy {
    /// Sample prompts for testing all emotion × day-part combinations
    static let samplePrompts: [(EmotionState, DayPart, String)] = [
        (.energized, .morning, "Momentum looks great — next best action?"),
        (.stable, .afternoon, "Steady is powerful — mix it up?"),
        (.stressed, .evening, "Let's wind down together."),
        (.tired, .morning, "Gentle start — protein helps."),
        (.offtrack, .afternoon, "Want a 5-minute reset?")
    ]
}
#endif
