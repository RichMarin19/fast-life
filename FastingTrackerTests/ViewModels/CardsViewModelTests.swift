//
//  CardsViewModelTests.swift
//  FastingTrackerTests
//
//  Created by Claude Code
//  Task 1B: Comprehensive Testing - ViewModel Test Suite
//  Reference: Industry TDD patterns (Google/Facebook test methodology)
//

import XCTest
@testable import FastLIFe

@MainActor
final class CardsViewModelTests: XCTestCase {

    var viewModel: CardsViewModel!
    var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()

        // Use a separate UserDefaults suite for testing
        userDefaults = UserDefaults(suiteName: "CardsViewModelTests")!

        // Clear all test data before each test
        userDefaults.removePersistentDomain(forName: "CardsViewModelTests")

        // Create fresh ViewModel (will use standard UserDefaults)
        // Note: CardsViewModel uses UserDefaults.standard, not injectable
        // For true unit testing, this would need dependency injection
        // However, we can test behavior by clearing standard UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        viewModel = CardsViewModel()
    }

    override func tearDown() {
        viewModel = nil
        userDefaults = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_setsDefaultCardOrder() {
        // Given - fresh ViewModel (no saved state)

        // Then - should have default order
        let expectedOrder: [ControlCenterCardType] = [.goals, .notifications, .insights, .sync, .history, .dataManagement, .experience]
        XCTAssertEqual(viewModel.cardOrder, expectedOrder, "Default card order should match specification")
    }

    func test_init_loadsAllCardsExpandedByDefault() {
        // Given - fresh ViewModel (no saved state)

        // Then - all cards should be expanded by default
        let allCardTypes = ControlCenterCardType.allCases
        for cardType in allCardTypes {
            XCTAssertTrue(viewModel.isCardExpanded(cardType),
                         "\(cardType.rawValue) card should be expanded by default")
        }

        // About card should also be expanded
        XCTAssertTrue(viewModel.expandedCards.contains("about"),
                     "About card should be expanded by default")
    }

    // MARK: - Card Expansion Tests

    func test_isCardExpanded_returnsTrueForExpandedCard() {
        // Given - goals card is expanded (default state)

        // When
        let isExpanded = viewModel.isCardExpanded(.goals)

        // Then
        XCTAssertTrue(isExpanded, "isCardExpanded should return true for expanded card")
    }

    func test_isCardExpanded_returnsFalseForCollapsedCard() {
        // Given - collapse the goals card first
        viewModel.expandedCards.remove(ControlCenterCardType.goals.rawValue)

        // When
        let isExpanded = viewModel.isCardExpanded(.goals)

        // Then
        XCTAssertFalse(isExpanded, "isCardExpanded should return false for collapsed card")
    }

    func test_toggleCardExpansion_expandsCollapsedCard() {
        // Given - goals card is collapsed
        viewModel.expandedCards.remove(ControlCenterCardType.goals.rawValue)
        XCTAssertFalse(viewModel.isCardExpanded(.goals), "Precondition: card should start collapsed")

        // When
        viewModel.toggleCardExpansion(.goals)

        // Then
        XCTAssertTrue(viewModel.isCardExpanded(.goals), "Collapsed card should become expanded after toggle")
    }

    func test_toggleCardExpansion_collapsesExpandedCard() {
        // Given - goals card is expanded (default)
        XCTAssertTrue(viewModel.isCardExpanded(.goals), "Precondition: card should start expanded")

        // When
        viewModel.toggleCardExpansion(.goals)

        // Then
        XCTAssertFalse(viewModel.isCardExpanded(.goals), "Expanded card should become collapsed after toggle")
    }

    func test_toggleCardExpansion_persistsStateToUserDefaults() {
        // Given - collapse a card
        viewModel.toggleCardExpansion(.goals)
        XCTAssertFalse(viewModel.isCardExpanded(.goals), "Precondition: goals card collapsed")

        // When - create new ViewModel (simulates app restart)
        let newViewModel = CardsViewModel()

        // Then - expansion state should be restored
        XCTAssertFalse(newViewModel.isCardExpanded(.goals),
                      "Expansion state should persist across ViewModel instances")
    }

    func test_toggleCardExpansion_multipleCards() {
        // Given - collapse goals and notifications, expand insights
        viewModel.toggleCardExpansion(.goals)      // Collapse
        viewModel.toggleCardExpansion(.notifications) // Collapse
        // insights already expanded

        // Then
        XCTAssertFalse(viewModel.isCardExpanded(.goals), "Goals should be collapsed")
        XCTAssertFalse(viewModel.isCardExpanded(.notifications), "Notifications should be collapsed")
        XCTAssertTrue(viewModel.isCardExpanded(.insights), "Insights should still be expanded")
        XCTAssertTrue(viewModel.isCardExpanded(.sync), "Sync should still be expanded")
    }

    // MARK: - Card Order Tests

    func test_saveCardOrder_persistsToUserDefaults() {
        // Given - modify card order
        viewModel.cardOrder = [.sync, .goals, .notifications, .insights, .history, .dataManagement, .experience]

        // When
        viewModel.saveCardOrder()

        // Create new ViewModel to verify persistence
        let newViewModel = CardsViewModel()

        // Then - card order should be restored
        XCTAssertEqual(newViewModel.cardOrder, [.sync, .goals, .notifications, .insights, .history, .dataManagement, .experience],
                      "Card order should persist to UserDefaults")
    }

    func test_loadCardOrder_restoresSavedOrder() {
        // Given - save custom order
        let customOrder: [ControlCenterCardType] = [.history, .experience, .dataManagement, .goals, .sync, .notifications, .insights]
        viewModel.cardOrder = customOrder
        viewModel.saveCardOrder()

        // When - create new ViewModel
        let newViewModel = CardsViewModel()

        // Then - should restore custom order
        XCTAssertEqual(newViewModel.cardOrder, customOrder,
                      "loadCardOrder should restore previously saved order")
    }

    // MARK: - Migration Tests

    func test_migration_addsHistoryCardIfMissing() {
        // Given - save order WITHOUT .history card (simulates old data)
        let oldOrder: [ControlCenterCardType] = [.goals, .notifications, .insights, .sync, .experience]
        let encoded = try! JSONEncoder().encode(oldOrder)
        UserDefaults.standard.set(encoded, forKey: "weightControlCenterCardOrder")

        // When - create new ViewModel (triggers migration)
        let newViewModel = CardsViewModel()

        // Then - .history should be added before .experience
        XCTAssertTrue(newViewModel.cardOrder.contains(.history),
                     "Migration should add .history card if missing")

        if let historyIndex = newViewModel.cardOrder.firstIndex(of: .history),
           let experienceIndex = newViewModel.cardOrder.firstIndex(of: .experience) {
            XCTAssertLessThan(historyIndex, experienceIndex,
                            "History card should be inserted before Experience card")
        } else {
            XCTFail("Both .history and .experience should be in card order")
        }
    }

    func test_migration_addsExperienceCardIfMissing() {
        // Given - save order WITHOUT .experience card (simulates very old data)
        let oldOrder: [ControlCenterCardType] = [.goals, .notifications, .insights, .sync]
        let encoded = try! JSONEncoder().encode(oldOrder)
        UserDefaults.standard.set(encoded, forKey: "weightControlCenterCardOrder")

        // When - create new ViewModel (triggers migration)
        let newViewModel = CardsViewModel()

        // Then - .experience should be added to end
        XCTAssertTrue(newViewModel.cardOrder.contains(.experience),
                     "Migration should add .experience card if missing")
        XCTAssertTrue(newViewModel.cardOrder.contains(.dataManagement),
                     "Migration should add .dataManagement card when absent")
        XCTAssertEqual(Array(newViewModel.cardOrder.suffix(2)), [.dataManagement, .experience],
                      "Data Management should precede Experience at the end")
    }

    func test_migration_addsBothHistoryAndExperienceIfMissing() {
        // Given - save very old order (before both cards existed)
        let veryOldOrder: [ControlCenterCardType] = [.goals, .notifications, .insights, .sync]
        let encoded = try! JSONEncoder().encode(veryOldOrder)
        UserDefaults.standard.set(encoded, forKey: "weightControlCenterCardOrder")

        // When - create new ViewModel (triggers migration)
        let newViewModel = CardsViewModel()

        // Then - both cards should be added
        XCTAssertTrue(newViewModel.cardOrder.contains(.history),
                     "Migration should add .history card")
        XCTAssertTrue(newViewModel.cardOrder.contains(.experience),
                     "Migration should add .experience card")

        // History should come before Experience
        if let historyIndex = newViewModel.cardOrder.firstIndex(of: .history),
           let experienceIndex = newViewModel.cardOrder.firstIndex(of: .experience) {
            XCTAssertLessThan(historyIndex, experienceIndex,
                            "History should be before Experience in migrated order")
        }

        XCTAssertEqual(Array(newViewModel.cardOrder.suffix(2)), [.dataManagement, .experience],
                      "Data Management should precede Experience after migration")
    }

    func test_migration_addsDataManagementCardIfMissing() {
        // Given - order without Data Management card
        let oldOrder: [ControlCenterCardType] = [.goals, .notifications, .insights, .sync, .history, .experience]
        let encoded = try! JSONEncoder().encode(oldOrder)
        UserDefaults.standard.set(encoded, forKey: "weightControlCenterCardOrder")

        // When
        let newViewModel = CardsViewModel()

        // Then
        XCTAssertTrue(newViewModel.cardOrder.contains(.dataManagement),
                     "Migration should add Data Management card if missing")
        XCTAssertEqual(Array(newViewModel.cardOrder.suffix(2)), [.dataManagement, .experience],
                      "Data Management should be inserted before Experience")
    }

    func test_migration_savesMigratedOrder() {
        // Given - save order without .history
        let oldOrder: [ControlCenterCardType] = [.goals, .notifications, .insights, .sync, .experience]
        let encoded = try! JSONEncoder().encode(oldOrder)
        UserDefaults.standard.set(encoded, forKey: "weightControlCenterCardOrder")

        // When - create ViewModel (triggers migration)
        _ = CardsViewModel()

        // Create another ViewModel to verify migration was saved
        let secondViewModel = CardsViewModel()

        // Then - migration should not run again (order already contains .history)
        XCTAssertTrue(secondViewModel.cardOrder.contains(.history),
                     "Migrated order should be saved to UserDefaults")
        XCTAssertEqual(secondViewModel.cardOrder.count, 7,
                      "Card order should have all cards after migration")
    }

    // MARK: - Drag and Drop State Tests

    func test_draggedCard_initiallyNil() {
        // Given - fresh ViewModel

        // Then
        XCTAssertNil(viewModel.draggedCard, "draggedCard should be nil initially")
    }

    func test_draggedCard_canBeSet() {
        // Given
        XCTAssertNil(viewModel.draggedCard, "Precondition: no card dragged")

        // When
        viewModel.draggedCard = .goals

        // Then
        XCTAssertEqual(viewModel.draggedCard, .goals, "draggedCard should be settable")
    }

    func test_draggedCard_canBeCleared() {
        // Given - card is being dragged
        viewModel.draggedCard = .goals
        XCTAssertNotNil(viewModel.draggedCard, "Precondition: card is dragged")

        // When - drag ends
        viewModel.draggedCard = nil

        // Then
        XCTAssertNil(viewModel.draggedCard, "draggedCard should be clearable")
    }
}
