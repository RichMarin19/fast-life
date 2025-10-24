//
// QueryIntent.swift
// FastingTracker
//
// Created for LifeGPT Phase 2 Hour 1 - Query Classification
// Production-grade intent recognition with 50+ patterns
// Reference: LIFEGPT-INTELLIGENCE-LAYER-SPEC.md Section 2
//

import Foundation

// MARK: - Query Intent Types

/// Represents the user's intent parsed from natural language query
/// **Production Standard:** 95%+ recognition rate across all intent types
///
/// **Intent Categories:**
/// - Weight stats (min, max, avg, median, percentile)
/// - Weight change (lost, gained, delta, rate)
/// - Fasting stats (count, longest, streak, completion rate)
/// - Fasting protocols (16:8, OMAD, ADF detection)
/// - Sleep stats (quality, duration, consistency)
/// - Comparative analytics (this vs last period, YoY)
/// - Trend queries (trending up/down, rate of change)
/// - Goal tracking (progress, ETA, on-track status)
enum QueryIntent: Equatable, Hashable {

    // MARK: - Weight Stats

    /// Get current weight (latest entry)
    /// Examples: "What's my weight?", "How much do I weigh?", "Current weight?"
    case currentWeight

    /// Find minimum weight recorded
    /// Examples: "What's the least I ever weighed?", "Lowest weight?"
    case minimumWeight(timeRange: TimeRange?)

    /// Find maximum weight recorded
    /// Examples: "What's the most I ever weighed?", "Highest weight?"
    case maximumWeight(timeRange: TimeRange?)

    /// Calculate average weight
    /// Examples: "What's my average weight?", "Mean weight this month?"
    case averageWeight(timeRange: TimeRange?)

    /// Calculate median weight
    /// Examples: "What's my median weight?", "Middle weight value?"
    case medianWeight(timeRange: TimeRange?)

    /// Calculate weight percentile
    /// Examples: "What percentile is 180 lbs?", "Where does 175 rank?"
    case weightPercentile(value: Double, timeRange: TimeRange?)

    // MARK: - Weight Change

    /// Find largest weight loss in a period
    /// Examples: "What's the most weight I lost in a month?", "Biggest weight drop?"
    case largestWeightLoss(period: TimePeriod)

    /// Find largest weight gain in a period
    /// Examples: "What's the most weight I gained?", "Biggest weight increase?"
    case largestWeightGain(period: TimePeriod)

    /// Calculate weight change over period
    /// Examples: "How much weight did I lose this month?", "Weight change this year?"
    case weightChange(period: TimePeriod)

    /// Calculate rate of weight change
    /// Examples: "How fast am I losing weight?", "What's my weight loss rate?"
    case weightChangeRate(period: TimePeriod)

    /// Calculate weight delta between two dates
    /// Examples: "Weight difference between Jan 1 and today?"
    case weightDelta(startDate: Date, endDate: Date)

    // MARK: - Fasting Stats

    /// Count fasts in period
    /// Examples: "How many fasts this week?", "Number of fasts this month?"
    case fastCount(timeRange: TimeRange?)

    /// Find longest fast
    /// Examples: "What's my longest fast?", "Best fast duration?"
    case longestFast(timeRange: TimeRange?)

    /// Calculate current streak
    /// Examples: "What's my streak?", "How many days in a row?"
    case fastingStreak

    /// Calculate completion rate
    /// Examples: "What's my completion rate?", "Success percentage?"
    case completionRate(timeRange: TimeRange?)

    /// Calculate average fast duration
    /// Examples: "What's my average fast length?", "Mean fast time?"
    case averageFastDuration(timeRange: TimeRange?)

    /// Detect fasting protocol
    /// Examples: "Am I doing 16:8?", "What protocol am I following?"
    case detectProtocol(timeRange: TimeRange?)

    /// Calculate total fasting hours
    /// Examples: "Total hours fasted this month?", "How long have I fasted?"
    case totalFastingHours(timeRange: TimeRange?)

    /// Calculate fast frequency
    /// Examples: "How often do I fast?", "Fasts per week?"
    case fastFrequency(timeRange: TimeRange?)

    // MARK: - Sleep Stats

    /// Calculate average sleep duration
    /// Examples: "How much sleep do I get?", "Average sleep time?"
    case averageSleep(timeRange: TimeRange?)

    /// Calculate sleep quality score
    /// Examples: "How's my sleep quality?", "Sleep score?"
    case sleepQuality(timeRange: TimeRange?)

    /// Analyze sleep consistency
    /// Examples: "Is my sleep consistent?", "Sleep schedule regularity?"
    case sleepConsistency(timeRange: TimeRange?)

    // MARK: - Comparative Analytics

    /// Compare this period to last period
    /// Examples: "This week vs last week?", "Compare this month to last?"
    case compareToLast(metric: MetricType, period: TimePeriod)

    /// Year-over-year comparison
    /// Examples: "This year vs last year?", "YoY comparison?"
    case yearOverYear(metric: MetricType)

    /// Month-over-month comparison
    /// Examples: "This month vs last month?", "MoM change?"
    case monthOverMonth(metric: MetricType)

    /// Week-over-week comparison
    /// Examples: "This week vs last week?", "WoW comparison?"
    case weekOverWeek(metric: MetricType)

    // MARK: - Trend Queries

    /// Detect weight trend (up/down/stable)
    /// Examples: "Am I trending up?", "Weight direction?"
    case weightTrend(timeRange: TimeRange?)

    /// Calculate moving average
    /// Examples: "7-day average weight?", "Moving average?"
    case movingAverage(metric: MetricType, days: Int)

    /// Predict goal completion
    /// Examples: "When will I reach 170 lbs?", "ETA to goal?"
    case goalETA(targetValue: Double, metric: MetricType)

    /// Check if on track to goal
    /// Examples: "Am I on track?", "Will I hit my goal?"
    case onTrackToGoal(targetValue: Double, targetDate: Date, metric: MetricType)

    /// Calculate rate of change
    /// Examples: "How fast is my weight changing?", "Rate of progress?"
    case rateOfChange(metric: MetricType, timeRange: TimeRange?)

    // MARK: - Goal Tracking

    /// Calculate progress to goal
    /// Examples: "How much progress to goal?", "Percentage complete?"
    case goalProgress(targetValue: Double, metric: MetricType)

    /// Check goal status
    /// Examples: "Did I hit my goal?", "Goal achieved?"
    case goalStatus(targetValue: Double, metric: MetricType)

    /// Calculate remaining to goal
    /// Examples: "How much left to goal?", "Pounds remaining?"
    case remainingToGoal(targetValue: Double, metric: MetricType)

    // MARK: - General Queries

    /// Current stats summary
    /// Examples: "Today's summary", "My stats", "How am I doing?"
    case currentStats

    /// Recent activity summary
    /// Examples: "Recent activity", "What's been happening?"
    case recentActivity(days: Int)

    /// Unknown intent (fallback to LLM)
    /// Examples: Complex queries, conversational questions
    case unknown(query: String)

    // MARK: - Intent Properties

    /// Whether this intent can be handled offline (without LLM)
    var isOfflineCapable: Bool {
        switch self {
        case .unknown:
            return false
        default:
            return true
        }
    }

    /// Estimated complexity (used for performance tracking)
    var complexity: QueryComplexity {
        switch self {
        case .currentStats, .fastingStreak, .goalStatus:
            return .simple
        case .weightTrend, .compareToLast, .goalProgress:
            return .moderate
        case .goalETA, .onTrackToGoal, .detectProtocol:
            return .complex
        default:
            return .moderate
        }
    }
}

// MARK: - Supporting Types

/// Time range for queries
enum TimeRange: Equatable, Hashable {
    case today
    case yesterday
    case thisWeek
    case lastWeek
    case thisMonth
    case lastMonth
    case thisYear
    case lastYear
    case last7Days
    case last30Days
    case last90Days
    case allTime
    case custom(startDate: Date, endDate: Date)

    /// Convert to date range
    func toDateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now)

        case .yesterday:
            let start = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
            let end = calendar.startOfDay(for: now)
            return (start, end)

        case .thisWeek:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return (start, now)

        case .lastWeek:
            let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let start = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart)!
            return (start, thisWeekStart)

        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return (start, now)

        case .lastMonth:
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
            return (start, thisMonthStart)

        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return (start, now)

        case .lastYear:
            let thisYearStart = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let start = calendar.date(byAdding: .year, value: -1, to: thisYearStart)!
            return (start, thisYearStart)

        case .last7Days:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            return (start, now)

        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -30, to: now)!
            return (start, now)

        case .last90Days:
            let start = calendar.date(byAdding: .day, value: -90, to: now)!
            return (start, now)

        case .allTime:
            // Use a date far in the past (10 years ago)
            let start = calendar.date(byAdding: .year, value: -10, to: now)!
            return (start, now)

        case .custom(let startDate, let endDate):
            return (startDate, endDate)
        }
    }
}

/// Time period for change calculations
enum TimePeriod: Equatable, Hashable {
    case day
    case week
    case month
    case year
    case custom(days: Int)

    /// Number of days in period
    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .year: return 365
        case .custom(let days): return days
        }
    }
}

/// Metric type for comparisons
enum MetricType: String, Equatable, Hashable {
    case weight
    case fasting
    case sleep
    case steps
    case heartRate
    case calories
}

/// Query complexity level
enum QueryComplexity {
    case simple      // <50ms expected
    case moderate    // <100ms expected
    case complex     // <500ms expected
}
