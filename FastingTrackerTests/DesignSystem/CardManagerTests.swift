import XCTest
import Combine
@testable import FastLIFe

/// Integration tests for CardManager (generic card management system)
/// TASK 1E PHASE 2: Tests card ordering persistence (consultant review fix)
/// Industry Pattern: Integration tests following Apple WWDC 2017 "Testing in Xcode"
/// Reference: WeightControlCenterViewModelTests proven pattern (Given-When-Then)
@MainActor
final class CardManagerTests: XCTestCase {
    var sut: CardManager<TrackerCardType>!

    // Unique test key to avoid conflicts with app's actual data
    private let testPreferencesKey = "testTrackerCardPreferences_v1"

    override func setUp() {
        super.setUp()

        // Clear test UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: testPreferencesKey)

        // Create CardManager with test key
        sut = CardManager<TrackerCardType>(preferencesKey: testPreferencesKey)
    }

    override func tearDown() {
        // Clean up test UserDefaults
        UserDefaults.standard.removeObject(forKey: testPreferencesKey)

        sut = nil
        super.tearDown()
    }

    // MARK: - Card Ordering Persistence Tests (CONSULTANT REVIEW - Issue #3)

    func test_cardOrdering_persistsAfterReorder() {
        // Given: Initial default order
        let initialOrder = sut.getVisibleCardsInOrder()
        let expectedVisibleCount = TrackerCardType.allCases.filter { $0 != .history }.count
        XCTAssertEqual(initialOrder.count, expectedVisibleCount,
                      "Should have \(expectedVisibleCount) visible tracker cards by default")

        // When: Reorder cards (move first card to last position)
        sut.reorderCards(from: 0, to: 3)

        // Then: Create new CardManager to verify persistence
        let newManager = CardManager<TrackerCardType>(preferencesKey: testPreferencesKey)
        let persistedOrder = newManager.getVisibleCardsInOrder()

        XCTAssertEqual(persistedOrder, sut.getVisibleCardsInOrder(),
                      "Card order should persist across CardManager instances")
    }

    func test_cardOrdering_multipleReordersPersist() {
        // Given: Default order
        let originalFirst = sut.getVisibleCardsInOrder().first

        // When: Perform multiple reorders
        sut.reorderCards(from: 0, to: 2)  // Move first to third
        sut.reorderCards(from: 1, to: 0)  // Move second to first

        let reorderedCards = sut.getVisibleCardsInOrder()

        // Then: New manager should have same order
        let newManager = CardManager<TrackerCardType>(preferencesKey: testPreferencesKey)
        let persistedOrder = newManager.getVisibleCardsInOrder()

        XCTAssertEqual(persistedOrder, reorderedCards,
                      "Multiple reorders should persist correctly")
        XCTAssertNotEqual(persistedOrder.first, originalFirst,
                         "First card should have changed after reordering")
    }

    // MARK: - Card Visibility Persistence Tests

    func test_cardVisibility_persistsAcrossInstances() {
        // Given: Hide a card
        let cardToHide = TrackerCardType.chart
        sut.hideCard(cardToHide)

        // When: Create new CardManager
        let newManager = CardManager<TrackerCardType>(preferencesKey: testPreferencesKey)

        // Then: Card should still be hidden
        XCTAssertFalse(newManager.isCardVisible(cardToHide),
                      "Hidden card should persist across CardManager instances")
    }

    func test_cardVisibility_multiplehidesPersist() {
        // Given: Hide multiple cards
        sut.hideCard(.chart)
        sut.hideCard(.stats)

        // When: Create new CardManager
        let newManager = CardManager<TrackerCardType>(preferencesKey: testPreferencesKey)

        // Then: All hidden cards should persist
        XCTAssertFalse(newManager.isCardVisible(.chart),
                      "First hidden card should persist")
        XCTAssertFalse(newManager.isCardVisible(.stats),
                      "Second hidden card should persist")
        XCTAssertTrue(newManager.isCardVisible(.currentWeight),
                     "Visible card should remain visible")
    }

    func test_showCard_togglesVisibilityAndPersists() {
        // Given: Hide then show a card
        // NOTE: Using .currentWeight for test since .milestone was removed (Enhancement 7)
        sut.hideCard(.currentWeight)
        sut.showCard(.currentWeight)

        // When: Create new CardManager
        let newManager = CardManager<TrackerCardType>(preferencesKey: testPreferencesKey)

        // Then: Card should be visible
        XCTAssertTrue(newManager.isCardVisible(.currentWeight),
                     "Card shown after hiding should persist as visible")
    }

    // MARK: - Card Expansion Persistence Tests

    func test_cardExpansion_persistsAcrossInstances() {
        // Given: Collapse a card
        sut.setCardExpanded(.currentWeight, isExpanded: false)

        // When: Create new CardManager
        let newManager = CardManager<TrackerCardType>(preferencesKey: testPreferencesKey)

        // Then: Card should still be collapsed
        XCTAssertFalse(newManager.isCardExpanded(.currentWeight),
                      "Collapsed card should persist across CardManager instances")
    }

    func test_toggleCardExpansion_persistsState() {
        // Given: Toggle expansion
        let initialState = sut.isCardExpanded(.chart)
        sut.toggleCardExpansion(.chart)

        // When: Create new CardManager
        let newManager = CardManager<TrackerCardType>(preferencesKey: testPreferencesKey)

        // Then: Toggled state should persist
        XCTAssertNotEqual(newManager.isCardExpanded(.chart), initialState,
                         "Toggled expansion state should persist")
    }

    // MARK: - Reset Tests

    func test_resetAllCards_clearsAllPreferences() {
        // Given: Custom preferences (hidden, reordered, collapsed)
        sut.hideCard(.stats)
        sut.reorderCards(from: 0, to: 2)
        sut.setCardExpanded(.currentWeight, isExpanded: false)

        // When: Reset all cards
        sut.resetAllCards()

        // Then: All cards should be back to defaults
        XCTAssertTrue(sut.isCardVisible(.stats),
                     "Hidden card should be visible after reset")
        XCTAssertTrue(sut.isCardExpanded(.currentWeight),
                     "Collapsed card should be expanded after reset")

        // Verify reset persists
        let newManager = CardManager<TrackerCardType>(preferencesKey: testPreferencesKey)
        XCTAssertTrue(newManager.isCardVisible(.stats),
                     "Reset should persist to new instance")
    }

    // MARK: - Visible Cards Tests

    func test_getVisibleCardsInOrder_returnsOnlyVisibleCards() {
        // Given: Hide some cards
        sut.hideCard(.chart)
        sut.hideCard(.stats)

        // When: Get visible cards
        let visibleCards = sut.getVisibleCardsInOrder()

        // Then: Should only return visible cards
        XCTAssertFalse(visibleCards.contains(.chart),
                      "Hidden card should not be in visible list")
        XCTAssertFalse(visibleCards.contains(.stats),
                      "Hidden card should not be in visible list")
        XCTAssertTrue(visibleCards.contains(.currentWeight),
                     "Visible card should be in list")
    }

    func test_getVisibleCardsInOrder_respectsSortOrder() {
        // Given: Reorder cards
        sut.reorderCards(from: 0, to: 3)  // Move first to last

        // When: Get visible cards
        let orderedCards = sut.getVisibleCardsInOrder()

        // Then: Should be in sorted order
        for i in 0..<(orderedCards.count - 1) {
            let currentOrder = sut.getCardOrder(orderedCards[i])
            let nextOrder = sut.getCardOrder(orderedCards[i + 1])
            XCTAssertLessThan(currentOrder, nextOrder,
                            "Cards should be sorted by sortOrder")
        }
    }

    // MARK: - Combined State Persistence Tests

    func test_allStateChanges_persistTogether() {
        // Given: Multiple state changes
        sut.hideCard(.stats)
        sut.reorderCards(from: 0, to: 1)
        sut.setCardExpanded(.currentWeight, isExpanded: false)

        let currentVisibleOrder = sut.getVisibleCardsInOrder()
        let currentExpandedState = sut.isCardExpanded(.currentWeight)
        let currentVisibilityState = sut.isCardVisible(.stats)

        // When: Create new CardManager
        let newManager = CardManager<TrackerCardType>(preferencesKey: testPreferencesKey)

        // Then: All state should persist
        XCTAssertEqual(newManager.getVisibleCardsInOrder(), currentVisibleOrder,
                      "Card order should persist")
        XCTAssertEqual(newManager.isCardExpanded(.currentWeight), currentExpandedState,
                      "Expansion state should persist")
        XCTAssertEqual(newManager.isCardVisible(.stats), currentVisibilityState,
                      "Visibility state should persist")
    }

    // MARK: - Edge Cases

    func test_reorderCards_ignoresSameIndexMove() {
        // Given: Initial order
        let initialOrder = sut.getVisibleCardsInOrder()

        // When: Reorder with same source and destination
        sut.reorderCards(from: 1, to: 1)

        // Then: Order should not change
        XCTAssertEqual(sut.getVisibleCardsInOrder(), initialOrder,
                      "Reordering to same index should not change order")
    }

    func test_reorderCards_handlesInvalidIndices() {
        // Given: Initial order
        let initialOrder = sut.getVisibleCardsInOrder()

        // When: Reorder with out-of-bounds index
        sut.reorderCards(from: 0, to: 100)

        // Then: Order should not change (no crash)
        XCTAssertEqual(sut.getVisibleCardsInOrder().count, initialOrder.count,
                      "Invalid reorder should not crash or change count")
    }

    // MARK: - Default Initialization Tests

    func test_init_loadsDefaultPreferencesOnFirstLaunch() {
        // Given: Fresh install (no saved preferences)
        // setUp already cleared UserDefaults

        // When: CardManager initializes
        // sut already created in setUp

        // Then: Should have default preferences for all card types
        let allCards = TrackerCardType.allCases
        XCTAssertGreaterThan(allCards.count, 0,
                            "Should have card types defined")

        for cardType in allCards {
            // All cards should be visible by default (except history which is hidden)
            let isVisible = sut.isCardVisible(cardType)
            if cardType == .history {
                XCTAssertFalse(isVisible,
                             "History card should be hidden by default")
            } else {
                XCTAssertTrue(isVisible,
                            "\(cardType) should be visible by default")
            }

            // All cards should be expanded by default
            XCTAssertTrue(sut.isCardExpanded(cardType),
                         "\(cardType) should be expanded by default")
        }
    }

    func test_init_migratesNewCardTypes() {
        // Given: Saved preferences for existing cards (simulating old version)
        let oldPreferences = [
            CardPreference(cardType: TrackerCardType.currentWeight, isVisible: true, isExpanded: true, sortOrder: 0)
        ]
        if let encoded = try? JSONEncoder().encode(oldPreferences) {
            UserDefaults.standard.set(encoded, forKey: testPreferencesKey)
        }

        // When: Create new CardManager (will load old prefs + add missing cards)
        let migratedManager = CardManager<TrackerCardType>(preferencesKey: testPreferencesKey)

        // Then: Should have preferences for all current card types
        let allCards = TrackerCardType.allCases
        for cardType in allCards {
            XCTAssertNotNil(migratedManager.getCardOrder(cardType),
                          "Migrated manager should have preference for \(cardType)")
        }
    }
}
