//
// UnifiedHealthDataService.swift
// FastingTracker
//
// Created for LifeGPT Feature - Phase 1
// Implementation of unified health data access (Fast LIFe + HealthKit)
//

import Foundation
import os.log

// MARK: - Unified Health Data Service

/// Implementation of HealthDataAggregator that merges Fast LIFe and HealthKit data
/// Phase 1: Fast LIFe data only (simple, fast, works for all users)
/// Phase 2: Add HealthKit data merge for users with sync enabled
/// Following Fast LIFe's protocol-based dependency injection pattern
@MainActor
class UnifiedHealthDataService: HealthDataAggregator {

    // MARK: - Dependencies

    private let weightManager: WeightManager
    private let fastingManager: FastingManager
    private let sleepManager: SleepManager
    private let hydrationManager: HydrationManager
    private let moodManager: MoodManager

    // MARK: - Logging

    private let logger = Logger(subsystem: "com.fastlife.FastingTracker", category: "UnifiedHealthDataService")

    // MARK: - Single Source of Truth for Goal Weight

    /// Read goal weight from UserDefaults (Single Source of Truth)
    /// **Key:** "goalWeight" (matches WeightTrackingViewModel, OnboardingView)
    /// **Fallback:** 170.0 if not set
    private func getGoalWeight() -> Double {
        let goalWeight = UserDefaults.standard.double(forKey: "goalWeight")
        // UserDefaults returns 0.0 if key doesn't exist, so check for that
        return goalWeight > 0 ? goalWeight : 170.0
    }

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
        return weightManager.weightEntries
    }

    func fetchWeightData(from startDate: Date, to endDate: Date) async -> [WeightEntry] {
        return weightManager.weightEntries.filter { entry in
            entry.date >= startDate && entry.date <= endDate
        }
    }

    func getCurrentWeight() async -> WeightEntry? {
        return weightManager.weightEntries.first
    }

    // MARK: - Fasting Data

    func fetchAllFastingSessions() async -> [FastingSession] {
        // Phase 1: Fast LIFe data only
        return fastingManager.fastingHistory
    }

    func fetchFastingSessions(from startDate: Date, to endDate: Date) async -> [FastingSession] {
        return fastingManager.fastingHistory.filter { session in
            session.startTime >= startDate && session.startTime <= endDate
        }
    }

    func getCurrentFast() async -> FastingSession? {
        return fastingManager.currentSession
    }

    // MARK: - Sleep Data

    func fetchAllSleepData() async -> [SleepEntry] {
        // Phase 1: Fast LIFe data only
        return sleepManager.sleepEntries
    }

    func fetchSleepData(from startDate: Date, to endDate: Date) async -> [SleepEntry] {
        return sleepManager.sleepEntries.filter { entry in
            entry.bedTime >= startDate && entry.bedTime <= endDate
        }
    }

    func getLastNightSleep() async -> SleepEntry? {
        return sleepManager.sleepEntries.first
    }

    // MARK: - Hydration Data

    func fetchAllHydrationData() async -> [(Date, Double)] {
        // Phase 1: Fast LIFe data only
        // Convert DrinkEntry to (Date, Double) format
        return hydrationManager.drinkEntries.map { entry in
            (entry.date, entry.amount)
        }
    }

    func fetchHydrationData(from startDate: Date, to endDate: Date) async -> [(Date, Double)] {
        return hydrationManager.drinkEntries
            .filter { entry in
                entry.date >= startDate && entry.date <= endDate
            }
            .map { ($0.date, $0.amount) }
    }

    func getTodayHydration() async -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()

        return hydrationManager.drinkEntries
            .filter { entry in
                entry.date >= today && entry.date < tomorrow
            }
            .reduce(0.0) { $0 + $1.amount }
    }

    // MARK: - Mood Data

    func fetchAllMoodData() async -> [MoodEntry] {
        // Phase 1: Fast LIFe data only
        return moodManager.moodEntries
    }

    func fetchMoodData(from startDate: Date, to endDate: Date) async -> [MoodEntry] {
        return moodManager.moodEntries.filter { entry in
            entry.date >= startDate && entry.date <= endDate
        }
    }

    func getTodayMood() async -> MoodEntry? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()

        return moodManager.moodEntries.first { entry in
            entry.date >= today && entry.date < tomorrow
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
            // Calculate elapsed time for active fast (endTime is nil for active fasts)
            let elapsed = Date().timeIntervalSince(currentFast.startTime)
            summary["fastingElapsed"] = elapsed
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

    // MARK: - Rich Health Context (Phase 8.1)

    /// Build comprehensive health context for AInstein LLM intelligence
    /// **Industry Pattern:** WHOOP Coach comprehensive summaries + recent patterns
    /// **Speed:** Pre-calculates correlations for 2-2.5s response time
    func buildRichHealthContext() async -> RichHealthContext {
        logger.info("🏗️ ===== BUILDING RICHHEALTHCONTEXT START =====")

        let calendar = Calendar.current
        let now = Date()

        // MARK: - Date Ranges
        let today = calendar.startOfDay(for: now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: today) ?? today

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        logger.info("📅 Date ranges: 7d=\(dateFormatter.string(from: sevenDaysAgo)), 30d=\(dateFormatter.string(from: thirtyDaysAgo)), 90d=\(dateFormatter.string(from: ninetyDaysAgo))")

        // MARK: - Current State
        logger.info("📊 Fetching current state...")
        let currentWeight = await getCurrentWeight()?.weight
        let currentFast = await getCurrentFast()
        let currentFastingStatus: String? = {
            if let fast = currentFast {
                let elapsed = Date().timeIntervalSince(fast.startTime)
                let hours = Int(elapsed / 3600)
                return "Active (\(hours)h elapsed)"
            }
            return nil
        }()
        let todayHydration = await getTodayHydration()
        let todayMood = await getTodayMood()
        let lastNightSleep = await getLastNightSleep()
        let weightAvailable = currentWeight != nil
        let fastingStatus = currentFastingStatus != nil ? "active" : "none"
        let hydrationLogged = todayHydration > 0
        let weightFlag = weightAvailable ? "yes" : "no"
        let hydrationFlag = hydrationLogged ? "yes" : "no"
        let snapshotSummary = "weightAvailable=\(weightFlag), fastingStatus=\(fastingStatus), hydrationLogged=\(hydrationFlag)"
        logger.info("✅ Current state snapshot ready — \(snapshotSummary, privacy: .private)")

        // MARK: - 7-Day Trends
        logger.info("📈 Fetching 7-day trends...")
        let weight7d = await fetchWeightData(from: sevenDaysAgo, to: now)
        let fasting7d = await fetchFastingSessions(from: sevenDaysAgo, to: now)
        let sleep7d = await fetchSleepData(from: sevenDaysAgo, to: now)
        let hydration7d = await fetchHydrationData(from: sevenDaysAgo, to: now)
        let mood7d = await fetchMoodData(from: sevenDaysAgo, to: now)

        logger.info("✅ 7-day data: \(weight7d.count) weights, \(fasting7d.count) fasts, \(sleep7d.count) sleep, \(hydration7d.count) hydration, \(mood7d.count) mood")

        // Debug fasting sessions
        if !fasting7d.isEmpty {
            logger.info("🔍 Last week fasting sessions:")
            for (index, fast) in fasting7d.prefix(10).enumerated() {
                logger.info("  [\(index)] \(dateFormatter.string(from: fast.startTime)) - \(Int(fast.duration/3600))h")
            }
        } else {
            logger.warning("⚠️ NO FASTING SESSIONS FOUND FOR LAST 7 DAYS")
            logger.warning("⚠️ FastingManager has \(self.fastingManager.fastingHistory.count) total sessions")
            if !self.fastingManager.fastingHistory.isEmpty {
                logger.warning("⚠️ Most recent fast: \(dateFormatter.string(from: self.fastingManager.fastingHistory.first!.startTime))")
            }
        }

        let weightChange7d: Double? = {
            guard let first = weight7d.last?.weight, let last = weight7d.first?.weight else { return nil }
            return last - first
        }()
        let avgSleep7d = sleep7d.map({ $0.duration / 3600 }).average()
        let avgHydration7d = hydration7d.map({ $0.1 }).average()
        let avgMood7d = mood7d.map({ Double($0.moodLevel) }).average()
        let avgEnergy7d = mood7d.map({ Double($0.energyLevel) }).average()

        // MARK: - 30-Day Trends
        logger.info("📈 Fetching 30-day trends...")
        let weight30d = await fetchWeightData(from: thirtyDaysAgo, to: now)
        let fasting30d = await fetchFastingSessions(from: thirtyDaysAgo, to: now)
        let sleep30d = await fetchSleepData(from: thirtyDaysAgo, to: now)
        let hydration30d = await fetchHydrationData(from: thirtyDaysAgo, to: now)
        let mood30d = await fetchMoodData(from: thirtyDaysAgo, to: now)
        logger.info("✅ 30-day data: \(weight30d.count) weights, \(fasting30d.count) fasts")

        let weightChange30d: Double? = {
            guard let first = weight30d.last?.weight, let last = weight30d.first?.weight else { return nil }
            return last - first
        }()
        let avgFastDuration30d = fasting30d.map({ $0.duration / 3600 }).average()
        let avgSleep30d = sleep30d.map({ $0.duration / 3600 }).average()
        let avgHydration30d = hydration30d.map({ $0.1 }).average()
        let avgMood30d = mood30d.map({ Double($0.moodLevel) }).average()
        let avgEnergy30d = mood30d.map({ Double($0.energyLevel) }).average()

        // MARK: - 90-Day Trends
        logger.info("📈 Fetching 90-day trends...")
        let weight90d = await fetchWeightData(from: ninetyDaysAgo, to: now)
        let fasting90d = await fetchFastingSessions(from: ninetyDaysAgo, to: now)
        let sleep90d = await fetchSleepData(from: ninetyDaysAgo, to: now)
        logger.info("✅ 90-day data: \(weight90d.count) weights, \(fasting90d.count) fasts")

        let weightChange90d: Double? = {
            guard let first = weight90d.last?.weight, let last = weight90d.first?.weight else { return nil }
            return last - first
        }()
        let avgFastDuration90d = fasting90d.map({ $0.duration / 3600 }).average()
        let avgSleep90d = sleep90d.map({ $0.duration / 3600 }).average()
        let avgWeightLossRate90d: Double? = {
            guard let change = weightChange90d else { return nil }
            return change / 90.0 * 7.0 // lbs per week
        }()

        // MARK: - Goals & Progress
        let startWeight = weight90d.last?.weight
        let totalWeightLost: Double? = {
            guard let start = startWeight, let current = currentWeight else { return nil }
            return start - current
        }()
        let daysInJourney = weight90d.count
        let goalWeight = getGoalWeight()
        let progressPercent: Double? = {
            guard let current = currentWeight, let start = startWeight else { return nil }
            let totalGoal = start - goalWeight
            let achieved = start - current
            return (achieved / totalGoal) * 100.0
        }()
        let estimatedDaysToGoal: Int? = {
            guard let rate = avgWeightLossRate90d, rate > 0 else { return nil }
            guard let current = currentWeight else { return nil }
            let remaining = current - goalWeight
            let weeksNeeded = remaining / rate
            return Int(weeksNeeded * 7)
        }()
        let onTrackStatus: String? = {
            guard let rate = avgWeightLossRate90d else { return nil }
            if rate >= 1.0 { return "On Track" }
            if rate >= 0.5 { return "Slow Progress" }
            return "Off Track"
        }()

        // MARK: - Streaks & Milestones
        let currentFastingStreak = calculateCurrentStreak(fasting: fasting90d)
        let longestFastingStreak = calculateLongestStreak(fasting: fasting90d)
        let totalFastsCompleted = fasting90d.count
        let milestones = generateMilestones(
            totalFasts: totalFastsCompleted,
            weightLost: totalWeightLost,
            longestStreak: longestFastingStreak
        )

        // MARK: - Recent History (30-Day DailySummary for LLM)
        let recentHistory = buildDailySummaries(
            from: thirtyDaysAgo,
            to: now,
            weights: weight30d,
            fasts: fasting30d,
            sleep: sleep30d,
            hydration: hydration30d,
            mood: mood30d
        )

        // MARK: - Correlations
        let weeklyCorrelations = calculateWeeklyCorrelations(
            fasts: fasting90d,
            weights: weight90d
        )

        let sleepCorrelations = calculateSleepCorrelations(
            sleep: sleep90d,
            weights: weight90d
        )

        let hydrationCorrelations = calculateHydrationCorrelations(
            hydration: hydration30d,
            weights: weight30d
        )

        // MARK: - Key Patterns
        let bestWorstWeeks = findBestWorstWeeks(fasts: fasting90d, weights: weight90d)
        let avgWeightLossRate = avgWeightLossRate90d
        let mostCommonFastDuration = findMostCommonFastDuration(fasts: fasting90d)
        let mostProductiveDayOfWeek = findMostProductiveDayOfWeek(fasts: fasting90d)

        // MARK: - Data Completeness
        logger.info("📊 Fetching all-time data completeness...")
        let allWeights = await fetchAllWeightData()
        let allSleep = await fetchAllSleepData()
        let allHydration = await fetchAllHydrationData()
        let allMood = await fetchAllMoodData()
        logger.info("✅ All-time data: \(allWeights.count) weights, \(self.sleepManager.sleepEntries.count) sleep, \(self.hydrationManager.drinkEntries.count) hydration, \(self.moodManager.moodEntries.count) mood")

        logger.info("🏗️ ===== RICHHEALTHCONTEXT COMPLETE - Returning context =====")

        return RichHealthContext(
            // Current State
            currentWeight: currentWeight,
            currentFastingStatus: currentFastingStatus,
            todayHydration: todayHydration > 0 ? todayHydration : nil,
            todayMood: todayMood?.moodLevel,
            lastNightSleep: lastNightSleep?.duration != nil ? lastNightSleep!.duration / 3600 : nil,

            // 7-Day Trends
            weightChange7d: weightChange7d,
            fastingCount7d: fasting7d.count,
            avgSleep7d: avgSleep7d,
            avgHydration7d: avgHydration7d,
            avgMood7d: avgMood7d,
            avgEnergy7d: avgEnergy7d,

            // 30-Day Trends
            weightChange30d: weightChange30d,
            fastingCount30d: fasting30d.count,
            avgFastDuration30d: avgFastDuration30d,
            avgSleep30d: avgSleep30d,
            avgHydration30d: avgHydration30d,
            avgMood30d: avgMood30d,
            avgEnergy30d: avgEnergy30d,

            // 90-Day Trends
            weightChange90d: weightChange90d,
            fastingCount90d: fasting90d.count,
            avgFastDuration90d: avgFastDuration90d,
            avgSleep90d: avgSleep90d,
            avgWeightLossRate90d: avgWeightLossRate90d,

            // Goals & Progress
            weightGoal: goalWeight,
            startWeight: startWeight,
            totalWeightLost: totalWeightLost,
            daysInJourney: daysInJourney > 0 ? daysInJourney : nil,
            progressPercent: progressPercent,
            estimatedDaysToGoal: estimatedDaysToGoal,
            onTrackStatus: onTrackStatus,

            // Streaks & Milestones
            currentFastingStreak: currentFastingStreak,
            longestFastingStreak: longestFastingStreak,
            totalFastsCompleted: totalFastsCompleted > 0 ? totalFastsCompleted : nil,
            milestones: milestones.isEmpty ? nil : milestones,

            // Recent History
            recentHistory: recentHistory.isEmpty ? nil : recentHistory,

            // Correlations
            weeksWith5PlusFasts_AvgWeightLoss: weeklyCorrelations.highFastWeeks,
            weeksWith3OrLessFasts_AvgWeightLoss: weeklyCorrelations.lowFastWeeks,
            avgWeightLoss_WellRested: sleepCorrelations.wellRested,
            avgWeightLoss_PoorlySleep: sleepCorrelations.poorlySleep,
            avgWeightLoss_HighHydration: hydrationCorrelations.highHydration,
            avgWeightLoss_LowHydration: hydrationCorrelations.lowHydration,

            // Key Patterns
            bestWeek_Date: bestWorstWeeks.bestDate,
            bestWeek_FastingCount: bestWorstWeeks.bestFastCount,
            bestWeek_WeightLoss: bestWorstWeeks.bestWeightLoss,
            worstWeek_Date: bestWorstWeeks.worstDate,
            worstWeek_FastingCount: bestWorstWeeks.worstFastCount,
            worstWeek_WeightChange: bestWorstWeeks.worstWeightChange,
            avgWeightLossRate: avgWeightLossRate,
            mostCommonFastDuration: mostCommonFastDuration,
            mostProductiveDayOfWeek: mostProductiveDayOfWeek,

            // Data Completeness
            totalWeightEntries: allWeights.count > 0 ? allWeights.count : nil,
            totalSleepEntries: allSleep.count > 0 ? allSleep.count : nil,
            totalHydrationEntries: allHydration.count > 0 ? allHydration.count : nil,
            totalMoodEntries: allMood.count > 0 ? allMood.count : nil
        )
    }

    // MARK: - Helper Methods for RichHealthContext

    private func calculateCurrentStreak(fasting: [FastingSession]) -> Int? {
        guard !fasting.isEmpty else { return nil }
        let calendar = Calendar.current
        let sortedSessions = fasting.sorted { $0.startTime > $1.startTime }

        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        for session in sortedSessions {
            let sessionDate = calendar.startOfDay(for: session.startTime)
            let daysDiff = calendar.dateComponents([.day], from: sessionDate, to: currentDate).day ?? 0

            if daysDiff <= 1 {
                streak += 1
                currentDate = sessionDate
            } else {
                break
            }
        }

        return streak > 0 ? streak : nil
    }

    private func calculateLongestStreak(fasting: [FastingSession]) -> Int? {
        guard !fasting.isEmpty else { return nil }
        let calendar = Calendar.current
        let sortedSessions = fasting.sorted { $0.startTime < $1.startTime }

        var longestStreak = 0
        var currentStreak = 1
        var previousDate = calendar.startOfDay(for: sortedSessions[0].startTime)

        for i in 1..<sortedSessions.count {
            let sessionDate = calendar.startOfDay(for: sortedSessions[i].startTime)
            let daysDiff = calendar.dateComponents([.day], from: previousDate, to: sessionDate).day ?? 0

            if daysDiff == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
            previousDate = sessionDate
        }

        return max(longestStreak, currentStreak)
    }

    private func generateMilestones(totalFasts: Int, weightLost: Double?, longestStreak: Int?) -> [String] {
        var milestones: [String] = []

        // Fasting milestones
        if totalFasts >= 100 { milestones.append("100+ Fasts Completed") }
        else if totalFasts >= 50 { milestones.append("50+ Fasts Completed") }
        else if totalFasts >= 25 { milestones.append("25+ Fasts Completed") }
        else if totalFasts >= 10 { milestones.append("10+ Fasts Completed") }

        // Weight loss milestones
        if let lost = weightLost {
            if lost >= 50 { milestones.append("50+ lbs Lost") }
            else if lost >= 25 { milestones.append("25+ lbs Lost") }
            else if lost >= 10 { milestones.append("10+ lbs Lost") }
            else if lost >= 5 { milestones.append("5+ lbs Lost") }
        }

        // Streak milestones
        if let streak = longestStreak {
            if streak >= 30 { milestones.append("30-Day Streak") }
            else if streak >= 14 { milestones.append("2-Week Streak") }
            else if streak >= 7 { milestones.append("1-Week Streak") }
        }

        return milestones
    }

    private func buildDailySummaries(
        from startDate: Date,
        to endDate: Date,
        weights: [WeightEntry],
        fasts: [FastingSession],
        sleep: [SleepEntry],
        hydration: [(Date, Double)],
        mood: [MoodEntry]
    ) -> [RichHealthContext.DailySummary] {
        let calendar = Calendar.current
        var summaries: [RichHealthContext.DailySummary] = []

        var currentDate = startDate
        while currentDate <= endDate {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate

            // Find data for this day
            let dayWeight = weights.first { calendar.isDate($0.date, inSameDayAs: currentDate) }
            let dayFasts = fasts.filter { calendar.isDate($0.startTime, inSameDayAs: currentDate) }
            let daySleep = sleep.first { calendar.isDate($0.bedTime, inSameDayAs: currentDate) }
            let dayHydration = hydration.filter { calendar.isDate($0.0, inSameDayAs: currentDate) }
            let dayMood = mood.first { calendar.isDate($0.date, inSameDayAs: currentDate) }

            let summary = RichHealthContext.DailySummary(
                date: currentDate,
                weight: dayWeight?.weight,
                fastsCompleted: dayFasts.count,
                sleepHours: daySleep?.duration != nil ? daySleep!.duration / 3600 : nil,
                hydrationOz: dayHydration.map({ $0.1 }).reduce(0, +),
                mood: dayMood?.moodLevel
            )

            summaries.append(summary)
            currentDate = nextDate
        }

        return summaries
    }

    private func calculateWeeklyCorrelations(fasts: [FastingSession], weights: [WeightEntry]) -> (highFastWeeks: Double?, lowFastWeeks: Double?) {
        guard !weights.isEmpty, !fasts.isEmpty else { return (nil, nil) }

        let calendar = Calendar.current
        var weeklyData: [Date: (fastCount: Int, weightChange: Double?)] = [:]

        // Group fasts by week
        for fast in fasts {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: fast.startTime)?.start ?? fast.startTime
            weeklyData[weekStart, default: (0, nil)].fastCount += 1
        }

        // Calculate weight changes by week
        for (weekStart, _) in weeklyData {
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            let weekWeights = weights.filter { $0.date >= weekStart && $0.date < weekEnd }

            if let first = weekWeights.last?.weight, let last = weekWeights.first?.weight {
                weeklyData[weekStart]?.weightChange = first - last // positive = weight loss
            }
        }

        // Calculate averages
        let highFastWeeks = weeklyData.values.filter { $0.fastCount >= 5 && $0.weightChange != nil }
        let lowFastWeeks = weeklyData.values.filter { $0.fastCount <= 3 && $0.weightChange != nil }

        let highAvg = highFastWeeks.compactMap({ $0.weightChange }).average()
        let lowAvg = lowFastWeeks.compactMap({ $0.weightChange }).average()

        return (highAvg, lowAvg)
    }

    private func calculateSleepCorrelations(sleep: [SleepEntry], weights: [WeightEntry]) -> (wellRested: Double?, poorlySleep: Double?) {
        guard !sleep.isEmpty, !weights.isEmpty else { return (nil, nil) }

        let calendar = Calendar.current
        var dailyData: [Date: (sleepHours: Double, weightChange: Double?)] = [:]

        // Map sleep to days
        for sleepEntry in sleep {
            let day = calendar.startOfDay(for: sleepEntry.bedTime)
            dailyData[day, default: (0, nil)].sleepHours = sleepEntry.duration / 3600
        }

        // Calculate weight changes
        for (day, _) in dailyData {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            if let todayWeight = weights.first(where: { calendar.isDate($0.date, inSameDayAs: day) }),
               let tomorrowWeight = weights.first(where: { calendar.isDate($0.date, inSameDayAs: nextDay) }) {
                dailyData[day]?.weightChange = todayWeight.weight - tomorrowWeight.weight
            }
        }

        let wellRested = dailyData.values.filter { $0.sleepHours >= 7 && $0.weightChange != nil }
        let poorlySleep = dailyData.values.filter { $0.sleepHours < 6 && $0.weightChange != nil }

        return (
            wellRested.compactMap({ $0.weightChange }).average(),
            poorlySleep.compactMap({ $0.weightChange }).average()
        )
    }

    private func calculateHydrationCorrelations(hydration: [(Date, Double)], weights: [WeightEntry]) -> (highHydration: Double?, lowHydration: Double?) {
        guard !hydration.isEmpty, !weights.isEmpty else { return (nil, nil) }

        let calendar = Calendar.current
        var dailyData: [Date: (hydration: Double, weightChange: Double?)] = [:]

        // Group hydration by day
        for (date, amount) in hydration {
            let day = calendar.startOfDay(for: date)
            dailyData[day, default: (0, nil)].hydration += amount
        }

        // Calculate weight changes
        for (day, _) in dailyData {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            if let todayWeight = weights.first(where: { calendar.isDate($0.date, inSameDayAs: day) }),
               let tomorrowWeight = weights.first(where: { calendar.isDate($0.date, inSameDayAs: nextDay) }) {
                dailyData[day]?.weightChange = todayWeight.weight - tomorrowWeight.weight
            }
        }

        let highHydration = dailyData.values.filter { $0.hydration >= 64 && $0.weightChange != nil }
        let lowHydration = dailyData.values.filter { $0.hydration < 32 && $0.weightChange != nil }

        return (
            highHydration.compactMap({ $0.weightChange }).average(),
            lowHydration.compactMap({ $0.weightChange }).average()
        )
    }

    private func findBestWorstWeeks(fasts: [FastingSession], weights: [WeightEntry]) -> (
        bestDate: String?, bestFastCount: Int?, bestWeightLoss: Double?,
        worstDate: String?, worstFastCount: Int?, worstWeightChange: Double?
    ) {
        guard !weights.isEmpty, !fasts.isEmpty else { return (nil, nil, nil, nil, nil, nil) }

        let calendar = Calendar.current
        var weeklyData: [(weekStart: Date, fastCount: Int, weightChange: Double)] = []

        // Group by week
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"

        let weeks = Set(fasts.map { calendar.dateInterval(of: .weekOfYear, for: $0.startTime)?.start ?? $0.startTime })

        for weekStart in weeks {
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            let weekFasts = fasts.filter { $0.startTime >= weekStart && $0.startTime < weekEnd }
            let weekWeights = weights.filter { $0.date >= weekStart && $0.date < weekEnd }

            if let first = weekWeights.last?.weight, let last = weekWeights.first?.weight {
                let change = first - last
                weeklyData.append((weekStart, weekFasts.count, change))
            }
        }

        guard !weeklyData.isEmpty else { return (nil, nil, nil, nil, nil, nil) }

        let best = weeklyData.max { $0.weightChange < $1.weightChange }
        let worst = weeklyData.min { $0.weightChange < $1.weightChange }

        return (
            best != nil ? dateFormatter.string(from: best!.weekStart) : nil,
            best?.fastCount,
            best?.weightChange,
            worst != nil ? dateFormatter.string(from: worst!.weekStart) : nil,
            worst?.fastCount,
            worst?.weightChange
        )
    }

    private func findMostCommonFastDuration(fasts: [FastingSession]) -> String? {
        guard !fasts.isEmpty else { return nil }

        let durations = fasts.map { Int($0.duration / 3600) }
        let grouped = Dictionary(grouping: durations, by: { $0 })
        let mostCommon = grouped.max { $0.value.count < $1.value.count }

        return mostCommon != nil ? "\(mostCommon!.key) hours" : nil
    }

    private func findMostProductiveDayOfWeek(fasts: [FastingSession]) -> String? {
        guard !fasts.isEmpty else { return nil }

        let calendar = Calendar.current
        let days = fasts.map { calendar.component(.weekday, from: $0.startTime) }
        let grouped = Dictionary(grouping: days, by: { $0 })
        let mostCommon = grouped.max { $0.value.count < $1.value.count }

        if let dayNum = mostCommon?.key {
            return calendar.weekdaySymbols[dayNum - 1]
        }
        return nil
    }
}

// MARK: - Array Extension for Average

fileprivate extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
