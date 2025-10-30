import SwiftUI

/// ViewModel for Weight Goal Management
/// Handles weight goal input formatting and validation
/// Extracted from WeightControlCenterViewModel as part of Phase 8.9 Phase 2
/// Reference: HANDOFF.md - Weight Tracker Refactoring
@MainActor
class GoalsViewModel: ObservableObject {
    // MARK: - Published State

    /// Current weight goal input string (formatted)
    @Published var weightGoalString: String = ""

    // MARK: - Goal Input Formatting

    /// Format weight goal input to one decimal place, max 999.9
    /// UX/UI Fix #2: Industry standard for health apps
    /// - Parameter input: Raw user input string
    func formatWeightGoalInput(_ input: String) {
        var formatted = input

        // Remove any non-numeric characters except decimal point
        formatted = formatted.filter { $0.isNumber || $0 == "." }

        // Ensure only one decimal point
        let components = formatted.components(separatedBy: ".")
        if components.count > 2 {
            formatted = components[0] + "." + components[1...].joined()
        }

        // Limit to one decimal place
        if let dotIndex = formatted.firstIndex(of: ".") {
            let afterDot = formatted.suffix(from: formatted.index(after: dotIndex))
            if afterDot.count > 1 {
                formatted = String(formatted.prefix(upTo: formatted.index(dotIndex, offsetBy: 2)))
            }
        }

        // FIRST: Limit integer part to 3 digits (for values like "12345" or "12345.5")
        if let dotIndex = formatted.firstIndex(of: ".") {
            let beforeDot = formatted.prefix(upTo: dotIndex)
            if beforeDot.count > 3 {
                formatted = String(beforeDot.prefix(3)) + String(formatted.suffix(from: dotIndex))
            }
        } else {
            if formatted.count > 3 {
                formatted = String(formatted.prefix(3))
            }
        }

        // THEN: Check max value after digit limiting (for values like "999.9" or after limiting)
        let hasDecimal = formatted.contains(".")
        let finalValue = Double(formatted) ?? 0
        if hasDecimal && finalValue > 999.9 {
            formatted = "999.9"
        }

        // Always update to ensure consistent state
        weightGoalString = formatted
    }
}
