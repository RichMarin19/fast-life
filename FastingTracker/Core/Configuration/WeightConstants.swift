//
// WeightConstants.swift
// FastLIFe
//
// Created for Weight Tracking & HealthKit Sync
// Single source of truth for weight-related constants, thresholds, and timing values
// Reference: SESSION-PREFERENCES.md - Always use tokens for centralized constants
//

import Foundation

/// Weight tracking constants for sync, deduplication, and statistics
/// **Single Source of Truth:** All weight-related constants centralized here
/// **Industry Pattern:** Apple HealthKit best practices for duplicate detection and sync timing
enum WeightConstants {

    // MARK: - Sync Timing

    enum SyncTiming {
        /// Delay after manual entry before re-enabling HealthKit observer
        /// **Purpose:** Prevent duplicate sync when manually adding entry that syncs to HealthKit
        /// **Industry Standard:** MyFitnessPal, Spotify use temporary suppression during bidirectional sync
        static let observerSuppressionDelay: TimeInterval = 2.0  // 2 seconds

        /// Default lookback period for historical sync operations
        /// **Purpose:** Comprehensive sync covers 10 years of historical data
        /// **Industry Standard:** Apple Health shows 10 years of data history
        static let defaultHistoricalLookbackYears: Int = 10
    }

    // MARK: - Duplication Thresholds

    enum DuplicationThreshold {
        /// Time window for duplicate detection during manual entry
        /// **Purpose:** Prevent duplicate entries within 30 minutes
        /// **Rationale:** Users typically weigh once in morning, multiple entries within 30min are likely duplicates
        static let timeInterval: TimeInterval = 1800.0  // 30 minutes

        /// Weight difference threshold for duplicate detection
        /// **Purpose:** Entries within 0.1 lbs are considered duplicates
        /// **Rationale:** Scale accuracy is typically ±0.1 lbs (±0.05 kg)
        static let weightDelta: Double = 0.1  // 0.1 lbs

        /// Tight time window for HealthKit sync duplicate detection
        /// **Purpose:** More precise duplicate detection for sync operations
        /// **Industry Standard:** Apple HealthKit samples timestamped to the second
        static let tightTimeInterval: TimeInterval = 60.0  // 1 minute

        /// Flexible time window for historical import duplicate detection
        /// **Purpose:** Account for timestamp rounding in historical data
        /// **Rationale:** Legacy data may have rounded timestamps
        static let historicalTimeInterval: TimeInterval = 300.0  // 5 minutes

        /// Weight difference threshold for historical import
        /// **Purpose:** More flexible threshold for historical data
        /// **Rationale:** Account for unit conversion rounding (lbs ↔ kg)
        static let historicalWeightDelta: Double = 0.2  // 0.2 lbs (≈0.09 kg)
    }

    // MARK: - Statistics

    enum Statistics {
        /// Minimum entries required to calculate meaningful weight trend
        /// **Purpose:** Need sufficient data points for trend analysis
        /// **Industry Standard:** 7 data points (1 week) for basic trend detection
        static let minimumEntriesForTrend: Int = 7
    }
}
