import SwiftUI

/// Notification settings for AI-powered coaching messages
/// Per Apple HIG: Use settings to let people configure app behavior
/// Reference: https://developer.apple.com/design/human-interface-guidelines/settings
struct NotificationSettingsView: View {
    // Persist settings with @AppStorage
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("notificationMode") private var notificationMode = NotificationMode.balanced.rawValue

    // Notification type toggles
    @AppStorage("notif_hydration") private var hydrationEnabled = true
    @AppStorage("notif_didyouknow") private var didYouKnowEnabled = true
    @AppStorage("notif_milestones") private var milestonesEnabled = true
    @AppStorage("notif_stages") private var stagesEnabled = true

    var body: some View {
        List {
            // Master Toggle Section
            Section {
                Toggle(isOn: $notificationsEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .font(.title2)
                            .foregroundColor(notificationsEnabled ? .orange : .gray)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Notifications")
                                .font(.headline)
                            Text(notificationsEnabled ? "Coaching active" : "Coaching paused")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Notification Status")
            } footer: {
                Text("Get personalized guidance powered by YOUR fasting data—patterns, progress, and current stage—for smarter, timely motivation.")
            }

            // Mode Selection Section
            if notificationsEnabled {
                Section {
                    Picker("Coaching Intensity", selection: $notificationMode) {
                        ForEach(NotificationMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()

                    // Selected mode description
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: selectedMode.icon)
                                .foregroundColor(selectedMode.color)
                            Text(selectedMode.displayName)
                                .font(.headline)
                        }

                        Text(selectedMode.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text(selectedMode.frequency)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } header: {
                    Text("Coaching Mode")
                } footer: {
                    Text("Control how we use your data to send insights. More messages = more real-time guidance based on your patterns and progress.")
                }

                // Notification Types Section
                Section {
                    // Select All / Deselect All Button
                    Button(action: {
                        let shouldEnableAll = !allTypesEnabled
                        hydrationEnabled = shouldEnableAll
                        didYouKnowEnabled = shouldEnableAll
                        milestonesEnabled = shouldEnableAll
                        stagesEnabled = shouldEnableAll
                    }) {
                        HStack {
                            Image(systemName: allTypesEnabled ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(allTypesEnabled ? .blue : .gray)
                            Text(allTypesEnabled ? "Deselect All" : "Select All")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    Divider()

                    // Hydration Reminders
                    Toggle(isOn: $hydrationEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "drop.fill")
                                .font(.title3)
                                .foregroundColor(.cyan)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Hydration Reminders")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Stay hydrated with timely water reminders during your fast")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // Did You Know Facts
                    Toggle(isOn: $didYouKnowEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .font(.title3)
                                .foregroundColor(.yellow)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Did You Know Facts")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Learn about fasting science, benefits, and what's happening in your body")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // Milestone Celebrations
                    Toggle(isOn: $milestonesEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Milestone Celebrations")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Get congratulated when you hit 12h, 16h, 18h, and other goals")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // Stage Transitions
                    Toggle(isOn: $stagesEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.title3)
                                .foregroundColor(.green)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Stage Transitions")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Know when you enter fat-burning, ketosis, and autophagy stages")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                } header: {
                    Text("Notification Types")
                } footer: {
                    Text("Choose which types of guidance you'd like. You can customize triggers later.")
                }
            }

            // How It Works Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    NotificationFeatureRow(
                        icon: "brain.head.profile",
                        color: .purple,
                        title: "Smart Timing",
                        description: "Messages sent when you need them most"
                    )

                    Divider()

                    NotificationFeatureRow(
                        icon: "waveform.path.ecg",
                        color: .red,
                        title: "Personalized Content",
                        description: "Based on your fasting stage and progress"
                    )

                    Divider()

                    NotificationFeatureRow(
                        icon: "moon.zzz.fill",
                        color: .indigo,
                        title: "Quiet Hours",
                        description: "Respects your sleep (8:30 PM - 6:30 AM)"
                    )
                }
            } header: {
                Text("How It Works")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Computed property for selected mode
    private var selectedMode: NotificationMode {
        NotificationMode(rawValue: notificationMode) ?? .balanced
    }

    // Computed property to check if all types are enabled
    private var allTypesEnabled: Bool {
        hydrationEnabled && didYouKnowEnabled && milestonesEnabled && stagesEnabled
    }
}

// MARK: - Notification Mode Enum

enum NotificationMode: String, CaseIterable {
    case minimal = "minimal"
    case balanced = "balanced"
    case coaching = "coaching"

    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .balanced: return "Balanced"
        case .coaching: return "Coaching"
        }
    }

    var description: String {
        switch self {
        case .minimal:
            return "Perfect for experienced fasters. Receive occasional check-ins and milestone celebrations only."
        case .balanced:
            return "Great for most users. Get timely reminders, encouragement during key fasting stages, and helpful tips."
        case .coaching:
            return "Ideal for beginners. Maximum support with frequent motivation, hydration reminders, and stage-specific guidance."
        }
    }

    var frequency: String {
        switch self {
        case .minimal: return "0-1 notification per day"
        case .balanced: return "1-2 notifications per day"
        case .coaching: return "Up to 3 notifications per day"
        }
    }

    var icon: String {
        switch self {
        case .minimal: return "leaf.fill"
        case .balanced: return "chart.bar.fill"
        case .coaching: return "medal.fill"
        }
    }

    var color: Color {
        switch self {
        case .minimal: return .green
        case .balanced: return .blue
        case .coaching: return .orange
        }
    }
}

// MARK: - Notification Feature Row Component

struct NotificationFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
