import Combine
import Foundation

@MainActor
protocol ProgressStoryCardManaging: AnyObject {
    var cardPreferences: [CardPreference<ProgressStoryCardType>] { get }
    var objectWillChange: ObservableObjectPublisher { get }

    func getVisibleCardsInOrder() -> [ProgressStoryCardType]
    func isCardVisible(_ card: ProgressStoryCardType) -> Bool
    func showCard(_ card: ProgressStoryCardType)
    func hideCard(_ card: ProgressStoryCardType)
    func reorderCards(from sourceIndex: Int, to destinationIndex: Int)
}

extension CardManager: ProgressStoryCardManaging where CardType == ProgressStoryCardType {}
