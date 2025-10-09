import Foundation
import Combine

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

// MARK: - Drink Entry Model

struct DrinkEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let type: DrinkType
    let amount: Double  // in ounces
    let date: Date

    init(id: UUID = UUID(), type: DrinkType, amount: Double, date: Date = Date()) {
        self.id = id
        self.type = type
        self.amount = amount
        self.date = date
    }
}

// MARK: - Hydration Manager

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

    init() {
        loadDrinkEntries()
        loadDailyGoal()
        loadStreak()
        loadLongestStreak()
        // Calculate streaks from history to ensure accuracy
        calculateStreakFromHistory()
    }

    // MARK: - Add Drink Entry

    func addDrinkEntry(_ entry: DrinkEntry) {
        drinkEntries.append(entry)

        // Sort by date (most recent first)
        drinkEntries.sort { $0.date > $1.date }

        saveDrinkEntries()

        // Recalculate streaks after adding entry
        calculateStreakFromHistory()

        // Auto-sync to HealthKit (all drink types sync as water)
        let healthKitManager = HealthKitManager.shared
        if healthKitManager.isWaterAuthorized() {
            healthKitManager.saveWater(amount: entry.amount, date: entry.date) { success, error in
                if let error = error {
                    AppLogger.error("Failed to auto-sync drink to HealthKit", category: AppLogger.hydration, error: error)
                } else if success {
                    AppLogger.info("Synced drink to HealthKit - amount: \(entry.amount)oz", category: AppLogger.hydration)
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
        drinkEntries.removeAll { $0.id == entry.id }
        saveDrinkEntries()

        // Recalculate streaks after deleting entry
        calculateStreakFromHistory()
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

    func syncFromHealthKit(startDate: Date? = nil, completion: (() -> Void)? = nil) {
        let healthKitManager = HealthKitManager.shared

        guard healthKitManager.isAuthorized else {
            AppLogger.warning("HealthKit not authorized for hydration import", category: AppLogger.hydration)
            completion?()
            return
        }

        // Default to last 365 days if no start date provided
        let fromDate = startDate ?? Calendar.current.date(byAdding: .day, value: -365, to: Date())!

        healthKitManager.fetchWaterData(startDate: fromDate) { [weak self] waterData in
            guard let self = self else {
                completion?()
                return
            }

            AppLogger.info("Importing \(waterData.count) water entries from HealthKit", category: AppLogger.hydration)

            // Import water data as "Water" type DrinkEntry
            var importedCount = 0
            for (date, amount) in waterData {
                // Check if we already have an entry for this exact date/amount to avoid duplicates
                let exists = self.drinkEntries.contains { entry in
                    entry.date == date && entry.amount == amount && entry.type == .water
                }

                if !exists {
                    let entry = DrinkEntry(type: .water, amount: amount, date: date)
                    self.drinkEntries.append(entry)
                    importedCount += 1
                }
            }

            if importedCount > 0 {
                AppLogger.info("Successfully imported \(importedCount) new drink entries from HealthKit", category: AppLogger.hydration)
            }

            // Sort and save
            self.drinkEntries.sort { $0.date > $1.date }
            self.saveDrinkEntries()
            self.calculateStreakFromHistory()

            // Call completion on main thread
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
}
