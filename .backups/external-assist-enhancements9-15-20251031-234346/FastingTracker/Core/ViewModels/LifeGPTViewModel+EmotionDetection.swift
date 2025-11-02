//
// LifeGPTViewModel+EmotionDetection.swift
// FastingTracker
//
// Created for LifeGPT Feature - Phase 1 Hour 3
// Emotion detection logic for ES-5 system
// Reference: FastLIFe_LIFeGPT_UI_Behavioral_Spec_Hour3.md
//

import Foundation

// MARK: - Emotion Detection Extension

extension LifeGPTViewModel {

    // MARK: - Public Emotion Detection

    /// Detect emotion state based on query type and data context
    /// **Simple heuristic approach for Phase 1**
    ///
    /// **Phase 2 Enhancement:** Replace with ML-based sentiment analysis or OpenAI integration
    ///
    /// **Detection Logic:**
    /// - **Energized:** Positive trends (weight loss, fasting streaks, good sleep)
    /// - **Stable:** Maintenance, neutral info, consistent patterns
    /// - **Stressed:** Volatility, inconsistency, missed goals
    /// - **Tired:** Low sleep, low energy indicators
    /// - **Off-track:** Negative trends, >72h idle, regression
    ///
    /// - Parameters:
    ///   - queryType: Type of query being handled
    ///   - dataContext: Context from data fetch results
    /// - Returns: Detected emotion state
    func detectEmotion(for queryType: QueryType, dataContext: DataContext) -> EmotionState {
        switch queryType {
        case .weight:
            return detectWeightEmotion(dataContext: dataContext)

        case .fasting:
            return detectFastingEmotion(dataContext: dataContext)

        case .sleep:
            return detectSleepEmotion(dataContext: dataContext)

        case .hydration:
            return detectHydrationEmotion(dataContext: dataContext)

        case .mood:
            return detectMoodEmotion(dataContext: dataContext)

        case .summary:
            return detectSummaryEmotion(dataContext: dataContext)

        case .general, .unknown:
            return .stable // Default to neutral
        }
    }

    // MARK: - Query Type-Specific Emotion Detection

    /// Detect emotion for weight queries
    private func detectWeightEmotion(dataContext: DataContext) -> EmotionState {
        guard let weightChange = dataContext.weightChange else {
            return .stable // No data = neutral
        }

        // Check for weight loss (positive trend)
        if weightChange < -2.0 {
            return .energized // Losing >2 lbs = great progress
        } else if weightChange < -0.5 {
            return .energized // Losing 0.5-2 lbs = positive momentum
        } else if weightChange >= -0.5 && weightChange <= 0.5 {
            return .stable // Maintenance range
        } else if weightChange > 0.5 && weightChange < 2.0 {
            return .stressed // Gaining 0.5-2 lbs = gentle awareness
        } else {
            return .offtrack // Gaining >2 lbs = need support
        }
    }

    /// Detect emotion for fasting queries
    private func detectFastingEmotion(dataContext: DataContext) -> EmotionState {
        guard let fastingCount = dataContext.fastingCount else {
            return .stable
        }

        // Check for active fast
        if dataContext.isFastingActive == true {
            return .energized // Currently fasting = momentum
        }

        // Check fasting frequency (this week)
        if fastingCount >= 5 {
            return .energized // 5+ fasts this week = excellent
        } else if fastingCount >= 3 {
            return .stable // 3-4 fasts = consistent
        } else if fastingCount >= 1 {
            return .stressed // 1-2 fasts = inconsistent
        } else {
            return .offtrack // 0 fasts = need restart
        }
    }

    /// Detect emotion for sleep queries
    private func detectSleepEmotion(dataContext: DataContext) -> EmotionState {
        guard let avgSleepHours = dataContext.avgSleepHours else {
            return .stable
        }

        // Sleep quality thresholds
        if avgSleepHours >= 7.5 {
            return .energized // Good sleep = energized
        } else if avgSleepHours >= 6.5 {
            return .stable // Adequate sleep = stable
        } else if avgSleepHours >= 5.5 {
            return .tired // Low sleep = tired
        } else {
            return .offtrack // Very low sleep = need recovery
        }
    }

    /// Detect emotion for hydration queries
    private func detectHydrationEmotion(dataContext: DataContext) -> EmotionState {
        guard let hydrationOz = dataContext.hydrationOz else {
            return .stable
        }

        // Hydration goals (assuming 64 oz daily goal)
        if hydrationOz >= 64 {
            return .energized // Met goal
        } else if hydrationOz >= 40 {
            return .stable // Partial progress
        } else if hydrationOz > 0 {
            return .stressed // Low hydration
        } else {
            return .offtrack // No hydration logged
        }
    }

    /// Detect emotion for mood queries
    private func detectMoodEmotion(dataContext: DataContext) -> EmotionState {
        guard let moodRating = dataContext.moodRating else {
            return .stable
        }

        // Mood rating scale (1-5)
        if moodRating >= 4 {
            return .energized // Happy mood
        } else if moodRating == 3 {
            return .stable // Neutral mood
        } else if moodRating == 2 {
            return .stressed // Low mood
        } else {
            return .tired // Very low mood (likely fatigue-related)
        }
    }

    /// Detect emotion for summary queries
    private func detectSummaryEmotion(dataContext: DataContext) -> EmotionState {
        // Aggregate multiple signals for overall emotion
        var emotionScore = 0

        // Weight contribution
        if let weightChange = dataContext.weightChange {
            if weightChange < -0.5 { emotionScore += 2 } // Positive
            else if weightChange > 1.0 { emotionScore -= 2 } // Negative
        }

        // Fasting contribution
        if let fastingCount = dataContext.fastingCount {
            if fastingCount >= 3 { emotionScore += 1 }
            else if fastingCount == 0 { emotionScore -= 1 }
        }

        // Sleep contribution
        if let avgSleep = dataContext.avgSleepHours {
            if avgSleep >= 7.0 { emotionScore += 1 }
            else if avgSleep < 6.0 { emotionScore -= 1 }
        }

        // Map aggregate score to emotion
        if emotionScore >= 3 {
            return .energized
        } else if emotionScore >= 1 {
            return .stable
        } else if emotionScore <= -3 {
            return .offtrack
        } else if emotionScore <= -1 {
            return .stressed
        } else {
            return .stable
        }
    }
}

// MARK: - Query Type

/// Type of query being handled
enum QueryType {
    case weight
    case fasting
    case sleep
    case hydration
    case mood
    case summary
    case general
    case unknown
}

// MARK: - Data Context

/// Context data for emotion detection
/// Contains relevant metrics fetched from data service
struct DataContext {
    // Weight context
    var weightChange: Double? // Change in lbs (negative = loss, positive = gain)
    var weightTrend: String? // "improving", "stable", "regressing"

    // Fasting context
    var fastingCount: Int? // Number of fasts this week
    var isFastingActive: Bool? // Whether currently fasting
    var fastingStreak: Int? // Current streak in days

    // Sleep context
    var avgSleepHours: Double? // Average sleep hours
    var sleepConsistency: Double? // Sleep consistency percentage

    // Hydration context
    var hydrationOz: Double? // Water intake in oz (today)

    // Mood context
    var moodRating: Int? // Mood rating 1-5
    var energyLevel: Int? // Energy level 1-5

    // General context
    var daysSinceLastEntry: Int? // Days since last data entry (idle detection)
    var overallTrend: String? // "improving", "stable", "declining"

    /// Initialize empty data context
    init(
        weightChange: Double? = nil,
        weightTrend: String? = nil,
        fastingCount: Int? = nil,
        isFastingActive: Bool? = nil,
        fastingStreak: Int? = nil,
        avgSleepHours: Double? = nil,
        sleepConsistency: Double? = nil,
        hydrationOz: Double? = nil,
        moodRating: Int? = nil,
        energyLevel: Int? = nil,
        daysSinceLastEntry: Int? = nil,
        overallTrend: String? = nil
    ) {
        self.weightChange = weightChange
        self.weightTrend = weightTrend
        self.fastingCount = fastingCount
        self.isFastingActive = isFastingActive
        self.fastingStreak = fastingStreak
        self.avgSleepHours = avgSleepHours
        self.sleepConsistency = sleepConsistency
        self.hydrationOz = hydrationOz
        self.moodRating = moodRating
        self.energyLevel = energyLevel
        self.daysSinceLastEntry = daysSinceLastEntry
        self.overallTrend = overallTrend
    }
}
