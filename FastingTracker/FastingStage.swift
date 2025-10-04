import Foundation

/// Model representing a stage in the fasting timeline
/// Educational content based on metabolic changes during fasting
/// Per Apple HIG: Provide context to help users understand app functionality
/// Reference: https://developer.apple.com/design/human-interface-guidelines/help
struct FastingStage: Identifiable {
    let id = UUID()
    let hourRange: String
    let title: String
    let icon: String
    let description: [String]
    let didYouKnow: String
    let startHour: Int
    let endHour: Int

    /// Returns all fasting stages with educational content
    static let all: [FastingStage] = [
        FastingStage(
            hourRange: "0-4",
            title: "Fed State",
            icon: "🍽️",
            description: [
                "Your body is digesting the last meal.",
                "Blood sugar and insulin are higher, giving energy to cells."
            ],
            didYouKnow: "Most of the calories you just ate are being used right now for energy!",
            startHour: 0,
            endHour: 4
        ),
        FastingStage(
            hourRange: "4-8",
            title: "Post-Absorptive State",
            icon: "🔄",
            description: [
                "Insulin starts to drop.",
                "Your body shifts from burning mostly carbs to mixing in some fat."
            ],
            didYouKnow: "Around now, your body begins dipping into stored fat for energy.",
            startHour: 4,
            endHour: 8
        ),
        FastingStage(
            hourRange: "8-12",
            title: "Early Fasting",
            icon: "⚡",
            description: [
                "Liver glycogen (stored sugar) is running low.",
                "Fat breakdown ramps up, releasing fatty acids."
            ],
            didYouKnow: "Your body is learning to run more on fat instead of sugar right now.",
            startHour: 8,
            endHour: 12
        ),
        FastingStage(
            hourRange: "12-16",
            title: "Fat-Burning Mode",
            icon: "🔥",
            description: [
                "Insulin stays low, fat is the main fuel.",
                "Small amounts of ketones (from fat) start appearing."
            ],
            didYouKnow: "Your brain is starting to get fuel from ketones, a clean-burning energy source!",
            startHour: 12,
            endHour: 16
        ),
        FastingStage(
            hourRange: "16-20",
            title: "Ketone Production Rises",
            icon: "🧠",
            description: [
                "Fat burning is steady.",
                "Ketones increase, mental clarity often improves."
            ],
            didYouKnow: "Many fasters feel sharper focus around this time thanks to ketones.",
            startHour: 16,
            endHour: 20
        ),
        FastingStage(
            hourRange: "20-24",
            title: "Deeper Fasting",
            icon: "💪",
            description: [
                "Growth hormone rises (helps protect muscle).",
                "Cells begin mild autophagy (cell cleanup)."
            ],
            didYouKnow: "Your body is starting its spring-cleaning process—removing damaged cell parts!",
            startHour: 20,
            endHour: 24
        ),
        FastingStage(
            hourRange: "24-36",
            title: "Strong Metabolic Shift",
            icon: "🧬",
            description: [
                "Glycogen stores are mostly gone.",
                "Ketones are a major fuel, autophagy continues."
            ],
            didYouKnow: "At this point, fat is your body's main energy source.",
            startHour: 24,
            endHour: 36
        ),
        FastingStage(
            hourRange: "36-48",
            title: "Deep Autophagy + Repair",
            icon: "🔬",
            description: [
                "Cell cleanup and repair ramp up.",
                "Inflammation lowers, immune system refreshes."
            ],
            didYouKnow: "Your immune cells are being renewed during this stage.",
            startHour: 36,
            endHour: 48
        ),
        FastingStage(
            hourRange: "48+",
            title: "Prolonged Fast Territory",
            icon: "⭐",
            description: [
                "Deeper autophagy, stem cells activate, insulin sensitivity improves."
            ],
            didYouKnow: "Long fasts trigger powerful repair—but should be supervised if extended.",
            startHour: 48,
            endHour: 999
        )
    ]

    /// Returns stages relevant to the user's fasting goal
    /// - Parameter goalHours: User's fasting goal in hours
    /// - Returns: Array of stages up to and including the goal
    static func relevantStages(for goalHours: Double) -> [FastingStage] {
        return all.filter { $0.startHour < Int(goalHours) + 4 }
    }
}
