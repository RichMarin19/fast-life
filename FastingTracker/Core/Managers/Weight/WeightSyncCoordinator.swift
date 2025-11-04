import Foundation

protocol WeightSyncCoordinating {
    func mergeNewEntries(currentEntries: inout [WeightEntry],
                         healthKitEntries: [WeightEntry],
                         duplicateChecker: (WeightEntry, WeightEntry) -> Bool)
        -> Int

    func mergeHistoricalEntries(currentEntries: inout [WeightEntry],
                                healthKitEntries: [WeightEntry],
                                duplicateChecker: (WeightEntry, WeightEntry) -> Bool)
        -> Int

    func reconcileAfterReset(currentEntries: inout [WeightEntry],
                             healthKitEntries: [WeightEntry],
                             duplicateChecker: (WeightEntry, WeightEntry) -> Bool)
        -> (added: Int, deleted: Int)
}

final class WeightSyncCoordinator: WeightSyncCoordinating {

    private let detailedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy HH:mm:ss"
        return formatter
    }()

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d 'at' h:mm a"
        return formatter
    }()

    func mergeNewEntries(currentEntries: inout [WeightEntry],
                         healthKitEntries: [WeightEntry],
                         duplicateChecker: (WeightEntry, WeightEntry) -> Bool) -> Int {
        AppLogger.info("🔍 [HealthKit Sync] Received \(healthKitEntries.count) entries from HealthKit", category: AppLogger.weightTracking)
        for (index, entry) in healthKitEntries.enumerated() {
            AppLogger.info("🔍 HK Entry #\(index): \(entry.weight) lbs on \(detailedFormatter.string(from: entry.date)) (source: \(entry.source.rawValue))", category: AppLogger.weightTracking)
        }
        AppLogger.info("🔍 [HealthKit Sync] Fast LIFe currently has \(currentEntries.count) entries", category: AppLogger.weightTracking)

        var newlyAddedCount = 0

        for hkEntry in healthKitEntries {
            var matchDetails = ""
            let isDuplicate = currentEntries.contains { existing in
                let isMatch = duplicateChecker(existing, hkEntry)
                if isMatch {
                    let timeDiff = abs(existing.date.timeIntervalSince(hkEntry.date))
                    let weightDiff = abs(existing.weight - hkEntry.weight)
                    matchDetails = "matches existing entry \(existing.weight) lbs on \(detailedFormatter.string(from: existing.date)) (timeDiff: \(String(format: "%.1f", timeDiff))s, weightDiff: \(String(format: "%.3f", weightDiff)) lbs)"
                }
                return isMatch
            }

            if isDuplicate {
                AppLogger.info("🔍 [Duplicate Check] SKIPPING HK entry \(hkEntry.weight) lbs on \(detailedFormatter.string(from: hkEntry.date)) - \(matchDetails)", category: AppLogger.weightTracking)
            } else {
                AppLogger.info("🔍 [Duplicate Check] ADDING HK entry \(hkEntry.weight) lbs on \(detailedFormatter.string(from: hkEntry.date)) - not a duplicate", category: AppLogger.weightTracking)
                currentEntries.append(hkEntry)
                newlyAddedCount += 1
            }
        }

        currentEntries.sort { $0.date > $1.date }
        return newlyAddedCount
    }

    func mergeHistoricalEntries(currentEntries: inout [WeightEntry],
                                healthKitEntries: [WeightEntry],
                                duplicateChecker: (WeightEntry, WeightEntry) -> Bool) -> Int {
        var newlyAddedCount = 0

        for entry in healthKitEntries {
            let isDuplicate = currentEntries.contains { duplicateChecker($0, entry) }
            if !isDuplicate {
                currentEntries.append(entry)
                newlyAddedCount += 1
            }
        }

        currentEntries.sort { $0.date > $1.date }
        return newlyAddedCount
    }

    func reconcileAfterReset(currentEntries: inout [WeightEntry],
                             healthKitEntries: [WeightEntry],
                             duplicateChecker: (WeightEntry, WeightEntry) -> Bool) -> (added: Int, deleted: Int) {
        let originalCount = currentEntries.count
        AppLogger.info("DELETION CHECK: Starting with \(originalCount) Fast LIFe entries, \(healthKitEntries.count) HealthKit entries", category: AppLogger.weightTracking)

        currentEntries.removeAll { entry in
            guard entry.source != .manual else {
                AppLogger.info("PRESERVING manual entry: \(entry.weight)lbs on \(dayFormatter.string(from: entry.date))", category: AppLogger.weightTracking)
                return false
            }

            let stillExists = healthKitEntries.contains { duplicateChecker(entry, $0) }
            let entryDateString = dayFormatter.string(from: entry.date)

            if !stillExists {
                AppLogger.info("DELETING entry: \(entry.weight)lbs on \(entryDateString) (source: \(entry.source.rawValue)) - not found in current HealthKit data", category: AppLogger.weightTracking)
            } else {
                AppLogger.info("KEEPING entry: \(entry.weight)lbs on \(entryDateString) (source: \(entry.source.rawValue)) - still exists in HealthKit", category: AppLogger.weightTracking)
            }

            return !stillExists
        }

        let deletedCount = originalCount - currentEntries.count
        AppLogger.info("DELETION COMPLETE: Removed \(deletedCount) entries, \(currentEntries.count) entries remaining", category: AppLogger.weightTracking)

        var addedCount = 0
        AppLogger.info("Starting comparison: HealthKit has \(healthKitEntries.count) entries, Fast LIFe has \(currentEntries.count) entries", category: AppLogger.weightTracking)

        for entry in healthKitEntries {
            let dateString = dayFormatter.string(from: entry.date)
            let alreadyExists = currentEntries.contains { existing in
                let matches = duplicateChecker(existing, entry)
                if matches {
                    AppLogger.info("MATCH FOUND: HealthKit(\(entry.weight)lbs \(dateString)) matches Fast LIFe(\(existing.weight)lbs \(dayFormatter.string(from: existing.date)))", category: AppLogger.weightTracking)
                }
                return matches
            }

            if !alreadyExists {
                AppLogger.info("MISSING ENTRY DETECTED: Adding HealthKit entry \(entry.weight)lbs on \(dateString) (source: \(entry.source.rawValue))", category: AppLogger.weightTracking)
                currentEntries.append(entry)
                addedCount += 1
            } else {
                AppLogger.info("Entry already exists: \(entry.weight)lbs on \(dateString)", category: AppLogger.weightTracking)
            }
        }

        currentEntries.sort { $0.date > $1.date }
        return (addedCount, deletedCount)
    }
}
