import Foundation

// MARK: - Data Source Enum for Fasting Tracking

enum FastingDataSource: String, Codable, CaseIterable {
    case manual = "Manual"
    case healthKit = "HealthKit"
}

struct FastingSession: Codable, Identifiable {
    let id: UUID
    var startTime: Date
    var endTime: Date?
    var goalHours: Double?
    var eatingWindowDuration: TimeInterval? // Duration of eating window before this fast (in seconds)
    var source: FastingDataSource

    var duration: TimeInterval {
        guard let end = endTime else {
            // If no end time, return 0 - don't use Date() which causes infinite re-renders
            return 0
        }
        return end.timeIntervalSince(self.startTime)
    }

    var isComplete: Bool {
        self.endTime != nil
    }

    var metGoal: Bool {
        let goal = self.goalHours ?? 16 // Default to 16 hours if not set
        return self.duration >= goal * 3600
    }

    var eatingWindowHours: Double? {
        guard let eatingWindow = eatingWindowDuration else { return nil }
        return eatingWindow / 3600
    }

    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        goalHours: Double? = nil,
        eatingWindowDuration: TimeInterval? = nil,
        source: FastingDataSource = .manual
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.goalHours = goalHours
        self.eatingWindowDuration = eatingWindowDuration
        self.source = source
    }
}
