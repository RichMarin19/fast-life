import Foundation
import Combine

class MoodManager: ObservableObject {
    @Published var moodEntries: [MoodEntry] = []

    private let userDefaults = UserDefaults.standard
    private let moodEntriesKey = "moodEntries"

    init() {
        loadMoodEntries()
    }

    // MARK: - Add/Update Entry

    func addMoodEntry(moodLevel: Int, energyLevel: Int, notes: String? = nil) {
        // ROADMAP REQUIREMENT: Clamp ranges for mood and energy levels
        // Following Apple input validation best practices
        // Reference: https://developer.apple.com/documentation/foundation/formatter/creating_a_custom_formatter
        let clampedMood = max(1, min(10, moodLevel))
        let clampedEnergy = max(1, min(10, energyLevel))

        if moodLevel != clampedMood {
            AppLogger.warning("Mood level clamped: \(moodLevel) → \(clampedMood)", category: AppLogger.mood)
        }
        if energyLevel != clampedEnergy {
            AppLogger.warning("Energy level clamped: \(energyLevel) → \(clampedEnergy)", category: AppLogger.mood)
        }

        let entry = MoodEntry(moodLevel: clampedMood, energyLevel: clampedEnergy, notes: notes)

        // ROADMAP REQUIREMENT: Add dedupe guards for entries in the same time window
        // Following Apple duplicate detection pattern similar to HealthKit
        // Reference: https://developer.apple.com/documentation/healthkit/about_the_healthkit_framework
        if isDuplicate(entry: entry, timeWindow: 3600) { // 1 hour window
            AppLogger.warning("Prevented duplicate mood entry within 1 hour", category: AppLogger.mood)
            return
        }

        moodEntries.append(entry)

        // Sort by date (most recent first)
        moodEntries.sort { $0.date > $1.date }

        saveMoodEntries()
        AppLogger.info("Added mood entry: mood=\(clampedMood), energy=\(clampedEnergy)", category: AppLogger.mood)
    }

    // MARK: - Validation Methods
    // Following Apple input validation pattern
    // Reference: https://developer.apple.com/documentation/foundation/numberformatter

    /// Check if a potential mood entry would be a duplicate within time window
    /// Following roadmap requirement for dedupe guards
    private func isDuplicate(entry: MoodEntry, timeWindow: TimeInterval) -> Bool {
        return moodEntries.contains { existingEntry in
            abs(entry.date.timeIntervalSince(existingEntry.date)) < timeWindow
        }
    }

    /// Validate if mood entry can be added (public method for UI validation)
    func canAddMoodEntry(at date: Date = Date()) -> Bool {
        let tempEntry = MoodEntry(date: date, moodLevel: 5, energyLevel: 5, notes: nil)
        return !isDuplicate(entry: tempEntry, timeWindow: 3600)
    }

    /// Get time remaining until next mood entry can be added
    func timeUntilNextEntry() -> TimeInterval? {
        guard let latestEntry = moodEntries.first else { return nil }
        let timeSinceLatest = Date().timeIntervalSince(latestEntry.date)
        let timeWindow: TimeInterval = 3600 // 1 hour
        return timeSinceLatest < timeWindow ? timeWindow - timeSinceLatest : nil
    }

    // MARK: - Delete Entry

    func deleteMoodEntry(_ entry: MoodEntry) {
        moodEntries.removeAll { $0.id == entry.id }
        saveMoodEntries()
    }

    // MARK: - Statistics

    /// Latest mood entry
    var latestEntry: MoodEntry? {
        moodEntries.first
    }

    /// Average mood level over last 7 days
    var averageMoodLevel: Double? {
        guard !moodEntries.isEmpty else { return nil }

        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            AppLogger.logSafetyWarning("Failed to calculate 7 days ago date for average mood")
            return nil
        }

        let recentEntries = moodEntries.filter { $0.date >= sevenDaysAgo }
        guard !recentEntries.isEmpty else { return nil }

        let totalMood = recentEntries.reduce(0) { $0 + $1.moodLevel }
        return Double(totalMood) / Double(recentEntries.count)
    }

    /// Average energy level over last 7 days
    var averageEnergyLevel: Double? {
        guard !moodEntries.isEmpty else { return nil }

        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            AppLogger.logSafetyWarning("Failed to calculate 7 days ago date for average energy")
            return nil
        }

        let recentEntries = moodEntries.filter { $0.date >= sevenDaysAgo }
        guard !recentEntries.isEmpty else { return nil }

        let totalEnergy = recentEntries.reduce(0) { $0 + $1.energyLevel }
        return Double(totalEnergy) / Double(recentEntries.count)
    }

    /// Get entries for a specific date range
    func entriesForRange(days: Int) -> [MoodEntry] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }

        return moodEntries.filter { $0.date >= startDate }
    }

    // MARK: - Persistence

    private func saveMoodEntries() {
        if let encoded = try? JSONEncoder().encode(moodEntries) {
            userDefaults.set(encoded, forKey: moodEntriesKey)
        }
    }

    private func loadMoodEntries() {
        guard let data = userDefaults.data(forKey: moodEntriesKey),
              let entries = try? JSONDecoder().decode([MoodEntry].self, from: data) else {
            return
        }
        moodEntries = entries.sorted { $0.date > $1.date }
    }
}
