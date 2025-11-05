import SwiftUI

enum WeightProgressStoryTrendState {
    case improving
    case regressing
    case flat
}

struct WeightProgressStoryBannerCopy {
    let text: String
    let accent: Color
}

@MainActor
struct WeightProgressStoryMetricsProvider {
    let weightManager: WeightManager

    func delta(days: Int) -> Double? {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return weightManager.weightChange(since: cutoffDate)
    }

    var netDelta30Days: Double {
        delta(days: 30) ?? 0
    }

    var bestStreak: Int {
        // Placeholder until streak logic moves into WeightManager
        weightManager.weightEntries.count
    }

    var totalEntries: Int {
        weightManager.weightEntries.count
    }

    func trendState(for delta: Double) -> WeightProgressStoryTrendState {
        if delta < -0.2 { return .improving }
        if delta > 0.2 { return .regressing }
        return .flat
    }

    func coachBarText(for state: WeightProgressStoryTrendState) -> String {
        switch state {
        case .improving:
            return "Progress in motion — your consistency shows!"
        case .regressing:
            return "Weight gain is feedback, not failure — hydrate and sleep strong!"
        case .flat:
            return "Balance is mastery in motion — keep showing up!"
        }
    }

    func bannerCopy(for state: WeightProgressStoryTrendState) -> WeightProgressStoryBannerCopy {
        switch state {
        case .improving:
            return WeightProgressStoryBannerCopy(
                text: "Small wins compound. Keep stacking the days!",
                accent: Theme.ColorToken.stateSuccess
            )
        case .regressing:
            return WeightProgressStoryBannerCopy(
                text: "Course‑correct today. One choice changes the trend!",
                accent: Theme.ColorToken.stateError
            )
        case .flat:
            return WeightProgressStoryBannerCopy(
                text: "Consistency is power. Nudge your routine by 1%!",
                accent: Theme.ColorToken.accentInfo
            )
        }
    }

    func randomDidYouKnowTip() -> String {
        let tips = [
            "Drinking water before meals can reduce calorie intake.",
            "Sleep loss increases hunger hormones; protect your 7–8 hours.",
            "Protein at your first meal improves satiety for the day.",
            "Consistent weigh-ins help track trends, not daily fluctuations.",
            "Strength training preserves muscle during weight loss."
        ]
        return tips.randomElement() ?? tips[0]
    }

    func randomReflectionPrompt() -> String {
        let prompts = [
            "One small habit to try this week?",
            "What helped most on your best day?",
            "Pick tomorrow's anchor: sleep / steps / water."
        ]
        return prompts.randomElement() ?? prompts[0]
    }

    func trendSummary(for days: Int?) -> (amount: Double, isLoss: Bool)? {
        let cutoffDate: Date
        if let days = days {
            cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        } else {
            cutoffDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
        }

        guard let change = weightManager.weightChange(since: cutoffDate) else { return nil }
        return (amount: abs(change), isLoss: change < 0)
    }
}
