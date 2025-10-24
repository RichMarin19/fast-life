//
// ResponseGenerator.swift
// FastingTracker
//
// Created for LifeGPT Phase 2 Hour 3 - Response Generation
// Production-grade emotion-aware responses with 50+ templates
// Reference: LIFEGPT-INTELLIGENCE-LAYER-SPEC.md Section 4
//
// Industry Standards:
// - Duolingo motivational messaging
// - MyFitnessPal progress celebrations
// - Headspace tone and voice
//

import Foundation

// MARK: - Response Generator Protocol

/// Protocol for generating emotion-aware responses
/// **Production Standard:** Contextual, personalized, ES-5 integrated
protocol ResponseGeneratorProtocol {
    /// Generate response from analysis result
    func generateResponse(
        for intent: QueryIntent,
        result: Any,
        emotion: EmotionState,
        userPreferences: UserPreferences
    ) -> String
}

// MARK: - User Preferences

/// User preferences for response personalization
struct UserPreferences {
    let preferredUnit: WeightUnit
    let name: String?
    let timeOfDay: String // "morning", "afternoon", "evening"

    static var `default`: UserPreferences {
        UserPreferences(
            preferredUnit: .pounds,
            name: nil,
            timeOfDay: BehavioralCopy.currentDayPart()
        )
    }
}

// MARK: - Response Generator Implementation

/// Production-grade response generator with ES-5 emotion awareness
/// **Features:**
/// - 50+ emotion-aware templates
/// - Dynamic value insertion
/// - Tone matching (encouraging, supportive, gentle, celebratory, hopeful)
/// - Unit preference handling
/// - Personalization
class ResponseGenerator: ResponseGeneratorProtocol {

    // MARK: - Singleton

    static let shared = ResponseGenerator()

    // MARK: - Template Categories (50+ templates)

    /// Weight minimum templates (5 per emotion = 25 templates)
    private let minimumWeightTemplates: [EmotionState: [String]] = [
        .energized: [
            "Your lowest weight was {value} on {date}. You're crushing it! 💪",
            "Amazing! You hit {value} on {date} - that's your best yet!",
            "{value} on {date} - that's your all-time low! Keep that energy going!",
            "Wow! {value} back on {date}. You're on fire! 🔥",
            "Your record low is {value} from {date}. You've got this momentum!"
        ],
        .stable: [
            "Your minimum weight was {value}, recorded on {date}.",
            "You reached {value} on {date} - your lowest point so far.",
            "The least you've weighed is {value}, which was on {date}.",
            "Your lowest recorded weight: {value} on {date}.",
            "{value} on {date} represents your minimum weight to date."
        ],
        .stressed: [
            "Your lowest weight was {value} on {date}. Remember, progress isn't always linear.",
            "You reached {value} on {date}. Every step forward counts, even small ones.",
            "{value} on {date} shows what's possible. You've done it before.",
            "Your minimum of {value} on {date} is proof you can get there again.",
            "Back on {date}, you hit {value}. That strength is still in you."
        ],
        .tired: [
            "Your lowest was {value} on {date}. Rest is part of the journey too.",
            "You reached {value} on {date}. Be gentle with yourself today.",
            "{value} on {date} - you've come far. It's okay to take breaks.",
            "Your minimum weight: {value} on {date}. Progress takes time.",
            "You hit {value} on {date}. Small steps are still steps forward."
        ],
        .offtrack: [
            "Your lowest weight was {value} on {date}. You can get back there.",
            "Remember {date}? You reached {value}. That's still achievable.",
            "{value} on {date} - you've done it once, you can do it again.",
            "Your minimum: {value} on {date}. Every day is a fresh start.",
            "You reached {value} on {date}. That goal is within reach again."
        ]
    ]

    /// Weight maximum templates (5 per emotion = 25 templates)
    private let maximumWeightTemplates: [EmotionState: [String]] = [
        .energized: [
            "Your highest was {value} on {date}. Look how far you've come!",
            "{value} on {date} - and you've made amazing progress since then!",
            "You were {value} on {date}, but you're crushing your goals now!",
            "From {value} on {date} to where you are now - incredible! 🎉",
            "Your max was {value} on {date}. You've come such a long way!"
        ],
        .stable: [
            "Your maximum weight was {value}, recorded on {date}.",
            "You reached {value} on {date} - your highest point.",
            "The most you've weighed is {value}, which was on {date}.",
            "Your highest recorded weight: {value} on {date}.",
            "{value} on {date} represents your maximum weight."
        ],
        .stressed: [
            "Your highest was {value} on {date}. You're working toward better now.",
            "{value} on {date} is in the past. Focus on today's progress.",
            "You were {value} on {date}. Every healthy choice matters.",
            "Your max: {value} on {date}. You're taking steps in the right direction.",
            "{value} on {date} - that's behind you now. Keep moving forward."
        ],
        .tired: [
            "Your highest was {value} on {date}. Rest and recovery matter too.",
            "{value} on {date} - and you're still here, still trying. That's strength.",
            "You were {value} on {date}. Be kind to yourself on this journey.",
            "Your maximum: {value} on {date}. Progress isn't always fast.",
            "{value} on {date} - you're working on it. That's what counts."
        ],
        .offtrack: [
            "Your highest was {value} on {date}. Today is a new opportunity.",
            "{value} on {date} - but you can change your story starting now.",
            "You were {value} on {date}. It's never too late to restart.",
            "Your max: {value} on {date}. Every moment is a chance to begin again.",
            "{value} on {date} - the past doesn't define your future."
        ]
    ]

    /// Weight change templates (celebration or support based on emotion)
    private let weightChangeTemplates: [EmotionState: [String]] = [
        .energized: [
            "You've lost {change} this {period}! Absolutely crushing it! 💪",
            "Down {change} this {period} - you're on fire! Keep it up!",
            "{change} lost this {period}! Your hard work is paying off!",
            "Amazing! {change} down this {period}. You're unstoppable!",
            "You dropped {change} this {period}! That's phenomenal progress!"
        ],
        .stable: [
            "You've lost {change} this {period}.",
            "Your weight decreased by {change} this {period}.",
            "This {period}, you're down {change}.",
            "Weight change this {period}: -{change}.",
            "You've shed {change} this {period}."
        ],
        .stressed: [
            "You've lost {change} this {period}. Every bit counts.",
            "Down {change} this {period}. You're doing better than you think.",
            "{change} lost this {period}. That's real progress.",
            "You're down {change} this {period}. Keep trusting the process.",
            "{change} this {period} - you're moving in the right direction."
        ],
        .tired: [
            "You've lost {change} this {period}. Be proud of that.",
            "Down {change} this {period}. You're doing great, even when it's hard.",
            "{change} lost this {period}. Rest is part of recovery too.",
            "You're down {change} this {period}. Small wins matter.",
            "{change} this {period} - that's progress worth celebrating."
        ],
        .offtrack: [
            "You've lost {change} this {period}. You're back on track.",
            "Down {change} this {period}. See? You can do this.",
            "{change} lost this {period}. Every step forward helps.",
            "You're down {change} this {period}. The comeback is real.",
            "{change} this {period} - proof that you haven't given up."
        ]
    ]

    /// Fast count templates
    private let fastCountTemplates: [EmotionState: [String]] = [
        .energized: [
            "You completed {count} fasts this {period}! Incredible dedication! 🔥",
            "{count} fasts this {period}! You're absolutely crushing your goals!",
            "Wow! {count} fasts this {period}. You're a fasting champion!",
            "{count} successful fasts this {period}! Keep that momentum!",
            "You've done {count} fasts this {period}! Outstanding consistency!"
        ],
        .stable: [
            "You completed {count} fasts this {period}.",
            "This {period}, you've done {count} fasts.",
            "Your fast count this {period}: {count}.",
            "You've fasted {count} times this {period}.",
            "{count} fasts completed this {period}."
        ],
        .stressed: [
            "You've done {count} fasts this {period}. That takes real discipline.",
            "{count} fasts this {period}. You're doing better than you realize.",
            "You completed {count} fasts this {period}. That's commitment.",
            "{count} fasts this {period} - you're still showing up.",
            "You've fasted {count} times this {period}. That matters."
        ],
        .tired: [
            "You've done {count} fasts this {period}. Rest when you need to.",
            "{count} fasts this {period}. Listen to your body.",
            "You completed {count} fasts this {period}. Be gentle with yourself.",
            "{count} fasts this {period} - you're doing your best.",
            "You've fasted {count} times this {period}. That's enough."
        ],
        .offtrack: [
            "You've done {count} fasts this {period}. You're getting back into it.",
            "{count} fasts this {period}. Every fast is a step forward.",
            "You completed {count} fasts this {period}. You can rebuild consistency.",
            "{count} fasts this {period} - you're not starting from zero.",
            "You've fasted {count} times this {period}. The journey continues."
        ]
    ]

    /// Streak templates
    private let streakTemplates: [EmotionState: [String]] = [
        .energized: [
            "You're on a {streak}-day streak! Absolutely crushing it! 🔥",
            "{streak} days in a row! You're unstoppable!",
            "Wow! {streak}-day streak! Keep that fire burning!",
            "{streak} consecutive days! You're a consistency champion!",
            "Your streak: {streak} days! That's phenomenal discipline!"
        ],
        .stable: [
            "Your current streak is {streak} days.",
            "You've been consistent for {streak} days in a row.",
            "{streak}-day streak maintained.",
            "Current fasting streak: {streak} days.",
            "You've completed {streak} consecutive fasting days."
        ],
        .stressed: [
            "You've maintained a {streak}-day streak. That's real strength.",
            "{streak} days in a row. You're doing better than you think.",
            "Your {streak}-day streak shows your commitment.",
            "{streak} consecutive days. You're still showing up.",
            "You've kept going for {streak} days. That matters."
        ],
        .tired: [
            "You've done {streak} days in a row. Rest when you need to.",
            "{streak}-day streak. Listen to your body.",
            "Your streak: {streak} days. Be proud of that.",
            "{streak} consecutive days. You're doing great.",
            "You've maintained {streak} days. That's enough."
        ],
        .offtrack: [
            "You have a {streak}-day streak. You're rebuilding consistency.",
            "{streak} days in a row. Every day counts.",
            "Your {streak}-day streak is proof you can do this.",
            "{streak} consecutive days. You're getting back on track.",
            "You've done {streak} days. Keep the momentum going."
        ]
    ]

    /// Trend templates
    private let trendTemplates: [EmotionState: [String]] = [
        .energized: [
            "Your weight is trending {direction}! You're {strength}% on track! 💪",
            "Trending {direction} with {confidence}% confidence! Amazing!",
            "You're moving {direction} strong! Keep this energy!",
            "Your trend: {direction} at {strength}% strength! Crushing it!",
            "Trending {direction}! Your consistency is paying off!"
        ],
        .stable: [
            "Your weight is trending {direction}.",
            "Trend analysis shows {direction} movement.",
            "Current trend: {direction}.",
            "Weight trajectory: {direction}.",
            "Your weight is moving {direction}."
        ],
        .stressed: [
            "You're trending {direction}. Progress isn't always linear.",
            "Your trend shows {direction} movement. Trust the process.",
            "Trending {direction}. Small steps add up over time.",
            "Weight moving {direction}. Every day is progress.",
            "Your trend: {direction}. Keep going, it's working."
        ],
        .tired: [
            "You're trending {direction}. Rest is part of the journey.",
            "Trending {direction}. Be gentle with yourself.",
            "Your weight is moving {direction}. Take it one day at a time.",
            "Trend: {direction}. You're doing enough.",
            "Trending {direction}. Progress takes time."
        ],
        .offtrack: [
            "You're trending {direction}. You can turn this around.",
            "Trending {direction}. Every day is a new opportunity.",
            "Your trend shows {direction} movement. You can change this.",
            "Weight moving {direction}. Time to refocus.",
            "Trend: {direction}. You've got this - start fresh today."
        ]
    ]

    /// Goal progress templates
    private let goalProgressTemplates: [EmotionState: [String]] = [
        .energized: [
            "You're {percentage}% of the way to your goal! Unstoppable! 🎯",
            "{percentage}% complete! You're crushing this goal!",
            "Amazing! {percentage}% progress toward {target}!",
            "You've achieved {percentage}% of your goal! Keep going!",
            "{percentage}% there! Your dedication is incredible!"
        ],
        .stable: [
            "You're {percentage}% of the way to your goal of {target}.",
            "Goal progress: {percentage}% complete.",
            "{percentage}% toward your target of {target}.",
            "Current progress: {percentage}% of goal achieved.",
            "You've reached {percentage}% of your {target} goal."
        ],
        .stressed: [
            "You're {percentage}% there. Every percentage point counts.",
            "{percentage}% progress toward {target}. You're doing it.",
            "You've achieved {percentage}% of your goal. Keep trusting yourself.",
            "{percentage}% complete. You're further than you were yesterday.",
            "Goal progress: {percentage}%. You're moving forward."
        ],
        .tired: [
            "You're {percentage}% of the way there. Rest when you need to.",
            "{percentage}% progress. You're doing great.",
            "You've reached {percentage}% of your goal. Be proud.",
            "{percentage}% complete. Take it one day at a time.",
            "Goal progress: {percentage}%. You're enough."
        ],
        .offtrack: [
            "You're {percentage}% there. You can still reach {target}.",
            "{percentage}% progress. Every day is a chance to improve.",
            "You've achieved {percentage}%. The goal is still within reach.",
            "{percentage}% complete. You can do this.",
            "Goal progress: {percentage}%. Don't give up now."
        ]
    ]

    // MARK: - Response Generation

    func generateResponse(
        for intent: QueryIntent,
        result: Any,
        emotion: EmotionState,
        userPreferences: UserPreferences
    ) -> String {
        switch intent {

        // MARK: Weight Stats Responses

        case .minimumWeight:
            guard let weightResult = result as? WeightAnalysisResult else {
                return fallbackResponse(for: emotion)
            }
            return generateWeightMinimumResponse(
                result: weightResult,
                emotion: emotion,
                userPreferences: userPreferences
            )

        case .maximumWeight:
            guard let weightResult = result as? WeightAnalysisResult else {
                return fallbackResponse(for: emotion)
            }
            return generateWeightMaximumResponse(
                result: weightResult,
                emotion: emotion,
                userPreferences: userPreferences
            )

        case .averageWeight:
            guard let weightResult = result as? WeightAnalysisResult else {
                return fallbackResponse(for: emotion)
            }
            return generateWeightAverageResponse(
                result: weightResult,
                emotion: emotion,
                userPreferences: userPreferences
            )

        case .weightChange:
            guard let changeResult = result as? WeightChangeResult else {
                return fallbackResponse(for: emotion)
            }
            return generateWeightChangeResponse(
                result: changeResult,
                emotion: emotion,
                userPreferences: userPreferences
            )

        // MARK: Fasting Stats Responses

        case .fastCount:
            guard let count = result as? Int else {
                return fallbackResponse(for: emotion)
            }
            return generateFastCountResponse(
                count: count,
                emotion: emotion,
                period: "week" // TODO: Extract from intent
            )

        case .fastingStreak:
            guard let streak = result as? Int else {
                return fallbackResponse(for: emotion)
            }
            return generateStreakResponse(
                streak: streak,
                emotion: emotion
            )

        // MARK: Trend Responses

        case .weightTrend:
            guard let trendResult = result as? TrendAnalysisResult else {
                return fallbackResponse(for: emotion)
            }
            return generateTrendResponse(
                result: trendResult,
                emotion: emotion
            )

        case .goalProgress:
            guard let percentage = result as? Double else {
                return fallbackResponse(for: emotion)
            }
            return generateGoalProgressResponse(
                percentage: percentage,
                emotion: emotion,
                target: "170 lbs" // TODO: Extract from intent
            )

        default:
            return fallbackResponse(for: emotion)
        }
    }

    // MARK: - Template Rendering

    private func generateWeightMinimumResponse(
        result: WeightAnalysisResult,
        emotion: EmotionState,
        userPreferences: UserPreferences
    ) -> String {
        let templates = minimumWeightTemplates[emotion] ?? minimumWeightTemplates[.stable]!
        let template = templates.randomElement()!

        let formattedValue = formatWeight(result.value, unit: userPreferences.preferredUnit)
        let formattedDate = formatDate(result.date)

        return template
            .replacingOccurrences(of: "{value}", with: formattedValue)
            .replacingOccurrences(of: "{date}", with: formattedDate)
    }

    private func generateWeightMaximumResponse(
        result: WeightAnalysisResult,
        emotion: EmotionState,
        userPreferences: UserPreferences
    ) -> String {
        let templates = maximumWeightTemplates[emotion] ?? maximumWeightTemplates[.stable]!
        let template = templates.randomElement()!

        let formattedValue = formatWeight(result.value, unit: userPreferences.preferredUnit)
        let formattedDate = formatDate(result.date)

        return template
            .replacingOccurrences(of: "{value}", with: formattedValue)
            .replacingOccurrences(of: "{date}", with: formattedDate)
    }

    private func generateWeightAverageResponse(
        result: WeightAnalysisResult,
        emotion: EmotionState,
        userPreferences: UserPreferences
    ) -> String {
        let formattedValue = formatWeight(result.value, unit: userPreferences.preferredUnit)

        switch emotion {
        case .energized:
            return "Your average weight is \(formattedValue)! You're tracking consistently! 📊"
        case .stable:
            return "Your average weight is \(formattedValue)."
        case .stressed:
            return "Your average weight is \(formattedValue). Consistency is progress."
        case .tired:
            return "Your average is \(formattedValue). You're doing great."
        case .offtrack:
            return "Your average weight is \(formattedValue). Let's build on that."
        }
    }

    private func generateWeightChangeResponse(
        result: WeightChangeResult,
        emotion: EmotionState,
        userPreferences: UserPreferences
    ) -> String {
        let templates = weightChangeTemplates[emotion] ?? weightChangeTemplates[.stable]!
        let template = templates.randomElement()!

        let formattedChange = formatWeight(abs(result.change), unit: userPreferences.preferredUnit)

        return template
            .replacingOccurrences(of: "{change}", with: formattedChange)
            .replacingOccurrences(of: "{period}", with: "month") // TODO: Extract from intent
    }

    private func generateFastCountResponse(
        count: Int,
        emotion: EmotionState,
        period: String
    ) -> String {
        let templates = fastCountTemplates[emotion] ?? fastCountTemplates[.stable]!
        let template = templates.randomElement()!

        return template
            .replacingOccurrences(of: "{count}", with: "\(count)")
            .replacingOccurrences(of: "{period}", with: period)
    }

    private func generateStreakResponse(
        streak: Int,
        emotion: EmotionState
    ) -> String {
        let templates = streakTemplates[emotion] ?? streakTemplates[.stable]!
        let template = templates.randomElement()!

        return template
            .replacingOccurrences(of: "{streak}", with: "\(streak)")
    }

    private func generateTrendResponse(
        result: TrendAnalysisResult,
        emotion: EmotionState
    ) -> String {
        let templates = trendTemplates[emotion] ?? trendTemplates[.stable]!
        let template = templates.randomElement()!

        let strengthPercent = Int(abs(result.strength) * 100)
        let confidencePercent = Int(result.confidence * 100)

        return template
            .replacingOccurrences(of: "{direction}", with: result.direction.rawValue)
            .replacingOccurrences(of: "{strength}", with: "\(strengthPercent)")
            .replacingOccurrences(of: "{confidence}", with: "\(confidencePercent)")
    }

    private func generateGoalProgressResponse(
        percentage: Double,
        emotion: EmotionState,
        target: String
    ) -> String {
        let templates = goalProgressTemplates[emotion] ?? goalProgressTemplates[.stable]!
        let template = templates.randomElement()!

        return template
            .replacingOccurrences(of: "{percentage}", with: String(format: "%.1f", percentage))
            .replacingOccurrences(of: "{target}", with: target)
    }

    // MARK: - Formatting Helpers

    private func formatWeight(_ value: Double, unit: WeightUnit) -> String {
        let formatted = String(format: "%.1f", value)
        return "\(formatted) \(unit.rawValue)"
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else {
            return "recently"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func fallbackResponse(for emotion: EmotionState) -> String {
        switch emotion {
        case .energized:
            return "I'm working on that answer for you! 💪"
        case .stable:
            return "I'm analyzing your data."
        case .stressed:
            return "I'm looking into that. Give me a moment."
        case .tired:
            return "Let me find that for you."
        case .offtrack:
            return "I'm working on your answer."
        }
    }
}

// MARK: - Template Metrics

extension ResponseGenerator {
    /// Total template count (production standard: 50+)
    var totalTemplateCount: Int {
        minimumWeightTemplates.values.reduce(0) { $0 + $1.count } +
        maximumWeightTemplates.values.reduce(0) { $0 + $1.count } +
        weightChangeTemplates.values.reduce(0) { $0 + $1.count } +
        fastCountTemplates.values.reduce(0) { $0 + $1.count } +
        streakTemplates.values.reduce(0) { $0 + $1.count } +
        trendTemplates.values.reduce(0) { $0 + $1.count } +
        goalProgressTemplates.values.reduce(0) { $0 + $1.count }
    }

    /// Emotion coverage (should be 5 emotions)
    var emotionCoverage: Int {
        Set(EmotionState.allCases).count
    }
}
