//
// WeightControlCenterCoordinator.swift
// FastLIFe
//
// Coordinator pattern for WeightControlCenterView
// Orchestrates multiple focused ViewModels for better separation of concerns
//

import SwiftUI
import Foundation

/// WeightControlCenterCoordinator
/// Coordinates all ViewModels for the Weight Control Center
/// Following Coordinator pattern to avoid massive ViewModels
@MainActor
class WeightControlCenterCoordinator: ObservableObject {
    // MARK: - Dependencies
    let weightManager: WeightManager
    let behavioralScheduler: BehavioralNotificationScheduler

    // MARK: - Child ViewModels
    let trackerCardManager: TrackerCardManaging
    let progressStoryCardManager: ProgressStoryCardManaging
    let optOutManager: ContentOptOutManaging

    let cardsViewModel = CardsViewModel()
    let badgesViewModel = BadgesViewModel()
    let preferencesViewModel: PreferencesViewModel
    let goalsViewModel = GoalsViewModel()
    let notificationsViewModel = NotificationsViewModel()
    let syncViewModel: SyncViewModel

    // MARK: - Initialization
    init(weightManager: WeightManager,
         behavioralScheduler: BehavioralNotificationScheduler,
         trackerCardManager: TrackerCardManaging,
         progressStoryCardManager: ProgressStoryCardManaging,
         optOutManager: ContentOptOutManaging) {
        self.weightManager = weightManager
        self.behavioralScheduler = behavioralScheduler
        self.trackerCardManager = trackerCardManager
        self.progressStoryCardManager = progressStoryCardManager
        self.optOutManager = optOutManager
        self.preferencesViewModel = PreferencesViewModel(
            optOutManager: self.optOutManager,
            cardManager: self.trackerCardManager,
            progressStoryCardManager: self.progressStoryCardManager
        )
        self.syncViewModel = SyncViewModel(weightManager: weightManager)
    }

    convenience init(weightManager: WeightManager,
                     behavioralScheduler: BehavioralNotificationScheduler) {
        self.init(
            weightManager: weightManager,
            behavioralScheduler: behavioralScheduler,
            trackerCardManager: TrackerCards.shared,
            progressStoryCardManager: ProgressStoryCards.shared,
            optOutManager: ContentOptOutManager.shared
        )
    }

    // MARK: - Computed Properties
    var shouldShowRestoreButton: Bool {
        preferencesViewModel.shouldShowRestoreButton
    }

    // MARK: - Actions
    func restoreAllToDefault() {
        // Delegate to PreferencesViewModel which handles all restore logic
        preferencesViewModel.restoreAllToDefault()

        // Reset sync preference and data (Weight tracker specific)
        weightManager.setSyncPreference(false)
        weightManager.deleteAllWeightData()

        // Reset cards view model states
        cardsViewModel.cardOrder = ControlCenterCardType.allCases
        cardsViewModel.expandedCards.removeAll()
        cardsViewModel.draggedCard = nil

        // Reset badges and goals view models
        badgesViewModel.badgeScale = 1.0
        badgesViewModel.highlightedItemID = nil
        badgesViewModel.scrollViewProxy = nil

        goalsViewModel.weightGoalString = ""

        // Reset notification settings
        notificationsViewModel.weightRemindersEnabled = false
        notificationsViewModel.timingMode = .specificTime
        notificationsViewModel.preferredReminderTime = Date()
        notificationsViewModel.minutesOffset = 30
        notificationsViewModel.quietHoursEnabled = false
        notificationsViewModel.quietHoursStart = Date()
        notificationsViewModel.quietHoursEnd = Date()
        notificationsViewModel.skipWeekdays.removeAll()
        notificationsViewModel.didYouKnowEnabled = false
        notificationsViewModel.didYouKnowFrequency = .daily
        notificationsViewModel.motivationalEnabled = false
        notificationsViewModel.motivationalFrequency = .daily
        notificationsViewModel.actionStepsEnabled = false
        notificationsViewModel.actionStepsFrequency = .daily

        // Reset sync view model
        syncViewModel.localSyncEnabled = false
        syncViewModel.userSyncPreference = false
        syncViewModel.hasHealthKitPermission = false
        syncViewModel.canEnableSync = true
        syncViewModel.isSyncing = false
        syncViewModel.permissionStatusMessage = ""
        syncViewModel.lastSyncStatus = ""
        syncViewModel.showingSyncAlert = false
        syncViewModel.showingSyncPreferenceDialog = false
        syncViewModel.syncMessage = ""
    }
}
