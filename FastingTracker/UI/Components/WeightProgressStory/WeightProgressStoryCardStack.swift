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
    let cards: [ProgressStoryCardType]
    let contentIDs: ProgressStoryContentIDs
    let context: ProgressStoryCardContext
    let isAnimating: Bool
    @ObservedObject private var optOutManager: ContentOptOutManager
    @ObservedObject private var cardManager: CardManager<ProgressStoryCardType>
    @Binding private var draggedCard: ProgressStoryCardType?
    let reflectionTap: () -> Void

    init(cards: [ProgressStoryCardType],
         optOutManager: ContentOptOutManager,
         cardManager: CardManager<ProgressStoryCardType>,
         contentIDs: ProgressStoryContentIDs,
         context: ProgressStoryCardContext,
         isAnimating: Bool,
         draggedCard: Binding<ProgressStoryCardType?>,
         reflectionTap: @escaping () -> Void) {
        self.cards = cards
        self.contentIDs = contentIDs
        self.context = context
        self.isAnimating = isAnimating
        _optOutManager = ObservedObject(wrappedValue: optOutManager)
        _cardManager = ObservedObject(wrappedValue: cardManager)
        _draggedCard = draggedCard
        self.reflectionTap = reflectionTap
    }

    var body: some View {
        ForEach(cards, id: \.self) { cardType in
            Group {
                switch cardType {
                case .sevenDay:
                    if !optOutManager.isContentOptedOut(id: contentIDs.sevenDay) {
                        CircularTrendRingCard(
                            periodLabel: "7 DAYS",
                            delta: context.sevenDayDelta,
                            surfaceStyle: .ice,
                            onHide: { hideCard(.sevenDay) }
                        )
                    }

                case .banner:
                    if !optOutManager.isContentOptedOut(id: contentIDs.banner) {
                        ProgressBanner(
                            text: context.bannerText,
                            accent: context.bannerAccent,
                            onHide: { hideCard(.banner) }
                        )
                    }

                case .thirtyDay:
                    if !optOutManager.isContentOptedOut(id: contentIDs.thirtyDay) {
                        CircularTrendRingCard(
                            periodLabel: "30 DAYS",
                            delta: context.thirtyDayDelta,
                            surfaceStyle: .ivory,
                            onHide: { hideCard(.thirtyDay) }
                        )
                    }

                case .reflection:
                    if !optOutManager.isContentOptedOut(id: contentIDs.reflection) {
                        ReflectionNudge(
                            text: context.reflectionPrompt,
                            onHide: { hideCard(.reflection) },
                            onTap: reflectionTap
                        )
                    }

                case .recap:
                    if !optOutManager.isContentOptedOut(id: contentIDs.recap) {
                        RecapRow(
                            netDelta: context.netDelta30d,
                            bestStreak: context.bestStreak,
                            entries: context.totalEntries,
                            onHide: { hideCard(.recap) }
                        )
                    }

                case .didYouKnow:
                    if context.totalEntries >= 5 && !optOutManager.isContentOptedOut(id: contentIDs.didYouKnow) {
                        DidYouKnowBanner(
                            text: context.didYouKnowText,
                            onHide: { hideCard(.didYouKnow) }
                        )
                    }

                case .coachBar:
                    EmptyView()
                }
            }
            .onDrag {
                draggedCard = cardType
                return NSItemProvider(object: cardType.rawValue as NSString)
            }
            .onDrop(of: [.text], delegate: ProgressStoryCardDropDelegate(
                cardType: cardType,
                visibleCards: cards,
                draggedCard: $draggedCard,
                cardManager: cardManager
            ))
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeInOut(duration: 0.4), value: isAnimating)
        }
    }

    // MARK: - Private

    private func hideCard(_ cardType: ProgressStoryCardType) {
        withAnimation(.easeInOut(duration: 0.25)) {
            cardManager.hideCard(cardType)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
