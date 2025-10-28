import Foundation
import SwiftUI

// MARK: - Data Source Enum for Mood Tracking
enum MoodDataSource: String, Codable, CaseIterable {
    case manual = "Manual"
    case healthKit = "HealthKit"
}

struct MoodEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let moodLevel: Int      // 1-10 scale
    let energyLevel: Int    // 1-10 scale
    let notes: String?
    let source: MoodDataSource

    init(id: UUID = UUID(), date: Date = Date(), moodLevel: Int, energyLevel: Int, notes: String? = nil, source: MoodDataSource = .manual) {
        self.id = id
        self.date = date
        self.moodLevel = max(1, min(10, moodLevel))  // Clamp to 1-10
        self.energyLevel = max(1, min(10, energyLevel))
        self.notes = notes
        self.source = source
    }

    // MARK: - Description Helpers

    var moodDescription: String {
        switch moodLevel {
        case 1...2: return "Very Low"
        case 3...4: return "Low"
        case 5...6: return "Moderate"
        case 7...8: return "Good"
        case 9...10: return "Excellent"
        default: return "Unknown"
        }
    }

    var energyDescription: String {
        switch energyLevel {
        case 1...2: return "Exhausted"
        case 3...4: return "Low"
        case 5...6: return "Moderate"
        case 7...8: return "Energized"
        case 9...10: return "Highly Energized"
        default: return "Unknown"
        }
    }

    // MARK: - Visual Helpers

    var moodEmoji: String {
        switch moodLevel {
        case 1...2: return "😢"
        case 3...4: return "😕"
        case 5...6: return "😐"
        case 7...8: return "🙂"
        case 9...10: return "😄"
        default: return "😐"
        }
    }

    var energyEmoji: String {
        switch energyLevel {
        case 1...2: return "🔋"
        case 3...4: return "🪫"
        case 5...6: return "⚡"
        case 7...8: return "⚡⚡"
        case 9...10: return "⚡⚡⚡"
        default: return "⚡"
        }
    }

    var moodColor: Color {
        switch moodLevel {
        case 1...3: return .red
        case 4...6: return .orange
        case 7...8: return .yellow
        case 9...10: return .green
        default: return .gray
        }
    }

    var energyColor: Color {
        switch energyLevel {
        case 1...3: return .red
        case 4...6: return .orange
        case 7...8: return .blue
        case 9...10: return .green
        default: return .gray
        }
    }
}
