import SwiftUI

struct ProgressStoryCardDropDelegate: DropDelegate {
    let cardType: ProgressStoryCardType
    @Binding var draggedCard: ProgressStoryCardType?
    let onReorder: (ProgressStoryCardType, ProgressStoryCardType) -> Void

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedCard = draggedCard else { return false }
        guard draggedCard != cardType else {
            self.draggedCard = nil
            return false
        }

        onReorder(draggedCard, cardType)

        // Haptic feedback on drop (medium style = card placement confirmation)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        self.draggedCard = nil
        return true
    }
}
