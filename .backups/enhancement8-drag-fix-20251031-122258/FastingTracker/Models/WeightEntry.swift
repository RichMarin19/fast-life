import Foundation

struct WeightEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let weight: Double  // in pounds (will convert based on user preference later)
    let bmi: Double?
    let bodyFat: Double?  // percentage
    let source: WeightSource
    let healthKitUUID: UUID?  // For precise HealthKit sample deletion (Apple best practice)

    // Task 1F Enhancement 4: Actual HealthKit source name (e.g., "Renpho Pro", "MyFitnessPal")
    // Industry Pattern: Apple Health displays actual app/device names for transparency
    // Reference: HKSample.sourceRevision.source.name
    let sourceName: String?  // Optional for backward compatibility

    init(id: UUID = UUID(), date: Date, weight: Double, bmi: Double? = nil, bodyFat: Double? = nil, source: WeightSource = .manual, healthKitUUID: UUID? = nil, sourceName: String? = nil) {
        self.id = id
        self.date = date
        self.weight = weight
        self.bmi = bmi
        self.bodyFat = bodyFat
        self.source = source
        self.healthKitUUID = healthKitUUID
        self.sourceName = sourceName
    }
}

enum WeightSource: String, Codable {
    case manual = "Manual Entry"
    case manualEntry = "Manual"        // API compatibility - unique raw value
    case healthKit = "Apple Health"
    case renpho = "Renpho Scale"
    case smartScale = "Smart Scale"    // API compatibility
    case other = "Other Scale"
}
