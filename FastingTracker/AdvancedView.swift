import SwiftUI
import UniformTypeIdentifiers

// MARK: - Quick Sync Status Widget

struct QuickSyncStatusWidget: View {
    let lastSyncDate: Date?
    let syncError: String?

    var body: some View {
        if let error = syncError {
            // Error state
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        } else if let lastSync = lastSyncDate {
            // Success state with timestamp
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("Last synced \(RelativeDateTimeFormatter().localizedString(for: lastSync, relativeTo: Date()))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else {
            // Never synced state
            HStack(spacing: 4) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("Not synced")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AdvancedView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @Binding var shouldPopToRoot: Bool
    @Binding var shouldResetToOnboarding: Bool
    @Binding var isOnboardingComplete: Bool
    @Binding var selectedTab: Int
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: self.$navigationPath) {
            ScrollView {
                VStack(spacing: 16) {
                    self.headerSection
                    self.featureCards
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self, destination: self.navigationDestination)
        }
        .onChange(of: self.shouldPopToRoot) { _, newValue in
            if newValue {
                self.navigationPath = NavigationPath()
                self.shouldPopToRoot = false
            }
        }
    }

    private var headerSection: some View {
        Text("Advanced Features")
            .font(.title2)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)
    }

    private var featureCards: some View {
        VStack(spacing: 16) {
            FeatureButton(
                title: "Weight Tracking",
                description: "Track your weight, BMI, and body fat percentage",
                icon: "scalemass.fill",
                color: .blue,
                destination: "weightTracking",
                navigationPath: self.$navigationPath
            )

            FeatureButton(
                title: "Hydration Tracker",
                description: "Track water, coffee, and tea intake during fasting",
                icon: "drop.fill",
                color: .cyan,
                destination: "hydrationTracking",
                navigationPath: self.$navigationPath
            )

            FeatureButton(
                title: "Sleep Tracker",
                description: "Track sleep duration and sync with Apple Health",
                icon: "bed.double.fill",
                color: .purple,
                destination: "sleepTracking",
                navigationPath: self.$navigationPath
            )

            FeatureButton(
                title: "Mood & Energy Tracker",
                description: "Track your mood and energy levels during fasting",
                icon: "face.smiling.fill",
                color: .orange,
                destination: "moodTracking",
                navigationPath: self.$navigationPath
            )

            FeatureButton(
                title: "Notifications",
                description: "AI-powered coaching messages to keep you motivated",
                icon: "bell.badge.fill",
                color: .orange,
                destination: "notificationSettings",
                navigationPath: self.$navigationPath
            )

            FeatureButton(
                title: "Settings",
                description: "Manage app data, sync, and preferences",
                icon: "gear",
                color: .gray,
                destination: "settings",
                navigationPath: self.$navigationPath
            )
        }
    }

    @ViewBuilder
    private func navigationDestination(for destination: String) -> some View {
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
                shouldResetToOnboarding: self.$shouldResetToOnboarding,
                isOnboardingComplete: self.$isOnboardingComplete,
                selectedTab: self.$selectedTab
            )
        default:
            EmptyView()
        }
    }
}

struct FeatureButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let destination: String
    @Binding var navigationPath: NavigationPath

    var body: some View {
        Button(action: { self.navigationPath.append(self.destination) }) {
            AdvancedFeatureCard(
                title: self.title,
                description: self.description,
                icon: self.icon,
                color: self.color,
                isAvailable: true
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
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
            Image(systemName: self.icon)
                .font(.system(size: 36))
                .foregroundColor(self.isAvailable ? self.color : .gray)
                .frame(width: 60, height: 60)
                .background(self.isAvailable ? self.color.opacity(0.15) : Color.gray.opacity(0.15))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(self.title)
                        .font(.headline)
                        .foregroundColor(self.isAvailable ? .primary : .secondary)

                    if !self.isAvailable {
                        Text("Coming Soon")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(6)
                    }
                }

                Text(self.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if self.isAvailable {
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .opacity(self.isAvailable ? 1.0 : 0.7)
    }
}

// MARK: - App Settings View

struct AppSettingsView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var hydrationManager: HydrationManager
    @EnvironmentObject var sleepManager: SleepManager
    @EnvironmentObject var moodManager: MoodManager
    @EnvironmentObject var appSettings: AppSettings

    @Binding var shouldResetToOnboarding: Bool
    @Binding var isOnboardingComplete: Bool
    @Binding var selectedTab: Int

    @State private var isExporting = false
    @State private var showingImportFilePicker = false

    var body: some View {
        List {
            self.dataImportExportSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var dataImportExportSection: some View {
        Section(
            header: Text("Data Import & Export"),
            footer: Text("Export your data for backup or import previously exported data to restore.")
        ) {
            Button(action: { self.exportData() }) {
                HStack {
                    if self.isExporting {
                        ProgressView()
                            .padding(.trailing, 8)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                    Text(self.isExporting ? "Exporting..." : "Export All Data to CSV")
                        .foregroundColor(.primary)
                }
            }
            .disabled(self.isExporting)

            Button(action: { self.showingImportFilePicker = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.green)
                    Text("Import Data from CSV")
                        .foregroundColor(.primary)
                }
            }
        }
    }

    private func exportData() {
        // Simplified export - just set state for UI feedback
        self.isExporting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isExporting = false
        }
    }
}

// MARK: - Supporting Structures

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
