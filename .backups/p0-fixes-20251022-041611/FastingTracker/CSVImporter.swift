import Foundation

// MARK: - CSV Importer
// Handles importing data from CSV files exported by DataExportManager
// Reference: RFC 4180 CSV Format Specification
// Reference: Apple Health's duplicate detection approach

class CSVImporter {
    static let shared = CSVImporter()

    private init() {}

    // MARK: - Public API

    /// Validates CSV file format and returns preview data
    func validateAndPreviewCSV(from url: URL) -> Result<ImportPreview, ImportError> {
        print("\n📥 === VALIDATE & PREVIEW CSV ===")
        print("File: \(url.lastPathComponent)")

        // Request access to security-scoped resource
        // Reference: https://developer.apple.com/documentation/foundation/nsurl/1417051-startaccessingsecurityscopedreso
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ Failed to access file (security-scoped resource)")
            return .failure(.fileReadError)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // Read file contents
        guard let csvContent = try? String(contentsOf: url, encoding: .utf8) else {
            print("❌ Failed to read file")
            return .failure(.fileReadError)
        }

        print("✅ File read successfully (\(csvContent.count) characters)")

        // Parse CSV sections
        guard let sections = parseCSVSections(csvContent) else {
            print("❌ Invalid CSV format")
            return .failure(.invalidFormat)
        }

        print("✅ CSV format valid")

        // Count entries in each section
        let preview = ImportPreview(
            fastingCount: sections.fastingRows.count,
            weightCount: sections.weightRows.count,
            hydrationCount: sections.hydrationRows.count,
            sleepCount: sections.sleepRows.count,
            moodCount: sections.moodRows.count
        )

        print("📊 Preview: \(preview.fastingCount) fasts, \(preview.weightCount) weights, \(preview.hydrationCount) drinks, \(preview.sleepCount) sleeps, \(preview.moodCount) moods")
        print("====================================\n")

        return .success(preview)
    }

    /// Imports data from CSV file (merge mode - skips duplicates)
    func importData(from url: URL) -> Result<ImportResult, ImportError> {
        print("\n📥 === IMPORT DATA FROM CSV ===")
        print("File: \(url.lastPathComponent)")
        print("Mode: Merge (skip duplicates)")

        // Request access to security-scoped resource
        // Reference: https://developer.apple.com/documentation/foundation/nsurl/1417051-startaccessingsecurityscopedreso
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ Failed to access file (security-scoped resource)")
            return .failure(.fileReadError)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // Read file contents
        guard let csvContent = try? String(contentsOf: url, encoding: .utf8) else {
            print("❌ Failed to read file")
            return .failure(.fileReadError)
        }

        // Parse CSV sections
        guard let sections = parseCSVSections(csvContent) else {
            print("❌ Invalid CSV format")
            return .failure(.invalidFormat)
        }

        var result = ImportResult()

        // Import each section
        print("\n📊 Importing sections...")

        result.fastingImported = importFastingSessions(sections.fastingRows, skipped: &result.fastingSkipped)
        result.weightImported = importWeightEntries(sections.weightRows, skipped: &result.weightSkipped)
        result.hydrationImported = importDrinkEntries(sections.hydrationRows, skipped: &result.hydrationSkipped)
        result.sleepImported = importSleepEntries(sections.sleepRows, skipped: &result.sleepSkipped)
        result.moodImported = importMoodEntries(sections.moodRows, skipped: &result.moodSkipped)

        print("\n✅ Import complete!")
        print("📈 Imported: \(result.totalImported) entries")
        print("⏭️  Skipped: \(result.totalSkipped) duplicates")
        print("====================================\n")

        return .success(result)
    }

    // MARK: - CSV Parsing

    private func parseCSVSections(_ content: String) -> CSVSections? {
        var sections = CSVSections()

        let lines = content.components(separatedBy: .newlines)
        var currentSection: String?
        var sectionLines: [String] = []

        for line in lines {
            if line.hasPrefix("===") {
                // Save previous section
                if let section = currentSection, !sectionLines.isEmpty {
                    saveSectionLines(section: section, lines: sectionLines, to: &sections)
                }

                // Start new section
                currentSection = line
                sectionLines = []
            } else if !line.isEmpty && currentSection != nil {
                sectionLines.append(line)
            }
        }

        // Save last section
        if let section = currentSection, !sectionLines.isEmpty {
            saveSectionLines(section: section, lines: sectionLines, to: &sections)
        }

        return sections
    }

    private func saveSectionLines(section: String, lines: [String], to sections: inout CSVSections) {
        if section.contains("FASTING HISTORY") {
            sections.fastingRows = Array(lines.dropFirst()) // Skip header
        } else if section.contains("WEIGHT TRACKING") {
            sections.weightRows = Array(lines.dropFirst())
        } else if section.contains("HYDRATION TRACKING") {
            sections.hydrationRows = Array(lines.dropFirst())
        } else if section.contains("SLEEP TRACKING") {
            sections.sleepRows = Array(lines.dropFirst())
        } else if section.contains("MOOD & ENERGY") {
            sections.moodRows = Array(lines.dropFirst())
        }
    }

    // MARK: - Import Functions

    private func importFastingSessions(_ rows: [String], skipped: inout Int) -> Int {
        print("📊 Importing fasting sessions...")

        guard !rows.isEmpty else { return 0 }

        // Load existing history
        let existing = loadExistingFastingSessions()
        var imported = 0

        for row in rows {
            let fields = parseCSVRow(row)
            guard fields.count >= 5 else { continue }

            // Parse fields: Start Time, End Time, Duration, Goal, Met Goal, Eating Window
            guard let startTime = parseDate(fields[0]),
                  let endTime = parseDate(fields[1]),
                  let goalHours = Double(fields[3]) else {
                continue
            }

            // Check for duplicates (within 60 seconds of start time)
            if isDuplicate(startTime: startTime, in: existing) {
                skipped += 1
                continue
            }

            // Parse eating window if present
            var eatingWindowDuration: TimeInterval?
            if fields.count > 5, !fields[5].isEmpty {
                if let hours = Double(fields[5]) {
                    eatingWindowDuration = hours * 3600
                }
            }

            // Create session
            let session = FastingSession(
                startTime: startTime,
                endTime: endTime,
                goalHours: goalHours,
                eatingWindowDuration: eatingWindowDuration
            )

            // Add to history
            addFastingSession(session)
            imported += 1
        }

        print("✅ Fasting: \(imported) imported, \(skipped) skipped")
        return imported
    }

    private func importWeightEntries(_ rows: [String], skipped: inout Int) -> Int {
        print("📊 Importing weight entries...")

        guard !rows.isEmpty else { return 0 }

        let existing = loadExistingWeightEntries()
        var imported = 0

        for row in rows {
            let fields = parseCSVRow(row)
            guard fields.count >= 2 else { continue }

            guard let date = parseDate(fields[0]),
                  let weight = Double(fields[1]) else {
                continue
            }

            // Check duplicates
            if isDuplicate(date: date, in: existing) {
                skipped += 1
                continue
            }

            let bmi = Double(fields[2])
            let bodyFat = Double(fields[3])

            let entry = WeightEntry(
                date: date,
                weight: weight,
                bmi: bmi,
                bodyFat: bodyFat,
                source: .manual
            )

            addWeightEntry(entry)
            imported += 1
        }

        print("✅ Weight: \(imported) imported, \(skipped) skipped")
        return imported
    }

    private func importDrinkEntries(_ rows: [String], skipped: inout Int) -> Int {
        print("📊 Importing hydration entries...")

        guard !rows.isEmpty else { return 0 }

        let existing = loadExistingDrinkEntries()
        var imported = 0

        for row in rows {
            let fields = parseCSVRow(row)
            guard fields.count >= 4 else { continue }

            // Parse date + time
            let dateStr = fields[0] + " " + fields[1]
            guard let date = parseDate(dateStr),
                  let amount = Double(fields[3]) else {
                continue
            }

            // Check duplicates
            if isDuplicate(date: date, in: existing) {
                skipped += 1
                continue
            }

            let typeStr = fields[2].lowercased()
            let type: DrinkType = typeStr == "water" ? .water : (typeStr == "coffee" ? .coffee : .tea)

            let entry = DrinkEntry(
                type: type,
                amount: amount,
                date: date
            )

            addDrinkEntry(entry)
            imported += 1
        }

        print("✅ Hydration: \(imported) imported, \(skipped) skipped")
        return imported
    }

    private func importSleepEntries(_ rows: [String], skipped: inout Int) -> Int {
        print("📊 Importing sleep entries...")

        guard !rows.isEmpty else { return 0 }

        let existing = loadExistingSleepEntries()
        var imported = 0

        for row in rows {
            let fields = parseCSVRow(row)
            guard fields.count >= 2 else { continue }

            guard let bedTime = parseDate(fields[0]),
                  let wakeTime = parseDate(fields[1]) else {
                continue
            }

            // Check duplicates
            if isDuplicate(bedTime: bedTime, in: existing) {
                skipped += 1
                continue
            }

            let quality = Int(fields[3])

            let entry = SleepEntry(
                bedTime: bedTime,
                wakeTime: wakeTime,
                quality: quality,
                source: .manual
            )

            addSleepEntry(entry)
            imported += 1
        }

        print("✅ Sleep: \(imported) imported, \(skipped) skipped")
        return imported
    }

    private func importMoodEntries(_ rows: [String], skipped: inout Int) -> Int {
        print("📊 Importing mood entries...")

        guard !rows.isEmpty else { return 0 }

        let existing = loadExistingMoodEntries()
        var imported = 0

        for row in rows {
            let fields = parseCSVRow(row)
            guard fields.count >= 3 else { continue }

            guard let date = parseDate(fields[0]),
                  let moodLevel = Int(fields[1]),
                  let energyLevel = Int(fields[2]) else {
                continue
            }

            // Check duplicates
            if isDuplicate(date: date, in: existing) {
                skipped += 1
                continue
            }

            let notes = fields.count > 3 ? fields[3] : nil

            let entry = MoodEntry(
                date: date,
                moodLevel: moodLevel,
                energyLevel: energyLevel,
                notes: notes
            )

            addMoodEntry(entry)
            imported += 1
        }

        print("✅ Mood: \(imported) imported, \(skipped) skipped")
        return imported
    }

    // MARK: - Duplicate Detection
    // Reference: Apple Health duplicate detection (60-second window)

    private func isDuplicate(startTime: Date, in sessions: [FastingSession]) -> Bool {
        return sessions.contains { session in
            let timeDiff = abs(session.startTime.timeIntervalSince(startTime))
            return timeDiff < 60 // Within 60 seconds = duplicate
        }
    }

    private func isDuplicate(date: Date, in entries: [WeightEntry]) -> Bool {
        return entries.contains { entry in
            let timeDiff = abs(entry.date.timeIntervalSince(date))
            return timeDiff < 60
        }
    }

    private func isDuplicate(date: Date, in entries: [DrinkEntry]) -> Bool {
        return entries.contains { entry in
            let timeDiff = abs(entry.date.timeIntervalSince(date))
            return timeDiff < 60
        }
    }

    private func isDuplicate(bedTime: Date, in entries: [SleepEntry]) -> Bool {
        return entries.contains { entry in
            let timeDiff = abs(entry.bedTime.timeIntervalSince(bedTime))
            return timeDiff < 60
        }
    }

    private func isDuplicate(date: Date, in entries: [MoodEntry]) -> Bool {
        return entries.contains { entry in
            let timeDiff = abs(entry.date.timeIntervalSince(date))
            return timeDiff < 60
        }
    }

    // MARK: - Helper Functions

    /// Parses CSV row handling quoted fields
    /// Reference: RFC 4180 - CSV Format Specification
    private func parseCSVRow(_ row: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }

        fields.append(currentField.trimmingCharacters(in: .whitespaces))
        return fields
    }

    /// Parses date from string (yyyy-MM-dd HH:mm:ss format)
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: dateString)
    }

    // MARK: - Data Loading Functions

    private func loadExistingFastingSessions() -> [FastingSession] {
        guard let data = UserDefaults.standard.data(forKey: "fastingHistory"),
              let sessions = try? JSONDecoder().decode([FastingSession].self, from: data) else {
            return []
        }
        return sessions
    }

    private func loadExistingWeightEntries() -> [WeightEntry] {
        guard let data = UserDefaults.standard.data(forKey: "weightEntries"),
              let entries = try? JSONDecoder().decode([WeightEntry].self, from: data) else {
            return []
        }
        return entries
    }

    private func loadExistingDrinkEntries() -> [DrinkEntry] {
        guard let data = UserDefaults.standard.data(forKey: "drinkEntries"),
              let entries = try? JSONDecoder().decode([DrinkEntry].self, from: data) else {
            return []
        }
        return entries
    }

    private func loadExistingSleepEntries() -> [SleepEntry] {
        guard let data = UserDefaults.standard.data(forKey: "sleepEntries"),
              let entries = try? JSONDecoder().decode([SleepEntry].self, from: data) else {
            return []
        }
        return entries
    }

    private func loadExistingMoodEntries() -> [MoodEntry] {
        guard let data = UserDefaults.standard.data(forKey: "moodEntries"),
              let entries = try? JSONDecoder().decode([MoodEntry].self, from: data) else {
            return []
        }
        return entries
    }

    // MARK: - Data Saving Functions

    private func addFastingSession(_ session: FastingSession) {
        var history = loadExistingFastingSessions()
        history.append(session)
        history.sort { $0.startTime > $1.startTime }

        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "fastingHistory")
        }
    }

    private func addWeightEntry(_ entry: WeightEntry) {
        var entries = loadExistingWeightEntries()
        entries.append(entry)
        entries.sort { $0.date > $1.date }

        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "weightEntries")
        }
    }

    private func addDrinkEntry(_ entry: DrinkEntry) {
        var entries = loadExistingDrinkEntries()
        entries.append(entry)
        entries.sort { $0.date > $1.date }

        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "drinkEntries")
        }
    }

    private func addSleepEntry(_ entry: SleepEntry) {
        var entries = loadExistingSleepEntries()
        entries.append(entry)
        entries.sort { $0.bedTime > $1.bedTime }

        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "sleepEntries")
        }
    }

    private func addMoodEntry(_ entry: MoodEntry) {
        var entries = loadExistingMoodEntries()
        entries.append(entry)
        entries.sort { $0.date > $1.date }

        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "moodEntries")
        }
    }
}

// MARK: - Supporting Types

struct CSVSections {
    var fastingRows: [String] = []
    var weightRows: [String] = []
    var hydrationRows: [String] = []
    var sleepRows: [String] = []
    var moodRows: [String] = []
}

struct ImportPreview {
    let fastingCount: Int
    let weightCount: Int
    let hydrationCount: Int
    let sleepCount: Int
    let moodCount: Int

    var totalCount: Int {
        fastingCount + weightCount + hydrationCount + sleepCount + moodCount
    }
}

struct ImportResult {
    var fastingImported = 0
    var fastingSkipped = 0
    var weightImported = 0
    var weightSkipped = 0
    var hydrationImported = 0
    var hydrationSkipped = 0
    var sleepImported = 0
    var sleepSkipped = 0
    var moodImported = 0
    var moodSkipped = 0

    var totalImported: Int {
        fastingImported + weightImported + hydrationImported + sleepImported + moodImported
    }

    var totalSkipped: Int {
        fastingSkipped + weightSkipped + hydrationSkipped + sleepSkipped + moodSkipped
    }
}

enum ImportError: Error, LocalizedError {
    case fileReadError
    case invalidFormat
    case corruptedData

    var errorDescription: String? {
        switch self {
        case .fileReadError:
            return "Failed to read CSV file. Please check file permissions."
        case .invalidFormat:
            return "Invalid CSV format. Please use a file exported from Fast LIFe."
        case .corruptedData:
            return "CSV file contains corrupted data. Some entries may be incomplete."
        }
    }
}
