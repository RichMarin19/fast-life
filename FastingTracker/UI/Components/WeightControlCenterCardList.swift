import SwiftUI

/// Lazy stack of Control Center cards with shared padding and reorder support.
/// Keeps the primary view lean while preserving the existing drag/drop + sheet wiring.
struct WeightControlCenterCardList: View {
    @ObservedObject var viewModel: WeightControlCenterViewModel
    @Binding var showGoalLine: Bool
    @Binding var weightGoal: Double
    @Binding var showDeleteAllConfirmation: Bool

    var body: some View {
        ScrollViewReader { proxy in
            LazyVStack(spacing: DSSpacing.cardSectionSpacing) {
                ForEach(viewModel.cardOrder) { cardType in
                    card(for: cardType)
                }

                WeightControlCenterAboutCard(viewModel: viewModel)
            }
            .padding(.horizontal, DSSpacing.cardSectionSpacing)
            .padding(.top, DSSpacing.cardSmallSpacing)
            .onAppear {
                viewModel.scrollViewProxy = proxy
            }
        }
    }

    @ViewBuilder
    private func card(for cardType: ControlCenterCardType) -> some View {
        WeightControlCenterCard(
            cardType: cardType,
            viewModel: viewModel,
            title: cardType.title,
            subtitle: subtitle(for: cardType),
            icon: cardType.icon
        ) {
            switch cardType {
            case .goals:
                WeightControlCenterGoalsCard(
                    viewModel: viewModel,
                    goalCoordinator: viewModel.goalCoordinator,
                    showGoalLine: $showGoalLine,
                    weightGoal: $weightGoal
                )
            case .notifications:
                WeightControlCenterNotificationsCard(coordinator: viewModel.notificationCoordinator)
            case .sync:
                WeightControlCenterSyncCard(
                    viewModel: viewModel,
                    showDeleteAllConfirmation: $showDeleteAllConfirmation
                )
            case .insights:
                WeightControlCenterInsightsCard()
            case .experience:
                WeightControlCenterExperienceCard(viewModel: viewModel)
            case .history:
                WeightControlCenterHistoryCard(viewModel: viewModel)
            }
        }
    }

    private func subtitle(for type: ControlCenterCardType) -> String? {
        switch type {
        case .goals:
            return "Set your start point, goal, and milestones"
        case .notifications:
            return "Fine-tune reminders so they feel personal"
        case .insights:
            return "Choose the guidance you want to see most"
        case .sync:
            return "Control how Apple Health powers your data"
        case .history:
            return "Review and manage logged weight entries"
        case .experience:
            return "Opt in to the motivation styles that work for you"
        }
    }
}

#Preview("Weight Control Center Card List") {
    ScrollView {
        WeightControlCenterCardList(
            viewModel: WeightControlCenterViewModel(
                weightManager: WeightManager(),
                behavioralScheduler: BehavioralNotificationScheduler()
            ),
            showGoalLine: .constant(true),
            weightGoal: .constant(150.0),
            showDeleteAllConfirmation: .constant(false)
        )
    }
    .environmentObject(BehavioralNotificationScheduler())
}
