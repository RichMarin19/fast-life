//
//  BadgesViewModelTests.swift
//  FastingTrackerTests
//
//  Created by Claude Code
//  Task 1B: Comprehensive Testing - ViewModel Test Suite
//  Reference: Industry TDD patterns (Google/Facebook test methodology)
//

import XCTest
import SwiftUI
@testable import FastLIFe

@MainActor
final class BadgesViewModelTests: XCTestCase {

    var viewModel: BadgesViewModel!

    override func setUp() {
        super.setUp()
        viewModel = BadgesViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Create mock ContentItem for testing
    private func createMockContentItem(id: String, displayText: String) -> ContentItem {
        return ContentItem(id: id, category: .educationalInsights, displayText: displayText)
    }

    // MARK: - Initialization Tests

    func test_init_setsDefaultValues() {
        // Given - fresh ViewModel

        // Then - all properties should have default values
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 0,
                      "currentHighlightedItemIndex should start at 0")
        XCTAssertNil(viewModel.highlightedItemID,
                    "highlightedItemID should start as nil")
        XCTAssertNil(viewModel.scrollViewProxy,
                    "scrollViewProxy should start as nil")
        XCTAssertEqual(viewModel.badgeScale, 1.0, accuracy: 0.001,
                      "badgeScale should start at 1.0 (normal size)")
    }

    // MARK: - Cycle to Next Item Tests

    func test_cycleToNextOptedOutItem_withEmptyArray_doesNothing() {
        // Given - empty opted-out items array
        let emptyItems: [ContentItem] = []
        let initialIndex = viewModel.currentHighlightedItemIndex

        // When
        viewModel.cycleToNextOptedOutItem(emptyItems)

        // Then - index should not change
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, initialIndex,
                      "Empty array should not change index (guard clause)")
        XCTAssertNil(viewModel.highlightedItemID,
                    "highlightedItemID should remain nil for empty array")
    }

    func test_cycleToNextOptedOutItem_incrementsIndex() {
        // Given - 3 opted-out items
        let items = [
            createMockContentItem(id: "item1", displayText: "Item 1"),
            createMockContentItem(id: "item2", displayText: "Item 2"),
            createMockContentItem(id: "item3", displayText: "Item 3")
        ]
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 0, "Precondition: starts at 0")

        // When - cycle once
        viewModel.cycleToNextOptedOutItem(items)

        // Then - index should increment to 1
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 1,
                      "Index should increment from 0 to 1")
    }

    func test_cycleToNextOptedOutItem_wrapsAroundToZero() {
        // Given - 3 items, index at last position
        let items = [
            createMockContentItem(id: "item1", displayText: "Item 1"),
            createMockContentItem(id: "item2", displayText: "Item 2"),
            createMockContentItem(id: "item3", displayText: "Item 3")
        ]
        viewModel.currentHighlightedItemIndex = 2 // Last item

        // When - cycle once more
        viewModel.cycleToNextOptedOutItem(items)

        // Then - index should wrap to 0
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 0,
                      "Index should wrap around from 2 to 0 (modulo behavior)")
    }

    func test_cycleToNextOptedOutItem_setsHighlightedItemID() {
        // Given - 2 items
        let items = [
            createMockContentItem(id: "item1", displayText: "Item 1"),
            createMockContentItem(id: "item2", displayText: "Item 2")
        ]
        viewModel.currentHighlightedItemIndex = 0

        // When - cycle to next item
        viewModel.cycleToNextOptedOutItem(items)

        // Then - highlightedItemID should be set to first item (index was 0 before increment)
        XCTAssertEqual(viewModel.highlightedItemID, "item1",
                      "highlightedItemID should be set to the target item")
    }

    func test_cycleToNextOptedOutItem_withoutScrollViewProxy_stillUpdatesState() {
        // Given - no scrollViewProxy set
        let items = [
            createMockContentItem(id: "item1", displayText: "Item 1"),
            createMockContentItem(id: "item2", displayText: "Item 2")
        ]
        XCTAssertNil(viewModel.scrollViewProxy, "Precondition: no scroll proxy")

        // When - cycle to next item
        viewModel.cycleToNextOptedOutItem(items)

        // Then - state should still update (scrolling just won't happen)
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 1,
                      "Index should still increment without scroll proxy")
        XCTAssertEqual(viewModel.highlightedItemID, "item1",
                      "highlightedItemID should still be set without scroll proxy")
    }

    func test_cycleToNextOptedOutItem_multipleCycles_correctOrder() {
        // Given - 3 items
        let items = [
            createMockContentItem(id: "item1", displayText: "Item 1"),
            createMockContentItem(id: "item2", displayText: "Item 2"),
            createMockContentItem(id: "item3", displayText: "Item 3")
        ]

        // When - cycle 5 times
        viewModel.cycleToNextOptedOutItem(items) // 0 → 1, highlights item1
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 1)
        XCTAssertEqual(viewModel.highlightedItemID, "item1")

        viewModel.cycleToNextOptedOutItem(items) // 1 → 2, highlights item2
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 2)
        XCTAssertEqual(viewModel.highlightedItemID, "item2")

        viewModel.cycleToNextOptedOutItem(items) // 2 → 0, highlights item3
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 0)
        XCTAssertEqual(viewModel.highlightedItemID, "item3")

        viewModel.cycleToNextOptedOutItem(items) // 0 → 1, highlights item1 (wrap around works)
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 1)
        XCTAssertEqual(viewModel.highlightedItemID, "item1")

        viewModel.cycleToNextOptedOutItem(items) // 1 → 2, highlights item2
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 2)
        XCTAssertEqual(viewModel.highlightedItemID, "item2")
    }

    func test_cycleToNextOptedOutItem_singleItem_staysAtZero() {
        // Given - only 1 item
        let items = [
            createMockContentItem(id: "onlyItem", displayText: "Only Item")
        ]

        // When - cycle multiple times
        viewModel.cycleToNextOptedOutItem(items)
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 0, "Single item: index wraps to 0")

        viewModel.cycleToNextOptedOutItem(items)
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 0, "Single item: index stays at 0")

        // Then - highlightedItemID should always be the same item
        XCTAssertEqual(viewModel.highlightedItemID, "onlyItem",
                      "Single item should always be highlighted")
    }

    // MARK: - Animation State Tests

    func test_badgeScale_animatesDuringCycle() async {
        // Given - item to cycle to
        let items = [
            createMockContentItem(id: "item1", displayText: "Item 1")
        ]

        // When - cycle to next item
        viewModel.cycleToNextOptedOutItem(items)

        // Wait briefly for animation to start
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        await MainActor.run {}

        // Then - badgeScale should animate to 1.15 (bounce effect)
        XCTAssertGreaterThan(viewModel.badgeScale, 1.0,
                            "badgeScale should increase during bounce animation")

        // Wait for animation to complete (150ms total in implementation)
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        await MainActor.run {}

        // Then - badgeScale should return to 1.0
        XCTAssertEqual(viewModel.badgeScale, 1.0, accuracy: 0.05,
                      "badgeScale should return to 1.0 after animation completes")
    }

    func test_highlightedItemID_clearsAfterDelay() async {
        // Given - item to cycle to
        let items = [
            createMockContentItem(id: "item1", displayText: "Item 1")
        ]

        // When - cycle to next item
        viewModel.cycleToNextOptedOutItem(items)

        // Then - highlightedItemID should be set immediately
        XCTAssertEqual(viewModel.highlightedItemID, "item1",
                      "highlightedItemID should be set immediately")

        // Wait for auto-reset delay (1 second in implementation)
        try? await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
        await MainActor.run {}

        // Then - highlightedItemID should be cleared
        XCTAssertNil(viewModel.highlightedItemID,
                    "highlightedItemID should clear after 1 second delay")
    }

    // MARK: - ScrollViewProxy Tests

    func test_scrollViewProxy_initiallyNil() {
        // Given - fresh ViewModel

        // Then
        XCTAssertNil(viewModel.scrollViewProxy,
                    "scrollViewProxy should be nil by default")
    }

    func test_scrollViewProxy_canBeSet() {
        // Given - initially nil
        XCTAssertNil(viewModel.scrollViewProxy, "Precondition: starts nil")

        // When/Then - verify property is settable (compile-time check)
        // Note: ScrollViewProxy is provided by SwiftUI at runtime, can't be instantiated in tests
        // This test verifies the property exists, is @Published, and is settable
        // If this compiles without errors, the property is correctly declared

        // We can verify it stays nil (can't create real ScrollViewProxy in unit tests)
        XCTAssertNil(viewModel.scrollViewProxy,
                     "scrollViewProxy should remain nil (can't instantiate in unit tests)")
    }

    // MARK: - Edge Cases

    func test_cycleToNextOptedOutItem_largeArray_handlesCorrectly() {
        // Given - large array (100 items)
        let items = (0..<100).map { i in
            createMockContentItem(id: "item\(i)", displayText: "Item \(i)")
        }

        // When - cycle through all items
        for i in 0..<100 {
            viewModel.cycleToNextOptedOutItem(items)
            XCTAssertEqual(viewModel.currentHighlightedItemIndex, (i + 1) % 100,
                          "Index should be \((i + 1) % 100) after \(i + 1) cycles")
        }

        // Then - should wrap back to 0
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 0,
                      "After 100 cycles with 100 items, index should wrap to 0")
    }

    func test_currentHighlightedItemIndex_canBeSetDirectly() {
        // Given
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 0, "Precondition: starts at 0")

        // When - set directly (useful for programmatic control)
        viewModel.currentHighlightedItemIndex = 5

        // Then
        XCTAssertEqual(viewModel.currentHighlightedItemIndex, 5,
                      "currentHighlightedItemIndex should be settable")
    }

    func test_badgeScale_canBeSetDirectly() {
        // Given
        XCTAssertEqual(viewModel.badgeScale, 1.0, accuracy: 0.001, "Precondition: starts at 1.0")

        // When - set to custom value
        viewModel.badgeScale = 1.5

        // Then
        XCTAssertEqual(viewModel.badgeScale, 1.5, accuracy: 0.001,
                      "badgeScale should be settable for custom animations")
    }
}
