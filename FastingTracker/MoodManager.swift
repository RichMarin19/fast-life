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
        let entry = MoodEntry(moodLevel: moodLevel, energyLevel: energyLevel, notes: notes)
        moodEntries.append(entry)

        // Sort by date (most recent first)
        moodEntries.sort { $0.date > $1.date }

        saveMoodEntries()
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
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        let recentEntries = moodEntries.filter { $0.date >= sevenDaysAgo }
        guard !recentEntries.isEmpty else { return nil }

        let totalMood = recentEntries.reduce(0) { $0 + $1.moodLevel }
        return Double(totalMood) / Double(recentEntries.count)
    }

    /// Average energy level over last 7 days
    var averageEnergyLevel: Double? {
        guard !moodEntries.isEmpty else { return nil }

        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

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
