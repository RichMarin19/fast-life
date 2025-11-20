//
// HealthDataAggregator.swift
// FastingTracker
//
// Created for LifeGPT Feature - Phase 1
// Unified data access protocol for Fast LIFe + HealthKit data
//

import Foundation

// MARK: - Protocol Definition

/// Protocol for unified health data access across Fast LIFe and HealthKit
/// Following Fast LIFe's protocol-based architecture pattern (HealthKitManagerProtocol)
/// Enables dependency injection and mocking for tests
protocol HealthDataAggregator {

    // MARK: - Weight Data

    /// Fetches all weight entries from Fast LIFe data
    /// Priority order: Fast LIFe data first (richer context), HealthKit fills gaps
    /// - Returns: Array of WeightEntry sorted by date (newest first)
    func fetchAllWeightData() async -> [WeightEntry]

    /// Fetches weight entries for specific date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of WeightEntry within range
    func fetchWeightData(from startDate: Date, to endDate: Date) async -> [WeightEntry]

    /// Gets current weight (most recent entry)
    /// - Returns: Latest WeightEntry or nil if no data
    func getCurrentWeight() async -> WeightEntry?

    // MARK: - Fasting Data

    /// Fetches all fasting sessions from Fast LIFe data
    /// - Returns: Array of FastingSession sorted by date (newest first)
    func fetchAllFastingSessions() async -> [FastingSession]

    /// Fetches fasting sessions for specific date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of FastingSession within range
    func fetchFastingSessions(from startDate: Date, to endDate: Date) async -> [FastingSession]

    /// Gets current active fast (if any)
    /// - Returns: Active FastingSession or nil
    func getCurrentFast() async -> FastingSession?

    // MARK: - Sleep Data

    /// Fetches all sleep entries from Fast LIFe data
    /// - Returns: Array of SleepEntry sorted by date (newest first)
    func fetchAllSleepData() async -> [SleepEntry]

    /// Fetches sleep entries for specific date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of SleepEntry within range
    func fetchSleepData(from startDate: Date, to endDate: Date) async -> [SleepEntry]

    /// Gets last night's sleep (most recent entry)
    /// - Returns: Latest SleepEntry or nil if no data
    func getLastNightSleep() async -> SleepEntry?

    // MARK: - Hydration Data

    /// Fetches all hydration entries from Fast LIFe data
    /// - Returns: Array of (Date, Double) tuples for water intake
    func fetchAllHydrationData() async -> [(Date, Double)]

    /// Fetches hydration data for specific date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of (Date, Double) tuples within range
    func fetchHydrationData(from startDate: Date, to endDate: Date) async -> [(Date, Double)]

    /// Gets today's total hydration
    /// - Returns: Total ounces of water today
    func getTodayHydration() async -> Double

    // MARK: - Mood Data

    /// Fetches all mood entries from Fast LIFe data
    /// - Returns: Array of MoodEntry sorted by date (newest first)
    func fetchAllMoodData() async -> [MoodEntry]

    /// Fetches mood entries for specific date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of MoodEntry within range
    func fetchMoodData(from startDate: Date, to endDate: Date) async -> [MoodEntry]

    /// Gets today's mood (if logged)
    /// - Returns: Today's MoodEntry or nil
    func getTodayMood() async -> MoodEntry?

    // MARK: - Summary Data

    /// Gets comprehensive health summary for today
    /// - Returns: Dictionary with all available today's data
    func getTodaySummary() async -> [String: Any]

    /// Gets comprehensive health summary for specific date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Dictionary with aggregated data
    func getSummary(from startDate: Date, to endDate: Date) async -> [String: Any]

    // MARK: - Rich Health Context (Phase 8.1)

    /// Build comprehensive RichHealthContext for AInstein LLM intelligence
    /// **Phase 8.1:** Aggregates 70+ metrics across all timeframes
    /// **Industry Pattern:** WHOOP Coach comprehensive summaries + recent patterns
    /// - Returns: RichHealthContext with current state, trends, correlations, history
    func buildRichHealthContext() async -> RichHealthContext
}

// MARK: - Default Implementations (Convenience)

extension HealthDataAggregator {

    /// Convenience method: Fetch last 7 days of weight data
    func fetchWeightLastWeek() async -> [WeightEntry] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        return await fetchWeightData(from: startDate, to: endDate)
    }

    /// Convenience method: Fetch last 30 days of weight data
    func fetchWeightLastMonth() async -> [WeightEntry] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        return await fetchWeightData(from: startDate, to: endDate)
    }

    /// Convenience method: Fetch this week's fasting sessions
    func fetchFastingThisWeek() async -> [FastingSession] {
        let endDate = Date()
        let startDate = Calendar.current.startOfWeek() ?? endDate
        return await fetchFastingSessions(from: startDate, to: endDate)
    }

    /// Convenience method: Fetch this month's fasting sessions
    func fetchFastingThisMonth() async -> [FastingSession] {
        let endDate = Date()
        let startDate = Calendar.current.startOfMonth() ?? endDate
        return await fetchFastingSessions(from: startDate, to: endDate)
    }
}

// MARK: - Calendar Extensions

fileprivate extension Calendar {
    func startOfWeek() -> Date? {
        let today = Date()
        let weekday = component(.weekday, from: today)
        return date(byAdding: .day, value: -(weekday - 1), to: today)
    }

    func startOfMonth() -> Date? {
        let today = Date()
        let components = dateComponents([.year, .month], from: today)
        return date(from: components)
    }
}
