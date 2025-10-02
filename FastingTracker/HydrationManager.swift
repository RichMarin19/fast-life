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

    private let userDefaults = UserDefaults.standard
    private let drinkEntriesKey = "drinkEntries"
    private let dailyGoalKey = "dailyHydrationGoal"

    init() {
        loadDrinkEntries()
        loadDailyGoal()
    }

    // MARK: - Add Drink Entry

    func addDrinkEntry(_ entry: DrinkEntry) {
        drinkEntries.append(entry)

        // Sort by date (most recent first)
        drinkEntries.sort { $0.date > $1.date }

        saveDrinkEntries()
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
}
