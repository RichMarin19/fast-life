import Foundation

/// Weight Tracker Constants
/// Centralizes all magic numbers for maintainability and consistency
/// Following industry best practice: Single source of truth for configuration values
///
/// Reference: Phase 8.9 Weight Tracker Refactoring (Issues #9-13)
/// Updated: October 28, 2025

// MARK: - Weight Constants

enum WeightConstants {

    // MARK: - Duplicate Detection Thresholds

    /// Time interval thresholds for detecting duplicate weight entries
    /// Different tolerances used for different sync scenarios
    enum DuplicationThreshold {
        /// Standard time window for duplicate detection (30 minutes)
        /// Used in: WeightManager.addWeightEntryInPreferredUnit(), wouldCreateDuplicate()
        /// Rationale: Two weight entries within 30 minutes are likely duplicates
        static let timeInterval: TimeInterval = 1800 // 30 minutes

        /// Historical sync time tolerance (5 minutes)
        /// Used in: WeightManager.syncFromHealthKitHistorical()
        /// Rationale: Tighter tolerance for historical data to reduce false positives
        static let historicalTimeInterval: TimeInterval = 300 // 5 minutes

        /// Tight time tolerance for sync operations (1 minute)
        /// Used in: WeightManager.syncFromHealthKit(), syncFromHealthKitWithReset()
        /// Rationale: Very precise matching for real-time sync operations
        static let tightTimeInterval: TimeInterval = 60 // 1 minute

        /// Weight delta tolerance for duplicate detection (±0.1 lbs)
        /// Used in: All duplicate detection logic
        /// Rationale: Weights within 0.1 lbs are considered the same reading
        static let weightDelta: Double = 0.1 // ±0.1 lbs

        /// Historical weight delta tolerance (±0.2 lbs)
        /// Used in: Historical sync operations
        /// Rationale: Slightly larger tolerance for older data (rounding differences)
        static let historicalWeightDelta: Double = 0.2 // ±0.2 lbs
    }

    // MARK: - Sync Timing

    /// Timing constants for HealthKit sync operations
    enum SyncTiming {
        /// Delay before suppressing HealthKit observer callbacks (2 seconds)
        /// Used in: WeightManager weight entry operations
        /// Rationale: Prevents duplicate callbacks immediately after manual entry
        static let observerSuppressionDelay: TimeInterval = 2.0

        /// Default lookback period for historical sync (10 years)
        /// Used in: WeightManager.syncFromHealthKitHistorical()
        /// Rationale: Covers typical weight tracking history for most users
        static let defaultHistoricalLookbackYears: Int = 10
    }

    // MARK: - Statistics

    /// Constants for weight statistics calculations
    enum Statistics {
        /// Minimum number of entries required for trend calculation (2 entries)
        /// Used in: WeightManager statistics calculations
        /// Rationale: Need at least 2 points to calculate a trend
        static let minimumEntriesForTrend: Int = 2

        /// Streak padding (2 days)
        /// Used in: WeightManager streak calculations
        /// Rationale: Allow small gaps in tracking without breaking streaks
        static let streakPaddingDays: Int = 2
    }

    // MARK: - Trend Thresholds

    /// Thresholds for weight trend classification
    /// Used in: UI components to determine trend state (improving/flat/regressing)
    enum TrendThresholds {
        /// Threshold for "improving" trend (losing weight) -0.2 lbs
        /// Weight change below this is considered improvement
        static let improvingThreshold: Double = -0.2

        /// Threshold for "regressing" trend (gaining weight) +0.2 lbs
        /// Weight change above this is considered regression
        static let regressingThreshold: Double = 0.2

        // Note: Values between improving and regressing are considered "flat"
    }

    // MARK: - Goal Settings

    /// Constants for weight goal configuration
    enum Goal {
        /// Default goal padding for chart display (5 lbs)
        /// Used in: Chart Y-axis calculations when goal line is shown
        /// Rationale: Provides visual buffer above/below goal line
        static let defaultChartPadding: Double = 5.0

        /// Small goal padding (5 lbs)
        /// Used in: Compact chart views
        static let smallPadding: Double = 5.0

        /// Medium goal padding (10 lbs)
        /// Used in: Standard chart views with wider ranges
        static let mediumPadding: Double = 10.0
    }
}
