import Foundation

/// Represents a single sleep session entry with detailed sleep stage analysis
/// Following Apple HealthKit Programming Guide for HKCategoryValueSleepAnalysis
struct SleepEntry: Codable, Identifiable {
    let id: UUID
    let bedTime: Date // When user went to bed
    let wakeTime: Date // When user woke up
    let quality: Int? // Optional sleep quality rating (1-5)
    let source: SleepSource
    let stages: [SleepStage] // Detailed sleep stage data (Apple Health style)

    /// Calculated sleep duration in hours
    var duration: TimeInterval {
        self.wakeTime.timeIntervalSince(self.bedTime)
    }

    /// Formatted duration string (e.g., "7h 30m")
    var formattedDuration: String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }

    /// Calculate total time spent in each sleep stage
    /// Following Apple Health pattern for stage breakdown
    var stageDurations: StageDurations {
        var awake: TimeInterval = 0
        var rem: TimeInterval = 0
        var core: TimeInterval = 0
        var deep: TimeInterval = 0

        for stage in self.stages {
            let duration = stage.endTime.timeIntervalSince(stage.startTime)
            switch stage.type {
            case .awake:
                awake += duration
            case .rem:
                rem += duration
            case .core:
                core += duration
            case .deep:
                deep += duration
            case .inBed:
                // In bed time is not counted in sleep stages
                break
            }
        }

        return StageDurations(awake: awake, rem: rem, core: core, deep: deep)
    }

    init(
        id: UUID = UUID(),
        bedTime: Date,
        wakeTime: Date,
        quality: Int? = nil,
        source: SleepSource = .manual,
        stages: [SleepStage] = []
    ) {
        self.id = id
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.quality = quality
        self.source = source
        self.stages = stages
    }
}

/// Represents a single sleep stage segment within a sleep session
/// Following Apple HealthKit HKCategoryValueSleepAnalysis values
struct SleepStage: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let type: SleepStageType

    var duration: TimeInterval {
        self.endTime.timeIntervalSince(self.startTime)
    }

    init(id: UUID = UUID(), startTime: Date, endTime: Date, type: SleepStageType) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.type = type
    }
}

/// Sleep stage types matching Apple HealthKit HKCategoryValueSleepAnalysis
/// Reference: https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis
enum SleepStageType: String, Codable, CaseIterable {
    case inBed = "In Bed" // HKCategoryValueSleepAnalysis.inBed
    case awake = "Awake" // HKCategoryValueSleepAnalysis.awake
    case core = "Core" // HKCategoryValueSleepAnalysis.asleepCore
    case deep = "Deep" // HKCategoryValueSleepAnalysis.asleepDeep
    case rem = "REM" // HKCategoryValueSleepAnalysis.asleepREM

    /// Color for timeline visualization (Apple Health style)
    var color: String {
        switch self {
        case .inBed: return "gray"
        case .awake: return "orange"
        case .core: return "blue"
        case .deep: return "darkBlue"
        case .rem: return "lightBlue"
        }
    }
}

/// Stage duration summary for display (Apple Health pattern)
struct StageDurations: Codable {
    let awake: TimeInterval
    let rem: TimeInterval
    let core: TimeInterval
    let deep: TimeInterval

    /// Format duration for display (e.g., "1h 29m")
    func formatted(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

/// Source of sleep data entry
enum SleepSource: String, Codable {
    case manual = "Manual Entry"
    case healthKit = "Apple Health"
    case appleWatch = "Apple Watch"
    case other = "Other Device"
}
