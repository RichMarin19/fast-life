import SwiftUI

struct AdvancedView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @Binding var shouldPopToRoot: Bool
    @Binding var shouldResetToOnboarding: Bool
    @Binding var isOnboardingComplete: Bool
    @Binding var selectedTab: Int
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

                    // Sleep Tracking Feature
                    Button(action: { navigationPath.append("sleepTracking") }) {
                        AdvancedFeatureCard(
                            title: "Sleep Tracker",
                            description: "Track sleep duration and sync with Apple Health",
                            icon: "bed.double.fill",
                            color: .purple,
                            isAvailable: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)

                    // Mood & Energy Tracking Feature
                    Button(action: { navigationPath.append("moodTracking") }) {
                        AdvancedFeatureCard(
                            title: "Mood & Energy Tracker",
                            description: "Track your mood and energy levels during fasting",
                            icon: "face.smiling.fill",
                            color: .orange,
                            isAvailable: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)

                    // Notifications - AI-powered habit coaching
                    Button(action: { navigationPath.append("notificationSettings") }) {
                        AdvancedFeatureCard(
                            title: "Notifications",
                            description: "AI-powered coaching messages to keep you motivated",
                            icon: "bell.badge.fill",
                            color: .orange,
                            isAvailable: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
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
                case "sleepTracking":
                    SleepTrackingView()
                case "moodTracking":
                    MoodTrackingView()
                case "notificationSettings":
                    NotificationSettingsView()
                case "settings":
                    AppSettingsView(
                        fastingManager: fastingManager,
                        shouldResetToOnboarding: $shouldResetToOnboarding,
                        isOnboardingComplete: $isOnboardingComplete,
                        selectedTab: $selectedTab
                    )
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
    @Binding var shouldResetToOnboarding: Bool
    @Binding var isOnboardingComplete: Bool
    @Binding var selectedTab: Int

    // REMOVED: @StateObject managers that were created on view init
    // Per Apple SwiftUI Best Practices: Don't create managers in views that don't own them
    // Reference: https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
    // Managers are now created on-demand only when sync operations are needed

    @Environment(\.dismiss) var dismiss

    @State private var showingClearFastingAlert = false
    @State private var showingClearFastingConfirmation = false
    @State private var showingClearWeightAlert = false
    @State private var showingClearWeightConfirmation = false
    @State private var showingClearHydrationAlert = false
    @State private var showingClearHydrationConfirmation = false
    @State private var showingClearSleepAlert = false
    @State private var showingClearSleepConfirmation = false
    @State private var showingClearMoodAlert = false
    @State private var showingClearMoodConfirmation = false
    @State private var showingClearAllDataAlert = false
    @State private var showingClearAllDataConfirmation = false
    @State private var showingHealthResetInstructions = false
    @State private var isSyncingFasting = false
    @State private var isSyncingWeight = false
    @State private var isSyncingHydration = false
    @State private var isSyncingAll = false
    @State private var syncMessage = ""
    @State private var showingSyncAlert = false
    @State private var showingFastingSyncOptions = false
    @State private var showingWeightSyncOptions = false
    @State private var showingHydrationSyncOptions = false
    @State private var showingAllDataSyncOptions = false
    @State private var versionTapCount = 0
    @State private var showingDebugLog = false
    @State private var showingExportSheet = false
    @State private var exportedFileURL: URL?
    @State private var isExporting = false
    @State private var showingImportFilePicker = false
    @State private var showingImportPreview = false
    @State private var importPreview: ImportPreview?
    @State private var importFileURL: URL?
    @State private var showingImportResult = false
    @State private var importResultMessage = ""

    var body: some View {
        List {
            // Data Import & Export Section
            Section(header: Text("Data Import & Export"), footer: Text("Export your data for backup or import previously exported data to restore.")) {
                // Export button
                Button(action: { exportData() }) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .padding(.trailing, 8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                        }
                        Text(isExporting ? "Exporting..." : "Export All Data to CSV")
                            .foregroundColor(.primary)
                    }
                }
                .disabled(isExporting)

                // Import button
                Button(action: { showingImportFilePicker = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.green)
                        Text("Import Data from CSV")
                            .foregroundColor(.primary)
                    }
                }
            }

            // App Info Section
            Section(header: Text("App Information")) {
                Button(action: {
                    versionTapCount += 1
                    if versionTapCount >= 5 {
                        showingDebugLog = true
                        versionTapCount = 0
                    }
                    // Reset counter after 2 seconds if not reached 5
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        versionTapCount = 0
                    }
                }) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                HStack {
                    Text("Build")
                    Spacer()
                    Text(buildNumber)
                        .foregroundColor(.secondary)
                }
            }

            // Notifications Section
            Section(header: Text("Notifications"), footer: Text("Get reminded when you hit fasting milestones and reach your goals.")) {
                Button(action: {
                    // Open iOS Settings app to notification settings
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.orange)
                        Text("Manage Notification Settings")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Apple Health Section
            Section(header: Text("Apple Health"), footer: Text("Sync your fasting, weight, and hydration data with Apple Health. Fasting sessions are saved as workouts. Water, coffee, and tea are saved as water intake.")) {
                Button(action: { showingFastingSyncOptions = true }) {
                    HStack {
                        if isSyncingFasting {
                            ProgressView()
                                .padding(.trailing, 8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.orange)
                        }
                        Text(isSyncingFasting ? "Syncing..." : "Sync Fasting with Apple Health")
                            .foregroundColor(.primary)
                    }
                }
                .disabled(isSyncingFasting || isSyncingAll)

                Button(action: { showingWeightSyncOptions = true }) {
                    HStack {
                        if isSyncingWeight {
                            ProgressView()
                                .padding(.trailing, 8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                        }
                        Text(isSyncingWeight ? "Syncing..." : "Sync Weight with Apple Health")
                            .foregroundColor(.primary)
                    }
                }
                .disabled(isSyncingWeight || isSyncingAll)

                Button(action: { showingHydrationSyncOptions = true }) {
                    HStack {
                        if isSyncingHydration {
                            ProgressView()
                                .padding(.trailing, 8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.cyan)
                        }
                        Text(isSyncingHydration ? "Syncing..." : "Sync Hydration with Apple Health")
                            .foregroundColor(.primary)
                    }
                }
                .disabled(isSyncingHydration || isSyncingAll)

                Button(action: { showingAllDataSyncOptions = true }) {
                    HStack {
                        if isSyncingAll {
                            ProgressView()
                                .padding(.trailing, 8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.green)
                        }
                        Text(isSyncingAll ? "Syncing..." : "Sync All Health Data")
                            .foregroundColor(.primary)
                    }
                }
                .disabled(isSyncingFasting || isSyncingWeight || isSyncingHydration || isSyncingAll)
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

                Button(action: { showingClearSleepAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Clear All Sleep Data")
                            .foregroundColor(.red)
                    }
                }

                Button(action: { showingClearMoodAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Clear All Mood Data")
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
        .alert("Clear All Sleep Data", isPresented: $showingClearSleepAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data", role: .destructive) {
                showingClearSleepConfirmation = true
            }
        } message: {
            Text("This will permanently delete all your sleep tracking data. This action cannot be undone.")
        }
        .alert("Are you sure?", isPresented: $showingClearSleepConfirmation) {
            Button("No", role: .cancel) { }
            Button("Yes", role: .destructive) {
                clearAllSleepData()
            }
        } message: {
            Text("⚠️ FINAL WARNING ⚠️\n\nThis will permanently delete all sleep data and cannot be restored unless you have created a backup.\n\nAre you absolutely sure?")
                .font(.headline)
                .fontWeight(.bold)
        }
        .alert("Clear All Mood Data", isPresented: $showingClearMoodAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data", role: .destructive) {
                showingClearMoodConfirmation = true
            }
        } message: {
            Text("This will permanently delete all your mood and energy tracking data. This action cannot be undone.")
        }
        .alert("Are you sure?", isPresented: $showingClearMoodConfirmation) {
            Button("No", role: .cancel) { }
            Button("Yes", role: .destructive) {
                clearAllMoodData()
            }
        } message: {
            Text("⚠️ FINAL WARNING ⚠️\n\nThis will permanently delete all mood data and cannot be restored unless you have created a backup.\n\nAre you absolutely sure?")
                .font(.headline)
                .fontWeight(.bold)
        }
        .alert("Clear All Data and Reset", isPresented: $showingClearAllDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data and Reset", role: .destructive) {
                showingClearAllDataConfirmation = true
            }
        } message: {
            Text("This will permanently delete ALL app data including fasting history, weight entries, hydration tracking, sleep tracking, mood & energy data, streaks, and statistics. The app will be reset to its initial state and you will need to set up your goals again. This action cannot be undone.")
        }
        .alert("Are you sure?", isPresented: $showingClearAllDataConfirmation) {
            Button("No", role: .cancel) { }
            Button("Yes, Clear App Data", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("⚠️ FINAL WARNING ⚠️\n\nThis will permanently delete ALL app data (fasting, weight, hydration, sleep, mood) and cannot be restored unless you have created a backup.\n\nThe app will be reset to its initial state.\n\nAre you absolutely sure?")
                .font(.headline)
                .fontWeight(.bold)
        }
        .alert("One More Step: Reset Health Permissions", isPresented: $showingHealthResetInstructions) {
            Button("Open Health App", role: .none) {
                // Deep link to Health app's Fast LIFe permissions page
                // Per Apple: Use x-apple-health:// URL scheme for Health app
                // Reference: https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app
                if let url = URL(string: "x-apple-health://") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Skip This Step", role: .cancel) { }
        } message: {
            Text("✅ App data cleared!\n\n⚠️ IMPORTANT: To see the permission dialog during onboarding, you must also DELETE Health data:\n\n1. Tap 'Open Health App' below\n2. Tap 'Browse' tab\n3. Tap 'Data Access & Devices'\n4. Find and tap 'Fast LIFe'\n5. Scroll down and tap 'Delete All Data from Fast LIFe'\n6. Confirm deletion\n\nWithout this step, iOS won't show the permission dialog again.")
        }
        .alert("Sync Status", isPresented: $showingSyncAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(syncMessage)
        }
        .sheet(isPresented: $showingDebugLog) {
            DebugLogView()
        }
        .confirmationDialog("Fasting Sync Options", isPresented: $showingFastingSyncOptions, titleVisibility: .visible) {
            Button("Backfill All Fasting History") {
                syncFastingWithHealthKit()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Sync all your fasting history to Apple Health as workouts. This allows you to view your fasting data in the Health app.")
        }
        .confirmationDialog("Weight Sync Options", isPresented: $showingWeightSyncOptions, titleVisibility: .visible) {
            Button("Sync All Data") {
                syncWeightWithHealthKit(futureOnly: false)
            }
            Button("Sync Future Data Only") {
                syncWeightWithHealthKit(futureOnly: true)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose whether to import all weight history from Apple Health or only sync new entries going forward.")
        }
        .confirmationDialog("Hydration Sync Options", isPresented: $showingHydrationSyncOptions, titleVisibility: .visible) {
            Button("Sync All Data") {
                syncHydrationWithHealthKit(futureOnly: false)
            }
            Button("Sync Future Data Only") {
                syncHydrationWithHealthKit(futureOnly: true)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose whether to import all hydration history from Apple Health or only sync new entries going forward.")
        }
        .confirmationDialog("Sync All Health Data", isPresented: $showingAllDataSyncOptions, titleVisibility: .visible) {
            Button("Sync All Data") {
                syncAllHealthData(futureOnly: false)
            }
            Button("Sync Future Data Only") {
                syncAllHealthData(futureOnly: true)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose whether to import all weight and hydration history from Apple Health or only sync new entries going forward.")
        }
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(
            isPresented: $showingImportFilePicker,
            allowedContentTypes: [.commaSeparatedText],  // Only accept .csv files
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("Import Preview", isPresented: $showingImportPreview) {
            Button("Cancel", role: .cancel) {
                importFileURL = nil
                importPreview = nil
            }
            Button("Import") {
                performImport()
            }
        } message: {
            if let preview = importPreview {
                Text("""
                Found \(preview.totalCount) entries:

                • Fasting: \(preview.fastingCount)
                • Weight: \(preview.weightCount)
                • Hydration: \(preview.hydrationCount)
                • Sleep: \(preview.sleepCount)
                • Mood: \(preview.moodCount)

                Duplicates will be skipped.
                """)
            }
        }
        .alert("Import Complete", isPresented: $showingImportResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importResultMessage)
        }
    }

    // MARK: - Data Export Function

    private func exportData() {
        print("\n📤 === USER TRIGGERED CSV EXPORT ===")

        // Show loading indicator
        isExporting = true

        // Run export on background thread to avoid blocking UI
        // Reference: https://developer.apple.com/documentation/dispatch/dispatchqueue
        DispatchQueue.global(qos: .userInitiated).async {
            print("📊 Exporting on background thread...")

            // Export data using DataExportManager (heavy work)
            let fileURL = DataExportManager.shared.exportAllDataToCSV()

            // Update UI on main thread
            DispatchQueue.main.async {
                self.isExporting = false

                if let url = fileURL {
                    print("✅ Export successful, showing share sheet")
                    self.exportedFileURL = url
                    self.showingExportSheet = true
                } else {
                    print("❌ Export failed")
                    self.syncMessage = "Failed to export data. Please try again."
                    self.showingSyncAlert = true
                }

                print("====================================\n")
            }
        }
    }

    // MARK: - Data Import Functions

    private func handleFileImport(_ result: Result<[URL], Error>) {
        print("\n📥 === USER SELECTED CSV FILE ===")

        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                print("❌ No file selected")
                return
            }

            print("Selected file: \(url.lastPathComponent)")

            // Validate and preview CSV
            let previewResult = CSVImporter.shared.validateAndPreviewCSV(from: url)

            switch previewResult {
            case .success(let preview):
                print("✅ Validation successful")
                importPreview = preview
                importFileURL = url
                showingImportPreview = true

            case .failure(let error):
                print("❌ Validation failed: \(error.localizedDescription)")
                syncMessage = error.localizedDescription
                showingSyncAlert = true
            }

        case .failure(let error):
            print("❌ File selection failed: \(error.localizedDescription)")
            syncMessage = "Failed to select file: \(error.localizedDescription)"
            showingSyncAlert = true
        }

        print("====================================\n")
    }

    private func performImport() {
        print("\n📥 === USER CONFIRMED IMPORT ===")

        guard let url = importFileURL else {
            print("❌ No file URL")
            return
        }

        // Import data
        let importResult = CSVImporter.shared.importData(from: url)

        switch importResult {
        case .success(let result):
            print("✅ Import successful")
            importResultMessage = """
            Import Complete! ✅

            Imported:
            • Fasting: \(result.fastingImported)
            • Weight: \(result.weightImported)
            • Hydration: \(result.hydrationImported)
            • Sleep: \(result.sleepImported)
            • Mood: \(result.moodImported)

            Skipped \(result.totalSkipped) duplicates
            """
            showingImportResult = true

            // Reload FastingManager to pick up imported data
            // Reference: https://developer.apple.com/library/archive/documentation/General/Conceptual/DevPedia-CocoaCore/Singleton.html
            print("🔄 Reloading FastingManager after import...")
            fastingManager.loadHistoryAsync()

            // Clear import state
            importFileURL = nil
            importPreview = nil

        case .failure(let error):
            print("❌ Import failed: \(error.localizedDescription)")
            syncMessage = "Import failed: \(error.localizedDescription)"
            showingSyncAlert = true
        }

        print("====================================\n")
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
        // Stop any active fast
        fastingManager.currentSession = nil

        // Clear all fasting history
        fastingManager.fastingHistory.removeAll()

        // Reset streaks
        fastingManager.currentStreak = 0
        fastingManager.longestStreak = 0

        // Reset goal to 0 to trigger goal setup on next use
        fastingManager.fastingGoalHours = 0

        // Save empty state
        UserDefaults.standard.removeObject(forKey: "currentFastingSession")
        UserDefaults.standard.removeObject(forKey: "fastingHistory")
        UserDefaults.standard.removeObject(forKey: "currentStreak")
        UserDefaults.standard.removeObject(forKey: "longestStreak")
        UserDefaults.standard.removeObject(forKey: "fastingGoalHours")
    }

    private func clearAllWeightData() {
        // Clear all weight entries from UserDefaults only
        // Don't clear instance array - it's a separate instance from WeightTrackingView
        UserDefaults.standard.removeObject(forKey: "weightEntries")

        // Disable HealthKit auto-sync to prevent re-importing data
        // Must SET to false (not remove) because default is true
        UserDefaults.standard.set(false, forKey: "syncWithHealthKit")
    }

    private func clearAllHydrationData() {
        // Clear all hydration entries from UserDefaults only
        // Don't clear instance arrays - it's a separate instance from HydrationTrackingView
        UserDefaults.standard.removeObject(forKey: "drinkEntries")
        UserDefaults.standard.removeObject(forKey: "dailyGoalOunces")
        UserDefaults.standard.removeObject(forKey: "hydrationCurrentStreak")
        UserDefaults.standard.removeObject(forKey: "hydrationLongestStreak")
    }

    private func clearAllSleepData() {
        // Clear all sleep entries from UserDefaults only
        // Don't clear instance array - it's a separate instance from SleepTrackingView
        UserDefaults.standard.removeObject(forKey: "sleepEntries")

        // Disable HealthKit auto-sync to prevent re-importing data
        // Must SET to false (not remove) because default is true
        UserDefaults.standard.set(false, forKey: "syncSleepWithHealthKit")
    }

    private func clearAllMoodData() {
        // Clear all mood entries from UserDefaults only
        // Don't clear instance array - it's a separate instance from MoodTrackingView
        UserDefaults.standard.removeObject(forKey: "moodEntries")
    }

    private func clearNotificationPreferences() {
        // Clear all disabled stage preferences
        // This allows all stage notifications to show again after reset
        let stageHours = [4, 6, 8, 10, 12, 14, 16, 18, 20, 24]
        for hour in stageHours {
            UserDefaults.standard.removeObject(forKey: "disabledStage_\(hour)h")
        }

        // Reset notification settings to defaults
        UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
        UserDefaults.standard.removeObject(forKey: "notificationMode")
        UserDefaults.standard.removeObject(forKey: "notif_hydration")
        UserDefaults.standard.removeObject(forKey: "notif_didyouknow")
        UserDefaults.standard.removeObject(forKey: "notif_milestones")
        UserDefaults.standard.removeObject(forKey: "notif_stages")
        UserDefaults.standard.removeObject(forKey: "notif_goalreminder")
        UserDefaults.standard.removeObject(forKey: "trigger_hydration")
        UserDefaults.standard.removeObject(forKey: "trigger_didyouknow")
        UserDefaults.standard.removeObject(forKey: "trigger_milestones")
        UserDefaults.standard.removeObject(forKey: "trigger_stages")
        UserDefaults.standard.removeObject(forKey: "trigger_goalreminder")
        UserDefaults.standard.removeObject(forKey: "expandedTriggersView")
        UserDefaults.standard.removeObject(forKey: "wakeTime")

        // Clear max per day settings
        UserDefaults.standard.removeObject(forKey: "maxStageNotificationsPerDay")
        UserDefaults.standard.removeObject(forKey: "maxHydrationNotificationsPerDay")
        UserDefaults.standard.removeObject(forKey: "maxDidYouKnowNotificationsPerDay")
        UserDefaults.standard.removeObject(forKey: "maxMilestoneNotificationsPerDay")
        UserDefaults.standard.removeObject(forKey: "maxGoalReminderNotificationsPerDay")

        // Clear rotation tracking data
        UserDefaults.standard.removeObject(forKey: "lastNotificationScheduleDate")
        UserDefaults.standard.removeObject(forKey: "sentStageIndicesToday")
        UserDefaults.standard.removeObject(forKey: "sentHydrationIndicesToday")
        UserDefaults.standard.removeObject(forKey: "sentMilestoneIndicesToday")

        // Clear quiet hours settings (reset to defaults)
        UserDefaults.standard.removeObject(forKey: "quietHoursEnabled")
        UserDefaults.standard.removeObject(forKey: "quietHoursStart")
        UserDefaults.standard.removeObject(forKey: "quietHoursEnd")

        // Cancel all pending notifications
        NotificationManager.shared.cancelAllNotifications()
    }

    private func clearAllData() {
        print("\n🔄 === CLEAR ALL DATA AND RESET ===")
        print("User confirmed: Clearing all app data and resetting to onboarding")

        // Clear fasting data (includes stopping active fast)
        print("📊 Clearing fasting data...")
        clearAllFastingData()

        // Clear weight data
        print("📊 Clearing weight data...")
        clearAllWeightData()

        // Clear hydration data
        print("📊 Clearing hydration data...")
        clearAllHydrationData()

        // Clear sleep data
        print("📊 Clearing sleep data...")
        clearAllSleepData()

        // Clear mood data
        print("📊 Clearing mood data...")
        clearAllMoodData()

        // Reset fasting goal to default
        print("📊 Resetting fasting goal to default (16h)...")
        fastingManager.fastingGoalHours = 16

        // Remove onboarding completed flag to trigger first-time setup
        print("📊 Removing UserDefaults keys:")
        print("   - onboardingCompleted")
        UserDefaults.standard.removeObject(forKey: "onboardingCompleted")

        // Save reset state
        print("   - fastingGoalHours")
        UserDefaults.standard.removeObject(forKey: "fastingGoalHours")

        // Remove goal weight
        print("   - goalWeight")
        UserDefaults.standard.removeObject(forKey: "goalWeight")

        // Remove hydration goal
        print("   - dailyHydrationGoal")
        UserDefaults.standard.removeObject(forKey: "dailyHydrationGoal")

        // Clear notification preferences and disabled stage settings
        // This resets all notification settings to defaults when user clears all data
        print("📊 Clearing notification preferences...")
        clearNotificationPreferences()

        // Ensure all UserDefaults changes are persisted to disk
        print("💾 Synchronizing UserDefaults to disk...")
        UserDefaults.standard.synchronize()

        // Reset to Timer tab (index 0) before showing onboarding
        // This ensures after onboarding completes, user sees Timer tab
        print("🔄 Resetting to Timer tab (index 0)")
        selectedTab = 0

        // Update state BEFORE dismissing to ensure proper propagation
        print("🔄 Setting isOnboardingComplete = false")
        print("🔄 Setting shouldResetToOnboarding = true")
        isOnboardingComplete = false
        shouldResetToOnboarding = true

        // Show Health reset instructions to user
        // Per Apple: Apps cannot programmatically reset HealthKit authorization
        // User must manually delete Health data to reset permissions
        // Reference: https://developer.apple.com/documentation/healthkit/hkhealthstore
        print("📱 Showing Health reset instructions to user...")
        print("ℹ️  Note: iOS does not allow apps to programmatically reset HealthKit authorization")
        print("ℹ️  User must manually delete Health data to see permission dialog again")

        // Dismiss settings to navigate back
        print("✅ All data cleared successfully")
        print("🚀 Dismissing settings → should trigger onboarding flow")
        print("=====================================\n")
        dismiss()

        // Show Health reset instructions after dismiss completes
        // Delay ensures dismiss animation completes before showing alert
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("📱 Presenting Health reset instructions alert...")
            showingHealthResetInstructions = true
        }
    }

    // MARK: - Fasting Sync Function

    private func syncFastingWithHealthKit() {
        print("\n🔄 === SYNC FASTING WITH HEALTHKIT (BACKFILL) ===")

        isSyncingFasting = true

        // Check if fasting (workouts) authorization is granted
        let isAuthorized = HealthKitManager.shared.isFastingAuthorized()
        print("Fasting (Workout) Authorization Status: \(isAuthorized ? "✅ Authorized" : "❌ Not Authorized")")

        if !isAuthorized {
            print("📱 Requesting FASTING (workout) authorization...")
            HealthKitManager.shared.requestFastingAuthorization { success, error in
                if success {
                    print("✅ Fasting authorization granted → performing backfill")
                    self.performFastingBackfill()
                } else {
                    print("❌ Fasting authorization failed: \(String(describing: error))")
                    self.isSyncingFasting = false
                    self.syncMessage = error?.localizedDescription ?? "Failed to authorize Apple Health. Please check Settings > Health > Data Access & Devices."
                    self.showingSyncAlert = true
                }
            }
        } else {
            print("✅ Already authorized → performing backfill")
            performFastingBackfill()
        }

        print("==============================================\n")
    }

    private func performFastingBackfill() {
        // Get all completed fasting sessions
        let allSessions = fastingManager.fastingHistory.filter { $0.isComplete }
        print("📊 Found \(allSessions.count) completed fasting sessions to sync")

        guard !allSessions.isEmpty else {
            isSyncingFasting = false
            syncMessage = "No completed fasting sessions found to sync."
            showingSyncAlert = true
            return
        }

        // STEP 1: Fetch existing Fast LIFe workouts from HealthKit to avoid duplicates
        // Query for the earliest session date to minimize data fetched
        let earliestDate = allSessions.map { $0.startTime }.min() ?? Date()
        print("🔍 Checking for existing workouts since: \(earliestDate)")

        HealthKitManager.shared.fetchFastingData(startDate: earliestDate) { existingWorkouts in
            print("📦 Found \(existingWorkouts.count) existing Fast LIFe workouts in HealthKit")

            // Create a set of existing workout start times for fast lookup
            // Use time rounded to nearest second to avoid floating-point comparison issues
            let existingStartTimes = Set(existingWorkouts.map { workout in
                Int(workout.startTime.timeIntervalSince1970)
            })

            // STEP 2: Filter out sessions that already exist
            let sessionsToSync = allSessions.filter { session in
                let startTimeRounded = Int(session.startTime.timeIntervalSince1970)
                let alreadyExists = existingStartTimes.contains(startTimeRounded)
                if alreadyExists {
                    print("⏭️  Skipping already synced session: \(session.startTime)")
                }
                return !alreadyExists
            }

            print("✨ \(sessionsToSync.count) new sessions to sync (skipped \(allSessions.count - sessionsToSync.count) duplicates)")

            guard !sessionsToSync.isEmpty else {
                DispatchQueue.main.async {
                    self.isSyncingFasting = false
                    self.syncMessage = "All fasting sessions are already synced to Apple Health."
                    self.showingSyncAlert = true
                }
                return
            }

            // STEP 3: Sync only new sessions
            var syncedCount = 0
            var errorCount = 0
            let dispatchGroup = DispatchGroup()

            for session in sessionsToSync {
                dispatchGroup.enter()

                HealthKitManager.shared.saveFastingSession(session) { success, error in
                    if success {
                        syncedCount += 1
                        print("✅ Synced session: \(session.startTime)")
                    } else {
                        errorCount += 1
                        print("❌ Failed to sync session: \(error?.localizedDescription ?? "Unknown error")")
                    }
                    dispatchGroup.leave()
                }
            }

            // STEP 4: Report results
            dispatchGroup.notify(queue: .main) {
                self.isSyncingFasting = false

                let skippedCount = allSessions.count - sessionsToSync.count

                if errorCount == 0 && skippedCount == 0 {
                    self.syncMessage = "Successfully synced \(syncedCount) fasting sessions to Apple Health."
                } else if errorCount == 0 && skippedCount > 0 {
                    self.syncMessage = "Synced \(syncedCount) new sessions. Skipped \(skippedCount) already synced."
                } else {
                    self.syncMessage = "Synced \(syncedCount) sessions. Skipped \(skippedCount) duplicates. \(errorCount) failed."
                }
                self.showingSyncAlert = true
            }
        }
    }

    // MARK: - Weight Sync Function

    private func syncWeightWithHealthKit(futureOnly: Bool) {
        print("\n🔄 === SYNC WEIGHT WITH HEALTHKIT (ADVANCED) ===")
        print("Future Only: \(futureOnly)")

        isSyncingWeight = true

        // BLOCKER 5 FIX: Request WEIGHT authorization only (not all permissions)
        // Per Apple best practices: Request permissions only when needed, per domain
        // Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy
        let isAuthorized = HealthKitManager.shared.isWeightAuthorized()
        print("Weight Authorization Status: \(isAuthorized ? "✅ Authorized" : "❌ Not Authorized")")

        if !isAuthorized {
            print("📱 Requesting WEIGHT authorization (granular)...")
            // Request authorization first
            HealthKitManager.shared.requestWeightAuthorization { success, error in
                if success {
                    print("✅ Weight authorization granted → performing sync")
                    performWeightSync(futureOnly: futureOnly)
                } else {
                    print("❌ Weight authorization failed: \(String(describing: error))")
                    isSyncingWeight = false
                    syncMessage = error?.localizedDescription ?? "Failed to authorize Apple Health. Please check Settings > Health > Data Access & Devices."
                    showingSyncAlert = true
                }
            }
        } else {
            print("✅ Already authorized → performing sync")
            // Already authorized, just sync
            performWeightSync(futureOnly: futureOnly)
        }

        print("==============================================\n")
    }

    private func performWeightSync(futureOnly: Bool) {
        // Create manager on-demand for sync operation only
        // Per Apple SwiftUI Best Practices: Create managers when needed, not on view init
        // Reference: https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
        let weightManager = WeightManager()

        if futureOnly {
            // Sync only from today forward
            weightManager.syncFromHealthKit(startDate: Date())
        } else {
            // Sync all historical data (default: last 365 days)
            weightManager.syncFromHealthKit()
        }

        // Give it a moment to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSyncingWeight = false
            let count = weightManager.weightEntries.count
            let timeframe = futureOnly ? "from today forward" : "from Apple Health"
            syncMessage = count > 0 ? "Successfully synced \(count) weight entries \(timeframe)." : "No weight data found in Apple Health."
            showingSyncAlert = true
        }
    }

    // MARK: - Hydration Sync Function

    private func syncHydrationWithHealthKit(futureOnly: Bool) {
        print("\n🔄 === SYNC HYDRATION WITH HEALTHKIT (ADVANCED) ===")
        print("Future Only: \(futureOnly)")

        isSyncingHydration = true

        // BLOCKER 5 FIX: Request HYDRATION authorization only (not all permissions)
        // Per Apple best practices: Request permissions only when needed, per domain
        // Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy
        let isAuthorized = HealthKitManager.shared.isWaterAuthorized()
        print("Hydration Authorization Status: \(isAuthorized ? "✅ Authorized" : "❌ Not Authorized")")

        if !isAuthorized {
            print("📱 Requesting HYDRATION authorization (granular)...")
            // Request authorization for water
            HealthKitManager.shared.requestHydrationAuthorization { success, error in
                if success {
                    // Check again after authorization
                    if HealthKitManager.shared.isWaterAuthorized() {
                        print("✅ Hydration authorization granted → performing sync")
                        self.performHydrationSync(futureOnly: futureOnly)
                    } else {
                        print("⚠️  Hydration permission not granted by user")
                        self.isSyncingHydration = false
                        self.syncMessage = "Water permission not granted. Please enable water access in Settings > Health > Apps > Fast LIFe."
                        self.showingSyncAlert = true
                    }
                } else {
                    print("❌ Hydration authorization failed: \(String(describing: error))")
                    self.isSyncingHydration = false
                    self.syncMessage = error?.localizedDescription ?? "Failed to authorize Apple Health. Please check Settings > Health > Data Access & Devices."
                    self.showingSyncAlert = true
                }
            }
        } else {
            print("✅ Already authorized → performing sync")
            // Already authorized for water, just sync
            performHydrationSync(futureOnly: futureOnly)
        }

        print("=================================================\n")
    }

    private func performHydrationSync(futureOnly: Bool) {
        // Create manager on-demand for sync operation only
        // Per Apple SwiftUI Best Practices: Create managers when needed, not on view init
        // Reference: https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
        let hydrationManager = HydrationManager()

        if futureOnly {
            // Sync only from today forward - TO HealthKit
            hydrationManager.syncToHealthKit()

            // No import needed for future-only, complete immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSyncingHydration = false
                let count = hydrationManager.drinkEntries.count
                syncMessage = "Successfully synced \(count) drink entries going forward. Future drinks will automatically sync to Apple Health."
                showingSyncAlert = true
            }
        } else {
            // Sync all drinks to HealthKit first
            hydrationManager.syncToHealthKit()

            // Then import from HealthKit with completion handler
            hydrationManager.syncFromHealthKit {
                // This runs AFTER import completes
                isSyncingHydration = false
                let count = hydrationManager.drinkEntries.count
                syncMessage = count > 0 ? "Successfully synced \(count) drink entries from Apple Health." : "No hydration data found in Apple Health."
                showingSyncAlert = true
            }
        }
    }

    // MARK: - Sync All Health Data

    private func syncAllHealthData(futureOnly: Bool) {
        print("\n🔄 === SYNC ALL HEALTH DATA (ADVANCED) ===")
        print("Future Only: \(futureOnly)")
        print("⚠️  NOTE: This uses LEGACY authorization (requests ALL permissions)")

        isSyncingAll = true

        // NOTE: "Sync All" intentionally uses legacy requestAuthorization()
        // This requests ALL permissions at once (weight + hydration + sleep)
        // Individual sync buttons use granular authorization per Blocker 5 fix
        let hasAnyAuth = HealthKitManager.shared.isAuthorized || HealthKitManager.shared.isWaterAuthorized()
        print("Any Authorization Status: \(hasAnyAuth ? "✅ Has some auth" : "❌ No auth")")

        if !hasAnyAuth {
            print("📱 Requesting ALL permissions (legacy method)...")
            // NOTE: "Sync All" intentionally uses LEGACY requestAuthorization()
            // Reason: User explicitly chose "Sync All" → requesting all permissions at once is acceptable UX
            // WARNING SUPPRESSION: This deprecation warning is acceptable - see comment above
            // Request authorization first
            HealthKitManager.shared.requestAuthorization { success, error in
                if success {
                    print("✅ Authorization granted → performing sync all")
                    performAllDataSync(futureOnly: futureOnly)
                } else {
                    print("❌ Authorization failed: \(String(describing: error))")
                    isSyncingAll = false
                    syncMessage = error?.localizedDescription ?? "Failed to authorize Apple Health. Please check Settings > Health > Data Access & Devices."
                    showingSyncAlert = true
                }
            }
        } else {
            print("✅ Already has some authorization → performing sync all")
            // Already authorized, just sync
            performAllDataSync(futureOnly: futureOnly)
        }

        print("==========================================\n")
    }

    private func performAllDataSync(futureOnly: Bool) {
        // Create managers on-demand for sync operation only
        // Per Apple SwiftUI Best Practices: Create managers when needed, not on view init
        // Reference: https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
        let weightManager = WeightManager()
        let hydrationManager = HydrationManager()

        if futureOnly {
            // Sync weight from today forward
            weightManager.syncFromHealthKit(startDate: Date())

            // Sync hydration to HealthKit only
            hydrationManager.syncToHealthKit()

            // No imports needed for future-only, complete after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isSyncingAll = false
                let weightCount = weightManager.weightEntries.count
                let drinkCount = hydrationManager.drinkEntries.count
                syncMessage = "Successfully synced \(weightCount) weight entries and \(drinkCount) drink entries going forward."
                showingSyncAlert = true
            }
        } else {
            // Sync weight from HealthKit
            weightManager.syncFromHealthKit()

            // Sync hydration to HealthKit first
            hydrationManager.syncToHealthKit()

            // Then import hydration from HealthKit with completion
            hydrationManager.syncFromHealthKit {
                // This runs AFTER all syncs complete
                isSyncingAll = false
                let weightCount = weightManager.weightEntries.count
                let drinkCount = hydrationManager.drinkEntries.count
                syncMessage = "Successfully synced \(weightCount) weight entries and \(drinkCount) drink entries from Apple Health."
                showingSyncAlert = true
            }
        }
    }
}

// MARK: - ShareSheet for sharing exported CSV files

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    AdvancedView(
        shouldPopToRoot: .constant(false),
        shouldResetToOnboarding: .constant(false),
        isOnboardingComplete: .constant(true),
        selectedTab: .constant(0)
    )
        .environmentObject(FastingManager())
}
