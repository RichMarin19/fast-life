import XCTest
import SwiftUI
@testable import FastLIFe

@MainActor
final class WeightTrendsViewModelTests: XCTestCase {
    private var weightManager: MockWeightManager!
    private var optOutManager: MockContentOptOutManager!
    private var cardManager: MockProgressStoryCardManager!
    private var metricsProvider: MockWeightProgressStoryMetricsProvider!
    private var measurementProvider: WeightControlCenterMeasurementProviderStub!
    private var measurementObserver: MeasurementSystemObserver!

    override func setUp() {
        super.setUp()
        weightManager = MockWeightManager()
        optOutManager = MockContentOptOutManager()
        cardManager = MockProgressStoryCardManager()
        metricsProvider = MockWeightProgressStoryMetricsProvider()
        measurementProvider = WeightControlCenterMeasurementProviderStub(localeIdentifier: "en_US")
        measurementObserver = MeasurementSystemObserver(provider: measurementProvider)
        metricsProvider.deltaResults = [
            7: -1.2,
            30: -3.4
        ]
        metricsProvider.trendStateResult = .improving
        metricsProvider.bannerCopyResult = WeightProgressStoryBannerCopy(text: "Great job", accent: .green)
        metricsProvider.didYouKnowText = "Tip text"
        metricsProvider.reflectionPromptText = "Prompt text"
        metricsProvider.totalEntriesValue = 2
    }

    override func tearDown() {
        weightManager = nil
        optOutManager = nil
        cardManager = nil
        metricsProvider = nil
        measurementProvider = nil
        measurementObserver = nil
        super.tearDown()
    }

    func testVisibleCardsRespectOrderAndOptOuts() {
        // Arrange: custom order (banner, didYouKnow, reflection)
        cardManager.cardPreferences = [
            CardPreference(cardType: .banner, sortOrder: 0),
            CardPreference(cardType: .didYouKnow, sortOrder: 1),
            CardPreference(cardType: .reflection, sortOrder: 2),
            CardPreference(cardType: .trendSnapshot, sortOrder: 3)
        ]
        optOutManager.isContentOptedOutHandler = { id in
            id == "progress_story_tip_v1" // Did You Know
        }

        // Act
        let sut = makeSUT()

        // Assert
        XCTAssertEqual(sut.visibleCards, [.banner, .reflection, .trendSnapshot])
    }

    func testBannerRestoredWhenHiddenWithoutOptOut() {
        // Arrange: banner hidden in card manager but no opt-out record
        cardManager.cardPreferences = [
            CardPreference(cardType: .banner, isVisible: false, sortOrder: 0),
            CardPreference(cardType: .trendSnapshot, sortOrder: 1)
        ]
        optOutManager.isContentOptedOutHandler = { _ in false }

        // Act
        _ = makeSUT()

        // Assert
        XCTAssertTrue(cardManager.showCardCallHistory.contains(.banner))
    }

    func testDidYouKnowRestoredWhenHiddenWithoutOptOut() {
        cardManager.cardPreferences = [
            CardPreference(cardType: .didYouKnow, isVisible: false, sortOrder: 0),
            CardPreference(cardType: .trendSnapshot, sortOrder: 1)
        ]
        optOutManager.isContentOptedOutHandler = { _ in false }

        _ = makeSUT()

        XCTAssertTrue(cardManager.showCardCallHistory.contains(.didYouKnow))
    }

    func testMeasurementSystemChangeRefreshesMetrics() {
        let sut = makeSUT()
        metricsProvider.deltaResults[7] = -2.2

        measurementProvider.setMeasurementSystem(.metric)
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        XCTAssertEqual(sut.sevenDayDelta, -2.2)
    }

    private func makeSUT() -> WeightTrendsViewModel {
        let dependencies = WeightTrendsViewModel.Dependencies(
            weightManager: weightManager,
            optOutManager: optOutManager,
            cardManager: cardManager,
            metricsProvider: metricsProvider,
            measurementObserver: measurementObserver
        )
        return WeightTrendsViewModel(dependencies: dependencies)
    }
}
