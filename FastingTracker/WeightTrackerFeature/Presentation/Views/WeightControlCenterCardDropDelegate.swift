import SwiftUI

/// Drag-and-drop delegate for Control Center cards.
struct WeightControlCenterCardDropDelegate: DropDelegate {
    let card: ControlCenterCardType
    @Binding var cardOrder: [ControlCenterCardType]
    @Binding var draggedCard: ControlCenterCardType?
    let saveAction: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedCard else { return false }

        if let fromIndex = cardOrder.firstIndex(of: draggedCard),
           let toIndex = cardOrder.firstIndex(of: card) {

            withAnimation(.spring()) {
                cardOrder.move(
                    fromOffsets: IndexSet(integer: fromIndex),
                    toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
                )
            }

            saveAction()
        }

        self.draggedCard = nil
        return true
    }

    func dropEntered(info: DropInfo) { }

    func dropExited(info: DropInfo) { }
}
