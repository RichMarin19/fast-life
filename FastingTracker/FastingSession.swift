import Foundation

struct FastingSession: Codable, Identifiable {
    let id: UUID
    var startTime: Date
    var endTime: Date?
    var goalHours: Double?
    var eatingWindowDuration: TimeInterval? // Duration of eating window before this fast (in seconds)

    var duration: TimeInterval {
        guard let end = endTime else {
            // If no end time, return 0 - don't use Date() which causes infinite re-renders
            return 0
        }
        return end.timeIntervalSince(startTime)
    }

    var isComplete: Bool {
        endTime != nil
    }

    var metGoal: Bool {
        let goal = goalHours ?? 16 // Default to 16 hours if not set
        return duration >= goal * 3600
    }

    var eatingWindowHours: Double? {
        guard let eatingWindow = eatingWindowDuration else { return nil }
        return eatingWindow / 3600
    }

    init(id: UUID = UUID(), startTime: Date, endTime: Date? = nil, goalHours: Double? = nil, eatingWindowDuration: TimeInterval? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.goalHours = goalHours
        self.eatingWindowDuration = eatingWindowDuration
    }
}
