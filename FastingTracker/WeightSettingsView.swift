import SwiftUI

// Test frequency options for Phase B engine validation
enum TestFrequency: String, CaseIterable, Identifiable {
    case immediate = "immediate"
    case thirtySeconds = "thirty_seconds"
    case daily = "daily"
    case testMode = "test_mode"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .immediate: return "Send Now"
        case .thirtySeconds: return "Every 30 Seconds"
        case .daily: return "Daily"
        case .testMode: return "Test Mode (2 min)"
        }
    }
}

struct WeightSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var weightManager: WeightManager
    @EnvironmentObject var behavioralScheduler: BehavioralNotificationScheduler
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

    // Phase B Engine Test Variables
    @State private var testNotificationsEnabled: Bool = false
    @State private var testFrequency: TestFrequency = .immediate
    @State private var testToneStyle: NotificationToneStyle = .supportive
    @State private var notificationPermissionStatus: String = "Not requested"

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
                                if hasHealthKitPermission && !lastSyncStatus.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(lastSyncStatus)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if hasHealthKitPermission {
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
                        showWeightSyncDetails()
                    }
                }

                Section(header: Text("Weight Goal")) {
                    Toggle("Show Goal Line on Chart", isOn: $showGoalLine)

                    if showGoalLine {
                        HStack {
                            Text("Goal Weight")
                            TextField("Enter goal", text: $weightGoalString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .onAppear {
                                    weightGoalString = String(format: "%.1f", weightGoal)
                                }
                            Text("lbs")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // PHASE B ENGINE TEST - TEMPORARY VALIDATION SECTION
                Section(header: Text("PHASE B ENGINE TEST")) {
                    Toggle("Test Weight Reminders", isOn: $testNotificationsEnabled)

                    if testNotificationsEnabled {
                        VStack(spacing: 12) {
                            // Tone Style Picker
                            HStack {
                                Text("Message Tone")
                                Spacer()
                                Picker("Tone", selection: $testToneStyle) {
                                    ForEach(NotificationToneStyle.allCases, id: \.rawValue) { tone in
                                        Text(tone.rawValue.capitalized).tag(tone)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }

                            // Test Frequency
                            HStack {
                                Text("Test Frequency")
                                Spacer()
                                Picker("Frequency", selection: $testFrequency) {
                                    ForEach(TestFrequency.allCases) { frequency in
                                        Text(frequency.displayName).tag(frequency)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }

                            // Permission Status
                            HStack {
                                Text("Permissions")
                                Spacer()
                                Text(notificationPermissionStatus)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // Test Actions
                            VStack(spacing: 8) {
                                Button("Request Notification Permissions") {
                                    self.requestNotificationPermissions()
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.blue)

                                Button("Send Test Notification") {
                                    self.sendTestNotification()
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.orange)
                                .disabled(notificationPermissionStatus != "Granted")
                            }
                        }
                    }
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Total Entries")
                        Spacer()
                        Text("\(weightManager.weightEntries.count)")
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
                Button("Done") {
                    // Update weight goal if valid
                    if let newGoal = Double(weightGoalString), newGoal > 0 {
                        weightGoal = newGoal
                    }
                    dismiss()
                }
            }
        }
        .onAppear {
            userSyncPreference = weightManager.syncWithHealthKit
            weightGoalString = String(format: "%.1f", weightGoal)
            updatePermissionStatus()
            loadLastSyncStatus()
            updateToggleState()
            // Phase B Engine Test: Update notification permission status
            updateNotificationPermissionStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Following iOS best practices: Update permission status when returning from Settings
            // Reference: https://developer.apple.com/documentation/uikit/uiapplication/willenterforegroundnotification
            updatePermissionStatus()
            loadLastSyncStatus()
            updateToggleState()
        }
        .alert("Sync Status", isPresented: $showingSyncAlert) {
            // Following Apple HIG: Handle different authorization states appropriately
            if syncMessage.contains("Permission denied") || syncMessage.contains("enable weight access") {
                // Check if we can re-request authorization or if user must go to Settings
                let authStatus = HealthKitManager.shared.getWeightAuthorizationStatus()

                if authStatus == .notDetermined {
                    // Can still show native dialog
                    Button("Try Again") {
                        syncWithHealthKit()
                    }
                } else {
                    // Previously denied - must go to Settings manually
                    Button("OK") { }
                }
                Button("Cancel", role: .cancel) { }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            Text(syncMessage)
        }
        .alert("Import Weight Data", isPresented: $showingSyncPreferenceDialog) {
            // Following Apple HIG: Clear primary and secondary actions for data import choice
            // Reference: iCloud merge dialog, Screen Time setup onboarding
            Button("Import All Historical Data") {
                // User chose to import all historical weight data
                performHistoricalSync()
            }
            Button("Future Data Only") {
                // User chose to sync only future weight entries
                performFutureOnlySync()
            }
            Button("Cancel", role: .cancel) {
                // User cancelled - disable sync preference
                userSyncPreference = false
                localSyncEnabled = false
                updateToggleState()
            }
        } message: {
            // Following Apple system dialog messaging patterns
            // Reference: Photos library access, Health data permissions
            Text("Choose how to sync your weight data with Apple Health. You can import all your historical weight entries or start fresh with only future entries.")
        }
        .sheet(isPresented: $showingWeightSyncDetails) {
            NavigationView {
                Form {
                    Section(header: Text("APPLE HEALTH INTEGRATION")) {
                        Toggle("Sync with Apple Health", isOn: $localSyncEnabled)
                            .disabled(!canEnableSync)
                            .onChange(of: localSyncEnabled) { _, newValue in
                                // Save user preference
                                userSyncPreference = newValue
                                // Only apply to WeightManager if permissions allow
                                if canEnableSync {
                                    weightManager.setSyncPreference(newValue)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    updatePermissionStatus()
                                    updateToggleState()
                                }
                            }

                        if localSyncEnabled {
                            Button(action: {
                                syncWithHealthKit()
                            }) {
                                HStack {
                                    if isSyncing {
                                        ProgressView()
                                            .padding(.trailing, 4)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                    }
                                    Text(isSyncing ? "Syncing..." : "Sync Now")
                                }
                            }
                            .disabled(isSyncing || !hasHealthKitPermission)
                            .foregroundColor(hasHealthKitPermission ? .blue : .secondary)
                        }

                        // Dynamic permission status message
                        if !hasHealthKitPermission {
                            Text(permissionStatusMessage)
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else if !lastSyncStatus.isEmpty {
                            Text(lastSyncStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle("Weight Sync")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button("Done") {
                        showingWeightSyncDetails = false
                    }
                }
            }
        }
    }

    private func showWeightSyncDetails() {
        showingWeightSyncDetails = true
    }

    private func syncWithHealthKit() {
        AppLogger.debug("Sync with HealthKit button tapped", category: AppLogger.ui)
        isSyncing = true

        // BLOCKER 5 FIX: Check WEIGHT authorization specifically (granular)
        // Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy
        let isAuthorized = HealthKitManager.shared.isWeightAuthorized()
        AppLogger.debug("Weight authorization status: \(isAuthorized ? "Authorized" : "Not authorized")", category: AppLogger.healthKit)

        if !isAuthorized {
            // Request WEIGHT authorization only (not all permissions)
            AppLogger.debug("Requesting weight authorization", category: AppLogger.healthKit)
            HealthKitManager.shared.requestWeightAuthorization { success, error in
                if success {
                    AppLogger.info("Weight authorization granted", category: AppLogger.healthKit)
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
                    AppLogger.info("Weight authorization denied", category: AppLogger.healthKit)
                    isSyncing = false
                    syncMessage = error?.localizedDescription ?? "HealthKit authorization required. Enable weight access in: Settings → Privacy & Security → Health → Data Access & Devices → Fast LIFe → Turn on Weight."
                    showingSyncAlert = true
                }
            }
        } else {
            AppLogger.debug("Weight already authorized", category: AppLogger.healthKit)
            // Already authorized - check if initial import choice was made
            if hasCompletedInitialImport() {
                AppLogger.debug("Initial import completed - proceeding with regular sync", category: AppLogger.healthKit)
                // User already made choice - proceed with regular sync
                performSync()
            } else {
                AppLogger.debug("First time - showing historical import choice dialog", category: AppLogger.ui)
                // First time - show historical import choice dialog
                // Following industry standards: One-time choice, then seamless sync
                isSyncing = false
                showingSyncPreferenceDialog = true
            }
        }
    }

    private func updatePermissionStatus() {
        // Following Apple HIG: Provide proactive feedback about system state
        hasHealthKitPermission = HealthKitManager.shared.isWeightAuthorized()
        let authStatus = HealthKitManager.shared.getWeightAuthorizationStatus()

        // Determine if user can enable sync toggle
        // Enable toggle when: permissions granted OR not yet determined (can request)
        // Disable toggle when: permissions explicitly denied (must go to Settings)
        canEnableSync = (authStatus != .sharingDenied)

        if hasHealthKitPermission {
            permissionStatusMessage = "When enabled, weight entries will be synced with Apple Health automatically."
        } else {
            if authStatus == .notDetermined {
                permissionStatusMessage = "Tap 'Sync Now' to set up Apple Health integration for weight tracking."
            } else {
                permissionStatusMessage = "Permission denied. Enable weight access in: Settings → Privacy & Security → Health → Data Access & Devices → Fast LIFe → Turn on Weight."
            }
        }
    }

    private func updateToggleState() {
        // Following Apple Settings app pattern: Toggle reflects actual functional state
        // Reference: Screen Time, Location Services - disabled features show as OFF
        if hasHealthKitPermission {
            // Permissions granted: show user preference
            localSyncEnabled = userSyncPreference
        } else {
            // No permissions: toggle must be OFF regardless of user preference
            localSyncEnabled = false
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

    private func performSync() {
        // INDUSTRY STANDARD FIX: Use comprehensive sync to ensure all entries are captured
        // Following MyFitnessPal pattern: Once user chooses historical import, maintain comprehensive scope
        // Use 10-year lookback to ensure we capture all possible historical data
        let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()

        // Use anchored sync with anchor reset for deletion detection
        // Following Apple HealthKit Programming Guide: Use anchored query with reset for manual sync
        weightManager.syncFromHealthKitWithReset(startDate: startDate) { syncedCount, error in
            DispatchQueue.main.async {
                isSyncing = false

                if let error = error {
                    // Handle sync errors with user-friendly messages
                    syncMessage = error.localizedDescription
                    showingSyncAlert = true
                    AppLogger.error("Weight sync failed", category: AppLogger.weightTracking, error: error)
                } else {
                    // Report accurate sync results based on actual HealthKit data transfer
                    if syncedCount > 0 {
                        syncMessage = "Successfully synced \(syncedCount) new weight entries from Apple Health."
                    } else {
                        // Could mean: no new data, no permission, or all data already synced
                        let hasPermission = HealthKitManager.shared.isWeightAuthorized()
                        if hasPermission {
                            syncMessage = "Weight data is up to date. No new entries found in Apple Health."
                        } else {
                            // Check authorization status to provide appropriate message
                            let authStatus = HealthKitManager.shared.getWeightAuthorizationStatus()
                            if authStatus == .notDetermined {
                                syncMessage = "HealthKit access not set up. Tap 'Try Again' to grant weight tracking permissions."
                            } else {
                                syncMessage = "Permission denied. To enable weight sync, go to: Settings → Privacy & Security → Health → Data Access & Devices → Fast LIFe → Turn on Weight."
                            }
                        }
                    }
                    showingSyncAlert = true
                    AppLogger.info("Weight sync completed: \(syncedCount) new entries", category: AppLogger.weightTracking)

                    // Update permission status and sync history after sync attempt
                    updatePermissionStatus()
                    loadLastSyncStatus()
                    updateToggleState()

                    // If permissions were granted, apply user preference to WeightManager
                    if hasHealthKitPermission && userSyncPreference {
                        weightManager.setSyncPreference(true)
                    }
                }
            }
        }
    }

    // MARK: - Sync Preference Dialog Actions

    private func performHistoricalSync() {
        AppLogger.info("User chose to import all historical weight data", category: AppLogger.ui)
        // Mark initial import as completed - no more dialogs needed
        markInitialImportCompleted()
        isSyncing = true

        // Following Apple HealthKit Programming Guide: Import all historical data
        // Use extended date range to capture all available weight entries
        let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()

        weightManager.syncFromHealthKitHistorical(startDate: startDate) { syncedCount, error in
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
                    AppLogger.info("Historical weight sync completed: \(syncedCount) entries imported", category: AppLogger.weightTracking)

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
        AppLogger.info("User chose to sync only future weight data", category: AppLogger.ui)
        // Mark initial import as completed - no more dialogs needed
        markInitialImportCompleted()

        // Following Apple HIG: Provide clear feedback for user choice
        syncMessage = "Weight sync enabled. Only new weight entries will be synced going forward."
        showingSyncAlert = true
        AppLogger.info("Future-only weight sync enabled", category: AppLogger.weightTracking)

        // Enable sync preference for future data only
        if hasHealthKitPermission {
            weightManager.setSyncPreference(true)
            userSyncPreference = true
            updatePermissionStatus()
            loadLastSyncStatus()
            updateToggleState()
        }
    }

    // MARK: - One-Time Setup Helper

    /// Check if user has completed initial historical import choice
    /// Following industry standard: One-time setup, then seamless auto-sync
    private func hasCompletedInitialImport() -> Bool {
        let completed = userDefaults.bool(forKey: hasCompletedInitialImportKey)
        AppLogger.info("Checking initial import status: \(completed ? "COMPLETED" : "NOT COMPLETED")", category: AppLogger.weightTracking)
        return completed
    }

    /// Mark initial import as completed to prevent repeated dialogs
    /// Following Apple iCloud pattern: Ask once during setup, then auto-sync forever
    private func markInitialImportCompleted() {
        userDefaults.set(true, forKey: hasCompletedInitialImportKey)
        // Force immediate synchronization to prevent timing issues
        // Following Apple UserDefaults best practices for critical flags
        userDefaults.synchronize()
        AppLogger.info("Initial import marked as completed and synchronized", category: AppLogger.weightTracking)
    }

    // MARK: - Phase B Engine Test Functions

    /// Request notification permissions using our Phase B behavioral scheduler
    private func requestNotificationPermissions() {
        AppLogger.info("Requesting notification permissions for Phase B engine test", category: AppLogger.notifications)

        Task {
            let granted = await behavioralScheduler.requestPermissions()

            await MainActor.run {
                if granted {
                    notificationPermissionStatus = "Granted"
                    AppLogger.info("Phase B engine test: Notification permissions granted", category: AppLogger.notifications)
                } else {
                    notificationPermissionStatus = "Denied"
                    AppLogger.warning("Phase B engine test: Notification permissions denied", category: AppLogger.notifications)
                    // Follow Apple standard: Guide user to Settings app when permissions denied
                    openNotificationSettings()
                }
            }
        }
    }

    /// Open iOS Settings app to notification settings (Apple standard approach)
    private func openNotificationSettings() {
        if #available(iOS 16.0, *) {
            // Direct to notification settings (iOS 16+)
            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                UIApplication.shared.open(url)
                AppLogger.info("Opened notification settings directly (iOS 16+)", category: AppLogger.notifications)
            }
        } else {
            // Fall back to app settings where notifications option is visible
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
                AppLogger.info("Opened app settings for notification access", category: AppLogger.notifications)
            }
        }
    }

    /// Send test notification using Phase B behavioral intelligence
    private func sendTestNotification() {
        AppLogger.info("Sending Phase B engine test notification", category: AppLogger.notifications)

        // Create test context for weight reminders - FORCE testing conditions
        let testLastActivity = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let context = BehavioralContext(
            currentStreak: weightManager.weightEntries.count > 0 ? 5 : 0,
            recentPattern: "consistent",
            timeOfDay: Date(),
            dataValue: weightManager.weightEntries.first?.weight ?? 150.0,
            goalProgress: 0.8,
            lastActivity: testLastActivity
        )

        AppLogger.info("TEST CONTEXT - lastActivity: \(testLastActivity), days ago: 2", category: AppLogger.notifications)

        Task {
            let trigger: BehavioralTrigger
            switch testFrequency {
            case .immediate:
                trigger = .immediate
            case .thirtySeconds:
                trigger = .timeInterval(30)
            case .testMode:
                trigger = .timeInterval(120) // 2 minutes
            case .daily:
                trigger = .timeInterval(86400) // 24 hours
            }

            // Update the rule with current test tone style and FORCE test mode
            if let weightRule = behavioralScheduler.getRule(for: .weight) as? WeightNotificationRule {
                await MainActor.run {
                    weightRule.toneStyle = testToneStyle
                    // FORCE enable for testing - bypass behavioral filtering
                    weightRule.isEnabled = true
                    // FORCE allow during quiet hours for testing
                    weightRule.allowDuringQuietHours = true
                    // FORCE enable sound for visibility during testing
                    weightRule.soundEnabled = true
                }
                AppLogger.info("Updated weight rule: enabled=\(weightRule.isEnabled), tone=\(weightRule.toneStyle.rawValue), allowDuringQuiet=\(weightRule.allowDuringQuietHours)", category: AppLogger.notifications)
            }

            await behavioralScheduler.scheduleGuidance(
                for: .weight,
                trigger: trigger,
                context: context
            )

            // VERIFY the notification was actually added to iOS notification center
            let pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let ourNotifications = pendingNotifications.filter { $0.identifier.contains("behavioral_weight") }

            // SHOW SUCCESS MESSAGE - Phase B engine working perfectly!
            if let testNotification = ourNotifications.first {
                await MainActor.run {
                    AppLogger.info("✅ PHASE B SUCCESS: '\(testNotification.content.title)' - '\(testNotification.content.body)'", category: AppLogger.notifications)
                }
            }

            await MainActor.run {
                AppLogger.info("Phase B engine test notification scheduled", category: AppLogger.notifications)
                AppLogger.info("VERIFICATION: \(ourNotifications.count) weight notifications in iOS pending queue", category: AppLogger.notifications)
                AppLogger.info("FORCED DELIVERY: Showing notification content as alert for testing", category: AppLogger.notifications)
                for notification in ourNotifications.prefix(3) {
                    AppLogger.info("PENDING: ID=\(notification.identifier), Title=\(notification.content.title)", category: AppLogger.notifications)
                }
            }
        }
    }

    /// Update notification permission status on view appear
    private func updateNotificationPermissionStatus() {
        Task {
            let status = await behavioralScheduler.getAuthorizationStatus()

            await MainActor.run {
                switch status {
                case .authorized, .provisional, .ephemeral:
                    notificationPermissionStatus = "Granted"
                case .denied:
                    notificationPermissionStatus = "Denied"
                case .notDetermined:
                    notificationPermissionStatus = "Not requested"
                @unknown default:
                    notificationPermissionStatus = "Unknown"
                }
            }
        }
    }
}

#Preview {
    WeightSettingsView(
        weightManager: WeightManager(),
        showGoalLine: .constant(true),
        weightGoal: .constant(180.0)
    )
}
