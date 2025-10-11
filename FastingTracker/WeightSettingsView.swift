import SwiftUI

struct WeightSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var weightManager: WeightManager
    @Binding var showGoalLine: Bool
    @Binding var weightGoal: Double

    @State private var weightGoalString: String = ""
    @State private var localSyncEnabled: Bool = true
    @State private var userSyncPreference: Bool = true
    @State private var isSyncing: Bool = false
    @State private var showingSyncAlert: Bool = false
    @State private var syncMessage: String = ""
    @State private var hasHealthKitPermission: Bool = false
    @State private var permissionStatusMessage: String = ""
    @State private var canEnableSync: Bool = true
    @State private var lastSyncStatus: String = ""
    @State private var showingWeightSyncDetails: Bool = false
    @State private var showingSyncPreferenceDialog: Bool = false

    // Industry standard: One-time historical import choice tracking
    // Following Apple iCloud, MyFitnessPal patterns - ask once, then auto-sync forever
    private let userDefaults = UserDefaults.standard
    private let hasCompletedInitialImportKey = "weightHasCompletedInitialImport"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("APPLE HEALTH")) {
                    // Following Apple Settings app navigation row pattern - like main Settings screen
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .frame(width: 29, height: 29)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync Weight with Apple Health")
                                .font(.body)

                            // Status line with icon - matching main Settings pattern
                            HStack(spacing: 4) {
                                if self.hasHealthKitPermission, !self.lastSyncStatus.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(self.lastSyncStatus)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if self.hasHealthKitPermission {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text("Ready to sync")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text("Not synced")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Spacer()

                        // Chevron to indicate navigation - like main Settings
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Open detailed weight sync settings
                        self.showWeightSyncDetails()
                    }
                }

                Section(header: Text("Weight Goal")) {
                    Toggle("Show Goal Line on Chart", isOn: self.$showGoalLine)

                    if self.showGoalLine {
                        HStack {
                            Text("Goal Weight")
                            TextField("Enter goal", text: self.$weightGoalString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .onAppear {
                                    self.weightGoalString = String(format: "%.1f", self.weightGoal)
                                }
                            Text("lbs")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Total Entries")
                        Spacer()
                        Text("\(self.weightManager.weightEntries.count)")
                            .foregroundColor(.secondary)
                    }

                    if let oldest = weightManager.weightEntries.last {
                        HStack {
                            Text("Tracking Since")
                            Spacer()
                            Text(oldest.date, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Weight Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Update weight goal if valid
                        if let newGoal = Double(weightGoalString), newGoal > 0 {
                            self.weightGoal = newGoal
                        }
                        self.dismiss()
                    }
                }
            }
        }
        .onAppear {
            self.userSyncPreference = self.weightManager.syncWithHealthKit
            self.weightGoalString = String(format: "%.1f", self.weightGoal)
            self.updatePermissionStatus()
            self.loadLastSyncStatus()
            self.updateToggleState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Following iOS best practices: Update permission status when returning from Settings
            // Reference: https://developer.apple.com/documentation/uikit/uiapplication/willenterforegroundnotification
            self.updatePermissionStatus()
            self.loadLastSyncStatus()
            self.updateToggleState()
        }
        .alert("Sync Status", isPresented: self.$showingSyncAlert) {
            // Following Apple HIG: Handle different authorization states appropriately
            if self.syncMessage.contains("Permission denied") || self.syncMessage.contains("enable weight access") {
                // Check if we can re-request authorization or if user must go to Settings
                let authStatus = HealthKitManager.shared.getWeightAuthorizationStatus()

                if authStatus == .notDetermined {
                    // Can still show native dialog
                    Button("Try Again") {
                        self.syncWithHealthKit()
                    }
                } else {
                    // Previously denied - must go to Settings manually
                    Button("OK") {}
                }
                Button("Cancel", role: .cancel) {}
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: {
            Text(self.syncMessage)
        }
        .alert("Import Weight Data", isPresented: self.$showingSyncPreferenceDialog) {
            // Following Apple HIG: Clear primary and secondary actions for data import choice
            // Reference: iCloud merge dialog, Screen Time setup onboarding
            Button("Import All Historical Data") {
                // User chose to import all historical weight data
                self.performHistoricalSync()
            }
            Button("Future Data Only") {
                // User chose to sync only future weight entries
                self.performFutureOnlySync()
            }
            Button("Cancel", role: .cancel) {
                // User cancelled - disable sync preference
                self.userSyncPreference = false
                self.localSyncEnabled = false
                self.updateToggleState()
            }
        } message: {
            // Following Apple system dialog messaging patterns
            // Reference: Photos library access, Health data permissions
            Text(
                "Choose how to sync your weight data with Apple Health. You can import all your historical weight entries or start fresh with only future entries."
            )
        }
        .sheet(isPresented: self.$showingWeightSyncDetails) {
            NavigationView {
                Form {
                    Section(header: Text("APPLE HEALTH INTEGRATION")) {
                        Toggle("Sync with Apple Health", isOn: self.$localSyncEnabled)
                            .disabled(!self.canEnableSync)
                            .onChange(of: self.localSyncEnabled) { _, newValue in
                                // Save user preference
                                self.userSyncPreference = newValue
                                // Only apply to WeightManager if permissions allow
                                if self.canEnableSync {
                                    self.weightManager.setSyncPreference(newValue)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    self.updatePermissionStatus()
                                    self.updateToggleState()
                                }
                            }

                        if self.localSyncEnabled {
                            Button(action: {
                                self.syncWithHealthKit()
                            }) {
                                HStack {
                                    if self.isSyncing {
                                        ProgressView()
                                            .padding(.trailing, 4)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                    }
                                    Text(self.isSyncing ? "Syncing..." : "Sync Now")
                                }
                            }
                            .disabled(self.isSyncing || !self.hasHealthKitPermission)
                            .foregroundColor(self.hasHealthKitPermission ? .blue : .secondary)
                        }

                        // Dynamic permission status message
                        if !self.hasHealthKitPermission {
                            Text(self.permissionStatusMessage)
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else if !self.lastSyncStatus.isEmpty {
                            Text(self.lastSyncStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle("Weight Sync")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            self.showingWeightSyncDetails = false
                        }
                    }
                }
            }
        }
    }

    private func showWeightSyncDetails() {
        self.showingWeightSyncDetails = true
    }

    private func syncWithHealthKit() {
        print("\n🔄 WeightSettingsView: Sync with HealthKit button tapped")
        self.isSyncing = true

        // BLOCKER 5 FIX: Check WEIGHT authorization specifically (granular)
        // Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy
        let isAuthorized = HealthKitManager.shared.isWeightAuthorized()
        print("Weight Authorization Status: \(isAuthorized ? "✅ Authorized" : "❌ Not Authorized")")

        if !isAuthorized {
            // Request WEIGHT authorization only (not all permissions)
            print("📱 WeightSettingsView: Requesting WEIGHT authorization (granular)...")
            HealthKitManager.shared.requestWeightAuthorization { success, error in
                if success {
                    print("✅ WeightSettingsView: Weight authorization granted")
                    // Check if initial import choice was already made
                    DispatchQueue.main.async {
                        self.isSyncing = false
                        if self.hasCompletedInitialImport() {
                            // User already made choice - proceed with regular sync
                            self.performSync()
                        } else {
                            // First time - show historical import choice dialog
                            self.showingSyncPreferenceDialog = true
                        }
                    }
                } else {
                    print("❌ WeightSettingsView: Weight authorization denied")
                    self.isSyncing = false
                    self.syncMessage = error?.localizedDescription ?? "HealthKit authorization required. Enable weight access in: Settings → Privacy & Security → Health → Data Access & Devices → Fast LIFe → Turn on Weight."
                    self.showingSyncAlert = true
                }
            }
        } else {
            print("✅ WeightSettingsView: Already authorized")
            // Already authorized - check if initial import choice was made
            if self.hasCompletedInitialImport() {
                print("✅ Initial import completed - proceeding with regular sync")
                // User already made choice - proceed with regular sync
                self.performSync()
            } else {
                print("📋 First time - showing historical import choice dialog")
                // First time - show historical import choice dialog
                // Following industry standards: One-time choice, then seamless sync
                self.isSyncing = false
                self.showingSyncPreferenceDialog = true
            }
        }
    }

    private func updatePermissionStatus() {
        // Following Apple HIG: Provide proactive feedback about system state
        self.hasHealthKitPermission = HealthKitManager.shared.isWeightAuthorized()
        let authStatus = HealthKitManager.shared.getWeightAuthorizationStatus()

        // Determine if user can enable sync toggle
        // Enable toggle when: permissions granted OR not yet determined (can request)
        // Disable toggle when: permissions explicitly denied (must go to Settings)
        self.canEnableSync = (authStatus != .sharingDenied)

        if self.hasHealthKitPermission {
            self.permissionStatusMessage = "When enabled, weight entries will be synced with Apple Health automatically."
        } else {
            if authStatus == .notDetermined {
                self.permissionStatusMessage = "Tap 'Sync Now' to set up Apple Health integration for weight tracking."
            } else {
                self.permissionStatusMessage = "Permission denied. Enable weight access in: Settings → Privacy & Security → Health → Data Access & Devices → Fast LIFe → Turn on Weight."
            }
        }
    }

    private func updateToggleState() {
        // Following Apple Settings app pattern: Toggle reflects actual functional state
        // Reference: Screen Time, Location Services - disabled features show as OFF
        if self.hasHealthKitPermission {
            // Permissions granted: show user preference
            self.localSyncEnabled = self.userSyncPreference
        } else {
            // No permissions: toggle must be OFF regardless of user preference
            self.localSyncEnabled = false
        }
    }

    private func loadLastSyncStatus() {
        // Following Apple Settings app pattern: Show last sync timestamp and status
        // Reference: iCloud backup, Screen Time sync status display
        if let lastSyncDate = HealthKitManager.shared.lastWeightSyncDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short

            let timeString = formatter.string(from: lastSyncDate)

            // Check for sync errors
            if HealthKitManager.shared.lastWeightSyncError != nil {
                self.lastSyncStatus = "Last sync failed at \(timeString)"
            } else {
                if Calendar.current.isDateInToday(lastSyncDate) {
                    self.lastSyncStatus = "Last synced today at \(timeString)"
                } else {
                    formatter.dateStyle = .short
                    self.lastSyncStatus = "Last synced \(formatter.string(from: lastSyncDate))"
                }
            }
        } else {
            self.lastSyncStatus = ""
        }
    }

    private func performSync() {
        // INDUSTRY STANDARD FIX: Use comprehensive sync to ensure all entries are captured
        // Following MyFitnessPal pattern: Once user chooses historical import, maintain comprehensive scope
        // Use 10-year lookback to ensure we capture all possible historical data
        let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()

        // Use anchored sync with anchor reset for deletion detection
        // Following Apple HealthKit Programming Guide: Use anchored query with reset for manual sync
        self.weightManager.syncFromHealthKitWithReset(startDate: startDate) { syncedCount, error in
            DispatchQueue.main.async {
                self.isSyncing = false

                if let error = error {
                    // Handle sync errors with user-friendly messages
                    self.syncMessage = error.localizedDescription
                    self.showingSyncAlert = true
                    AppLogger.error("Weight sync failed", category: AppLogger.weightTracking, error: error)
                } else {
                    // Report accurate sync results based on actual HealthKit data transfer
                    if syncedCount > 0 {
                        self.syncMessage = "Successfully synced \(syncedCount) new weight entries from Apple Health."
                    } else {
                        // Could mean: no new data, no permission, or all data already synced
                        let hasPermission = HealthKitManager.shared.isWeightAuthorized()
                        if hasPermission {
                            self.syncMessage = "Weight data is up to date. No new entries found in Apple Health."
                        } else {
                            // Check authorization status to provide appropriate message
                            let authStatus = HealthKitManager.shared.getWeightAuthorizationStatus()
                            if authStatus == .notDetermined {
                                self.syncMessage = "HealthKit access not set up. Tap 'Try Again' to grant weight tracking permissions."
                            } else {
                                self.syncMessage = "Permission denied. To enable weight sync, go to: Settings → Privacy & Security → Health → Data Access & Devices → Fast LIFe → Turn on Weight."
                            }
                        }
                    }
                    self.showingSyncAlert = true
                    AppLogger.info(
                        "Weight sync completed: \(syncedCount) new entries",
                        category: AppLogger.weightTracking
                    )

                    // Update permission status and sync history after sync attempt
                    self.updatePermissionStatus()
                    self.loadLastSyncStatus()
                    self.updateToggleState()

                    // If permissions were granted, apply user preference to WeightManager
                    if self.hasHealthKitPermission, self.userSyncPreference {
                        self.weightManager.setSyncPreference(true)
                    }
                }
            }
        }
    }

    // MARK: - Sync Preference Dialog Actions

    private func performHistoricalSync() {
        print("🔄 WeightSettingsView: User chose to import all historical weight data")
        // Mark initial import as completed - no more dialogs needed
        self.markInitialImportCompleted()
        self.isSyncing = true

        // Following Apple HealthKit Programming Guide: Import all historical data
        // Use extended date range to capture all available weight entries
        let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()

        self.weightManager.syncFromHealthKitHistorical(startDate: startDate) { syncedCount, error in
            DispatchQueue.main.async {
                self.isSyncing = false

                if let error = error {
                    self.syncMessage = "Failed to import historical weight data: \(error.localizedDescription)"
                    self.showingSyncAlert = true
                    AppLogger.error("Historical weight sync failed", category: AppLogger.weightTracking, error: error)
                } else {
                    if syncedCount > 0 {
                        self.syncMessage = "Successfully imported \(syncedCount) weight entries from your Apple Health history."
                    } else {
                        self.syncMessage = "All weight data is already up to date. No new historical entries found."
                    }
                    self.showingSyncAlert = true
                    AppLogger.info(
                        "Historical weight sync completed: \(syncedCount) entries imported",
                        category: AppLogger.weightTracking
                    )

                    // Enable sync preference and update UI
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

    private func performFutureOnlySync() {
        print("🔄 WeightSettingsView: User chose to sync only future weight data")
        // Mark initial import as completed - no more dialogs needed
        self.markInitialImportCompleted()

        // Following Apple HIG: Provide clear feedback for user choice
        self.syncMessage = "Weight sync enabled. Only new weight entries will be synced going forward."
        self.showingSyncAlert = true
        AppLogger.info("Future-only weight sync enabled", category: AppLogger.weightTracking)

        // Enable sync preference for future data only
        if self.hasHealthKitPermission {
            self.weightManager.setSyncPreference(true)
            self.userSyncPreference = true
            self.updatePermissionStatus()
            self.loadLastSyncStatus()
            self.updateToggleState()
        }
    }

    // MARK: - One-Time Setup Helper

    /// Check if user has completed initial historical import choice
    /// Following industry standard: One-time setup, then seamless auto-sync
    private func hasCompletedInitialImport() -> Bool {
        let completed = self.userDefaults.bool(forKey: self.hasCompletedInitialImportKey)
        AppLogger.info(
            "Checking initial import status: \(completed ? "COMPLETED" : "NOT COMPLETED")",
            category: AppLogger.weightTracking
        )
        return completed
    }

    /// Mark initial import as completed to prevent repeated dialogs
    /// Following Apple iCloud pattern: Ask once during setup, then auto-sync forever
    private func markInitialImportCompleted() {
        self.userDefaults.set(true, forKey: self.hasCompletedInitialImportKey)
        // Force immediate synchronization to prevent timing issues
        // Following Apple UserDefaults best practices for critical flags
        self.userDefaults.synchronize()
        AppLogger.info("Initial import marked as completed and synchronized", category: AppLogger.weightTracking)
    }
}

#Preview {
    WeightSettingsView(
        weightManager: WeightManager(),
        showGoalLine: .constant(true),
        weightGoal: .constant(180.0)
    )
}
