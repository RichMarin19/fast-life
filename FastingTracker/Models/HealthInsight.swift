//
// HealthInsight.swift
// FastingTracker
//
// Created for Phase 3B: Insight Generator Models
// Industry Pattern: Oura Readiness, Whoop Recovery, Levels Insights
// Reference: docs/planning/PHASE-3-INTELLIGENCE-UPGRADE.md
//

import Foundation

// MARK: - Insight Context

/// Comprehensive health data context for intelligence layers
/// **Phase 4B:** Single source of truth for EmotionEngine, InsightGenerator, ConversationManager
/// **Industry Pattern:** Whoop Recovery Context, Oura Readiness Context
struct InsightContext {
    // Goal data
    let weightGoal: Double?
    let currentWeight: Double?
    let startWeight: Double?

    // Trend data (week-over-week)
    let weightChangeWeek: Double?

    // Fasting correlation data
    let fastingCountThisWeek: Int
    let fastingCountLastWeek: Int

    // Streak data (motivational)
    let currentStreak: Int
    let longestStreak: Int

    /// Initialize with all health data
    init(
        weightGoal: Double? = nil,
        currentWeight: Double? = nil,
        startWeight: Double? = nil,
        weightChangeWeek: Double? = nil,
        fastingCountThisWeek: Int = 0,
        fastingCountLastWeek: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0
    ) {
        self.weightGoal = weightGoal
        self.currentWeight = currentWeight
        self.startWeight = startWeight
        self.weightChangeWeek = weightChangeWeek
        self.fastingCountThisWeek = fastingCountThisWeek
        self.fastingCountLastWeek = fastingCountLastWeek
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
    }
}

// MARK: - Health Insight

/// Structured insight from multi-metric analysis
/// **Single Source of Truth** for insight data models
/// **Industry Pattern:** Oura Readiness, Whoop Strain Score, Levels Glucose Insights
struct HealthInsight: Identifiable, Equatable {
    let id: UUID
    let type: InsightType
    let priority: InsightPriority
    let title: String
    let message: String
    let value: Double?  // Optional numeric value (for charts/display)
    let metadata: [String: String]  // Additional context

    init(
        id: UUID = UUID(),
        type: InsightType,
        priority: InsightPriority,
        title: String,
        message: String,
        value: Double? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.priority = priority
        self.title = title
        self.message = message
        self.value = value
        self.metadata = metadata
    }
}

// MARK: - Insight Type

/// Type of insight (categorizes the insight for UI/sorting)
enum InsightType: String, Codable, CaseIterable {
    // MARK: Progress Insights
    case goalProgress       // Distance to goal, ETA, on-track status
    case trendAnalysis      // Weight trending up/down, rate of change
    case progressRate       // Current progress vs required progress

    // MARK: Correlation Insights
    case weightFastingCorrelation  // Weight change × fasting frequency
    case consistencyImpact         // Consistency × results correlation
    case streakEffect              // Streak length × progress relationship

    // MARK: Comparison Insights
    case weekOverWeek       // This week vs last week comparison
    case monthOverMonth     // This month vs last month comparison
    case historicalComparison // Current vs historical average

    // MARK: Recommendation Insights
    case actionable         // Specific action to take
    case celebration        // Milestone reached, positive reinforcement
    case support            // Encouragement during difficult times

    /// Display name for UI
    var displayName: String {
        switch self {
        case .goalProgress: return "Goal Progress"
        case .trendAnalysis: return "Trend Analysis"
        case .progressRate: return "Progress Rate"
        case .weightFastingCorrelation: return "Weight & Fasting"
        case .consistencyImpact: return "Consistency"
        case .streakEffect: return "Streak Effect"
        case .weekOverWeek: return "Week Comparison"
        case .monthOverMonth: return "Month Comparison"
        case .historicalComparison: return "Historical"
        case .actionable: return "Action"
        case .celebration: return "Milestone"
        case .support: return "Support"
        }
    }

    /// Icon for UI (SF Symbol)
    var icon: String {
        switch self {
        case .goalProgress: return "target"
        case .trendAnalysis: return "chart.line.uptrend.xyaxis"
        case .progressRate: return "speedometer"
        case .weightFastingCorrelation: return "link"
        case .consistencyImpact: return "calendar.badge.checkmark"
        case .streakEffect: return "flame.fill"
        case .weekOverWeek: return "calendar.day.timeline.left"
        case .monthOverMonth: return "calendar"
        case .historicalComparison: return "clock.arrow.circlepath"
        case .actionable: return "lightbulb.fill"
        case .celebration: return "star.fill"
        case .support: return "heart.fill"
        }
    }
}

// MARK: - Insight Priority

/// Priority level for insight display (higher = show first)
enum InsightPriority: Int, Codable, Comparable {
    case critical = 4   // Show immediately (offtrack, urgent action needed)
    case high = 3       // Important (milestone, significant correlation)
    case medium = 2     // Informative (week-over-week, trends)
    case low = 1        // Nice-to-know (historical comparisons)

    /// Compare priorities (for sorting)
    static func < (lhs: InsightPriority, rhs: InsightPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Display name for debugging
    var displayName: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
}

// MARK: - Insight Collection

/// Collection of insights with convenience methods
struct InsightCollection {
    let insights: [HealthInsight]

    /// Get insights sorted by priority (critical first)
    var sortedByPriority: [HealthInsight] {
        insights.sorted { $0.priority > $1.priority }
    }

    /// Get insights of specific type
    func insights(ofType type: InsightType) -> [HealthInsight] {
        insights.filter { $0.type == type }
    }

    /// Get insights with priority >= threshold
    func insights(withPriority minPriority: InsightPriority) -> [HealthInsight] {
        insights.filter { $0.priority >= minPriority }
    }

    /// Get top N insights by priority
    func topInsights(count: Int) -> [HealthInsight] {
        Array(sortedByPriority.prefix(count))
    }

    /// Check if collection has insights of specific type
    func hasInsight(ofType type: InsightType) -> Bool {
        insights.contains { $0.type == type }
    }

    /// Count insights by priority
    func count(forPriority priority: InsightPriority) -> Int {
        insights.filter { $0.priority == priority }.count
    }
}

// MARK: - Recommendation

/// Actionable recommendation (specific advice for user)
/// **Industry Pattern:** Levels food recommendations, Whoop recovery actions
struct Recommendation: Identifiable {
    let id: UUID
    let action: String              // What to do (e.g., "Increase fasting window to 18 hours")
    let reason: String              // Why to do it (e.g., "You lost more weight on weeks with longer fasts")
    let impact: RecommendationImpact  // Expected impact
    let confidence: Double          // 0.0-1.0 confidence in recommendation

    init(
        id: UUID = UUID(),
        action: String,
        reason: String,
        impact: RecommendationImpact,
        confidence: Double
    ) {
        self.id = id
        self.action = action
        self.reason = reason
        self.impact = impact
        self.confidence = confidence
    }
}

// MARK: - Recommendation Impact

/// Expected impact of recommendation
enum RecommendationImpact: String, Codable {
    case high       // Significant impact (1-2 lbs/week improvement)
    case medium     // Moderate impact (0.5-1 lbs/week improvement)
    case low        // Small impact (0.25-0.5 lbs/week improvement)

    /// Display name for UI
    var displayName: String {
        switch self {
        case .high: return "High Impact"
        case .medium: return "Medium Impact"
        case .low: return "Low Impact"
        }
    }

    /// Icon for UI
    var icon: String {
        switch self {
        case .high: return "arrow.up.circle.fill"
        case .medium: return "arrow.right.circle.fill"
        case .low: return "arrow.up.right.circle.fill"
        }
    }

    /// Color token for UI
    var colorToken: String {
        switch self {
        case .high: return "accentTeal"
        case .medium: return "moodStableEnd"
        case .low: return "textSecondary"
        }
    }
}

// MARK: - Sample Data (Testing/Previews)

#if DEBUG
extension HealthInsight {
    static let samples: [HealthInsight] = [
        HealthInsight(
            type: .goalProgress,
            priority: .high,
            title: "10.2 lbs to Goal",
            message: "You're 10.2 lbs away from your 170 lb goal. At your current rate, you'll reach it in 14 weeks.",
            value: 10.2,
            metadata: ["goalWeight": "170.0", "currentWeight": "180.2", "eta": "14 weeks"]
        ),
        HealthInsight(
            type: .weightFastingCorrelation,
            priority: .high,
            title: "Fasting Impact",
            message: "Weeks with 5+ fasts averaged 1.8 lbs lost, vs 0.4 lbs on weeks with <3 fasts.",
            value: 1.8,
            metadata: ["highFastWeeks": "1.8", "lowFastWeeks": "0.4"]
        ),
        HealthInsight(
            type: .weekOverWeek,
            priority: .medium,
            title: "Weekly Progress",
            message: "You're up 0.4 lbs from last week. You completed 3 fasts this week, down from 5 last week.",
            value: 0.4,
            metadata: ["thisWeek": "180.2", "lastWeek": "179.8", "fastsThisWeek": "3", "fastsLastWeek": "5"]
        ),
        HealthInsight(
            type: .actionable,
            priority: .critical,
            title: "Increase Frequency",
            message: "Try adding 2 more fasts this week. Your data shows 5+ fasts/week leads to 4x better results.",
            value: 5.0,
            metadata: ["targetFasts": "5", "currentFasts": "3"]
        ),
        HealthInsight(
            type: .celebration,
            priority: .high,
            title: "Milestone Reached!",
            message: "You've completed 50 fasts total! That's incredible dedication. Keep it up!",
            value: 50.0,
            metadata: ["milestone": "50"]
        )
    ]
}

extension Recommendation {
    static let samples: [Recommendation] = [
        Recommendation(
            action: "Increase fasting frequency to 5 times per week",
            reason: "You lost 1.8 lbs/week on weeks with 5+ fasts vs 0.4 lbs on weeks with <3 fasts",
            impact: .high,
            confidence: 0.85
        ),
        Recommendation(
            action: "Extend fasting window to 18 hours",
            reason: "Your longest fasts (18+ hours) correlated with 2x better weekly progress",
            impact: .medium,
            confidence: 0.72
        ),
        Recommendation(
            action: "Maintain your current streak",
            reason: "Your 7-day streak is associated with consistent 1.2 lbs/week loss",
            impact: .medium,
            confidence: 0.68
        )
    ]
}
#endif

// MARK: - Rich Health Context (Phase 8.1)

/// Comprehensive health data context for AInstein LLM intelligence
/// **Purpose:** Fix "not enough data" bug by sending 10x more context to GPT-4o-mini
/// **Industry Pattern:** WHOOP Coach sends ALL metrics (Sleep, Strain, HRV, Stress, Recovery)
/// **Replaces:** InsightContext (Phase 3) which only sent 8 data points
struct RichHealthContext {
    // MARK: - Current Metrics
    let currentWeight: Double?
    let currentFastingStatus: String?
    let todayHydration: Double?
    let todayMood: Int?
    let lastNightSleep: Double?

    // MARK: - 7-Day Trends
    let weightChange7d: Double?
    let fastingCount7d: Int?
    let avgSleep7d: Double?
    let avgHydration7d: Double?
    let avgMood7d: Double?
    let avgEnergy7d: Double?

    // MARK: - 30-Day Trends
    let weightChange30d: Double?
    let fastingCount30d: Int?
    let avgFastDuration30d: Double?
    let avgSleep30d: Double?
    let avgHydration30d: Double?
    let avgMood30d: Double?
    let avgEnergy30d: Double?

    // MARK: - 90-Day Trends
    let weightChange90d: Double?
    let fastingCount90d: Int?
    let avgFastDuration90d: Double?
    let avgSleep90d: Double?
    let avgWeightLossRate90d: Double?

    // MARK: - Goals & Progress
    let weightGoal: Double?
    let startWeight: Double?
    let totalWeightLost: Double?
    let daysInJourney: Int?
    let progressPercent: Double?
    let estimatedDaysToGoal: Int?
    let onTrackStatus: String?

    // MARK: - Streaks & Milestones
    let currentFastingStreak: Int?
    let longestFastingStreak: Int?
    let totalFastsCompleted: Int?
    let milestones: [String]?

    // MARK: - Correlations
    let weeksWith5PlusFasts_AvgWeightLoss: Double?
    let weeksWith3OrLessFasts_AvgWeightLoss: Double?
    let bestWeek_Date: String?
    let bestWeek_FastingCount: Int?
    let bestWeek_WeightLoss: Double?
    let worstWeek_Date: String?
    let worstWeek_FastingCount: Int?
    let worstWeek_WeightChange: Double?
    let avgWeightLoss_WellRested: Double?
    let avgWeightLoss_PoorlySleep: Double?
    let avgWeightLoss_HighHydration: Double?
    let avgWeightLoss_LowHydration: Double?

    // MARK: - Historical Patterns
    let avgWeightLossRate: Double?
    let mostCommonFastDuration: String?
    let mostProductiveDayOfWeek: String?
    let totalWeightEntries: Int?
    let totalSleepEntries: Int?
    let totalHydrationEntries: Int?
    let totalMoodEntries: Int?
}
