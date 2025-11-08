import Combine
@testable import FastLIFe

@MainActor
final class MockProgressStoryCardManager: ProgressStoryCardManaging {
    var objectWillChange = ObservableObjectPublisher()

    var cardPreferences: [CardPreference<ProgressStoryCardType>] = ProgressStoryCardType.allCases.enumerated().map { index, cardType in
        CardPreference(cardType: cardType, isVisible: true, isExpanded: true, sortOrder: index)
    }

    func getVisibleCardsInOrder() -> [ProgressStoryCardType] {
        cardPreferences
            .filter { $0.isVisible }
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { ProgressStoryCardType(rawValue: $0.id) }
    }

    func isCardVisible(_ card: ProgressStoryCardType) -> Bool {
        preference(for: card)?.isVisible ?? true
    }

    func showCard(_ card: ProgressStoryCardType) {
        update(card: card) { preference in
            preference.isVisible = true
        }
    }

    func hideCard(_ card: ProgressStoryCardType) {
        update(card: card) { preference in
            preference.isVisible = false
        }
    }

    func reorderCards(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex < cardPreferences.count,
              destinationIndex < cardPreferences.count else {
            return
        }

        let preference = cardPreferences.remove(at: sourceIndex)
        cardPreferences.insert(preference, at: destinationIndex)
        for (index, _) in cardPreferences.enumerated() {
            cardPreferences[index].sortOrder = index
        }
        objectWillChange.send()
    }

    // MARK: - Helpers

    private func preference(for card: ProgressStoryCardType) -> CardPreference<ProgressStoryCardType>? {
        cardPreferences.first { $0.id == card.rawValue }
    }

    private func update(card: ProgressStoryCardType, mutation: (inout CardPreference<ProgressStoryCardType>) -> Void) {
        guard let index = cardPreferences.firstIndex(where: { $0.id == card.rawValue }) else { return }
        mutation(&cardPreferences[index])
        objectWillChange.send()
    }
}
