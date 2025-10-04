import Foundation

/// Represents a single sleep session entry
struct SleepEntry: Codable, Identifiable {
    let id: UUID
    let bedTime: Date          // When user went to bed
    let wakeTime: Date         // When user woke up
    let quality: Int?          // Optional sleep quality rating (1-5)
    let source: SleepSource

    /// Calculated sleep duration in hours
    var duration: TimeInterval {
        wakeTime.timeIntervalSince(bedTime)
    }

    /// Formatted duration string (e.g., "7h 30m")
    var formattedDuration: String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }

    init(id: UUID = UUID(), bedTime: Date, wakeTime: Date, quality: Int? = nil, source: SleepSource = .manual) {
        self.id = id
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.quality = quality
        self.source = source
    }
}

/// Source of sleep data entry
enum SleepSource: String, Codable {
    case manual = "Manual Entry"
    case healthKit = "Apple Health"
    case appleWatch = "Apple Watch"
    case other = "Other Device"
}
