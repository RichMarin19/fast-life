import SwiftUI
import Combine

/// Coordinator for Weight Control Center
/// Orchestrates 6 focused ViewModels and provides unified interface to View layer
/// Replaces monolithic WeightControlCenterViewModel (902 LOC → 6 focused ViewModels)
/// Industry Pattern: Coordinator Pattern (WWDC 2020 - Building for iPad)
/// Reference: Phase 8.9 Phase 2 - Weight Tracker Refactoring
@MainActor
class WeightControlCenterCoordinator: ObservableObject {
    // MARK: - Sub-ViewModels (Focused Responsibilities)

    /// Handles card order, expansion, drag/drop
    let cardsViewModel: CardsViewModel

    /// Handles weight goal input and validation
    let goalsViewModel: GoalsViewModel

    /// Handles badge interactions and highlighting
    let badgesViewModel: BadgesViewModel

    /// Handles experience opt-outs and content preferences
    let preferencesViewModel: PreferencesViewModel

    /// Handles HealthKit sync operations
    let syncViewModel: SyncViewModel

    /// Handles weight reminder notifications
    let notificationsViewModel: NotificationsViewModel

    // MARK: - Dependencies (Pass-through to sub-ViewModels)

    let weightManager: WeightManager
    let behavioralScheduler: BehavioralNotificationScheduler

    // MARK: - Initialization

    init(weightManager: WeightManager, behavioralScheduler: BehavioralNotificationScheduler) {
        self.weightManager = weightManager
        self.behavioralScheduler = behavioralScheduler

        // Initialize all sub-ViewModels
        self.cardsViewModel = CardsViewModel()
        self.goalsViewModel = GoalsViewModel()
        self.badgesViewModel = BadgesViewModel()
        self.preferencesViewModel = PreferencesViewModel()
        self.syncViewModel = SyncViewModel(weightManager: weightManager)
        self.notificationsViewModel = NotificationsViewModel()
    }

    // MARK: - Convenience Methods (Delegate to Sub-ViewModels)

    /// Cycle to next opted-out item when badge is tapped
    /// Delegates to: BadgesViewModel, PreferencesViewModel
    func cycleToNextOptedOutItem() {
        let optedOutItems = preferencesViewModel.visuallyOrderedOptedOutItems
        badgesViewModel.cycleToNextOptedOutItem(optedOutItems)
    }

    /// Computed property: Should show restore button
    /// Delegates to: PreferencesViewModel
    var shouldShowRestoreButton: Bool {
        preferencesViewModel.shouldShowRestoreButton
    }

    /// Computed property: Visually ordered opted-out items
    /// Delegates to: PreferencesViewModel
    var visuallyOrderedOptedOutItems: [ContentItem] {
        preferencesViewModel.visuallyOrderedOptedOutItems
    }
}
