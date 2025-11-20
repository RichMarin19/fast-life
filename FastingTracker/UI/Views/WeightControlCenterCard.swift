import SwiftUI

/// Shared container that restores the Control Center drag + collapse behavior.
/// Inspired by Apple's editable list guidance (WWDC23) and the original Weight tracker hub pattern.
struct WeightControlCenterCard<Content: View>: View {
    private let cardType: ControlCenterCardType
    @ObservedObject private var viewModel: WeightControlCenterViewModel
    private let title: String
    private let subtitle: String?
    private let icon: String
    private let content: Content

    init(
        cardType: ControlCenterCardType,
        viewModel: WeightControlCenterViewModel,
        title: String,
        subtitle: String? = nil,
        icon: String,
        @ViewBuilder content: () -> Content
    ) {
        self.cardType = cardType
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.content = content()
    }

    private var isExpanded: Bool {
        viewModel.isCardExpanded(cardType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { toggleExpansion() }) {
                header
                    .padding(.horizontal, DSSpacing.cardPadding)
                    .padding(.vertical, DSSpacing.cardElementSpacing)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title) card")
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand"). Drag with two fingers on the grab handle to reorder.")

            if isExpanded {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)
                    .padding(.horizontal, DSSpacing.cardPadding)

                content
                    .padding(.horizontal, DSSpacing.cardPadding)
                    .padding(.top, DSSpacing.cardElementSpacing)
                    .padding(.bottom, DSSpacing.cardPadding)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.ColorToken.cardOnDark)
        .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.card, style: .continuous))
        .shadow(color: Theme.ColorToken.shadowCardOnDark, radius: 16, x: 0, y: 8)
        .onDrag {
            viewModel.draggedCard = cardType
            return NSItemProvider(object: cardType.rawValue as NSString)
        }
        .onDrop(of: [.text], delegate: WeightControlCenterCardDropDelegate(
            card: cardType,
            cardOrder: Binding(
                get: { viewModel.cardOrder },
                set: { viewModel.cardOrder = $0 }
            ),
            draggedCard: Binding(
                get: { viewModel.draggedCard },
                set: { viewModel.draggedCard = $0 }
            ),
            saveAction: viewModel.saveCardOrder
        ))
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: Text("Move down")) { moveCard(by: 1) }
        .accessibilityAction(named: Text("Move up")) { moveCard(by: -1) }
    }

    private var header: some View {
        HStack(spacing: DSSpacing.cardSmallSpacing) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.7))
                .accessibilityHidden(true)

            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.ColorToken.accentCyan, Theme.ColorToken.accentLightBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DSTypography.listTitle)
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

                if let subtitle {
                    Text(subtitle)
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }

            Spacer()

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark.opacity(0.85))
                .accessibilityHidden(true)
        }
    }
}

private extension WeightControlCenterCard {
    func toggleExpansion() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            viewModel.toggleCardExpansion(cardType)
        }
    }

    func moveCard(by offset: Int) {
        guard let currentIndex = viewModel.cardOrder.firstIndex(of: cardType) else { return }
        let newIndex = min(max(currentIndex + offset, 0), viewModel.cardOrder.count - 1)
        guard newIndex != currentIndex else { return }

        var updatedOrder = viewModel.cardOrder
        updatedOrder.remove(at: currentIndex)
        updatedOrder.insert(cardType, at: newIndex)
        viewModel.cardOrder = updatedOrder
        viewModel.saveCardOrder()
        viewModel.scrollViewProxy?.scrollTo(cardType, anchor: .top)
    }
}
