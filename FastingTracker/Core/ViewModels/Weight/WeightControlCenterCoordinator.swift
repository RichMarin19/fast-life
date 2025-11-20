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
    let healthKitManager: HealthKitManagerProtocol

    // MARK: - Child ViewModels
    let trackerCardManager: TrackerCardManaging
    let progressStoryCardManager: ProgressStoryCardManaging
    let optOutManager: ContentOptOutManaging

    let cardsViewModel = CardsViewModel()
    let badgesViewModel = BadgesViewModel()
    let preferencesViewModel: PreferencesViewModel
    let goalsViewModel = GoalsViewModel()
    let notificationsViewModel: NotificationsViewModel
    let syncViewModel: SyncViewModel

    // MARK: - Initialization
    init(weightManager: WeightManager,
         behavioralScheduler: BehavioralNotificationScheduler,
         healthKitManager: HealthKitManagerProtocol,
         trackerCardManager: TrackerCardManaging,
         progressStoryCardManager: ProgressStoryCardManaging,
         optOutManager: ContentOptOutManaging,
         preferencesViewModel: PreferencesViewModel) {
        self.weightManager = weightManager
        self.behavioralScheduler = behavioralScheduler
        self.healthKitManager = healthKitManager
        self.trackerCardManager = trackerCardManager
        self.progressStoryCardManager = progressStoryCardManager
        self.optOutManager = optOutManager
        self.preferencesViewModel = preferencesViewModel
        self.notificationsViewModel = NotificationsViewModel()
        self.syncViewModel = SyncViewModel(weightManager: weightManager, healthKitManager: healthKitManager)
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

// MARK: - Factories

extension WeightControlCenterCoordinator {
    @MainActor
    static func live(
        weightManager: WeightManager,
        behavioralScheduler: BehavioralNotificationScheduler,
        healthKitManager: HealthKitManagerProtocol? = nil,
        trackerCardManager: CardManager<TrackerCardType>? = nil,
        progressStoryCardManager: ProgressStoryCardManaging? = nil,
        optOutManager: ContentOptOutManaging? = nil
    ) -> WeightControlCenterCoordinator {
        let healthKitManager = healthKitManager ?? HealthKitManager.shared
        let trackerCards = trackerCardManager ?? TrackerCards.shared
        let progressCards = progressStoryCardManager ?? ProgressStoryCards.shared
        let optOut = optOutManager ?? ContentOptOutManager.shared
        let preferences = PreferencesViewModel(
            optOutManager: optOut,
            cardManager: trackerCards,
            progressStoryCardManager: progressCards
        )
        return WeightControlCenterCoordinator(
            weightManager: weightManager,
            behavioralScheduler: behavioralScheduler,
            healthKitManager: healthKitManager,
            trackerCardManager: trackerCards,
            progressStoryCardManager: progressCards,
            optOutManager: optOut,
            preferencesViewModel: preferences
        )
    }
}
