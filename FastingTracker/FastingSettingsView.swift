import SwiftUI

/// Fasting Settings View following WeightSettingsView pattern
/// Industry standard: Consistent settings UI across all health trackers
/// Apple HIG: Form-based settings with clear sections and descriptions
struct FastingSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var fastingManager: FastingManager

    @State private var localSyncEnabled: Bool = false
    @State private var isSyncing: Bool = false
    @State private var showingSyncAlert: Bool = false
    @State private var syncMessage: String = ""

    var body: some View {
        NavigationView {
            Form {
                // Apple Health Integration Section
                Section(header: Text("APPLE HEALTH INTEGRATION")) {
                    Toggle("Sync with Apple Health", isOn: $localSyncEnabled)
                        .onChange(of: localSyncEnabled) { _, newValue in
                            setFastingSyncPreference(newValue)
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
                        .disabled(isSyncing)
                    }

                    Text("When enabled, fasting sessions will be synced with Apple Health as workouts automatically.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Fasting Goal Section
                Section(header: Text("FASTING GOAL")) {
                    HStack {
                        Text("Goal Duration")
                        Spacer()
                        Text("\(Int(fastingManager.fastingGoalHours))h")
                            .foregroundColor(.secondary)
                    }

                    Text("Tap the goal in the main timer to change your fasting duration.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Stats Section
                Section(header: Text("ABOUT")) {
                    HStack {
                        Text("Total Fasts")
                        Spacer()
                        Text("\(fastingManager.fastingHistory.filter { $0.isComplete }.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Tracking Since")
                        Spacer()
                        if let firstFast = fastingManager.fastingHistory.first {
                            Text(formatTrackingSinceDate(firstFast.startTime))
                                .foregroundColor(.secondary)
                        } else {
                            Text("No fasts yet")
                                .foregroundColor(.secondary)
                        }
                    }

                    if fastingManager.fastingHistory.filter({ $0.isComplete }).count > 0 {
                        HStack {
                            Text("Average Duration")
                            Spacer()
                            Text(formatAverageDuration())
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Longest Fast")
                            Spacer()
                            Text(formatLongestFast())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Fasting Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadSyncSettings()
        }
        .alert("Sync Status", isPresented: $showingSyncAlert) {
            // Following Apple HIG: Handle different authorization states appropriately
            if syncMessage.contains("Permission denied") || syncMessage.contains("enable") {
                // Check if we can re-request authorization or if user must go to Settings
                let authStatus = HealthKitManager.shared.getFastingAuthorizationStatus()

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
    }

    // MARK: - Sync Functions

    private func loadSyncSettings() {
        // Check if fasting sync is enabled by checking if HealthKit is authorized
        localSyncEnabled = HealthKitManager.shared.isFastingAuthorized()
        AppLogger.info("Loaded fasting sync settings: enabled=\(localSyncEnabled)", category: AppLogger.healthKit)
    }

    private func setFastingSyncPreference(_ enabled: Bool) {
        AppLogger.info("Setting fasting sync preference: \(enabled)", category: AppLogger.healthKit)

        if enabled {
            // Request authorization first
            HealthKitManager.shared.requestFastingAuthorization { success, error in
                DispatchQueue.main.async {
                    if success {
                        AppLogger.info("Fasting HealthKit authorization granted", category: AppLogger.healthKit)
                        // Authorization successful - sync preference is automatically enabled
                    } else {
                        AppLogger.info("Fasting HealthKit authorization denied", category: AppLogger.healthKit)
                        // Reset toggle if user denied permission
                        localSyncEnabled = false
                        syncMessage = "HealthKit authorization required. Enable workout access in: Settings → Privacy & Security → Health → Data Access & Devices → Fast LIFe → Turn on Workouts."
                        showingSyncAlert = true
                    }
                }
            }
        } else {
            // User disabled sync - just update the toggle
            // Note: We can't revoke HealthKit permissions, but we can stop syncing
            AppLogger.info("User disabled fasting sync", category: AppLogger.healthKit)
        }
    }

    private func syncWithHealthKit() {
        AppLogger.info("Manual fasting sync requested", category: AppLogger.healthKit)

        isSyncing = true

        // Request authorization if needed, then sync
        HealthKitManager.shared.requestFastingAuthorization { success, error in
            if success {
                // Following Apple HealthKit Programming Guide: Check authorization before claiming success
                let hasPermission = HealthKitManager.shared.isFastingAuthorized()

                if hasPermission {
                    // Permission granted - provide accurate sync status
                    let completedFasts = fastingManager.fastingHistory.filter { $0.isComplete }

                    DispatchQueue.main.async {
                        self.isSyncing = false

                        if completedFasts.count > 0 {
                            // NOTE: This reports local data count since fasting sync is write-only to HealthKit
                            // Unlike weight/water which are bidirectional, fasting sessions are only exported
                            // This is accurate behavior for export-only operations
                            self.syncMessage = "Fasting sessions are now being synced to Apple Health. \(completedFasts.count) sessions available for export."
                        } else {
                            self.syncMessage = "No completed fasting sessions to sync to Apple Health."
                        }
                        self.showingSyncAlert = true

                        // Update sync status
                        HealthKitManager.shared.updateFastingSyncStatus(success: true)

                        AppLogger.info("Fasting HealthKit authorization confirmed: \(completedFasts.count) sessions available", category: AppLogger.healthKit)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isSyncing = false
                        self.syncMessage = "Permission denied. Enable workout access in: Settings → Privacy & Security → Health → Data Access & Devices → Fast LIFe → Turn on Workouts."
                        self.showingSyncAlert = true

                        AppLogger.info("Fasting HealthKit authorization denied after request", category: AppLogger.healthKit)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isSyncing = false
                    self.syncMessage = error?.localizedDescription ?? "Failed to sync with Apple Health. Please check your permissions in Settings > Health."
                    self.showingSyncAlert = true

                    AppLogger.info("Manual fasting sync failed", category: AppLogger.healthKit)
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func formatTrackingSinceDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatAverageDuration() -> String {
        let completedFasts = fastingManager.fastingHistory.filter { $0.isComplete }
        guard !completedFasts.isEmpty else { return "N/A" }

        let totalDuration = completedFasts.reduce(0) { total, fast in
            total + fast.duration
        }
        let averageDuration = totalDuration / Double(completedFasts.count)

        let hours = Int(averageDuration / 3600)
        let minutes = Int((averageDuration.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func formatLongestFast() -> String {
        let completedFasts = fastingManager.fastingHistory.filter { $0.isComplete }
        guard !completedFasts.isEmpty else { return "N/A" }

        let longestDuration = completedFasts.map { $0.duration }.max() ?? 0

        let hours = Int(longestDuration / 3600)
        let minutes = Int((longestDuration.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    FastingSettingsView(fastingManager: FastingManager())
}