//
// UnifiedHealthDataService.swift
// FastingTracker
//
// Created for LifeGPT Feature - Phase 1
// Implementation of unified health data access (Fast LIFe + HealthKit)
//

import Foundation

// MARK: - Unified Health Data Service

/// Implementation of HealthDataAggregator that merges Fast LIFe and HealthKit data
/// Phase 1: Fast LIFe data only (simple, fast, works for all users)
/// Phase 2: Add HealthKit data merge for users with sync enabled
/// Following Fast LIFe's protocol-based dependency injection pattern
class UnifiedHealthDataService: HealthDataAggregator {

    // MARK: - Dependencies

    private let weightManager: WeightManager
    private let fastingManager: FastingManager
    private let sleepManager: SleepManager
    private let hydrationManager: HydrationManager
    private let moodManager: MoodManager

    // MARK: - Initialization

    /// Initialize with manager dependencies (dependency injection)
    /// Following Fast LIFe's pattern from WeightTrackingViewModel, WeightControlCenterViewModel
    /// - Parameters:
    ///   - weightManager: Weight data source
    ///   - fastingManager: Fasting data source
    ///   - sleepManager: Sleep data source
    ///   - hydrationManager: Hydration data source
    ///   - moodManager: Mood data source
    init(
        weightManager: WeightManager,
        fastingManager: FastingManager,
        sleepManager: SleepManager,
        hydrationManager: HydrationManager,
        moodManager: MoodManager
    ) {
        self.weightManager = weightManager
        self.fastingManager = fastingManager
        self.sleepManager = sleepManager
        self.hydrationManager = hydrationManager
        self.moodManager = moodManager
    }

    // MARK: - Weight Data

    func fetchAllWeightData() async -> [WeightEntry] {
        // Phase 1: Fast LIFe data only
        // Phase 2: Merge with HealthKit data, deduplicate
        return await MainActor.run {
            weightManager.weightEntries
        }
    }

    func fetchWeightData(from startDate: Date, to endDate: Date) async -> [WeightEntry] {
        return await MainActor.run {
            weightManager.weightEntries.filter { entry in
                entry.date >= startDate && entry.date <= endDate
            }
        }
    }

    func getCurrentWeight() async -> WeightEntry? {
        return await MainActor.run {
            weightManager.weightEntries.first
        }
    }

    // MARK: - Fasting Data

    func fetchAllFastingSessions() async -> [FastingSession] {
        // Phase 1: Fast LIFe data only
        return await MainActor.run {
            fastingManager.fastingHistory
        }
    }

    func fetchFastingSessions(from startDate: Date, to endDate: Date) async -> [FastingSession] {
        return await MainActor.run {
            fastingManager.fastingHistory.filter { session in
                session.startTime >= startDate && session.startTime <= endDate
            }
        }
    }

    func getCurrentFast() async -> FastingSession? {
        return await MainActor.run {
            fastingManager.currentSession
        }
    }

    // MARK: - Sleep Data

    func fetchAllSleepData() async -> [SleepEntry] {
        // Phase 1: Fast LIFe data only
        return await MainActor.run {
            sleepManager.sleepEntries
        }
    }

    func fetchSleepData(from startDate: Date, to endDate: Date) async -> [SleepEntry] {
        return await MainActor.run {
            sleepManager.sleepEntries.filter { entry in
                entry.bedTime >= startDate && entry.bedTime <= endDate
            }
        }
    }

    func getLastNightSleep() async -> SleepEntry? {
        return await MainActor.run {
            sleepManager.sleepEntries.first
        }
    }

    // MARK: - Hydration Data

    func fetchAllHydrationData() async -> [(Date, Double)] {
        // Phase 1: Fast LIFe data only
        // Convert DrinkEntry to (Date, Double) format
        return await MainActor.run {
            hydrationManager.drinkEntries.map { entry in
                (entry.date, entry.amount)
            }
        }
    }

    func fetchHydrationData(from startDate: Date, to endDate: Date) async -> [(Date, Double)] {
        return await MainActor.run {
            hydrationManager.drinkEntries
                .filter { entry in
                    entry.date >= startDate && entry.date <= endDate
                }
                .map { ($0.date, $0.amount) }
        }
    }

    func getTodayHydration() async -> Double {
        return await MainActor.run {
            hydrationManager.todaysTotalOunces()
        }
    }

    // MARK: - Mood Data

    func fetchAllMoodData() async -> [MoodEntry] {
        // Phase 1: Fast LIFe data only
        return await MainActor.run {
            moodManager.moodEntries
        }
    }

    func fetchMoodData(from startDate: Date, to endDate: Date) async -> [MoodEntry] {
        return await MainActor.run {
            moodManager.moodEntries.filter { entry in
                entry.date >= startDate && entry.date <= endDate
            }
        }
    }

    func getTodayMood() async -> MoodEntry? {
        return await MainActor.run {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()

            return moodManager.moodEntries.first { entry in
                entry.date >= today && entry.date < tomorrow
            }
        }
    }

    // MARK: - Summary Data

    func getTodaySummary() async -> [String: Any] {
        var summary: [String: Any] = [:]

        // Weight
        if let currentWeight = await getCurrentWeight() {
            summary["weight"] = currentWeight.weight
            summary["weightDate"] = currentWeight.date
        }

        // Fasting
        if let currentFast = await getCurrentFast() {
            summary["fastingActive"] = true
            summary["fastingDuration"] = currentFast.duration
            // Calculate elapsed time manually
            let elapsedTime = Date().timeIntervalSince(currentFast.startTime)
            summary["fastingElapsed"] = elapsedTime
        } else {
            summary["fastingActive"] = false
        }

        // Hydration
        let todayHydration = await getTodayHydration()
        summary["hydration"] = todayHydration

        // Mood
        if let todayMood = await getTodayMood() {
            summary["mood"] = todayMood.moodLevel
            summary["energy"] = todayMood.energyLevel
        }

        // Sleep (last night)
        if let lastNightSleep = await getLastNightSleep() {
            summary["sleepDuration"] = lastNightSleep.duration
            summary["bedTime"] = lastNightSleep.bedTime
            summary["wakeTime"] = lastNightSleep.wakeTime
        }

        return summary
    }

    func getSummary(from startDate: Date, to endDate: Date) async -> [String: Any] {
        var summary: [String: Any] = [:]

        // Weight
        let weightData = await fetchWeightData(from: startDate, to: endDate)
        summary["weightEntries"] = weightData.count
        if let avgWeight = weightData.map({ $0.weight }).average() {
            summary["avgWeight"] = avgWeight
        }
        if let firstWeight = weightData.last?.weight,
           let lastWeight = weightData.first?.weight {
            summary["weightChange"] = lastWeight - firstWeight
        }

        // Fasting
        let fastingSessions = await fetchFastingSessions(from: startDate, to: endDate)
        summary["fastingCount"] = fastingSessions.count
        if let avgDuration = fastingSessions.map({ $0.duration }).average() {
            summary["avgFastDuration"] = avgDuration / 3600 // Convert to hours
        }

        // Sleep
        let sleepData = await fetchSleepData(from: startDate, to: endDate)
        summary["sleepNights"] = sleepData.count
        if let avgSleep = sleepData.map({ $0.duration }).average() {
            summary["avgSleepDuration"] = avgSleep / 3600 // Convert to hours
        }

        // Hydration
        let hydrationData = await fetchHydrationData(from: startDate, to: endDate)
        let totalHydration = hydrationData.map({ $0.1 }).reduce(0, +)
        summary["totalHydration"] = totalHydration

        // Mood
        let moodData = await fetchMoodData(from: startDate, to: endDate)
        summary["moodEntries"] = moodData.count
        if let avgMood = moodData.map({ Double($0.moodLevel) }).average() {
            summary["avgMood"] = avgMood
        }

        return summary
    }
}

// MARK: - Array Extension for Average

fileprivate extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
