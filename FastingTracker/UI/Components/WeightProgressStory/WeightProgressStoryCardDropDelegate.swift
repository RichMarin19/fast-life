import SwiftUI

struct ProgressStoryCardDropDelegate: DropDelegate {
    let cardType: ProgressStoryCardType
    let visibleCards: [ProgressStoryCardType]
    @Binding var draggedCard: ProgressStoryCardType?
    let cardManager: CardManager<ProgressStoryCardType>

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedCard = draggedCard else { return false }

        // 🔧 FIX #3: Convert visible card indices to actual cardPreferences array indices
        // CRITICAL: visibleCards only contains VISIBLE cards, but cardManager.reorderCards
        // operates on the FULL cardPreferences array (which includes HIDDEN cards)
        // We must convert indices from visibleCards → cardPreferences to match correctly

        // Get all cards in cardPreferences order (includes hidden cards)
        let allCardsInOrder = cardManager.cardPreferences.sorted { $0.sortOrder < $1.sortOrder }

        // Find actual indices in full array
        guard let sourceIndex = allCardsInOrder.firstIndex(where: { $0.id == draggedCard.rawValue }),
              let destinationIndex = allCardsInOrder.firstIndex(where: { $0.id == cardType.rawValue }) else {
            return false
        }

        // Reorder using unified CardManager (Phase v1.4a)
        // This automatically updates sortOrder and persists to UserDefaults
        cardManager.reorderCards(from: sourceIndex, to: destinationIndex)

        // Haptic feedback on drop (medium style = card placement confirmation)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        self.draggedCard = nil
        return true
    }
}
