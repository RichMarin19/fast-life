import SwiftUI
@testable import FastLIFe

@MainActor
final class MockWeightProgressStoryMetricsProvider: WeightProgressStoryMetricsProviding {
    var deltaResults: [Int: Double?] = [:]
    var netDelta30DaysValue: Double = 0
    var bestStreakValue: Int = 0
    var totalEntriesValue: Int = 0
    var trendStateResult: WeightProgressStoryTrendState = .flat
    var coachBarTextResult: String = "Coach"
    var bannerCopyResult = WeightProgressStoryBannerCopy(text: "Banner", accent: .blue)
    var didYouKnowText: String = "Tip"
    var reflectionPromptText: String = "Prompt"
    var trendSummaryResult: (amount: Double, isLoss: Bool)?

    func delta(days: Int) -> Double? {
        deltaResults[days] ?? nil
    }

    var netDelta30Days: Double { netDelta30DaysValue }
    var bestStreak: Int { bestStreakValue }
    var totalEntries: Int { totalEntriesValue }

    func trendState(for delta: Double) -> WeightProgressStoryTrendState {
        trendStateResult
    }

    func coachBarText(for state: WeightProgressStoryTrendState) -> String {
        coachBarTextResult
    }

    func bannerCopy(for state: WeightProgressStoryTrendState) -> WeightProgressStoryBannerCopy {
        bannerCopyResult
    }

    func randomDidYouKnowTip() -> String {
        didYouKnowText
    }

    func randomReflectionPrompt() -> String {
        reflectionPromptText
    }

    func trendSummary(for days: Int?) -> (amount: Double, isLoss: Bool)? {
        trendSummaryResult
    }
}
