import SwiftUI

/// Drop delegate for drag-and-drop tracker card reordering on the Weight tracker screen.
/// Mirrors the Control Center delegate but constrained to the dashboard cards.
struct WeightTrackerCardDropDelegate: DropDelegate {
    let card: TrackerCardType
    @Binding var draggedCard: TrackerCardType?
    let cardManager: CardManager<TrackerCardType>

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedCard else { return false }

        let fromIndex = cardManager.getCardOrder(draggedCard)
        let toIndex = cardManager.getCardOrder(card)

        guard fromIndex != toIndex else {
            self.draggedCard = nil
            return false
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            cardManager.reorderCards(from: fromIndex, to: toIndex)
        }

        self.draggedCard = nil
        return true
    }

    func dropEntered(info: DropInfo) { }

    func dropExited(info: DropInfo) { }
}
