import Foundation

struct WeightMilestoneStats {
    let goalProgress: Double
    let currentIndex: Int
    let completedCount: Int
    let currentMilestoneProgress: Double
    let startWeight: Double
    let currentWeight: Double
    let remainingWeight: Double
}

protocol WeightAnalyticsServicing {
    func weightTrend(for entries: [WeightEntry]) -> Double?
    func averageWeight(for entries: [WeightEntry]) -> Double?
    func weightChange(for entries: [WeightEntry], latestEntry: WeightEntry?, since date: Date) -> Double?
    func totalWeightChange(startWeight: Double?, currentWeight: Double?, entryCount: Int, hasStartWeightOverride: Bool) -> Double?
    func progressToGoal(startWeight: Double?, currentWeight: Double?, goalWeight: Double) -> Double?
    func currentMilestoneIndex(progress: Double?, totalMilestones: Int) -> Int
    func completedMilestones(progress: Double?, totalMilestones: Int) -> Int
    func milestoneProgress(progress: Double?, totalMilestones: Int) -> Double
    func milestoneStats(startWeight: Double?,
                        currentWeight: Double?,
                        goalWeight: Double,
                        totalMilestones: Int,
                        progress: Double?,
                        entryCount: Int,
                        hasStartWeightOverride: Bool) -> WeightMilestoneStats?
}

final class WeightAnalyticsService: WeightAnalyticsServicing {

    func weightTrend(for entries: [WeightEntry]) -> Double? {
        guard entries.count >= WeightConstants.Statistics.minimumEntriesForTrend else {
            return nil
        }

        let recentEntries = Array(entries.prefix(WeightConstants.Statistics.minimumEntriesForTrend))
        guard let oldestRecent = recentEntries.last?.weight,
              let newest = recentEntries.first?.weight else {
            AppLogger.error("❌ Unexpected nil in weightTrend after count validation", category: AppLogger.weightTracking)
            return nil
        }

        return newest - oldestRecent
    }

    func averageWeight(for entries: [WeightEntry]) -> Double? {
        guard !entries.isEmpty else { return nil }
        let sum = entries.lazy.map { $0.weight }.reduce(0.0, +)
        return sum / Double(entries.count)
    }

    func weightChange(for entries: [WeightEntry], latestEntry: WeightEntry?, since date: Date) -> Double? {
        guard let latestEntry else {
            AppLogger.info("🔍 [WeightAnalyticsService.weightChange] NO DATA - latestEntry is nil", category: AppLogger.weightTracking)
            return nil
        }

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"

        AppLogger.info("🔍 [WeightAnalyticsService.weightChange] START - since: \(formatter.string(from: date)) | current weight: \(latestEntry.weight) lbs", category: AppLogger.weightTracking)

        let detailedFormatter = DateFormatter()
        detailedFormatter.dateFormat = "MMM d, yyyy HH:mm:ss"
#if DEBUG
        AppLogger.info("🔍 [WeightAnalyticsService.weightChange] FULL DUMP - Total entries: \(entries.count)", category: AppLogger.weightTracking)
        for (index, entry) in entries.enumerated() {
            AppLogger.info("🔍 Entry #\(index): \(entry.weight) lbs on \(detailedFormatter.string(from: entry.date)) (source: \(entry.source.rawValue))", category: AppLogger.weightTracking)
        }
#endif

        var oldestEntry: WeightEntry?
        for entry in entries.reversed() {
            let comparison = calendar.compare(entry.date, to: date, toGranularity: .day)
            if comparison == .orderedDescending || comparison == .orderedSame {
                oldestEntry = entry
                break
            }
        }

        guard let oldestEntry else {
            AppLogger.info("🔍 [WeightAnalyticsService.weightChange] NO DATA - no entries found in date range", category: AppLogger.weightTracking)
            return nil
        }

        AppLogger.info("🔍 [WeightAnalyticsService.weightChange] Oldest date in window: \(formatter.string(from: oldestEntry.date))", category: AppLogger.weightTracking)

        let startOfOldestDay = calendar.startOfDay(for: oldestEntry.date)
        guard let endOfOldestDay = calendar.date(byAdding: .day, value: 1, to: startOfOldestDay) else {
            AppLogger.info("🔍 [WeightAnalyticsService.weightChange] ERROR - Could not calculate end of day", category: AppLogger.weightTracking)
            return nil
        }

        let entriesOnOldestDay = entries.filter {
            $0.date >= startOfOldestDay && $0.date < endOfOldestDay
        }

        AppLogger.info("🔍 [WeightAnalyticsService.weightChange] Date range: \(formatter.string(from: startOfOldestDay)) to \(formatter.string(from: endOfOldestDay))", category: AppLogger.weightTracking)
        AppLogger.info("🔍 [WeightAnalyticsService.weightChange] Entries on oldest day: \(entriesOnOldestDay.count) - weights: \(entriesOnOldestDay.map { $0.weight })", category: AppLogger.weightTracking)

        guard !entriesOnOldestDay.isEmpty else { return nil }
        if entriesOnOldestDay.count == 1, let singleEntry = entriesOnOldestDay.first, singleEntry.id == latestEntry.id {
            return nil
        }

        let sumWeight = entriesOnOldestDay.map { $0.weight }.reduce(0.0, +)
        let avgWeightOnOldestDay = sumWeight / Double(entriesOnOldestDay.count)

        AppLogger.info("🔍 [WeightAnalyticsService.weightChange] Average weight on oldest day: \(avgWeightOnOldestDay) lbs", category: AppLogger.weightTracking)

        let change = latestEntry.weight - avgWeightOnOldestDay
        AppLogger.info("🔍 [WeightAnalyticsService.weightChange] RESULT: \(change) lbs (\(latestEntry.weight) - \(avgWeightOnOldestDay))", category: AppLogger.weightTracking)
        return change
    }

    func totalWeightChange(startWeight: Double?, currentWeight: Double?, entryCount: Int, hasStartWeightOverride: Bool) -> Double? {
        guard let startWeight, let currentWeight else {
            return nil
        }
        if entryCount < 2 && !hasStartWeightOverride {
            return nil
        }
        return currentWeight - startWeight
    }

    func progressToGoal(startWeight: Double?, currentWeight: Double?, goalWeight: Double) -> Double? {
        guard let startWeight,
              let currentWeight,
              goalWeight > 0,
              goalWeight < startWeight else {
            return nil
        }

        let totalDistance = startWeight - goalWeight
        let progressMade = startWeight - currentWeight

        if progressMade <= 0 {
            return 0.0
        }

        let progress = max(0.0, min(1.0, progressMade / totalDistance))
        return progress
    }

    func currentMilestoneIndex(progress: Double?, totalMilestones: Int) -> Int {
        guard let progress else { return 1 }
        let milestoneFloat = progress * Double(totalMilestones)
        let milestone = Int(ceil(milestoneFloat))
        return max(1, min(totalMilestones, milestone))
    }

    func completedMilestones(progress: Double?, totalMilestones: Int) -> Int {
        guard let progress else { return 0 }
        let completed = Int(floor(progress * Double(totalMilestones)))
        return max(0, min(totalMilestones, completed))
    }

    func milestoneProgress(progress: Double?, totalMilestones: Int) -> Double {
        guard let progress else { return 0.0 }
        let milestoneFloat = progress * Double(totalMilestones)
        return milestoneFloat - floor(milestoneFloat)
    }

    func milestoneStats(startWeight: Double?,
                        currentWeight: Double?,
                        goalWeight: Double,
                        totalMilestones: Int,
                        progress: Double?,
                        entryCount: Int,
                        hasStartWeightOverride: Bool) -> WeightMilestoneStats? {
        guard let startWeight,
              let currentWeight,
              goalWeight > 0,
              goalWeight < startWeight else {
            return nil
        }

        if entryCount < 2 && !hasStartWeightOverride {
            return nil
        }

        guard let progress = progress ?? progressToGoal(startWeight: startWeight,
                                                        currentWeight: currentWeight,
                                                        goalWeight: goalWeight) else {
            return nil
        }

        let currentIndex = currentMilestoneIndex(progress: progress, totalMilestones: totalMilestones)
        let completed = completedMilestones(progress: progress, totalMilestones: totalMilestones)
        let milestoneProgress = milestoneProgress(progress: progress, totalMilestones: totalMilestones)

        return WeightMilestoneStats(
            goalProgress: progress,
            currentIndex: currentIndex,
            completedCount: completed,
            currentMilestoneProgress: milestoneProgress,
            startWeight: startWeight,
            currentWeight: currentWeight,
            remainingWeight: max(0, currentWeight - goalWeight)
        )
    }
}
