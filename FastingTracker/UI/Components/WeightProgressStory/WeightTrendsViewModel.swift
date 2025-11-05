import SwiftUI

@MainActor
final class WeightTrendsViewModel: ObservableObject {
    // Dependencies
    private let weightManager: WeightManager
    private let optOutManager: ContentOptOutManager
    private let cardManager: CardManager<ProgressStoryCardType>
    let contentIDs = ProgressStoryContentIDs(
        sevenDay: "progress_story_7day_v1",
        thirtyDay: "progress_story_30day_v1",
        banner: "progress_story_banner_v1",
        reflection: "progress_story_reflection_v1",
        recap: "progress_story_recap_v1",
        didYouKnow: "progress_story_tip_v1"
    )
    private let contentIDProgressStory = "progress_story_v1"
    private let contentIDCoachBar = "progress_story_coach_bar_v1"

    // Metrics
    private let metricsProvider: WeightProgressStoryMetricsProvider

    @Published private(set) var sevenDayDelta: Double?
    @Published private(set) var thirtyDayDelta: Double?
    @Published private(set) var trendState7Day: WeightProgressStoryTrendState
    @Published private(set) var bannerCopy: WeightProgressStoryBannerCopy
    @Published private(set) var didYouKnowText: String
    @Published private(set) var reflectionPromptText: String

    init(weightManager: WeightManager) {
        self.weightManager = weightManager
        self.optOutManager = ContentOptOutManager.shared
        self.cardManager = ProgressStoryCards.shared
        self.metricsProvider = WeightProgressStoryMetricsProvider(weightManager: weightManager)

        let delta7 = metricsProvider.delta(days: 7)
        self.sevenDayDelta = delta7
        let state = metricsProvider.trendState(for: delta7 ?? 0)
        self.trendState7Day = state
        self.bannerCopy = metricsProvider.bannerCopy(for: state)
        self.thirtyDayDelta = metricsProvider.delta(days: 30)
        self.didYouKnowText = metricsProvider.randomDidYouKnowTip()
        self.reflectionPromptText = metricsProvider.randomReflectionPrompt()
    }

    func refresh() {
        let delta7 = metricsProvider.delta(days: 7)
        sevenDayDelta = delta7
        let state = metricsProvider.trendState(for: delta7 ?? 0)
        trendState7Day = state
        bannerCopy = metricsProvider.bannerCopy(for: state)
        thirtyDayDelta = metricsProvider.delta(days: 30)
        didYouKnowText = metricsProvider.randomDidYouKnowTip()
        reflectionPromptText = metricsProvider.randomReflectionPrompt()
    }

    var coachBarText: String {
        metricsProvider.coachBarText(for: trendState7Day)
    }

    var isCoachBarVisible: Bool {
        cardManager.isCardVisible(.coachBar) && !optOutManager.isContentOptedOut(id: contentIDCoachBar)
    }

    var reorderableCards: [ProgressStoryCardType] {
        cardManager.getVisibleCardsInOrder().filter { $0 != .coachBar }
    }

    var cardStackOptOutManager: ContentOptOutManager { optOutManager }
    var cardStackManager: CardManager<ProgressStoryCardType> { cardManager }

    func hideCard(_ cardType: ProgressStoryCardType) {
        cardManager.hideCard(cardType)
        if let optOutID = cardType.optOutContentID {
            optOutManager.optOutContent(id: optOutID, category: .progressSummaries, text: cardType.displayName)
        }
    }

    func hideCoachBar() {
        hideCard(.coachBar)
    }

    func optOutProgressStory(onDismiss: @escaping () -> Void) {
        optOutManager.optOutContent(id: contentIDProgressStory, category: .progressSummaries, text: "Your Progress Story")
        onDismiss()
    }

    var shouldShowFooter: Bool {
        metricsProvider.totalEntries >= 1
    }

    var totalEntries: Int {
        metricsProvider.totalEntries
    }

    var bannerContext: WeightProgressStoryBannerCopy {
        WeightProgressStoryBannerCopy(
            text: bannerCopy.text,
            accent: bannerCopy.accent
        )
    }

    var cardContext: ProgressStoryCardContext {
        ProgressStoryCardContext(
            sevenDayDelta: sevenDayDelta,
            thirtyDayDelta: thirtyDayDelta,
            netDelta30d: metricsProvider.netDelta30Days,
            bestStreak: metricsProvider.bestStreak,
            totalEntries: metricsProvider.totalEntries,
            bannerText: bannerCopy.text,
            bannerAccent: bannerCopy.accent,
            didYouKnowText: didYouKnowText,
            reflectionPrompt: reflectionPromptText
        )
    }
}
