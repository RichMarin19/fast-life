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
        let existingCount = currentEntries.count
        let incomingCount = healthKitEntries.count
        AppLogger.info("🔍 [HealthKit Sync] mergeNewEntries — incoming=\(incomingCount), existing=\(existingCount)", category: AppLogger.weightTracking)

#if DEBUG
        let sampleIdentifiers = healthKitEntries.prefix(5).map { entry in
            "\(entry.id.uuidString.prefix(8)):\(entry.source.rawValue)"
        }
        AppLogger.debug("🔍 [HealthKit Sync] mergeNewEntries sampleIds=\(sampleIdentifiers)", category: AppLogger.weightTracking)
        if incomingCount > sampleIdentifiers.count {
            AppLogger.debug("🔍 [HealthKit Sync] mergeNewEntries sample truncated=\(incomingCount - sampleIdentifiers.count)", category: AppLogger.weightTracking)
        }
#endif

        var newlyAddedCount = 0
        var duplicateCount = 0
        var additionsBySource: [String: Int] = [:]

        for hkEntry in healthKitEntries {
            let isDuplicate = currentEntries.contains { existing in
                let isMatch = duplicateChecker(existing, hkEntry)
                return isMatch
            }

            if isDuplicate {
                duplicateCount += 1
            } else {
                currentEntries.append(hkEntry)
                newlyAddedCount += 1
                additionsBySource[hkEntry.source.rawValue, default: 0] += 1
            }
        }

        currentEntries.sort { $0.date > $1.date }
        AppLogger.info("🔍 [HealthKit Sync] mergeNewEntries summary — added=\(newlyAddedCount), duplicates=\(duplicateCount), additionsBySource=\(additionsBySource)", category: AppLogger.weightTracking)
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
        AppLogger.info("🔍 [HealthKit Sync] reconcileAfterReset — startingAppEntries=\(originalCount), incoming=\(healthKitEntries.count)", category: AppLogger.weightTracking)

        var manualPreserved = 0
        var deletedCount = 0

        currentEntries.removeAll { entry in
            guard entry.source != .manual else {
                manualPreserved += 1
                return false
            }

            let stillExists = healthKitEntries.contains { duplicateChecker(entry, $0) }

            if !stillExists {
                deletedCount += 1
            }

            return !stillExists
        }

        AppLogger.info("🔍 [HealthKit Sync] reconcileAfterReset post-filter — deleted=\(deletedCount), manualPreserved=\(manualPreserved), remaining=\(currentEntries.count)", category: AppLogger.weightTracking)

        var addedCount = 0
        var alreadyExistingDuringCompare = 0
        AppLogger.info("🔍 [HealthKit Sync] reconcileAfterReset comparison — incoming=\(healthKitEntries.count), current=\(currentEntries.count)", category: AppLogger.weightTracking)

        for entry in healthKitEntries {
            let alreadyExists = currentEntries.contains { existing in
                duplicateChecker(existing, entry)
            }

            if !alreadyExists {
                currentEntries.append(entry)
                addedCount += 1
            } else {
                alreadyExistingDuringCompare += 1
            }
        }

        currentEntries.sort { $0.date > $1.date }
        AppLogger.info("🔍 [HealthKit Sync] reconcileAfterReset summary — added=\(addedCount), alreadyPresent=\(alreadyExistingDuringCompare), finalCount=\(currentEntries.count)", category: AppLogger.weightTracking)
        return (addedCount, deletedCount)
    }
}
