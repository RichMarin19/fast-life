//
// ResponseGenerator.swift
// FastingTracker
//
// Created for LifeGPT Phase 2 Hour 3 - Response Generation
// Updated for Phase 3D: Intelligence-Enhanced Responses
// Production-grade insight-rich responses with 100+ templates
// Reference: docs/planning/PHASE-3-INTELLIGENCE-UPGRADE.md Phase 3D
//
// Industry Standards:
// - Duolingo motivational messaging
// - MyFitnessPal progress celebrations
// - Headspace tone and voice
// - Whoop recovery insights
// - Oura readiness recommendations
// - Levels actionable advice
//

import Foundation

// MARK: - Response Generator Protocol

/// Protocol for generating emotion-aware, insight-rich responses
/// **Production Standard:** Contextual, personalized, ES-5 integrated, multi-metric insights
protocol ResponseGeneratorProtocol {
    /// Generate response from analysis result
    func generateResponse(
        for intent: QueryIntent,
        result: Any,
        emotion: EmotionState,
        userPreferences: UserPreferences
    ) -> String

    /// Generate insight-rich response with context, recommendations, and follow-ups
    /// **Phase 3D Enhancement:** Integrates InsightGenerator + ConversationManager
    func generateEnhancedResponse(
        for intent: QueryIntent,
        result: Any,
        emotion: EmotionState,
        userPreferences: UserPreferences,
        insights: InsightCollection?,
        recommendations: [Recommendation]?,
        conversationContext: ConversationContext?
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
            timeOfDay: BehavioralCopy.currentDayPart().rawValue
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

    // MARK: - Phase 3D: Insight-Rich Templates (50+ new templates)

    /// Insight-rich average weight templates (context + interpretation + recommendation)
    /// **Industry Pattern:** Whoop recovery insights, Oura readiness
    private let insightfulAverageTemplates: [EmotionState: [String]] = [
        .energized: [
            "Your average weight this week is {value} - that's down {change} from last week! You completed {fasts} fasts this week. Great consistency! 💪",
            "Average: {value} this week (down {change} from last week). Your {fasts} fasts are paying off! Keep this momentum!",
            "{value} average this week - you're down {change} from last week! With {fasts} fasts completed, you're crushing it!",
            "This week's average: {value}, down {change} from last week. Your {fasts} fasts are driving results! 🔥",
            "Average weight: {value} (down {change}). You're {distance} from your goal. At this rate, you'll reach it in {eta}!"
        ],
        .stable: [
            "Your average weight this week is {value}, {comparison} from last week. You completed {fasts} fasts this week.",
            "Average: {value} this week. You're {distance} away from your {goal} goal. You completed {fasts} fasts.",
            "{value} is your average this week. With {fasts} fasts completed, you're {comparison} from last week.",
            "This week's average: {value}. You're maintaining consistency with {fasts} fasts.",
            "Your average is {value}. You're {distance} from your goal of {goal}."
        ],
        .stressed: [
            "Your average weight this week is {value}, {comparison} from last week. You completed {fasts} fasts (down from {lastFasts} last week). Try increasing frequency for better results.",
            "Average: {value} this week. You're {distance} from your {goal} goal. Consistency is key - you completed {fasts} fasts vs {lastFasts} last week.",
            "{value} average this week, {comparison} from last week. Increasing your fasting to {targetFasts}x per week could accelerate progress.",
            "This week's average: {value}. You completed {fasts} fasts. Try matching last week's {lastFasts} fasts for better momentum.",
            "Your average is {value}. You're {distance} from your goal. Focus on consistent fasting - aim for {targetFasts} fasts per week."
        ],
        .tired: [
            "Your average weight this week is {value}. You completed {fasts} fasts. Rest is important too - be gentle with yourself.",
            "Average: {value} this week. You're {distance} from your goal. You completed {fasts} fasts - that's enough.",
            "{value} is your average. With {fasts} fasts this week, you're still showing up. Be proud.",
            "This week's average: {value}. You completed {fasts} fasts. Take it one day at a time.",
            "Your average is {value}. You're {distance} from your goal. Focus on consistency, not perfection."
        ],
        .offtrack: [
            "Your average weight this week is {value}, up {change} from last week. You completed {fasts} fasts this week (down from {lastFasts} last week). Try increasing frequency to get back on track.",
            "Average: {value} this week (up {change}). You're {distance} from your {goal} goal. Increase fasting to {targetFasts}x per week to accelerate progress.",
            "{value} average this week. You completed {fasts} fasts vs {lastFasts} last week. Let's rebuild consistency together.",
            "This week's average: {value}, up {change} from last week. Try adding {additionalFasts} more fasts this week.",
            "Your average is {value}. You're {distance} from your goal. Focus on getting back to {targetFasts} fasts per week."
        ]
    ]

    /// Week-over-week comparison templates (multi-metric correlation)
    /// **Industry Pattern:** Levels glucose correlation insights
    private let weekOverWeekTemplates: [EmotionState: [String]] = [
        .energized: [
            "This week vs last week: Weight down {weightChange}, fasts up from {lastFasts} to {thisFasts}! Your consistency is driving results! 💪",
            "Week-over-week: {weightChange} lost, {fastingChange} more fasts completed. You're in a great rhythm!",
            "Compared to last week: Down {weightChange}, completed {thisFasts} fasts (up from {lastFasts}). Keep this energy!",
            "This week's progress: {weightChange} lost, {thisFasts} fasts done vs {lastFasts} last week. Amazing correlation!",
            "Week comparison: Weight trending down ({weightChange}), fasting up ({thisFasts} vs {lastFasts}). Perfect sync! 🔥"
        ],
        .stable: [
            "This week vs last week: Weight {weightChange}, completed {thisFasts} fasts (last week: {lastFasts}).",
            "Week-over-week: {weightChange} change, {thisFasts} fasts this week vs {lastFasts} last week.",
            "Compared to last week: {weightChange}, {thisFasts} fasts completed.",
            "This week's data: {weightChange} weight change, {thisFasts} fasts (previous: {lastFasts}).",
            "Week comparison: {weightChange} shift, {thisFasts} fasts vs {lastFasts} prior week."
        ],
        .stressed: [
            "This week vs last week: Weight up {weightChange}, fasts down from {lastFasts} to {thisFasts}. Try increasing frequency.",
            "Week-over-week: {weightChange} gain, {thisFasts} fasts vs {lastFasts} last week. Consistency matters.",
            "Compared to last week: Up {weightChange}, completed {thisFasts} fasts (down from {lastFasts}). Let's rebuild momentum.",
            "This week's data: {weightChange} change, {thisFasts} fasts done. Aim for {targetFasts} fasts next week.",
            "Week comparison: Weight shifted {weightChange}, fasting dropped to {thisFasts}. Focus on consistency."
        ],
        .tired: [
            "This week vs last week: {weightChange}, completed {thisFasts} fasts. Be gentle with yourself.",
            "Week-over-week: {weightChange} change, {thisFasts} fasts. You're still showing up.",
            "Compared to last week: {weightChange}, {thisFasts} fasts completed. That's enough.",
            "This week's data: {weightChange}, {thisFasts} fasts done. Rest is part of the journey.",
            "Week comparison: {weightChange} shift, {thisFasts} fasts. Take it one day at a time."
        ],
        .offtrack: [
            "This week vs last week: Weight up {weightChange}, fasts down from {lastFasts} to {thisFasts}. You can turn this around.",
            "Week-over-week: {weightChange} gain, {fastingChange} fewer fasts. Let's refocus together.",
            "Compared to last week: Up {weightChange}, {thisFasts} fasts (down from {lastFasts}). Every day is a fresh start.",
            "This week's data: {weightChange} change, {thisFasts} fasts. Try adding {additionalFasts} more fasts next week.",
            "Week comparison: {weightChange} shift, {thisFasts} fasts vs {lastFasts}. You've got this - rebuild consistency."
        ]
    ]

    /// Recommendation templates (actionable advice)
    /// **Industry Pattern:** Noom coaching recommendations
    private let recommendationTemplates: [RecommendationImpact: [String]] = [
        .high: [
            "💡 Try this: {action}. Your data shows {reason}. This could have a significant impact.",
            "Recommended: {action}. Why? {reason}. High-impact change.",
            "Here's what I suggest: {action}. Based on your patterns, {reason}.",
            "Action item: {action}. Your data reveals {reason}. This is a game-changer.",
            "I'd recommend: {action}. The data shows {reason}. High confidence."
        ],
        .medium: [
            "Consider: {action}. {reason}. This could help.",
            "Suggestion: {action}. Based on your data, {reason}.",
            "Try: {action}. Your patterns show {reason}.",
            "Recommended approach: {action}. Why? {reason}.",
            "Worth trying: {action}. {reason} according to your data."
        ],
        .low: [
            "Optional: {action}. {reason}. Small adjustment.",
            "You might try: {action}. {reason}.",
            "Consider this: {action}. {reason} based on your history.",
            "Small suggestion: {action}. Your data indicates {reason}.",
            "Worth noting: {action}. {reason}."
        ]
    ]

    /// Celebration templates (milestone achievements)
    /// **Industry Pattern:** MyFitnessPal celebrations
    private let celebrationTemplates: [String] = [
        "🎉 {milestone}! You've {achievement}! That's incredible dedication!",
        "Wow! {milestone}! You've {achievement}! Keep this momentum!",
        "Amazing! {milestone} reached! You've {achievement}! Outstanding!",
        "Congratulations! {milestone}! You've {achievement}! You're crushing it!",
        "Fantastic! {milestone}! You've {achievement}! That's phenomenal!"
    ]

    /// Contextual reference templates (conversation continuity)
    /// **Industry Pattern:** ChatGPT conversation memory
    private let contextualReferenceTemplates: [String] = [
        "Building on what we discussed earlier, {insight}",
        "Following up on your last question, {insight}",
        "As I mentioned before, {insight}",
        "Looking at your recent data, {insight}",
        "Based on your progress, {insight}"
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

        case .weightChange(let period):
            guard let changeResult = result as? WeightChangeResult else {
                return fallbackResponse(for: emotion)
            }
            // Extract period from intent's period (Apple pattern: context from query)
            let periodString = timePeriodToDisplayString(period)
            return generateWeightChangeResponse(
                result: changeResult,
                emotion: emotion,
                userPreferences: userPreferences,
                period: periodString
            )

        // MARK: Fasting Stats Responses

        case .fastCount(let timeRange):
            guard let count = result as? Int else {
                return fallbackResponse(for: emotion)
            }
            // Extract period from intent's timeRange (Apple pattern: context from query)
            let periodString = timeRangeToDisplayString(timeRange)
            return generateFastCountResponse(
                count: count,
                emotion: emotion,
                period: periodString
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

    // MARK: - Phase 3D: Enhanced Response Generation

    /// Generate insight-rich response with context, recommendations, and follow-ups
    /// **Industry Pattern:** Whoop + Oura + Levels insight synthesis
    /// **Flow:**
    /// 1. Generate base response (existing logic)
    /// 2. Add contextual reference (if conversation history exists)
    /// 3. Synthesize top insights (goal progress, trends, correlations)
    /// 4. Add actionable recommendations
    /// 5. Optionally add celebration if milestone reached
    func generateEnhancedResponse(
        for intent: QueryIntent,
        result: Any,
        emotion: EmotionState,
        userPreferences: UserPreferences,
        insights: InsightCollection?,
        recommendations: [Recommendation]?,
        conversationContext: ConversationContext?
    ) -> String {
        var responseParts: [String] = []

        // MARK: 1. Contextual Reference (if conversation history)

        if let context = conversationContext, context.currentTopic != .unknown {
            // Only add reference if it's a follow-up question (same topic)
            if !detectTopicSwitch(context: context, newIntent: intent) {
                if let reference = generateContextualReference(context: context) {
                    responseParts.append(reference)
                }
            }
        }

        // MARK: 2. Core Response (with insights if available)

        let coreResponse = generateCoreResponseWithInsights(
            for: intent,
            result: result,
            emotion: emotion,
            userPreferences: userPreferences,
            insights: insights
        )
        responseParts.append(coreResponse)

        // MARK: 3. Top Priority Insights (if critical)

        if let insights = insights {
            let criticalInsights = insights.insights(withPriority: .critical)
            if !criticalInsights.isEmpty {
                let insightText = synthesizeInsights(criticalInsights, emotion: emotion)
                responseParts.append(insightText)
            }
        }

        // MARK: 4. Actionable Recommendation (highest confidence)

        if let recommendations = recommendations, !recommendations.isEmpty {
            let topRec = recommendations.first!  // Already sorted by confidence
            let recText = renderRecommendation(topRec)
            responseParts.append(recText)
        }

        // MARK: 5. Celebration (if milestone)

        if let insights = insights {
            let celebrations = insights.insights(ofType: .celebration)
            if !celebrations.isEmpty, let celebration = celebrations.first {
                let celebrationText = renderCelebration(celebration)
                responseParts.append(celebrationText)
            }
        }

        // Join all parts with line breaks
        return responseParts.joined(separator: "\n\n")
    }

    // MARK: - Enhanced Response Helpers

    /// Generate core response with insights baked in (if available)
    private func generateCoreResponseWithInsights(
        for intent: QueryIntent,
        result: Any,
        emotion: EmotionState,
        userPreferences: UserPreferences,
        insights: InsightCollection?
    ) -> String {
        // CRITICAL: Always answer the question FIRST, then add insights
        // Industry Pattern: Whoop/Oura/Apple Health - Data point first, analysis second

        // For currentWeight queries, generate simple answer first
        if case .currentWeight = intent,
           let weightResult = result as? WeightAnalysisResult {

            let formattedValue = formatWeight(weightResult.value, unit: userPreferences.preferredUnit)
            let formattedDate = formatDate(weightResult.date)

            // Simple, direct answer (what user asked for)
            return "Your current weight is \(formattedValue) as of \(formattedDate)."
        }

        // For average weight queries, use insight-rich templates if insights available
        if case .averageWeight = intent,
           let weightResult = result as? WeightAnalysisResult,
           let insights = insights {

            return generateInsightfulAverageResponse(
                result: weightResult,
                emotion: emotion,
                userPreferences: userPreferences,
                insights: insights
            )
        }

        // For other intents, use existing logic
        return generateResponse(
            for: intent,
            result: result,
            emotion: emotion,
            userPreferences: userPreferences
        )
    }

    /// Generate insight-rich average weight response
    /// **Enhancement:** Context + interpretation + recommendation baked into single response
    private func generateInsightfulAverageResponse(
        result: WeightAnalysisResult,
        emotion: EmotionState,
        userPreferences: UserPreferences,
        insights: InsightCollection
    ) -> String {
        let templates = insightfulAverageTemplates[emotion] ?? insightfulAverageTemplates[.stable]!
        let template = templates.randomElement()!

        let formattedValue = formatWeight(result.value, unit: userPreferences.preferredUnit)

        // Extract insight data for template tokens
        var tokens: [String: String] = [
            "value": formattedValue
        ]

        // Add goal progress data
        if let goalInsight = insights.insights(ofType: .goalProgress).first {
            if let distance = goalInsight.metadata["distance"] {
                tokens["distance"] = distance + " lbs"
            }
            if let goal = goalInsight.metadata["goalWeight"] {
                tokens["goal"] = goal + " lbs"
            }
            if let eta = goalInsight.metadata["eta"] {
                tokens["eta"] = eta
            }
        }

        // Add week-over-week data
        if let weekInsight = insights.insights(ofType: .weekOverWeek).first {
            if let weightChange = weekInsight.metadata["weightChange"] {
                tokens["change"] = weightChange + " lbs"
                tokens["comparison"] = "up \(weightChange) lbs"
            }
            if let fastsThisWeek = weekInsight.metadata["fastsThisWeek"] {
                tokens["fasts"] = fastsThisWeek
            }
            if let fastsLastWeek = weekInsight.metadata["fastsLastWeek"] {
                tokens["lastFasts"] = fastsLastWeek
            }
        }

        // Add target fasts (from recommendations)
        tokens["targetFasts"] = "5"  // Default target
        tokens["additionalFasts"] = "2"  // Default suggestion

        // Replace tokens in template
        var response = template
        for (key, value) in tokens {
            response = response.replacingOccurrences(of: "{\(key)}", with: value)
        }

        // Clean up any unreplaced tokens
        response = response.replacingOccurrences(of: #"\{[^}]+\}"#, with: "", options: .regularExpression)

        return response
    }

    /// Synthesize multiple insights into readable text
    private func synthesizeInsights(_ insights: [HealthInsight], emotion: EmotionState) -> String {
        guard !insights.isEmpty else { return "" }

        // For critical insights, combine into urgent message
        let messages = insights.map { $0.message }
        return messages.joined(separator: " ")
    }

    /// Render recommendation using templates
    private func renderRecommendation(_ recommendation: Recommendation) -> String {
        let templates = recommendationTemplates[recommendation.impact] ?? recommendationTemplates[.medium]!
        let template = templates.randomElement()!

        return template
            .replacingOccurrences(of: "{action}", with: recommendation.action)
            .replacingOccurrences(of: "{reason}", with: recommendation.reason)
    }

    /// Render celebration using templates
    private func renderCelebration(_ celebration: HealthInsight) -> String {
        let template = celebrationTemplates.randomElement()!

        return template
            .replacingOccurrences(of: "{milestone}", with: celebration.title)
            .replacingOccurrences(of: "{achievement}", with: celebration.message)
    }

    /// Generate contextual reference from conversation history
    private func generateContextualReference(context: ConversationContext) -> String? {
        // Check if context has a last query (intentionally unused for now, reserved for future enhancement)
        guard context.lastQuery != nil else { return nil }

        let template = contextualReferenceTemplates.randomElement()!
        let reference = "your recent \(context.currentTopic.rawValue) data"

        return template.replacingOccurrences(of: "{insight}", with: reference)
    }

    /// Detect if topic switched (different from last query)
    private func detectTopicSwitch(context: ConversationContext, newIntent: QueryIntent) -> Bool {
        // Simple heuristic: if intent category changed, topic switched
        let previousTopic = context.currentTopic
        let newTopic = intentToTopic(newIntent)

        return newTopic != previousTopic
    }

    /// Map intent to conversation topic
    private func intentToTopic(_ intent: QueryIntent) -> ConversationTopic {
        switch intent {
        case .minimumWeight, .maximumWeight, .averageWeight, .weightChange, .weightTrend:
            return .weight
        case .fastCount, .fastingStreak:
            return .fasting
        case .goalProgress:
            return .goal
        default:
            return .general
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
        userPreferences: UserPreferences,
        period: String
    ) -> String {
        let templates = weightChangeTemplates[emotion] ?? weightChangeTemplates[.stable]!
        let template = templates.randomElement()!

        let formattedChange = formatWeight(abs(result.change), unit: userPreferences.preferredUnit)

        return template
            .replacingOccurrences(of: "{change}", with: formattedChange)
            .replacingOccurrences(of: "{period}", with: period)
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

    /// Convert TimeRange enum to human-readable display string
    /// Following Apple pattern: context from query metadata
    private func timeRangeToDisplayString(_ timeRange: TimeRange?) -> String {
        guard let timeRange = timeRange else {
            return "recently"
        }

        switch timeRange {
        case .today:
            return "today"
        case .yesterday:
            return "yesterday"
        case .thisWeek:
            return "week"
        case .lastWeek:
            return "last week"
        case .thisMonth:
            return "month"
        case .lastMonth:
            return "last month"
        case .thisYear:
            return "year"
        case .lastYear:
            return "last year"
        case .last7Days:
            return "week"
        case .last30Days:
            return "month"
        case .last90Days:
            return "quarter"
        case .allTime:
            return "all time"
        case .custom:
            return "period"
        }
    }

    /// Convert TimePeriod enum to human-readable display string
    /// Following Apple pattern: context from query metadata
    private func timePeriodToDisplayString(_ period: TimePeriod?) -> String {
        guard let period = period else {
            return "period"
        }

        switch period {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        case .custom(let days):
            if days == 7 {
                return "week"
            } else if days == 30 {
                return "month"
            } else if days == 90 {
                return "quarter"
            } else {
                return "\(days)-day period"
            }
        }
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
    /// Total template count (production standard: 100+)
    /// **Phase 3D:** Expanded from 50 to 100+ templates
    var totalTemplateCount: Int {
        // Original templates (50)
        let originalCount = minimumWeightTemplates.values.reduce(0) { $0 + $1.count } +
        maximumWeightTemplates.values.reduce(0) { $0 + $1.count } +
        weightChangeTemplates.values.reduce(0) { $0 + $1.count } +
        fastCountTemplates.values.reduce(0) { $0 + $1.count } +
        streakTemplates.values.reduce(0) { $0 + $1.count } +
        trendTemplates.values.reduce(0) { $0 + $1.count } +
        goalProgressTemplates.values.reduce(0) { $0 + $1.count }

        // Phase 3D insight-rich templates (50+)
        let insightCount = insightfulAverageTemplates.values.reduce(0) { $0 + $1.count } +
        weekOverWeekTemplates.values.reduce(0) { $0 + $1.count } +
        recommendationTemplates.values.reduce(0) { $0 + $1.count } +
        celebrationTemplates.count +
        contextualReferenceTemplates.count

        return originalCount + insightCount
    }

    /// Emotion coverage (should be 5 emotions)
    var emotionCoverage: Int {
        Set(EmotionState.allCases).count
    }

    /// Insight integration (Phase 3D feature flag)
    var supportsEnhancedResponses: Bool {
        true
    }
}
