import Foundation

struct WeightEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let weight: Double // in pounds (will convert based on user preference later)
    let bmi: Double?
    let bodyFat: Double? // percentage
    let source: WeightSource
    let healthKitUUID: UUID? // For precise HealthKit sample deletion (Apple best practice)

    init(
        id: UUID = UUID(),
        date: Date,
        weight: Double,
        bmi: Double? = nil,
        bodyFat: Double? = nil,
        source: WeightSource = .manual,
        healthKitUUID: UUID? = nil
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.bmi = bmi
        self.bodyFat = bodyFat
        self.source = source
        self.healthKitUUID = healthKitUUID
    }
}

enum WeightSource: String, Codable {
    case manual = "Manual Entry"
    case healthKit = "Apple Health"
    case renpho = "Renpho Scale"
    case other = "Other Scale"
}
