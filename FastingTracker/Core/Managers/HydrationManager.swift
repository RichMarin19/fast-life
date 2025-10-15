import Foundation
import Combine
import HealthKit

// MARK: - Drink Type Enum

enum DrinkType: String, Codable, CaseIterable {
    case water = "Water"
    case coffee = "Coffee"
    case tea = "Tea"

    var icon: String {
        switch self {
        case .water: return "drop.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .tea: return "mug.fill"
        }
    }

    // Standard serving sizes in ounces
    var standardServing: Double {
        switch self {
        case .water: return 8.0  // 8 oz glass
        case .coffee: return 8.0  // 8 oz cup
        case .tea: return 8.0     // 8 oz cup
        }
    }

    /// Get standard serving in user's preferred unit
    /// Following Apple localization pattern for unit preferences
    /// Reference: https://developer.apple.com/documentation/foundation/locale
    func standardServingInPreferredUnit(_ unit: HydrationUnit) -> Double {
        return unit.fromOunces(standardServing)
    }
}

// MARK: - Data Source Enum
enum DataSource: String, Codable, CaseIterable {
    case manual = "Manual"
    case healthKit = "HealthKit"
}

// MARK: - Drink Entry Model

struct DrinkEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let type: DrinkType
    let amount: Double  // in ounces
    let date: Date
    let source: DataSource

    init(id: UUID = UUID(), type: DrinkType, amount: Double, date: Date = Date(), source: DataSource = .manual) {
        self.id = id
        self.type = type
        self.amount = amount
        self.date = date
        self.source = source
    }
}

// MARK: - Hydration Manager

@MainActor
class HydrationManager: ObservableObject {
    @Published var drinkEntries: [DrinkEntry] = []
    @Published var dailyGoalOunces: Double = 64.0  // Default 8 glasses of water
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0

    // MARK: - Unit Preference Integration
    // Following Apple single source of truth pattern for global settings
    // Reference: https://developer.apple.com/documentation/swiftui/managing-user-interface-state
    private let appSettings = AppSettings.shared

    private let userDefaults = UserDefaults.standard
    private let drinkEntriesKey = "drinkEntries"
    private let dailyGoalKey = "dailyHydrationGoal"
    private let streakKey = "hydrationCurrentStreak"
    private let longestStreakKey = "hydrationLongestStreak"

    // MARK: - HealthKit Sync Properties
    @Published var syncWithHealthKit: Bool = false
    private let syncPreferenceKey = "hydrationSyncWithHealthKit"
    private let hasCompletedInitialImportKey = "hydrationHasCompletedInitialImport"

    init() {
        loadDrinkEntries()
        loadDailyGoal()
        loadStreak()
        loadLongestStreak()
        loadSyncPreference()

        // Calculate streaks from history to ensure accuracy
        calculateStreakFromHistory()

        // Setup observer if sync is already enabled (app restart scenario)
        if syncWithHealthKit && HealthKitManager.shared.isHydrationAuthorized() {
            startObservingHealthKit()
        }
    }

    // MARK: - Add Drink Entry

    func addDrinkEntry(_ entry: DrinkEntry) {
        // Industry Standard: All @Published property updates must be on main thread
        DispatchQueue.main.async {
            self.drinkEntries.append(entry)

            // Sort by date (most recent first)
            self.drinkEntries.sort { $0.date > $1.date }

            self.saveDrinkEntries()

            // Recalculate streaks after adding entry
            self.calculateStreakFromHistory()
        }

        // Sync to HealthKit if enabled and manual entry (prevent observer loops)
        if syncWithHealthKit && entry.source == .manual {
            // Observer suppression prevents infinite sync loops
            isSuppressingObserver = true

            let healthKitManager = HealthKitManager.shared
            if healthKitManager.isHydrationAuthorized() {
                healthKitManager.saveWater(amount: entry.amount, date: entry.date) { [weak self] success, error in
                    // Re-enable observer after HealthKit write completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self?.isSuppressingObserver = false
                        AppLogger.info("Observer suppression lifted after manual hydration entry", category: AppLogger.hydration)
                    }

                    if let error = error {
                        AppLogger.error("Failed to sync drink to HealthKit", category: AppLogger.hydration, error: error)
                    } else if success {
                        AppLogger.info("Synced drink to HealthKit - amount: \(entry.amount)oz", category: AppLogger.hydration)
                    }
                }
            } else {
                // Reset suppression if not authorized
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.isSuppressingObserver = false
                }
            }
        }
    }

    func addDrink(type: DrinkType, amount: Double? = nil) {
        let drinkAmount = amount ?? type.standardServing
        let entry = DrinkEntry(type: type, amount: drinkAmount)
        addDrinkEntry(entry)
    }

    /// Add drink entry from user input in preferred unit
    /// Following Apple data conversion pattern for user input
    /// Reference: https://developer.apple.com/documentation/foundation/measurement
    func addDrinkInPreferredUnit(type: DrinkType, amount: Double? = nil) {
        let userAmount = amount ?? appSettings.hydrationUnit.fromOunces(type.standardServing)
        let amountInOunces = appSettings.hydrationUnit.toOunces(userAmount)

        AppLogger.info("Adding drink: \(userAmount) \(appSettings.hydrationUnit.abbreviation) (\(amountInOunces) oz internal)", category: AppLogger.hydration)

        let entry = DrinkEntry(type: type, amount: amountInOunces)
        addDrinkEntry(entry)
    }

    // MARK: - Delete Drink Entry

    func deleteDrinkEntry(_ entry: DrinkEntry) {
        // Industry Standard: All @Published property updates must be on main thread
        DispatchQueue.main.async {
            self.drinkEntries.removeAll { $0.id == entry.id }
            self.saveDrinkEntries()

            // Recalculate streaks after deleting entry
            self.calculateStreakFromHistory()
        }
    }

    // MARK: - Unit Conversion Methods
    // Following Apple adapter pattern to maintain backward compatibility
    // Reference: https://docs.swift.org/swift-book/LanguageGuide/Protocols.html#ID521

    /// Get today's total in user's preferred unit
    /// Maintains backward compatibility while supporting unit preferences
    func todaysTotalInPreferredUnit() -> Double {
        let totalOunces = todaysTotalOunces()
        return appSettings.hydrationUnit.fromOunces(totalOunces)
    }

    /// Get daily goal in user's preferred unit
    func dailyGoalInPreferredUnit() -> Double {
        return appSettings.hydrationUnit.fromOunces(dailyGoalOunces)
    }

    // MARK: - Computed Properties for SwiftUI Reactivity (Following Weight Pattern)
    // Industry Standard: Computed properties automatically trigger SwiftUI view updates
    // Reference: https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app

    /// Today's total hydration in preferred unit - computed property for SwiftUI reactivity
    /// Following WeightManager.latestWeight pattern for automatic UI updates
    var todaysTotalInPreferredUnitComputed: Double {
        let totalOunces = todaysTotalOunces()
        return appSettings.hydrationUnit.fromOunces(totalOunces)
    }

    /// Daily goal in preferred unit - computed property for SwiftUI reactivity
    var dailyGoalInPreferredUnitComputed: Double {
        return appSettings.hydrationUnit.fromOunces(dailyGoalOunces)
    }

    /// Current unit abbreviation - computed property for SwiftUI reactivity
    var currentUnitAbbreviationComputed: String {
        return appSettings.hydrationUnit.abbreviation
    }

    /// Convert user input from preferred unit to internal ounces
    /// Ensures data consistency in storage format
    func convertToInternalUnit(_ value: Double) -> Double {
        return appSettings.hydrationUnit.toOunces(value)
    }

    /// Get current unit abbreviation for display
    var currentUnitAbbreviation: String {
        return appSettings.hydrationUnit.abbreviation
    }

    /// Convert drink entry amount to user's preferred unit for display
    /// Following Apple display formatting pattern
    /// Reference: https://developer.apple.com/documentation/foundation/formatter
    func displayAmount(for entry: DrinkEntry) -> Double {
        return appSettings.hydrationUnit.fromOunces(entry.amount)
    }

    // MARK: - Daily Progress Calculations

    func todaysDrinks() -> [DrinkEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return drinkEntries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: today)
        }
    }

    func todaysTotalOunces() -> Double {
        return todaysDrinks().reduce(0) { $0 + $1.amount }
    }

    func todaysProgress() -> Double {
        let total = todaysTotalOunces()
        return min(total / dailyGoalOunces, 1.0)  // Cap at 100%
    }

    func todaysProgressPercentage() -> Int {
        return Int(todaysProgress() * 100)
    }

    // MARK: - Drink Type Breakdown

    func todaysDrinksByType() -> [DrinkType: Double] {
        var breakdown: [DrinkType: Double] = [:]
        for drink in todaysDrinks() {
            breakdown[drink.type, default: 0.0] += drink.amount
        }
        return breakdown
    }

    func todaysProgressByType(_ type: DrinkType) -> Double {
        let typeAmount = todaysDrinksByType()[type] ?? 0.0
        return min(typeAmount / dailyGoalOunces, 1.0)
    }

    // MARK: - Goal Management

    func updateDailyGoal(_ newGoal: Double) {
        dailyGoalOunces = max(8.0, newGoal)  // Minimum 8 oz
        userDefaults.set(dailyGoalOunces, forKey: dailyGoalKey)
    }

    /// Update daily goal from user input in preferred unit
    /// Following Apple input validation pattern with unit conversion
    /// Reference: https://developer.apple.com/documentation/foundation/numberformatter
    func updateDailyGoalFromPreferredUnit(_ newGoal: Double) {
        // Apply minimum constraint (8 oz = ~237 ml)
        let minimumInOunces = 8.0
        let minimumInPreferredUnit = appSettings.hydrationUnit.fromOunces(minimumInOunces)

        // Validate minimum based on preferred unit
        let validatedGoal = max(minimumInPreferredUnit, newGoal)
        let validatedGoalInOunces = appSettings.hydrationUnit.toOunces(validatedGoal)

        dailyGoalOunces = validatedGoalInOunces
        userDefaults.set(dailyGoalOunces, forKey: dailyGoalKey)

        AppLogger.info("Daily hydration goal updated: \(validatedGoal) \(appSettings.hydrationUnit.abbreviation) (\(validatedGoalInOunces) oz internal)", category: AppLogger.hydration)
    }

    // MARK: - Persistence

    private func saveDrinkEntries() {
        if let encoded = try? JSONEncoder().encode(drinkEntries) {
            userDefaults.set(encoded, forKey: drinkEntriesKey)
        }
    }

    private func loadDrinkEntries() {
        if let data = userDefaults.data(forKey: drinkEntriesKey),
           let decoded = try? JSONDecoder().decode([DrinkEntry].self, from: data) {
            drinkEntries = decoded
        }
    }

    private func loadDailyGoal() {
        let savedGoal = userDefaults.double(forKey: dailyGoalKey)
        if savedGoal > 0 {
            dailyGoalOunces = savedGoal
        }
    }

    // MARK: - Streak Management

    private func calculateStreakFromHistory() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get all days that met the goal (group by day)
        var goalMetDays: Set<Date> = []

        for entry in drinkEntries {
            let dayStart = calendar.startOfDay(for: entry.date)

            // Get total for this day
            let dayTotal = drinkEntries
                .filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
                .reduce(0.0) { $0 + $1.amount }

            if dayTotal >= dailyGoalOunces {
                goalMetDays.insert(dayStart)
            }
        }

        let sortedDays = goalMetDays.sorted(by: >)  // Most recent first

        guard !sortedDays.isEmpty else {
            currentStreak = 0
            longestStreak = 0
            saveStreak()
            saveLongestStreak()
            return
        }

        // Calculate current streak (must include today or yesterday)
        let mostRecentDay = sortedDays[0]
        let daysBetween = calendar.dateComponents([.day], from: mostRecentDay, to: today).day ?? 0

        if daysBetween > 1 {
            // Streak is broken
            currentStreak = 0
            saveStreak()
        } else {
            // Calculate current streak
            var streak = 1
            var currentDay = mostRecentDay

            for i in 1..<sortedDays.count {
                let previousDay = sortedDays[i]
                let dayDiff = calendar.dateComponents([.day], from: previousDay, to: currentDay).day ?? 0

                if dayDiff == 1 {
                    streak += 1
                    currentDay = previousDay
                } else {
                    break
                }
            }

            currentStreak = streak
            saveStreak()
        }

        // Calculate longest streak
        var maxStreak = 0
        var tempStreak = 0
        var lastDay: Date?

        let sortedAscending = sortedDays.sorted(by: <)  // Oldest first

        for day in sortedAscending {
            if let last = lastDay {
                let dayDiff = calendar.dateComponents([.day], from: last, to: day).day ?? 0

                if dayDiff == 1 {
                    tempStreak += 1
                } else {
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }

            if tempStreak > maxStreak {
                maxStreak = tempStreak
            }

            lastDay = day
        }

        longestStreak = maxStreak
        saveLongestStreak()
    }

    private func saveStreak() {
        userDefaults.set(currentStreak, forKey: streakKey)
    }

    private func loadStreak() {
        currentStreak = userDefaults.integer(forKey: streakKey)
    }

    private func saveLongestStreak() {
        userDefaults.set(longestStreak, forKey: longestStreakKey)
    }

    private func loadLongestStreak() {
        longestStreak = userDefaults.integer(forKey: longestStreakKey)
    }

    // MARK: - HealthKit Sync

    func syncToHealthKit() {
        let healthKitManager = HealthKitManager.shared

        guard healthKitManager.isWaterAuthorized() else {
            AppLogger.warning("HealthKit not authorized for water, cannot sync hydration", category: AppLogger.hydration)
            return
        }

        // Get list of already exported entries to prevent duplicates
        let exportedEntries = getExportedEntryIds()

        // Filter to only new entries that haven't been exported yet
        let newEntries = drinkEntries.filter { !exportedEntries.contains($0.id.uuidString) }

        AppLogger.info("Starting hydration export to HealthKit - \(newEntries.count) new entries", category: AppLogger.hydration)

        guard !newEntries.isEmpty else {
            AppLogger.info("No new hydration entries to export - all up to date", category: AppLogger.hydration)
            return
        }

        // Export only new drink entries to HealthKit as water
        var syncedCount = 0
        let dispatchGroup = DispatchGroup()

        for entry in newEntries {
            dispatchGroup.enter()
            healthKitManager.saveWater(amount: entry.amount, date: entry.date) { success, error in
                if let error = error {
                    AppLogger.error("Failed to export drink to HealthKit", category: AppLogger.hydration, error: error)
                } else if success {
                    syncedCount += 1
                    // Mark this entry as exported
                    self.markEntryAsExported(entry.id.uuidString)
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            AppLogger.info("Completed hydration export to HealthKit - \(syncedCount) entries synced", category: AppLogger.hydration)
        }
    }

    // MARK: - Export Tracking for Deduplication

    private let exportedEntriesKey = "exportedHydrationEntries"

    private func getExportedEntryIds() -> Set<String> {
        let exported = userDefaults.array(forKey: exportedEntriesKey) as? [String] ?? []
        return Set(exported)
    }

    private func markEntryAsExported(_ entryId: String) {
        var exported = getExportedEntryIds()
        exported.insert(entryId)
        userDefaults.set(Array(exported), forKey: exportedEntriesKey)
    }

    // MARK: - Universal HealthKit Sync Architecture (Industry Standard)
    // Following Universal Sync Architecture patterns from handoff.md

    /// Observer suppression flag to prevent infinite sync loops during manual operations
    /// NOTE: nonisolated for thread-safe access from HealthKit background contexts
    private nonisolated(unsafe) var isSuppressingObserver = false

    /// Observer query for automatic HealthKit sync
    private var observerQuery: Any? // HKObserverQuery type-erased to avoid import issues

    // MARK: - Universal Sync Methods (Required by Architecture)

    /// Automatic observer-triggered sync (Universal Method #1)
    func syncFromHealthKit(startDate: Date? = nil, completion: ((Int, Error?) -> Void)? = nil) {
        guard syncWithHealthKit else {
            DispatchQueue.main.async {
                completion?(0, nil)
            }
            return
        }

        guard HealthKitManager.shared.isHydrationAuthorized() else {
            AppLogger.warning("HealthKit not authorized for hydration sync", category: AppLogger.hydration)
            DispatchQueue.main.async {
                completion?(0, NSError(domain: "HydrationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit not authorized"]))
            }
            return
        }

        // Prevent sync during observer suppression (manual operations)
        guard !isSuppressingObserver else {
            AppLogger.info("Skipping HealthKit sync - observer suppressed during manual operation", category: AppLogger.hydration)
            DispatchQueue.main.async {
                completion?(0, nil)
            }
            return
        }

        // Default to comprehensive sync (1 year) for data consistency
        let fromDate = startDate ?? Calendar.current.date(byAdding: .year, value: -1, to: Date())!

        AppLogger.info("Starting hydration sync from HealthKit", category: AppLogger.hydration)

        HealthKitManager.shared.fetchWaterData(startDate: fromDate) { [weak self] waterData in
            guard let self = self else {
                completion?(0, NSError(domain: "HydrationManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "HydrationManager deallocated"]))
                return
            }

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                // Track newly added entries for accurate reporting
                var newlyAddedCount = 0

                // Import water data as "Water" type DrinkEntry with robust deduplication
                for (date, amount) in waterData {
                    // More comprehensive duplicate check following WeightManager pattern
                    let isDuplicate = self.drinkEntries.contains { entry in
                        abs(entry.date.timeIntervalSince(date)) < 300 && // Within 5 minutes
                        abs(entry.amount - amount) < 0.01 && // Within 0.01 oz/ml
                        entry.type == .water // Only check against water entries
                    }

                    if !isDuplicate {
                        let entry = DrinkEntry(type: .water, amount: amount, date: date, source: .healthKit)
                        self.drinkEntries.append(entry)
                        newlyAddedCount += 1
                    }
                }

                // Sort by date (most recent first) and save
                self.drinkEntries.sort { $0.date > $1.date }
                self.saveDrinkEntries()
                self.calculateStreakFromHistory()

                // Report sync results
                AppLogger.info("HealthKit sync completed: \(newlyAddedCount) new hydration entries added", category: AppLogger.hydration)
                completion?(newlyAddedCount, nil)
            }
        }
    }

    /// Complete historical data import (Universal Method #2)
    func syncFromHealthKitHistorical(startDate: Date, completion: @escaping (Int, Error?) -> Void) {
        guard syncWithHealthKit else {
            DispatchQueue.main.async {
                completion(0, NSError(domain: "HydrationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit sync is disabled"]))
            }
            return
        }

        AppLogger.info("Starting historical hydration sync from \(startDate)", category: AppLogger.hydration)

        HealthKitManager.shared.fetchWaterData(startDate: startDate) { [weak self] waterData in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(0, NSError(domain: "HydrationManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "HydrationManager instance deallocated"]))
                }
                return
            }

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                // Track newly added entries for accurate reporting
                var newlyAddedCount = 0

                // Merge HealthKit entries with local entries using robust deduplication
                for (date, amount) in waterData {
                    // Historical import uses more flexible duplicate check
                    let isDuplicate = self.drinkEntries.contains { entry in
                        abs(entry.date.timeIntervalSince(date)) < 300 && // Within 5 minutes (flexible for historical)
                        abs(entry.amount - amount) < 0.02 && // Within 0.02 oz/ml (account for conversion rounding)
                        entry.type == .water
                    }

                    if !isDuplicate {
                        let entry = DrinkEntry(type: .water, amount: amount, date: date, source: .healthKit)
                        self.drinkEntries.append(entry)
                        newlyAddedCount += 1
                    }
                }

                // Sort by date (most recent first)
                self.drinkEntries.sort { $0.date > $1.date }
                self.saveDrinkEntries()
                self.calculateStreakFromHistory()

                // Report actual sync results
                AppLogger.info("Historical HealthKit sync completed: \(newlyAddedCount) new hydration entries imported from \(waterData.count) total entries", category: AppLogger.hydration)
                completion(newlyAddedCount, nil)
            }
        }
    }

    /// Manual sync with deletion detection (Universal Method #3)
    func syncFromHealthKitWithReset(startDate: Date, completion: @escaping (Int, Error?) -> Void) {
        guard syncWithHealthKit else {
            DispatchQueue.main.async {
                completion(0, NSError(domain: "HydrationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit sync is disabled"]))
            }
            return
        }

        AppLogger.info("Starting manual hydration sync with anchor reset for deletion detection from \(startDate)", category: AppLogger.hydration)

        HealthKitManager.shared.fetchWaterData(startDate: startDate) { [weak self] waterData in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(0, NSError(domain: "HydrationManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "HydrationManager instance deallocated"]))
                }
                return
            }

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                // Industry Standard: Complete sync with deletion detection
                // Step 1: Remove HealthKit entries that are no longer in Apple Health
                let originalCount = self.drinkEntries.count

                self.drinkEntries.removeAll { fastLifeEntry in
                    // Only remove HealthKit-sourced water entries (preserve manual entries)
                    guard fastLifeEntry.source == .healthKit && fastLifeEntry.type == .water else {
                        return false
                    }

                    // Check if this Fast LIFe entry still exists in current HealthKit data
                    let stillExistsInHealthKit = waterData.contains { (healthKitDate, healthKitAmount) in
                        let timeDiff = abs(fastLifeEntry.date.timeIntervalSince(healthKitDate))
                        let amountDiff = abs(fastLifeEntry.amount - healthKitAmount)
                        return timeDiff < 300 && amountDiff < 0.02 // Within 5 minutes and 0.02 oz/ml
                    }

                    return !stillExistsInHealthKit
                }
                let deletedCount = originalCount - self.drinkEntries.count

                // Step 2: Add new HealthKit entries not already in Fast LIFe
                var addedCount = 0
                for (healthKitDate, healthKitAmount) in waterData {
                    let alreadyExists = self.drinkEntries.contains { fastLifeEntry in
                        let timeDiff = abs(fastLifeEntry.date.timeIntervalSince(healthKitDate))
                        let amountDiff = abs(fastLifeEntry.amount - healthKitAmount)
                        return timeDiff < 300 && amountDiff < 0.02 && fastLifeEntry.type == .water
                    }

                    if !alreadyExists {
                        let entry = DrinkEntry(type: .water, amount: healthKitAmount, date: healthKitDate, source: .healthKit)
                        self.drinkEntries.append(entry)
                        addedCount += 1
                    }
                }

                // Sort by date (most recent first) and save
                self.drinkEntries.sort { $0.date > $1.date }
                self.saveDrinkEntries()
                self.calculateStreakFromHistory()

                // Report comprehensive sync results
                AppLogger.info("Manual HealthKit sync completed: \(addedCount) entries added, \(deletedCount) entries removed, \(waterData.count) total HealthKit entries", category: AppLogger.hydration)
                completion(addedCount, nil)
            }
        }
    }

    // MARK: - Observer Pattern Implementation

    /// Start observing HealthKit for automatic sync (Universal Pattern)
    func startObservingHealthKit() {
        guard syncWithHealthKit && HealthKitManager.shared.isHydrationAuthorized() else {
            AppLogger.info("Hydration HealthKit observer not started - sync disabled or not authorized", category: AppLogger.hydration)
            return
        }

        // Start observing hydration data changes
        HealthKitManager.shared.startObservingHydration { [weak self] in
            guard let self = self else { return }

            // Industry Standard: All @Published property updates must be on main thread
            DispatchQueue.main.async {
                // Trigger automatic sync when HealthKit data changes
                self.syncFromHealthKit { count, error in
                    if let error = error {
                        AppLogger.error("Observer-triggered hydration sync failed", category: AppLogger.hydration, error: error)
                    } else if count > 0 {
                        AppLogger.info("Observer-triggered hydration sync: \(count) new entries added", category: AppLogger.hydration)
                    }
                }
            }
        }

        AppLogger.info("Hydration HealthKit observer started successfully - automatic sync enabled", category: AppLogger.hydration)
    }

    /// Stop observing HealthKit (Universal Pattern)
    func stopObservingHealthKit() {
        // Stop the observer query if it exists
        if let query = observerQuery as? HKObserverQuery {
            HealthKitManager.shared.stopObservingHydration(query: query)
        }
        observerQuery = nil
        AppLogger.info("Hydration HealthKit observer stopped", category: AppLogger.hydration)
    }

    // MARK: - Preference Management (Universal Pattern)

    func setSyncPreference(_ enabled: Bool) {
        AppLogger.info("Setting hydration sync preference to \(enabled)", category: AppLogger.hydration)
        syncWithHealthKit = enabled
        userDefaults.set(enabled, forKey: syncPreferenceKey)

        if enabled {
            // Request authorization and start observing if not already authorized
            if !HealthKitManager.shared.isHydrationAuthorized() {
                HealthKitManager.shared.requestHydrationAuthorization { [weak self] success, error in
                    DispatchQueue.main.async {
                        if success {
                            AppLogger.info("Hydration authorization granted, syncing from HealthKit", category: AppLogger.hydration)
                            self?.syncFromHealthKit { _, _ in }
                            self?.startObservingHealthKit()
                        } else {
                            AppLogger.error("Hydration authorization failed", category: AppLogger.hydration, error: error)
                        }
                    }
                }
            } else {
                AppLogger.info("Already authorized, syncing from HealthKit", category: AppLogger.hydration)
                syncFromHealthKit { _, _ in }
                startObservingHealthKit()
            }
        } else {
            AppLogger.info("Hydration sync disabled, stopping HealthKit observer", category: AppLogger.hydration)
            stopObservingHealthKit()
        }
    }

    private func loadSyncPreference() {
        syncWithHealthKit = userDefaults.bool(forKey: syncPreferenceKey)
    }

    func hasCompletedInitialImport() -> Bool {
        return userDefaults.bool(forKey: hasCompletedInitialImportKey)
    }

    func markInitialImportComplete() {
        userDefaults.set(true, forKey: hasCompletedInitialImportKey)
    }
}
