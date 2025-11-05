import SwiftUI

struct ProgressStoryContentIDs {
    let sevenDay: String
    let thirtyDay: String
    let banner: String
    let reflection: String
    let recap: String
    let didYouKnow: String
}

struct ProgressStoryCardContext {
    let sevenDayDelta: Double?
    let thirtyDayDelta: Double?
    let netDelta30d: Double
    let bestStreak: Int
    let totalEntries: Int
    let bannerText: String
    let bannerAccent: Color
    let didYouKnowText: String
    let reflectionPrompt: String
}

struct ProgressStoryCardStack: View {
    let contentIDs: ProgressStoryContentIDs
    let context: ProgressStoryCardContext
    let isAnimating: Bool
    @ObservedObject private var optOutManager: ContentOptOutManager
    @ObservedObject private var cardManager: CardManager<ProgressStoryCardType>
    @Binding private var draggedCard: ProgressStoryCardType?
    let reflectionTap: () -> Void
    let onHideCard: (ProgressStoryCardType) -> Void

    init(optOutManager: ContentOptOutManager,
         cardManager: CardManager<ProgressStoryCardType>,
         contentIDs: ProgressStoryContentIDs,
         context: ProgressStoryCardContext,
         isAnimating: Bool,
         draggedCard: Binding<ProgressStoryCardType?>,
         reflectionTap: @escaping () -> Void,
         onHideCard: @escaping (ProgressStoryCardType) -> Void) {
        self.contentIDs = contentIDs
        self.context = context
        self.isAnimating = isAnimating
        _optOutManager = ObservedObject(wrappedValue: optOutManager)
        _cardManager = ObservedObject(wrappedValue: cardManager)
        _draggedCard = draggedCard
        self.reflectionTap = reflectionTap
        self.onHideCard = onHideCard
    }

    var body: some View {
        let orderedCards = visibleCards

        ForEach(orderedCards, id: \.self) { cardType in
            if shouldDisplay(cardType) {
                ProgressStoryReorderableCard(
                    cardType: cardType,
                    visibleCards: orderedCards,
                    draggedCard: $draggedCard,
                    cardManager: cardManager,
                    isAnimating: isAnimating
                ) {
                    cardContent(for: cardType)
                }
            }
        }
    }

    // MARK: - Private

    private func shouldDisplay(_ cardType: ProgressStoryCardType) -> Bool {
        switch cardType {
        case .sevenDay:
            return !optOutManager.isContentOptedOut(id: contentIDs.sevenDay)
        case .banner:
            return !optOutManager.isContentOptedOut(id: contentIDs.banner)
        case .thirtyDay:
            return !optOutManager.isContentOptedOut(id: contentIDs.thirtyDay)
        case .reflection:
            return !optOutManager.isContentOptedOut(id: contentIDs.reflection)
        case .recap:
            return !optOutManager.isContentOptedOut(id: contentIDs.recap)
        case .didYouKnow:
            return context.totalEntries >= 5 && !optOutManager.isContentOptedOut(id: contentIDs.didYouKnow)
        case .coachBar:
            return false
        }
    }

    private var visibleCards: [ProgressStoryCardType] {
        cardManager
            .getVisibleCardsInOrder()
            .filter { $0 != .coachBar }
    }

    @ViewBuilder
    private func cardContent(for cardType: ProgressStoryCardType) -> some View {
        switch cardType {
        case .sevenDay:
            CircularTrendRingCard(
                periodLabel: "7 DAYS",
                delta: context.sevenDayDelta,
                surfaceStyle: cardType.surfaceStyle ?? .ice,
                onHide: { onHideCard(.sevenDay) }
            )

        case .banner:
            ProgressBanner(
                text: context.bannerText,
                accent: context.bannerAccent,
                onHide: { onHideCard(.banner) }
            )

        case .thirtyDay:
            CircularTrendRingCard(
                periodLabel: "30 DAYS",
                delta: context.thirtyDayDelta,
                surfaceStyle: cardType.surfaceStyle ?? .ivory,
                onHide: { onHideCard(.thirtyDay) }
            )

        case .reflection:
            ReflectionNudge(
                text: context.reflectionPrompt,
                onHide: { onHideCard(.reflection) },
                onTap: reflectionTap
            )

        case .recap:
            RecapRow(
                netDelta: context.netDelta30d,
                bestStreak: context.bestStreak,
                entries: context.totalEntries,
                onHide: { onHideCard(.recap) }
            )

        case .didYouKnow:
            DidYouKnowBanner(
                text: context.didYouKnowText,
                onHide: { onHideCard(.didYouKnow) }
            )

        case .coachBar:
            EmptyView()
        }
    }
}

// MARK: - Reorderable Card Wrapper

private struct ProgressStoryReorderableCard<Content: View>: View {
    let cardType: ProgressStoryCardType
    let visibleCards: [ProgressStoryCardType]
    @Binding var draggedCard: ProgressStoryCardType?
    @ObservedObject var cardManager: CardManager<ProgressStoryCardType>
    let isAnimating: Bool
    let content: Content

    init(
        cardType: ProgressStoryCardType,
        visibleCards: [ProgressStoryCardType],
        draggedCard: Binding<ProgressStoryCardType?>,
        cardManager: CardManager<ProgressStoryCardType>,
        isAnimating: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.cardType = cardType
        self.visibleCards = visibleCards
        _draggedCard = draggedCard
        _cardManager = ObservedObject(wrappedValue: cardManager)
        self.isAnimating = isAnimating
        self.content = content()
    }

    var body: some View {
        content
            .overlay(alignment: .leading) {
                dragHandle
                    .padding(.leading, DSSpacing.cardPadding * 0.6)
            }
            .contentShape(Rectangle())
            .onDrag {
                draggedCard = cardType
                return NSItemProvider(object: cardType.rawValue as NSString)
            }
            .onDrop(of: [.text], delegate: ProgressStoryCardDropDelegate(
                cardType: cardType,
                visibleCards: visibleCards,
                draggedCard: $draggedCard,
                cardManager: cardManager
            ))
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeInOut(duration: 0.4), value: isAnimating)
    }

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.65))
            .padding(.vertical, 6)
            .accessibilityHidden(true)
    }
}
