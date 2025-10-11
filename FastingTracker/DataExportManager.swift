import Foundation

class DataExportManager {
    static let shared = DataExportManager()

    private init() {}

    // MARK: - CSV Export

    /// Exports all app data to a CSV file and returns the file URL
    /// Returns nil if export fails
    func exportAllDataToCSV() -> URL? {
        print("\n📤 === EXPORT ALL DATA TO CSV ===")

        // Create temporary directory for export
        let tempDir = FileManager.default.temporaryDirectory
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileName = "FastLIFe_Export_\(timestamp).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        print("Export file: \(fileURL.path)")

        // Build CSV content
        var csvContent = ""

        // SECTION 1: Fasting History
        csvContent += "=== FASTING HISTORY ===\n"
        csvContent += "Start Time,End Time,Duration (hours),Goal (hours),Met Goal,Eating Window (hours)\n"

        let fastingHistory = self.loadFastingHistory()
        print("📊 Fasting entries: \(fastingHistory.count)")

        for session in fastingHistory {
            let startTime = self.formatDate(session.startTime)
            let endTime = session.endTime.map { self.formatDate($0) } ?? "Ongoing"
            let duration = String(format: "%.2f", session.duration / 3600)
            let goal = session.goalHours.map { String(format: "%.1f", $0) } ?? "N/A"
            let metGoal = session.metGoal ? "Yes" : "No"
            let eatingWindow = session.eatingWindowDuration.map { String(format: "%.2f", $0 / 3600) } ?? ""

            csvContent += "\"\(startTime)\",\"\(endTime)\",\(duration),\(goal),\(metGoal),\(eatingWindow)\n"
        }

        csvContent += "\n"

        // SECTION 2: Weight Tracking
        csvContent += "=== WEIGHT TRACKING ===\n"
        csvContent += "Date,Weight (lbs),BMI,Body Fat %,Source\n"

        let weightEntries = self.loadWeightEntries()
        print("📊 Weight entries: \(weightEntries.count)")

        for entry in weightEntries {
            let date = self.formatDate(entry.date)
            let weight = String(format: "%.1f", entry.weight)
            let bmi = entry.bmi.map { String(format: "%.1f", $0) } ?? ""
            let bodyFat = entry.bodyFat.map { String(format: "%.1f", $0) } ?? ""
            let source = entry.source.rawValue

            csvContent += "\"\(date)\",\(weight),\(bmi),\(bodyFat),\"\(source)\"\n"
        }

        csvContent += "\n"

        // SECTION 3: Hydration Tracking
        csvContent += "=== HYDRATION TRACKING ===\n"
        csvContent += "Date,Time,Type,Amount (oz)\n"

        let drinkEntries = self.loadDrinkEntries()
        print("📊 Hydration entries: \(drinkEntries.count)")

        for entry in drinkEntries {
            let date = self.formatDate(entry.date, includeTime: false)
            let time = self.formatTime(entry.date)
            let type = entry.type.rawValue.capitalized
            let amount = String(format: "%.1f", entry.amount)

            csvContent += "\"\(date)\",\"\(time)\",\(type),\(amount)\n"
        }

        csvContent += "\n"

        // SECTION 4: Sleep Tracking
        csvContent += "=== SLEEP TRACKING ===\n"
        csvContent += "Bed Time,Wake Time,Duration (hours),Quality (1-5),Source\n"

        let sleepEntries = self.loadSleepEntries()
        print("📊 Sleep entries: \(sleepEntries.count)")

        for entry in sleepEntries {
            let bedTime = self.formatDate(entry.bedTime)
            let wakeTime = self.formatDate(entry.wakeTime)
            let hours = String(format: "%.1f", entry.duration / 3600)
            let quality = entry.quality.map { String($0) } ?? ""
            let source = entry.source.rawValue

            csvContent += "\"\(bedTime)\",\"\(wakeTime)\",\(hours),\(quality),\"\(source)\"\n"
        }

        csvContent += "\n"

        // SECTION 5: Mood & Energy Tracking
        csvContent += "=== MOOD & ENERGY TRACKING ===\n"
        csvContent += "Date,Mood (1-10),Energy (1-10),Notes\n"

        let moodEntries = self.loadMoodEntries()
        print("📊 Mood entries: \(moodEntries.count)")

        for entry in moodEntries {
            let date = self.formatDate(entry.date)
            let mood = String(entry.moodLevel)
            let energy = String(entry.energyLevel)
            let notes = entry.notes?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""

            csvContent += "\"\(date)\",\(mood),\(energy),\"\(notes)\"\n"
        }

        csvContent += "\n"

        // SECTION 6: Statistics Summary
        csvContent += "=== STATISTICS SUMMARY ===\n"
        csvContent += "Metric,Value\n"

        let stats = self.calculateStatistics(
            fastingHistory: fastingHistory,
            weightEntries: weightEntries,
            drinkEntries: drinkEntries,
            sleepEntries: sleepEntries,
            moodEntries: moodEntries
        )

        for (key, value) in stats {
            csvContent += "\"\(key)\",\"\(value)\"\n"
        }

        // Write to file
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ CSV export successful: \(fileURL.lastPathComponent)")
            print("=====================================\n")
            return fileURL
        } catch {
            print("❌ CSV export failed: \(error.localizedDescription)")
            print("=====================================\n")
            return nil
        }
    }

    // MARK: - Data Loading

    private func loadFastingHistory() -> [FastingSession] {
        guard let data = UserDefaults.standard.data(forKey: "fastingHistory"),
              let history = try? JSONDecoder().decode([FastingSession].self, from: data) else {
            return []
        }
        return history.filter(\.isComplete).sorted { $0.startTime > $1.startTime }
    }

    private func loadWeightEntries() -> [WeightEntry] {
        guard let data = UserDefaults.standard.data(forKey: "weightEntries"),
              let entries = try? JSONDecoder().decode([WeightEntry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.date > $1.date }
    }

    private func loadDrinkEntries() -> [DrinkEntry] {
        guard let data = UserDefaults.standard.data(forKey: "drinkEntries"),
              let entries = try? JSONDecoder().decode([DrinkEntry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.date > $1.date }
    }

    private func loadSleepEntries() -> [SleepEntry] {
        guard let data = UserDefaults.standard.data(forKey: "sleepEntries"),
              let entries = try? JSONDecoder().decode([SleepEntry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.bedTime > $1.bedTime }
    }

    private func loadMoodEntries() -> [MoodEntry] {
        guard let data = UserDefaults.standard.data(forKey: "moodEntries"),
              let entries = try? JSONDecoder().decode([MoodEntry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.date > $1.date }
    }

    // MARK: - Statistics Calculation

    private func calculateStatistics(
        fastingHistory: [FastingSession],
        weightEntries: [WeightEntry],
        drinkEntries: [DrinkEntry],
        sleepEntries: [SleepEntry],
        moodEntries: [MoodEntry]
    ) -> [String: String] {
        var stats: [String: String] = [:]

        // Fasting stats
        let totalFasts = fastingHistory.count
        let completedGoals = fastingHistory.filter(\.metGoal).count
        let goalRate = totalFasts > 0 ? Double(completedGoals) / Double(totalFasts) * 100 : 0
        let avgDuration = fastingHistory.isEmpty ? 0 : fastingHistory.map(\.duration)
            .reduce(0, +) / Double(totalFasts) / 3600

        stats["Total Fasts Completed"] = "\(totalFasts)"
        stats["Goals Met"] = "\(completedGoals)"
        stats["Goal Success Rate"] = String(format: "%.1f%%", goalRate)
        stats["Average Fast Duration"] = String(format: "%.1f hours", avgDuration)

        // Current streak
        let currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
        let longestStreak = UserDefaults.standard.integer(forKey: "longestStreak")
        stats["Current Streak"] = "\(currentStreak) days"
        stats["Longest Streak"] = "\(longestStreak) days"

        // Weight stats
        if !weightEntries.isEmpty {
            let startWeight = weightEntries.last!.weight
            let currentWeight = weightEntries.first!.weight
            let weightChange = currentWeight - startWeight
            let changeSign = weightChange >= 0 ? "+" : ""

            stats["Starting Weight"] = String(format: "%.1f lbs", startWeight)
            stats["Current Weight"] = String(format: "%.1f lbs", currentWeight)
            stats["Weight Change"] = String(format: "%@%.1f lbs", changeSign, weightChange)
            stats["Total Weight Entries"] = "\(weightEntries.count)"
        }

        // Hydration stats
        let totalWater = drinkEntries.filter { $0.type == .water }.reduce(0.0) { $0 + $1.amount }
        let totalCoffee = drinkEntries.filter { $0.type == .coffee }.reduce(0.0) { $0 + $1.amount }
        let totalTea = drinkEntries.filter { $0.type == .tea }.reduce(0.0) { $0 + $1.amount }

        stats["Total Water"] = String(format: "%.1f oz", totalWater)
        stats["Total Coffee"] = String(format: "%.1f oz", totalCoffee)
        stats["Total Tea"] = String(format: "%.1f oz", totalTea)

        // Sleep stats
        if !sleepEntries.isEmpty {
            let avgSleep = sleepEntries.map { $0.duration / 3600 }.reduce(0, +) / Double(sleepEntries.count)
            stats["Average Sleep"] = String(format: "%.1f hours", avgSleep)
            stats["Total Sleep Entries"] = "\(sleepEntries.count)"
        }

        // Mood stats
        if !moodEntries.isEmpty {
            let avgMood = Double(moodEntries.map(\.moodLevel).reduce(0, +)) / Double(moodEntries.count)
            let avgEnergy = Double(moodEntries.map(\.energyLevel).reduce(0, +)) / Double(moodEntries.count)
            stats["Average Mood"] = String(format: "%.1f/10", avgMood)
            stats["Average Energy"] = String(format: "%.1f/10", avgEnergy)
            stats["Total Mood Entries"] = "\(moodEntries.count)"
        }

        // Export metadata
        stats["Export Date"] = self.formatDate(Date())
        stats["App Version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

        return stats
    }

    // MARK: - Formatting Helpers

    private func formatDate(_ date: Date, includeTime: Bool = true) -> String {
        let formatter = DateFormatter()
        if includeTime {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        } else {
            formatter.dateFormat = "yyyy-MM-dd"
        }
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
