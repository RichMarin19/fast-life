import SwiftUI

struct AdvancedView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @Binding var shouldPopToRoot: Bool
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Advanced Features")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)

                    // Weight Tracking Feature
                    Button(action: { navigationPath.append("weightTracking") }) {
                        AdvancedFeatureCard(
                            title: "Weight Tracking",
                            description: "Track your weight, BMI, and body fat percentage",
                            icon: "scalemass.fill",
                            color: .blue,
                            isAvailable: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)

                    // Hydration Tracking Feature
                    Button(action: { navigationPath.append("hydrationTracking") }) {
                        AdvancedFeatureCard(
                            title: "Hydration Tracker",
                            description: "Track water, coffee, and tea intake during fasting",
                            icon: "drop.fill",
                            color: .cyan,
                            isAvailable: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)

                    // Coming Soon Features
                    AdvancedFeatureCard(
                        title: "Mood & Energy Tracker",
                        description: "Track your mood and energy levels during fasting",
                        icon: "face.smiling.fill",
                        color: .orange,
                        isAvailable: false
                    )
                    .padding(.horizontal)

                    AdvancedFeatureCard(
                        title: "Data Export & Backup",
                        description: "Export your fasting data to CSV or backup to iCloud",
                        icon: "square.and.arrow.up.fill",
                        color: .green,
                        isAvailable: false
                    )
                    .padding(.horizontal)

                    // Settings - Placed at bottom
                    Button(action: { navigationPath.append("settings") }) {
                        AdvancedFeatureCard(
                            title: "Settings",
                            description: "Manage app data, sync, and preferences",
                            icon: "gear",
                            color: .gray,
                            isAvailable: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "weightTracking":
                    WeightTrackingView()
                case "hydrationTracking":
                    HydrationTrackingView()
                case "settings":
                    AppSettingsView(fastingManager: fastingManager)
                default:
                    EmptyView()
                }
            }
        }
        .onChange(of: shouldPopToRoot) { _, newValue in
            if newValue {
                // Pop to root by clearing navigation path
                navigationPath = NavigationPath()
                shouldPopToRoot = false  // Reset trigger
            }
        }
    }
}

struct AdvancedFeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isAvailable: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(isAvailable ? color : .gray)
                .frame(width: 60, height: 60)
                .background(isAvailable ? color.opacity(0.15) : Color.gray.opacity(0.15))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isAvailable ? .primary : .secondary)

                    if !isAvailable {
                        Text("Coming Soon")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(6)
                    }
                }

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if isAvailable {
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .opacity(isAvailable ? 1.0 : 0.7)
    }
}

// MARK: - App Settings View

struct AppSettingsView: View {
    @ObservedObject var fastingManager: FastingManager
    @StateObject private var weightManager = WeightManager()
    @StateObject private var hydrationManager = HydrationManager()
    @StateObject private var healthKitManager = HealthKitManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var showingClearFastingAlert = false
    @State private var showingClearFastingConfirmation = false
    @State private var showingClearWeightAlert = false
    @State private var showingClearWeightConfirmation = false
    @State private var showingClearHydrationAlert = false
    @State private var showingClearHydrationConfirmation = false
    @State private var showingClearAllDataAlert = false
    @State private var showingClearAllDataConfirmation = false
    @State private var isSyncing = false
    @State private var syncMessage = ""
    @State private var showingSyncAlert = false
    @State private var showingSyncOptions = false

    var body: some View {
        List {
            // App Info Section
            Section(header: Text("App Information")) {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text(buildNumber)
                        .foregroundColor(.secondary)
                }
            }

            // Apple Health Section
            Section(header: Text("Apple Health"), footer: Text("Choose whether to sync all historical data or only future weight entries with Apple Health.")) {
                Button(action: { showingSyncOptions = true }) {
                    HStack {
                        if isSyncing {
                            ProgressView()
                                .padding(.trailing, 8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                        }
                        Text(isSyncing ? "Syncing..." : "Sync Weight with Apple Health")
                            .foregroundColor(.primary)
                    }
                }
                .disabled(isSyncing)
            }

            // Danger Zone Section
            Section(header: Text("Danger Zone"), footer: Text("These actions cannot be undone. All data will be permanently deleted.")) {
                Button(action: { showingClearFastingAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Clear All Fasting Data")
                            .foregroundColor(.red)
                    }
                }

                Button(action: { showingClearWeightAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Clear All Weight Data")
                            .foregroundColor(.red)
                    }
                }

                Button(action: { showingClearHydrationAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Clear All Hydration Data")
                            .foregroundColor(.red)
                    }
                }

                Button(action: { showingClearAllDataAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Clear All Data and Reset")
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Clear All Fasting Data", isPresented: $showingClearFastingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data", role: .destructive) {
                showingClearFastingConfirmation = true
            }
        } message: {
            Text("This will permanently delete all your fasting history, streaks, and statistics. This action cannot be undone.")
        }
        .alert("Are you sure?", isPresented: $showingClearFastingConfirmation) {
            Button("No", role: .cancel) { }
            Button("Yes", role: .destructive) {
                clearAllFastingData()
            }
        } message: {
            Text("⚠️ FINAL WARNING ⚠️\n\nThis will permanently delete all fasting data and cannot be restored unless you have created a backup.\n\nAre you absolutely sure?")
                .font(.headline)
                .fontWeight(.bold)
        }
        .alert("Clear All Weight Data", isPresented: $showingClearWeightAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data", role: .destructive) {
                showingClearWeightConfirmation = true
            }
        } message: {
            Text("This will permanently delete all your weight entries. This action cannot be undone.")
        }
        .alert("Are you sure?", isPresented: $showingClearWeightConfirmation) {
            Button("No", role: .cancel) { }
            Button("Yes", role: .destructive) {
                clearAllWeightData()
            }
        } message: {
            Text("⚠️ FINAL WARNING ⚠️\n\nThis will permanently delete all weight data and cannot be restored unless you have created a backup.\n\nAre you absolutely sure?")
                .font(.headline)
                .fontWeight(.bold)
        }
        .alert("Clear All Hydration Data", isPresented: $showingClearHydrationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data", role: .destructive) {
                showingClearHydrationConfirmation = true
            }
        } message: {
            Text("This will permanently delete all your hydration tracking data including water, coffee, and tea entries. This action cannot be undone.")
        }
        .alert("Are you sure?", isPresented: $showingClearHydrationConfirmation) {
            Button("No", role: .cancel) { }
            Button("Yes", role: .destructive) {
                clearAllHydrationData()
            }
        } message: {
            Text("⚠️ FINAL WARNING ⚠️\n\nThis will permanently delete all hydration data and cannot be restored unless you have created a backup.\n\nAre you absolutely sure?")
                .font(.headline)
                .fontWeight(.bold)
        }
        .alert("Clear All Data and Reset", isPresented: $showingClearAllDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data and Reset", role: .destructive) {
                showingClearAllDataConfirmation = true
            }
        } message: {
            Text("This will permanently delete ALL app data including fasting history, weight entries, hydration tracking, streaks, and statistics. The app will be reset to its initial state and you will need to set up your goals again. This action cannot be undone.")
        }
        .alert("Are you sure?", isPresented: $showingClearAllDataConfirmation) {
            Button("No", role: .cancel) { }
            Button("Yes", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("⚠️ FINAL WARNING ⚠️\n\nThis will permanently delete ALL app data (fasting, weight, hydration) and cannot be restored unless you have created a backup.\n\nThe app will be reset to its initial state.\n\nAre you absolutely sure?")
                .font(.headline)
                .fontWeight(.bold)
        }
        .alert("Sync Status", isPresented: $showingSyncAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(syncMessage)
        }
        .confirmationDialog("Sync Options", isPresented: $showingSyncOptions, titleVisibility: .visible) {
            Button("Sync All Data") {
                syncWithHealthKit(futureOnly: false)
            }
            Button("Sync Future Data Only") {
                syncWithHealthKit(futureOnly: true)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose whether to import all weight history from Apple Health or only sync new entries going forward.")
        }
    }

    // MARK: - App Info Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    // MARK: - Clear Data Functions

    private func clearAllFastingData() {
        // Clear all fasting history
        fastingManager.fastingHistory.removeAll()

        // Reset streaks
        fastingManager.currentStreak = 0
        fastingManager.longestStreak = 0

        // Reset goal to 0 to trigger goal setup on next use
        fastingManager.fastingGoalHours = 0

        // Save empty state
        UserDefaults.standard.removeObject(forKey: "fastingHistory")
        UserDefaults.standard.removeObject(forKey: "currentStreak")
        UserDefaults.standard.removeObject(forKey: "longestStreak")
        UserDefaults.standard.removeObject(forKey: "fastingGoalHours")
    }

    private func clearAllWeightData() {
        // Clear all weight entries
        weightManager.weightEntries.removeAll()

        // Save empty state
        UserDefaults.standard.removeObject(forKey: "weightEntries")
    }

    private func clearAllHydrationData() {
        // Clear all hydration entries
        hydrationManager.drinkEntries.removeAll()

        // Reset daily goal to 0 to trigger goal setup on next use
        hydrationManager.dailyGoalOunces = 0

        // Reset streak
        hydrationManager.currentStreak = 0

        // Save empty state
        UserDefaults.standard.removeObject(forKey: "drinkEntries")
        UserDefaults.standard.removeObject(forKey: "dailyGoalOunces")
        UserDefaults.standard.removeObject(forKey: "hydrationStreak")
    }

    private func clearAllData() {
        // Clear fasting data
        clearAllFastingData()

        // Clear weight data
        clearAllWeightData()

        // Clear hydration data
        clearAllHydrationData()

        // Reset fasting goal to default
        fastingManager.fastingGoalHours = 16

        // Remove onboarding completed flag to trigger first-time setup
        UserDefaults.standard.removeObject(forKey: "onboardingCompleted")

        // Save reset state
        UserDefaults.standard.removeObject(forKey: "fastingGoalHours")

        // Remove goal weight
        UserDefaults.standard.removeObject(forKey: "goalWeight")

        // Ensure all UserDefaults changes are persisted to disk before exit
        UserDefaults.standard.synchronize()

        // Exit app so user must relaunch to see onboarding
        // Using a brief delay to ensure data is fully saved
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }

    // MARK: - Sync Function

    private func syncWithHealthKit(futureOnly: Bool) {
        isSyncing = true

        // Check if HealthKit is authorized
        if !healthKitManager.isAuthorized {
            // Request authorization first
            healthKitManager.requestAuthorization { success, error in
                if success {
                    performSync(futureOnly: futureOnly)
                } else {
                    isSyncing = false
                    syncMessage = error?.localizedDescription ?? "Failed to authorize Apple Health. Please check Settings > Health > Data Access & Devices."
                    showingSyncAlert = true
                }
            }
        } else {
            // Already authorized, just sync
            performSync(futureOnly: futureOnly)
        }
    }

    private func performSync(futureOnly: Bool) {
        if futureOnly {
            // Sync only from today forward
            weightManager.syncFromHealthKit(startDate: Date())
        } else {
            // Sync all historical data (default: last 365 days)
            weightManager.syncFromHealthKit()
        }

        // Give it a moment to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSyncing = false
            let count = weightManager.weightEntries.count
            let timeframe = futureOnly ? "from today forward" : "from Apple Health"
            syncMessage = count > 0 ? "Successfully synced \(count) weight entries \(timeframe)." : "No weight data found in Apple Health."
            showingSyncAlert = true
        }
    }
}

#Preview {
    AdvancedView(shouldPopToRoot: .constant(false))
        .environmentObject(FastingManager())
}
