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
                    print("Failed to auto-sync drink to HealthKit: \(error.localizedDescription)")
                } else if success {
                    print("Successfully synced drink to HealthKit as water: \(entry.amount)oz")
                }
            }
        }
    }

    func addDrink(type: DrinkType, amount: Double? = nil) {
        let drinkAmount = amount ?? type.standardServing
        let entry = DrinkEntry(type: type, amount: drinkAmount)
        addDrinkEntry(entry)
    }

    // MARK: - Delete Drink Entry

    func deleteDrinkEntry(_ entry: DrinkEntry) {
        drinkEntries.removeAll { $0.id == entry.id }
        saveDrinkEntries()

        // Recalculate streaks after deleting entry
        calculateStreakFromHistory()
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
            print("HealthKit not authorized for water - cannot sync hydration")
            return
        }

        print("Starting hydration sync to HealthKit - \(drinkEntries.count) total drinks")

        // Sync all drink entries to HealthKit as water
        var syncedCount = 0
        for entry in drinkEntries {
            healthKitManager.saveWater(amount: entry.amount, date: entry.date) { success, error in
                if let error = error {
                    print("Failed to sync drink to HealthKit: \(error.localizedDescription)")
                } else if success {
                    syncedCount += 1
                }
            }
        }

        print("Completed hydration sync attempt for \(drinkEntries.count) drinks")
    }

    func syncFromHealthKit(startDate: Date? = nil, completion: (() -> Void)? = nil) {
        let healthKitManager = HealthKitManager.shared

        guard healthKitManager.isAuthorized else {
            print("HealthKit not authorized for hydration import")
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

            print("Importing \(waterData.count) water entries from HealthKit")

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

            print("Successfully imported \(importedCount) new drink entries from HealthKit")

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
