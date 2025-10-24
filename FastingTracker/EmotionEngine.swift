//
// EmotionEngine.swift
// FastingTracker
//
// Created for Phase 3A: Goal-Aware Emotion Detection
// Industry Pattern: Fitbit coaching tones, Whoop recovery scoring
// Reference: docs/planning/PHASE-3-INTELLIGENCE-UPGRADE.md
//

import Foundation

// MARK: - Emotion Engine Protocol

/// Protocol for goal-aware emotion detection
/// **Single Source of Truth** for ES-5 state determination
protocol EmotionEngineProtocol {
    /// Detect emotion state based on user's goal progress and trends
    /// - Parameters:
    ///   - context: Current health metrics and goal information
    /// - Returns: Detected EmotionState (ES-5)
    func detectEmotion(context: EmotionContext) -> EmotionState
}

// MARK: - Emotion Context

/// Context for emotion detection
/// Contains all data needed to determine user's emotional state
struct EmotionContext {
    // MARK: Weight Goal Context

    /// User's weight goal (optional - may not be set)
    let weightGoal: Double?

    /// Current weight
    let currentWeight: Double?

    /// Weight trend direction (positive = gaining, negative = losing)
    let weightTrend: Double?  // lbs per week

    /// Weight change in last 7 days
    let weightChangeLast7Days: Double?  // positive = gain, negative = loss

    // MARK: Fasting Context

    /// Fasting count this week
    let fastingCountThisWeek: Int?

    /// Fasting count last week
    let fastingCountLastWeek: Int?

    /// Current fasting streak (days)
    let fastingStreak: Int?

    // MARK: Progress Metrics

    /// Progress rate toward goal (lbs per week)
    /// Calculated as: (currentWeight - goalWeight) / weeksToGoal
    let progressRate: Double?

    /// Required rate to hit goal (lbs per week)
    /// Based on user's target date
    let requiredRate: Double?

    /// Days since last activity (data entry, fast, weight log)
    let daysSinceLastActivity: Int?

    // MARK: Convenience Initializer

    /// Create context with all optional parameters (for testing/flexibility)
    init(
        weightGoal: Double? = nil,
        currentWeight: Double? = nil,
        weightTrend: Double? = nil,
        weightChangeLast7Days: Double? = nil,
        fastingCountThisWeek: Int? = nil,
        fastingCountLastWeek: Int? = nil,
        fastingStreak: Int? = nil,
        progressRate: Double? = nil,
        requiredRate: Double? = nil,
        daysSinceLastActivity: Int? = nil
    ) {
        self.weightGoal = weightGoal
        self.currentWeight = currentWeight
        self.weightTrend = weightTrend
        self.weightChangeLast7Days = weightChangeLast7Days
        self.fastingCountThisWeek = fastingCountThisWeek
        self.fastingCountLastWeek = fastingCountLastWeek
        self.fastingStreak = fastingStreak
        self.progressRate = progressRate
        self.requiredRate = requiredRate
        self.daysSinceLastActivity = daysSinceLastActivity
    }
}

// MARK: - Emotion Engine Implementation

/// Production-grade goal-aware emotion detection engine
/// **Architecture:** Rule-based decision tree (no ML/AI required)
/// **Industry Patterns:**
/// - Fitbit: Coaching tones based on goal progress
/// - Whoop: Recovery scoring with strain context
/// - Oura: Readiness detection from multi-metric synthesis
class EmotionEngine: EmotionEngineProtocol {

    // MARK: - Singleton

    static let shared = EmotionEngine()

    private init() {}

    // MARK: - Detection Logic

    /// Detect emotion state using goal-aware decision tree
    /// **Decision Priority:**
    /// 1. Check for inactivity (offtrack if >3 days idle)
    /// 2. Check goal direction + trend alignment (offtrack if opposing)
    /// 3. Check progress rate vs required rate (energized, stable, stressed, tired)
    /// 4. Fallback to stable if insufficient data
    ///
    /// - Parameter context: User's current health metrics and goals
    /// - Returns: Detected EmotionState
    func detectEmotion(context: EmotionContext) -> EmotionState {

        // MARK: Priority 1 - Inactivity Detection

        // If user hasn't logged data in >3 days, they're offtrack
        if let daysSinceActivity = context.daysSinceLastActivity,
           daysSinceActivity > 3 {
            return .offtrack
        }

        // MARK: Priority 2 - Goal Direction vs Trend Alignment

        // If user has a weight goal, check if trend is moving in right direction
        if let goal = context.weightGoal,
           let current = context.currentWeight,
           let trend = context.weightTrend {

            let goalDirection: GoalDirection = current > goal ? .decreasing : .increasing
            let trendDirection: EmotionTrendDirection = trend > 0 ? .increasing : .decreasing

            // If trend is moving OPPOSITE to goal direction → offtrack
            if goalDirection == .decreasing && trendDirection == .increasing {
                // Goal is to lose weight, but weight is increasing
                return .offtrack
            } else if goalDirection == .increasing && trendDirection == .decreasing {
                // Goal is to gain weight, but weight is decreasing
                return .offtrack
            }
        }

        // MARK: Priority 3 - Progress Rate Analysis

        // If we have goal + progress data, analyze rate
        if let progressRate = context.progressRate,
           let requiredRate = context.requiredRate,
           requiredRate > 0 {  // Avoid division by zero

            let rateRatio = abs(progressRate) / abs(requiredRate)

            // **Rate Thresholds (Industry Standard):**
            // - Energized: >120% of required rate (exceeding goal)
            // - Stable: 80-120% of required rate (on track)
            // - Stressed: 50-80% of required rate (falling behind)
            // - Tired: <50% of required rate (struggling)

            if rateRatio >= 1.2 {
                return .energized  // Exceeding expectations!
            } else if rateRatio >= 0.8 {
                return .stable  // On track
            } else if rateRatio >= 0.5 {
                return .stressed  // Falling behind, needs support
            } else {
                return .tired  // Struggling, needs recovery
            }
        }

        // MARK: Priority 4 - Fasting Consistency Check

        // If no goal data, check fasting consistency
        if let thisWeek = context.fastingCountThisWeek,
           let lastWeek = context.fastingCountLastWeek,
           lastWeek > 0 {  // Avoid division by zero

            let consistencyRatio = Double(thisWeek) / Double(lastWeek)

            // **Consistency Thresholds:**
            // - Energized: Improved by >20% (6 → 8+ fasts)
            // - Stable: Within ±20% (steady consistency)
            // - Stressed: Dropped 20-50% (slipping)
            // - Offtrack: Dropped >50% (major decline)

            if consistencyRatio >= 1.2 {
                return .energized  // Improving consistency!
            } else if consistencyRatio >= 0.8 {
                return .stable  // Maintaining consistency
            } else if consistencyRatio >= 0.5 {
                return .stressed  // Consistency slipping
            } else {
                return .offtrack  // Major consistency drop
            }
        }

        // MARK: Priority 5 - Weight Change Fallback

        // If we only have weight change data (no goal), use simple heuristics
        if let weightChange = context.weightChangeLast7Days {

            // **Weight Change Heuristics:**
            // Most users want to lose weight (common assumption)
            // - Energized: Lost >2 lbs in 7 days
            // - Stable: ±1 lb (maintaining)
            // - Stressed: Gained 1-3 lbs
            // - Offtrack: Gained >3 lbs

            if weightChange <= -2.0 {
                return .energized  // Significant loss
            } else if weightChange >= -1.0 && weightChange <= 1.0 {
                return .stable  // Maintaining
            } else if weightChange <= 3.0 {
                return .stressed  // Moderate gain
            } else {
                return .offtrack  // Significant gain
            }
        }

        // MARK: Fallback - Stable

        // If we don't have enough data to make a determination, default to stable
        // This is the neutral, non-judgmental state
        return .stable
    }
}

// MARK: - Helper Enums

/// Goal direction (user wants to increase or decrease metric)
private enum GoalDirection {
    case increasing  // User wants to gain weight/metric
    case decreasing  // User wants to lose weight/metric
}

/// Trend direction (metric is actually increasing or decreasing)
/// Renamed to avoid conflict with HealthDataAnalyzer.TrendDirection
private enum EmotionTrendDirection {
    case increasing  // Metric going up
    case decreasing  // Metric going down
}

// MARK: - Emotion Engine Extensions

extension EmotionEngine {

    /// Convenience method to detect emotion from ViewModel data
    /// Maps ViewModel properties to EmotionContext
    ///
    /// - Parameters:
    ///   - weightGoal: User's target weight
    ///   - currentWeight: User's current weight
    ///   - trendResult: TrendAnalysisResult from HealthDataAnalyzer
    ///   - fastingCountThisWeek: Fasts completed this week
    ///   - fastingCountLastWeek: Fasts completed last week
    ///   - daysSinceLastActivity: Days since last data entry
    /// - Returns: Detected EmotionState
    func detectEmotion(
        weightGoal: Double?,
        currentWeight: Double?,
        trendResult: TrendAnalysisResult?,
        fastingCountThisWeek: Int?,
        fastingCountLastWeek: Int?,
        daysSinceLastActivity: Int?
    ) -> EmotionState {

        let context = EmotionContext(
            weightGoal: weightGoal,
            currentWeight: currentWeight,
            weightTrend: trendResult?.strength,  // strength is rate of change
            weightChangeLast7Days: nil,  // Can calculate from trend if needed
            fastingCountThisWeek: fastingCountThisWeek,
            fastingCountLastWeek: fastingCountLastWeek,
            fastingStreak: nil,  // Optional for now
            progressRate: calculateProgressRate(
                current: currentWeight,
                goal: weightGoal,
                trend: trendResult?.strength
            ),
            requiredRate: calculateRequiredRate(
                current: currentWeight,
                goal: weightGoal
            ),
            daysSinceLastActivity: daysSinceLastActivity
        )

        return detectEmotion(context: context)
    }

    // MARK: - Private Helpers

    /// Calculate progress rate (lbs per week)
    /// Based on current trend strength
    private func calculateProgressRate(
        current: Double?,
        goal: Double?,
        trend: Double?
    ) -> Double? {
        guard let trend = trend else { return nil }

        // trend is already lbs per day (from linear regression)
        // Convert to lbs per week
        return trend * 7.0
    }

    /// Calculate required rate to hit goal (lbs per week)
    /// Assumes 12-week timeline (industry standard: 0.5-2 lbs/week)
    private func calculateRequiredRate(
        current: Double?,
        goal: Double?
    ) -> Double? {
        guard let current = current, let goal = goal else { return nil }

        let distance = abs(current - goal)
        let weeksToGoal = 12.0  // Industry standard: 12-week program

        return distance / weeksToGoal
    }
}
