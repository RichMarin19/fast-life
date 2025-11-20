import SwiftUI
import Combine

@MainActor
final class WeightTrendsViewModel: ObservableObject {
    struct Dependencies {
        let weightManager: WeightManager
        let optOutManager: ContentOptOutManaging
        let cardManager: ProgressStoryCardManaging
        let metricsProvider: WeightProgressStoryMetricsProviding
        let measurementObserver: MeasurementSystemObserver
    }

    // Dependencies
    private let weightManager: WeightManager
    private let optOutManager: ContentOptOutManaging
    private let cardManager: ProgressStoryCardManaging
    private let measurementObserver: MeasurementSystemObserver
    let contentIDs = ProgressStoryContentIDs(
        trendSnapshot: "progress_story_trend_snapshot_v1",
        trendSnapshotLegacyIDs: ["progress_story_7day_v1", "progress_story_30day_v1"],
        banner: "progress_story_banner_v1",
        reflection: "progress_story_reflection_v1",
        recap: "progress_story_recap_v1",
        didYouKnow: "progress_story_tip_v1"
    )
    private let contentIDProgressStory = "progress_story_v1"
    private let contentIDCoachBar = "progress_story_coach_bar_v1"

    // Metrics
    private let metricsProvider: WeightProgressStoryMetricsProviding

    @Published private(set) var sevenDayDelta: Double?
    @Published private(set) var thirtyDayDelta: Double?
    @Published private(set) var trendState7Day: WeightProgressStoryTrendState
    @Published private(set) var bannerCopy: WeightProgressStoryBannerCopy
    @Published private(set) var didYouKnowText: String
    @Published private(set) var reflectionPromptText: String
    private var cancellables = Set<AnyCancellable>()

    init(dependencies: Dependencies) {
        self.weightManager = dependencies.weightManager
        self.optOutManager = dependencies.optOutManager
        self.cardManager = dependencies.cardManager
        self.metricsProvider = dependencies.metricsProvider
        self.measurementObserver = dependencies.measurementObserver

        let delta7 = self.metricsProvider.delta(days: 7)
        self.sevenDayDelta = delta7
        let state = self.metricsProvider.trendState(for: delta7 ?? 0)
        self.trendState7Day = state
        self.bannerCopy = self.metricsProvider.bannerCopy(for: state)
        self.thirtyDayDelta = self.metricsProvider.delta(days: 30)
        self.didYouKnowText = self.metricsProvider.randomDidYouKnowTip()
        self.reflectionPromptText = self.metricsProvider.randomReflectionPrompt()
        recordTrendSnapshotTelemetry(delta7: self.sevenDayDelta, delta30: self.thirtyDayDelta, state: state)
        restoreBannerIfHiddenByDefault()
        restoreDidYouKnowIfHiddenByDefault()

        self.cardManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        self.optOutManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        dependencies.measurementObserver.$system
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleMeasurementSystemDidChange()
            }
            .store(in: &cancellables)
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
        recordTrendSnapshotTelemetry(delta7: sevenDayDelta, delta30: thirtyDayDelta, state: state)
    }

    var coachBarText: String {
        metricsProvider.coachBarText(for: trendState7Day)
    }

    var isCoachBarVisible: Bool {
        cardManager.isCardVisible(.coachBar) && !optOutManager.isContentOptedOut(id: contentIDCoachBar)
    }

    var visibleCards: [ProgressStoryCardType] {
        reorderableCards.filter { shouldDisplayCard($0) }
    }

    private var reorderableCards: [ProgressStoryCardType] {
        cardManager.getVisibleCardsInOrder().filter { $0 != .coachBar }
    }

    private func shouldDisplayCard(_ cardType: ProgressStoryCardType) -> Bool {
        switch cardType {
        case .trendSnapshot:
            if optOutManager.isContentOptedOut(id: contentIDs.trendSnapshot) {
                return false
            }
            for legacyID in contentIDs.trendSnapshotLegacyIDs {
                if optOutManager.isContentOptedOut(id: legacyID) {
                    return false
                }
            }
            return true
        case .banner:
            return !optOutManager.isContentOptedOut(id: contentIDs.banner)
        case .reflection:
            return !optOutManager.isContentOptedOut(id: contentIDs.reflection)
        case .didYouKnow:
            return !optOutManager.isContentOptedOut(id: contentIDs.didYouKnow)
        case .coachBar:
            return false
        }
    }

    func hideCard(_ cardType: ProgressStoryCardType) {
        cardManager.hideCard(cardType)
        if let optOutID = cardType.optOutContentID {
            optOutManager.optOutContent(id: optOutID, category: .progressSummaries, text: cardType.displayName)
        }
        WeightTrackerMetrics.recordProgressStoryEvent(
            .cardHidden,
            metadata: ["card": cardType.rawValue]
        )
    }

    func hideCoachBar() {
        hideCard(.coachBar)
    }

    func reorderCard(_ draggedCard: ProgressStoryCardType, before destinationCard: ProgressStoryCardType) {
        guard draggedCard != destinationCard else { return }

        let sortedPreferences = cardManager.cardPreferences.sorted { $0.sortOrder < $1.sortOrder }

        guard let sourceIndex = sortedPreferences.firstIndex(where: { $0.id == draggedCard.rawValue }),
              let destinationIndex = sortedPreferences.firstIndex(where: { $0.id == destinationCard.rawValue }) else {
            return
        }

        cardManager.reorderCards(from: sourceIndex, to: destinationIndex)
        WeightTrackerMetrics.recordProgressStoryEvent(
            .cardReordered,
            metadata: [
                "card": draggedCard.rawValue,
                "before": destinationCard.rawValue
            ]
        )
    }

    func optOutProgressStory(onDismiss: @escaping () -> Void) {
        optOutManager.optOutContent(id: contentIDProgressStory, category: .progressSummaries, text: "Your Progress Story")
        onDismiss()
        WeightTrackerMetrics.recordProgressStoryEvent(.stackOptedOut)
    }

    var bannerContext: WeightProgressStoryBannerCopy {
        WeightProgressStoryBannerCopy(
            text: bannerCopy.text,
            accent: bannerCopy.accent
        )
    }

    var shouldShowFooter: Bool {
        metricsProvider.totalEntries >= 1
    }

    var cardContext: ProgressStoryCardContext {
        ProgressStoryCardContext(
            trendSnapshotMetrics: [
                trendSnapshotContext(days: 7, delta: sevenDayDelta),
                trendSnapshotContext(days: 30, delta: thirtyDayDelta)
            ],
            bannerText: bannerCopy.text,
            bannerAccent: bannerCopy.accent,
            didYouKnowText: didYouKnowText,
            reflectionPrompt: reflectionPromptText
        )
    }

    private func trendSnapshotContext(days: Int, delta: Double?) -> TrendSnapshotMetricContext {
        let unitAbbreviation = weightManager.currentUnitAbbreviation
        let title = localized(days == 7 ? "progress_story_metric_title_7" : "progress_story_metric_title_30", comment: "Trend snapshot metric title")
        let daysLabel = localized(days == 7 ? "progress_story_metric_days_label_7" : "progress_story_metric_days_label_30", comment: "Trend snapshot metric days label")

        guard let delta else {
            return TrendSnapshotMetricContext(
                id: title,
                title: title,
                valueText: "--",
                unitText: "",
                tagText: localized("progress_story_metric_no_data", comment: "Trend snapshot no data label"),
                tagTextColor: Theme.ColorToken.textSecondary,
                tagBackgroundColor: Theme.ColorToken.strokeLight.opacity(0.3),
                iconName: "slash.circle",
                iconColor: Theme.ColorToken.textSecondary.opacity(0.6),
                accessibilityLabel: localized(
                    "progress_story_metric_no_data",
                    comment: "Trend snapshot no data label"
                )
            )
        }

        let state = metricsProvider.trendState(for: delta)
        let valueText = weightManager.formattedDisplayWeight(abs(delta))

        let (tagText, tagBackground, tagForeground, iconName, iconColor, directionKey): (String, Color, Color, String, Color, String) = {
            switch state {
            case .improving:
                return (
                    localized("progress_story_metric_tag_lost", comment: "Trend snapshot LOST tag"),
                    Theme.ColorToken.stateSuccess.opacity(0.15),
                    Theme.ColorToken.stateSuccess,
                    "arrow.down.forward",
                    Theme.ColorToken.stateSuccess,
                    "progress_story_metric_direction_lost"
                )
            case .regressing:
                return (
                    localized("progress_story_metric_tag_gained", comment: "Trend snapshot GAINED tag"),
                    Theme.ColorToken.stateError.opacity(0.2),
                    Theme.ColorToken.stateError,
                    "arrow.up.forward",
                    Theme.ColorToken.stateError,
                    "progress_story_metric_direction_gained"
                )
            case .flat:
                return (
                    localized("progress_story_metric_tag_flat", comment: "Trend snapshot FLAT tag"),
                    Theme.ColorToken.textSecondary.opacity(0.15),
                    Theme.ColorToken.textSecondary,
                    "equal",
                    Theme.ColorToken.textSecondary,
                    "progress_story_metric_direction_flat"
                )
            }
        }()

        let directionText = localized(directionKey, comment: "Trend snapshot direction text")
        let accessibilityTemplate = NSLocalizedString("progress_story_metric_accessibility", comment: "Accessibility label for progress trend metric. Parameters: {daysLabel}, {directionText}, {valueText}, {unitAbbreviation}")
        let accessibilityLabel = String(
            format: accessibilityTemplate,
            daysLabel.capitalized,
            directionText,
            valueText,
            unitAbbreviation
        )

        return TrendSnapshotMetricContext(
            id: title,
            title: title,
            valueText: valueText,
            unitText: unitAbbreviation,
            tagText: tagText,
            tagTextColor: tagForeground,
            tagBackgroundColor: tagBackground,
            iconName: iconName,
            iconColor: iconColor,
            accessibilityLabel: accessibilityLabel
        )
    }

    private func localized(_ key: String, comment: StaticString) -> String {
        NSLocalizedString(key, bundle: .main, comment: String(describing: comment))
    }

    private func recordTrendSnapshotTelemetry(delta7: Double?, delta30: Double?, state: WeightProgressStoryTrendState) {
        WeightTrackerMetrics.recordTrendSnapshotState(
            hasSevenDayData: delta7 != nil,
            hasThirtyDayData: delta30 != nil,
            trendState: telemetryLabel(for: state)
        )
    }

    private func restoreBannerIfHiddenByDefault() {
        // Older builds defaulted the banner to hidden even when the user never opted out.
        // If that legacy state is still present but there is no opt-out record, restore visibility.
        let bannerID = contentIDs.banner
        guard !optOutManager.isContentOptedOut(id: bannerID),
              !cardManager.isCardVisible(.banner) else {
            return
        }
        cardManager.showCard(.banner)
    }

    private func restoreDidYouKnowIfHiddenByDefault() {
        let tipID = contentIDs.didYouKnow
        guard !optOutManager.isContentOptedOut(id: tipID),
              !cardManager.isCardVisible(.didYouKnow) else {
            return
        }
        cardManager.showCard(.didYouKnow)
    }

    private func telemetryLabel(for state: WeightProgressStoryTrendState) -> String {
        switch state {
        case .improving:
            return "improving"
        case .regressing:
            return "regressing"
        case .flat:
            return "flat"
        }
    }
}

// MARK: - Measurement Handling

private extension WeightTrendsViewModel {
    func handleMeasurementSystemDidChange() {
        refresh()
    }
}
