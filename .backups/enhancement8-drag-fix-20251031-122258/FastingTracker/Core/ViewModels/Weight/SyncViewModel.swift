import SwiftUI

/// ViewModel for Weight HealthKit Sync Management
/// Handles HealthKit authorization, sync operations, and sync state
/// Extracted from WeightControlCenterViewModel as part of Phase 8.9 Phase 2
/// Reference: HANDOFF.md - Weight Tracker Refactoring
@MainActor
class SyncViewModel: ObservableObject {
    // MARK: - Published State

    /// Local sync toggle state (reflects both permission and user preference)
    @Published var localSyncEnabled: Bool = true

    /// User's sync preference (saved independent of permission state)
    @Published var userSyncPreference: Bool = true

    /// Sync operation in progress
    @Published var isSyncing: Bool = false

    /// Show sync result alert
    @Published var showingSyncAlert: Bool = false

    /// Sync result message (success or error)
    @Published var syncMessage: String = ""

    /// HealthKit permission granted
    @Published var hasHealthKitPermission: Bool = false

    /// Permission status message for UI display
    @Published var permissionStatusMessage: String = ""

    /// Can user enable sync (false if permission denied)
    @Published var canEnableSync: Bool = true

    /// Last sync status string (e.g., "Last synced today at 2:30 PM")
    @Published var lastSyncStatus: String = ""

    /// Show weight sync details sheet
    @Published var showingWeightSyncDetails: Bool = false

    /// Show sync preference dialog (historical vs future-only)
    @Published var showingSyncPreferenceDialog: Bool = false

    // MARK: - Dependencies

    private let weightManager: WeightManager
    private let userDefaults = UserDefaults.standard
    private let hasCompletedInitialImportKey = "weightHasCompletedInitialImport"

    // MARK: - Initialization

    init(weightManager: WeightManager) {
        self.weightManager = weightManager
        updatePermissionStatus()
        loadLastSyncStatus()
        updateToggleState()
    }

    // MARK: - Sync Methods

    /// Initiate sync with HealthKit
    func syncWithHealthKit() {
        isSyncing = true

        let isAuthorized = HealthKitManager.shared.isWeightAuthorized()

        if !isAuthorized {
            HealthKitManager.shared.requestWeightAuthorization { success, error in
                Task { @MainActor in
                    if success {
                        self.isSyncing = false
                        if self.hasCompletedInitialImport() {
                            self.performSync()
                        } else {
                            self.showingSyncPreferenceDialog = true
                        }
                    } else {
                        self.isSyncing = false
                        self.syncMessage = error?.localizedDescription ?? "HealthKit authorization required. Enable weight access in Settings."
                        self.showingSyncAlert = true
                    }
                }
            }
        } else {
            if hasCompletedInitialImport() {
                performSync()
            } else {
                isSyncing = false
                showingSyncPreferenceDialog = true
            }
        }
    }

    /// Perform sync operation (fetches last 10 years)
    func performSync() {
        let startDate = Calendar.current.date(byAdding: .year, value: -WeightConstants.SyncTiming.defaultHistoricalLookbackYears, to: Date()) ?? Date()

        weightManager.syncFromHealthKitWithReset(startDate: startDate) { syncedCount, error in
            Task { @MainActor in
                self.isSyncing = false

                if let error = error {
                    self.syncMessage = error.localizedDescription
                    self.showingSyncAlert = true
                } else {
                    if syncedCount > 0 {
                        self.syncMessage = "Successfully synced \(syncedCount) new weight entries from Apple Health."
                    } else {
                        let hasPermission = HealthKitManager.shared.isWeightAuthorized()
                        if hasPermission {
                            self.syncMessage = "Weight data is up to date. No new entries found in Apple Health."
                        } else {
                            self.syncMessage = "Permission denied. To enable weight sync, go to Settings → Privacy → Health."
                        }
                    }
                    self.showingSyncAlert = true

                    self.updatePermissionStatus()
                    self.loadLastSyncStatus()
                    self.updateToggleState()

                    if self.hasHealthKitPermission && self.userSyncPreference {
                        self.weightManager.setSyncPreference(true)
                    }
                }
            }
        }
    }

    /// Perform historical sync (imports all data from last 10 years)
    func performHistoricalSync() {
        markInitialImportCompleted()
        isSyncing = true

        let startDate = Calendar.current.date(byAdding: .year, value: -WeightConstants.SyncTiming.defaultHistoricalLookbackYears, to: Date()) ?? Date()

        weightManager.syncFromHealthKitHistorical(startDate: startDate) { syncedCount, error in
            Task { @MainActor in
                self.isSyncing = false

                if let error = error {
                    self.syncMessage = "Failed to import historical weight data: \(error.localizedDescription)"
                    self.showingSyncAlert = true
                } else {
                    if syncedCount > 0 {
                        self.syncMessage = "Successfully imported \(syncedCount) weight entries from your Apple Health history."
                    } else {
                        self.syncMessage = "All weight data is already up to date. No new historical entries found."
                    }
                    self.showingSyncAlert = true

                    if self.hasHealthKitPermission {
                        self.weightManager.setSyncPreference(true)
                        self.userSyncPreference = true
                        self.updatePermissionStatus()
                        self.loadLastSyncStatus()
                        self.updateToggleState()
                    }
                }
            }
        }
    }

    /// Perform future-only sync (no historical import)
    func performFutureOnlySync() {
        markInitialImportCompleted()

        syncMessage = "Weight sync enabled. Only new weight entries will be synced going forward."
        showingSyncAlert = true

        if hasHealthKitPermission {
            weightManager.setSyncPreference(true)
            userSyncPreference = true
            updatePermissionStatus()
            loadLastSyncStatus()
            updateToggleState()
        }
    }

    // MARK: - Permission Management

    /// Update HealthKit permission status and messages
    func updatePermissionStatus() {
        hasHealthKitPermission = HealthKitManager.shared.isWeightAuthorized()
        let authStatus = HealthKitManager.shared.getWeightAuthorizationStatus()

        canEnableSync = (authStatus != .sharingDenied)

        if hasHealthKitPermission {
            permissionStatusMessage = "When enabled, weight entries will sync automatically."
        } else {
            if authStatus == .notDetermined {
                permissionStatusMessage = "Tap 'Sync Now' to set up Apple Health integration."
            } else {
                permissionStatusMessage = "Permission denied. Enable in Settings → Privacy → Health."
            }
        }
    }

    /// Update toggle state based on permission and user preference
    func updateToggleState() {
        if hasHealthKitPermission {
            localSyncEnabled = userSyncPreference
        } else {
            localSyncEnabled = false
        }
    }

    /// Load and format last sync status
    func loadLastSyncStatus() {
        if let lastSyncDate = HealthKitManager.shared.lastWeightSyncDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short

            let timeString = formatter.string(from: lastSyncDate)

            if HealthKitManager.shared.lastWeightSyncError != nil {
                lastSyncStatus = "Last sync failed at \(timeString)"
            } else {
                if Calendar.current.isDateInToday(lastSyncDate) {
                    lastSyncStatus = "Last synced today at \(timeString)"
                } else {
                    formatter.dateStyle = .short
                    lastSyncStatus = "Last synced \(formatter.string(from: lastSyncDate))"
                }
            }
        } else {
            lastSyncStatus = ""
        }
    }

    // MARK: - Initial Import State

    /// Check if user has completed initial import choice
    func hasCompletedInitialImport() -> Bool {
        return userDefaults.bool(forKey: hasCompletedInitialImportKey)
    }

    /// Mark initial import as completed
    private func markInitialImportCompleted() {
        userDefaults.set(true, forKey: hasCompletedInitialImportKey)
        userDefaults.synchronize()
    }
}
