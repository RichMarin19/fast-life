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
        let metricName: StaticString = days == 7 ? "trend_delta_7" : "trend_delta_30"
        return WeightTrackerMetrics.measure(name: metricName) {
            weightManager.weightChange(since: cutoffDate)
        }
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
            return localized("progress_story_coach_bar_improving", comment: "Coach bar text when improving")
        case .regressing:
            return localized("progress_story_coach_bar_regressing", comment: "Coach bar text when regressing")
        case .flat:
            return localized("progress_story_coach_bar_flat", comment: "Coach bar text when flat")
        }
    }

    func bannerCopy(for state: WeightProgressStoryTrendState) -> WeightProgressStoryBannerCopy {
        switch state {
        case .improving:
            return WeightProgressStoryBannerCopy(
                text: localized("progress_story_banner_improving", comment: "Banner copy when improving"),
                accent: Theme.ColorToken.stateSuccess
            )
        case .regressing:
            return WeightProgressStoryBannerCopy(
                text: localized("progress_story_banner_regressing", comment: "Banner copy when regressing"),
                accent: Theme.ColorToken.stateError
            )
        case .flat:
            return WeightProgressStoryBannerCopy(
                text: localized("progress_story_banner_flat", comment: "Banner copy when flat"),
                accent: Theme.ColorToken.accentInfo
            )
        }
    }

    func randomDidYouKnowTip() -> String {
        let tips = [
            localized("progress_story_tip_1", comment: "Did you know tip 1"),
            localized("progress_story_tip_2", comment: "Did you know tip 2"),
            localized("progress_story_tip_3", comment: "Did you know tip 3"),
            localized("progress_story_tip_4", comment: "Did you know tip 4"),
            localized("progress_story_tip_5", comment: "Did you know tip 5")
        ]
        return tips.randomElement() ?? tips[0]
    }

    func randomReflectionPrompt() -> String {
        let prompts = [
            localized("progress_story_prompt_1", comment: "Reflection prompt 1"),
            localized("progress_story_prompt_2", comment: "Reflection prompt 2"),
            localized("progress_story_prompt_3", comment: "Reflection prompt 3")
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

    private func localized(_ key: String, comment: StaticString) -> String {
        NSLocalizedString(key, bundle: .main, comment: String(describing: comment))
    }
}
