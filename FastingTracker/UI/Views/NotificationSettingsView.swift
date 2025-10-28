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
    @AppStorage("notif_goalreminder") private var goalReminderEnabled = true

    // Trigger selections
    @AppStorage("trigger_hydration") private var hydrationTrigger = HydrationTrigger.every3h.rawValue
    @AppStorage("trigger_didyouknow") private var didYouKnowTrigger = DidYouKnowTrigger.midMorning.rawValue
    @AppStorage("trigger_milestones") private var milestonesTrigger = MilestonesTrigger.whenReached.rawValue
    @AppStorage("trigger_stages") private var stagesTrigger = StagesTrigger.whenEntering.rawValue
    @AppStorage("trigger_goalreminder") private var goalReminderTrigger = GoalReminderTrigger.min15Before.rawValue

    // Max per day limits
    @AppStorage("maxStageNotificationsPerDay") private var maxStagePerDay = 2
    @AppStorage("maxHydrationNotificationsPerDay") private var maxHydrationPerDay = 2
    @AppStorage("maxDidYouKnowNotificationsPerDay") private var maxDidYouKnowPerDay = 1
    @AppStorage("maxMilestoneNotificationsPerDay") private var maxMilestonePerDay = 2
    @AppStorage("maxGoalReminderNotificationsPerDay") private var maxGoalReminderPerDay = 1

    // View preferences
    @AppStorage("expandedTriggersView") private var expandedTriggersView = false
    @AppStorage("wakeTime") private var wakeTimeString = "07:00"

    // Quiet Hours settings
    // Per Apple HIG: Give users control over when notifications can be delivered
    // Reference: https://developer.apple.com/design/human-interface-guidelines/notifications
    @AppStorage("quietHoursEnabled") private var quietHoursEnabled = true
    @AppStorage("quietHoursStart") private var quietHoursStartString = "21:00" // 9:00 PM
    @AppStorage("quietHoursEnd") private var quietHoursEndString = "06:30" // 6:30 AM

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

                // My Wake Time Section
                Section {
                    DatePicker("Wake Time", selection: Binding(
                        get: {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            return formatter.date(from: wakeTimeString) ?? Date()
                        },
                        set: { newDate in
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            wakeTimeString = formatter.string(from: newDate)
                        }
                    ), displayedComponents: .hourAndMinute)

                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Used for 'after wake' notification triggers. You can sync with Sleep Tracker in a future update.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
                } header: {
                    Text("My Wake Time")
                } footer: {
                    Text("Some notifications use your wake time for optimal scheduling.")
                }

                // Notification Types Section
                Section {
                    // Expanded View Toggle
                    Toggle(isOn: $expandedTriggersView) {
                        HStack(spacing: 12) {
                            Image(systemName: expandedTriggersView ? "list.bullet.indent" : "chevron.right.circle")
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Expanded View")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(expandedTriggersView ? "Showing all trigger options inline" : "Tap notification types to customize triggers")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    // Select All / Deselect All Button
                    Button(action: {
                        let shouldEnableAll = !allTypesEnabled
                        hydrationEnabled = shouldEnableAll
                        didYouKnowEnabled = shouldEnableAll
                        milestonesEnabled = shouldEnableAll
                        stagesEnabled = shouldEnableAll
                        goalReminderEnabled = shouldEnableAll
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

                    // Trigger customization for Hydration
                    if hydrationEnabled {
                        if expandedTriggersView {
                            // Expanded mode: Show inline picker
                            Picker("Frequency", selection: $hydrationTrigger) {
                                ForEach(HydrationTrigger.allCases, id: \.self) { trigger in
                                    Text(trigger.displayName).tag(trigger.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.leading, 44)
                        } else {
                            // Compact mode: Show current selection + chevron, navigate to detail
                            NavigationLink(destination: HydrationTriggersView()) {
                                HStack {
                                    Text(HydrationTrigger(rawValue: hydrationTrigger)?.displayName ?? "Every 3 hours")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.leading, 44)
                            }
                        }

                        // Max per day control
                        // Per Apple HIG: Give users control over notification frequency
                        // Reference: https://developer.apple.com/design/human-interface-guidelines/notifications
                        HStack {
                            Text("Max Per Day")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("", selection: $maxHydrationPerDay) {
                                ForEach(1...5, id: \.self) { num in
                                    Text("\(num)").tag(num)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 60)
                        }
                        .padding(.leading, 44)
                        .padding(.trailing, 16)
                        .padding(.top, 4)
                    }

                    Divider()

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

                    // Trigger customization for Did You Know
                    if didYouKnowEnabled {
                        if expandedTriggersView {
                            // Expanded mode: Show inline picker
                            Picker("Timing", selection: $didYouKnowTrigger) {
                                ForEach(DidYouKnowTrigger.allCases, id: \.self) { trigger in
                                    Text(trigger.displayName).tag(trigger.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.leading, 44)
                        } else {
                            // Compact mode: Show current selection + chevron, navigate to detail
                            NavigationLink(destination: DidYouKnowTriggersView()) {
                                HStack {
                                    Text(DidYouKnowTrigger(rawValue: didYouKnowTrigger)?.displayName ?? "Mid-morning (10 AM)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.leading, 44)
                            }
                        }

                        // Max per day control
                        HStack {
                            Text("Max Per Day")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("", selection: $maxDidYouKnowPerDay) {
                                ForEach(1...5, id: \.self) { num in
                                    Text("\(num)").tag(num)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 60)
                        }
                        .padding(.leading, 44)
                        .padding(.trailing, 16)
                        .padding(.top, 4)
                    }

                    Divider()

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
                                Text("Get congratulated at key milestones (4h, 8h, 12h, 16h, etc.) based on your goal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // Trigger customization for Milestones
                    if milestonesEnabled {
                        if expandedTriggersView {
                            // Expanded mode: Show inline picker
                            Picker("Timing", selection: $milestonesTrigger) {
                                ForEach(MilestonesTrigger.allCases, id: \.self) { trigger in
                                    Text(trigger.displayName).tag(trigger.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.leading, 44)
                        } else {
                            // Compact mode: Show current selection + chevron, navigate to detail
                            NavigationLink(destination: MilestonesTriggersView()) {
                                HStack {
                                    Text(MilestonesTrigger(rawValue: milestonesTrigger)?.displayName ?? "When goal is reached")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.leading, 44)
                            }
                        }

                        // Max per day control
                        HStack {
                            Text("Max Per Day")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("", selection: $maxMilestonePerDay) {
                                ForEach(1...5, id: \.self) { num in
                                    Text("\(num)").tag(num)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 60)
                        }
                        .padding(.leading, 44)
                        .padding(.trailing, 16)
                        .padding(.top, 4)
                    }

                    Divider()

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

                    // Trigger customization for Stage Transitions
                    if stagesEnabled {
                        if expandedTriggersView {
                            // Expanded mode: Show inline picker
                            Picker("Timing", selection: $stagesTrigger) {
                                ForEach(StagesTrigger.allCases, id: \.self) { trigger in
                                    Text(trigger.displayName).tag(trigger.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.leading, 44)
                        } else {
                            // Compact mode: Show current selection + chevron, navigate to detail
                            NavigationLink(destination: StageTransitionsTriggersView()) {
                                HStack {
                                    Text(StagesTrigger(rawValue: stagesTrigger)?.displayName ?? "When entering stage")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.leading, 44)
                            }
                        }

                        // Max per day control
                        HStack {
                            Text("Max Per Day")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("", selection: $maxStagePerDay) {
                                ForEach(1...5, id: \.self) { num in
                                    Text("\(num)").tag(num)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 60)
                        }
                        .padding(.leading, 44)
                        .padding(.trailing, 16)
                        .padding(.top, 4)
                    }

                    Divider()

                    // Goal Reminders
                    Toggle(isOn: $goalReminderEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "target")
                                .font(.title3)
                                .foregroundColor(.purple)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Goal Reminders")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Get notified before or when you reach your fasting goal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // Trigger customization for Goal Reminders
                    if goalReminderEnabled {
                        if expandedTriggersView {
                            // Expanded mode: Show inline picker
                            Picker("Timing", selection: $goalReminderTrigger) {
                                ForEach(GoalReminderTrigger.allCases, id: \.self) { trigger in
                                    Text(trigger.displayName).tag(trigger.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.leading, 44)
                        } else {
                            // Compact mode: Show current selection + chevron, navigate to detail
                            NavigationLink(destination: GoalRemindersTriggersView()) {
                                HStack {
                                    Text(GoalReminderTrigger(rawValue: goalReminderTrigger)?.displayName ?? "15 min before goal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.leading, 44)
                            }
                        }

                        // Max per day control
                        HStack {
                            Text("Max Per Day")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("", selection: $maxGoalReminderPerDay) {
                                ForEach(1...5, id: \.self) { num in
                                    Text("\(num)").tag(num)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 60)
                        }
                        .padding(.leading, 44)
                        .padding(.trailing, 16)
                        .padding(.top, 4)
                    }
                } header: {
                    Text("Notification Types")
                } footer: {
                    Text("Choose which types of guidance you'd like. Tap to customize when each notification is sent.")
                }
            }

            // Quiet Hours Section
            // Per Apple HIG: Give users control over notification delivery times
            // Reference: https://developer.apple.com/design/human-interface-guidelines/notifications
            if notificationsEnabled {
                Section {
                    // Enable/Disable Toggle
                    Toggle(isOn: $quietHoursEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.title3)
                                .foregroundColor(.indigo)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Quiet Hours")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(quietHoursEnabled ? "Notifications paused during sleep" : "Notifications allowed anytime")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if quietHoursEnabled {
                        // Start Time Picker
                        DatePicker("Start Time", selection: Binding(
                            get: {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                return formatter.date(from: quietHoursStartString) ?? Date()
                            },
                            set: { newDate in
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                quietHoursStartString = formatter.string(from: newDate)
                            }
                        ), displayedComponents: .hourAndMinute)
                        .padding(.leading, 44)

                        // End Time Picker
                        DatePicker("End Time", selection: Binding(
                            get: {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                return formatter.date(from: quietHoursEndString) ?? Date()
                            },
                            set: { newDate in
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                quietHoursEndString = formatter.string(from: newDate)
                            }
                        ), displayedComponents: .hourAndMinute)
                        .padding(.leading, 44)

                        // Info box
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("Notifications won't be sent during these hours. Scheduled notifications will fire after quiet hours end.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 44)
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    Text("Quiet Hours")
                } footer: {
                    Text("Control when notifications can be delivered. Future update will allow syncing with Sleep Tracker.")
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
                        description: quietHoursEnabled ? "Respects your sleep (\(formatTime(quietHoursStartString)) - \(formatTime(quietHoursEndString)))" : "Disabled - notifications anytime"
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
        hydrationEnabled && didYouKnowEnabled && milestonesEnabled && stagesEnabled && goalReminderEnabled
    }

    // Helper function to format time strings (e.g., "21:00" -> "9:00 PM")
    // Reference: https://developer.apple.com/documentation/foundation/dateformatter
    private func formatTime(_ timeString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm"

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"

        if let time = inputFormatter.date(from: timeString) {
            return outputFormatter.string(from: time)
        }
        return timeString
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

// MARK: - Trigger Enums

enum HydrationTrigger: String, CaseIterable {
    case every2h = "every2h"
    case every3h = "every3h"
    case every4h = "every4h"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .every2h: return "Every 2 hours"
        case .every3h: return "Every 3 hours"
        case .every4h: return "Every 4 hours"
        case .custom: return "Custom interval"
        }
    }
}

enum DidYouKnowTrigger: String, CaseIterable {
    case afterWake = "afterwake"
    case midMorning = "midmorning"
    case afternoon = "afternoon"
    case evening = "evening"

    var displayName: String {
        switch self {
        case .afterWake: return "1 hour after wake"
        case .midMorning: return "Mid-morning (10 AM)"
        case .afternoon: return "Afternoon (2 PM)"
        case .evening: return "Evening (7 PM)"
        }
    }
}

enum MilestonesTrigger: String, CaseIterable {
    case whenReached = "whenreached"
    case min15Before = "15before"
    case min30Before = "30before"
    case hour1Before = "1hbefore"

    var displayName: String {
        switch self {
        case .whenReached: return "When goal is reached"
        case .min15Before: return "15 min before goal"
        case .min30Before: return "30 min before goal"
        case .hour1Before: return "1 hour before goal"
        }
    }
}

enum StagesTrigger: String, CaseIterable {
    case whenEntering = "whenentering"
    case min30Into = "30into"
    case hour1Into = "1hinto"

    var displayName: String {
        switch self {
        case .whenEntering: return "When entering stage"
        case .min30Into: return "30 min into stage"
        case .hour1Into: return "1 hour into stage"
        }
    }
}

enum GoalReminderTrigger: String, CaseIterable {
    case min15Before = "15before"
    case min30Before = "30before"
    case hour1Before = "1hbefore"
    case atGoal = "atgoal"

    var displayName: String {
        switch self {
        case .min15Before: return "15 min before goal"
        case .min30Before: return "30 min before goal"
        case .hour1Before: return "1 hour before goal"
        case .atGoal: return "When goal is reached"
        }
    }
}

// MARK: - Trigger Detail Views

struct HydrationTriggersView: View {
    @AppStorage("trigger_hydration") private var hydrationTrigger = HydrationTrigger.every3h.rawValue

    var body: some View {
        List {
            Section {
                Picker("Hydration Reminder Frequency", selection: $hydrationTrigger) {
                    ForEach(HydrationTrigger.allCases, id: \.self) { trigger in
                        Text(trigger.displayName).tag(trigger.rawValue)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("When to Send")
            } footer: {
                Text("Choose how often you'd like hydration reminders during your fast. Staying hydrated is crucial for successful fasting.")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    TriggerOptionRow(
                        title: "Every 2 hours",
                        description: "Frequent reminders for maximum hydration support",
                        isSelected: hydrationTrigger == HydrationTrigger.every2h.rawValue
                    )

                    Divider()

                    TriggerOptionRow(
                        title: "Every 3 hours",
                        description: "Balanced hydration support (recommended)",
                        isSelected: hydrationTrigger == HydrationTrigger.every3h.rawValue
                    )

                    Divider()

                    TriggerOptionRow(
                        title: "Every 4 hours",
                        description: "Occasional reminders for experienced fasters",
                        isSelected: hydrationTrigger == HydrationTrigger.every4h.rawValue
                    )

                    Divider()

                    TriggerOptionRow(
                        title: "Custom interval",
                        description: "Set your own reminder schedule",
                        isSelected: hydrationTrigger == HydrationTrigger.custom.rawValue
                    )
                }
            } header: {
                Text("Options")
            }
        }
        .navigationTitle("Hydration Reminders")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DidYouKnowTriggersView: View {
    @AppStorage("trigger_didyouknow") private var didYouKnowTrigger = DidYouKnowTrigger.midMorning.rawValue

    var body: some View {
        List {
            Section {
                Picker("Did You Know Fact Timing", selection: $didYouKnowTrigger) {
                    ForEach(DidYouKnowTrigger.allCases, id: \.self) { trigger in
                        Text(trigger.displayName).tag(trigger.rawValue)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("When to Send")
            } footer: {
                Text("Choose when you'd like to receive educational facts about fasting science and benefits.")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    TriggerOptionRow(
                        title: "1 hour after wake",
                        description: "Start your day with fasting knowledge",
                        isSelected: didYouKnowTrigger == DidYouKnowTrigger.afterWake.rawValue
                    )

                    Divider()

                    TriggerOptionRow(
                        title: "Mid-morning (10 AM)",
                        description: "Learn during your morning routine (recommended)",
                        isSelected: didYouKnowTrigger == DidYouKnowTrigger.midMorning.rawValue
                    )

                    Divider()

                    TriggerOptionRow(
                        title: "Afternoon (2 PM)",
                        description: "Educational content during midday",
                        isSelected: didYouKnowTrigger == DidYouKnowTrigger.afternoon.rawValue
                    )

                    Divider()

                    TriggerOptionRow(
                        title: "Evening (7 PM)",
                        description: "Wind down with fasting insights",
                        isSelected: didYouKnowTrigger == DidYouKnowTrigger.evening.rawValue
                    )
                }
            } header: {
                Text("Options")
            }
        }
        .navigationTitle("Did You Know Facts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MilestonesTriggersView: View {
    @AppStorage("trigger_milestones") private var milestonesTrigger = MilestonesTrigger.whenReached.rawValue

    var body: some View {
        List {
            Section {
                Picker("Milestone Celebration Timing", selection: $milestonesTrigger) {
                    ForEach(MilestonesTrigger.allCases, id: \.self) { trigger in
                        Text(trigger.displayName).tag(trigger.rawValue)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("When to Send")
            } footer: {
                Text("Choose when to receive celebrations for reaching fasting milestones like 12h, 16h, 18h, etc.")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    TriggerOptionRow(
                        title: "When goal is reached",
                        description: "Celebrate the moment you hit your milestone (recommended)",
                        isSelected: milestonesTrigger == MilestonesTrigger.whenReached.rawValue
                    )

                    Divider()

                    TriggerOptionRow(
                        title: "15 min before goal",
                        description: "Get motivated as you approach your milestone",
                        isSelected: milestonesTrigger == MilestonesTrigger.min15Before.rawValue
                    )

                    Divider()

                    TriggerOptionRow(
                        title: "30 min before goal",
                        description: "Prepare for your upcoming achievement",
                        isSelected: milestonesTrigger == MilestonesTrigger.min30Before.rawValue
                    )

                    Divider()

                    TriggerOptionRow(
                        title: "1 hour before goal",
                        description: "Early reminder to stay focused",
                        isSelected: milestonesTrigger == MilestonesTrigger.hour1Before.rawValue
                    )
                }
            } header: {
                Text("Options")
            }
        }
        .navigationTitle("Milestone Celebrations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StageTransitionsTriggersView: View {
    @AppStorage("trigger_stages") private var stagesTrigger = StagesTrigger.whenEntering.rawValue

    var body: some View {
        List {
            Section {
                Picker("Stage Transition Timing", selection: $stagesTrigger) {
                    ForEach(StagesTrigger.allCases, id: \.self) { trigger in
                        Text(trigger.displayName).tag(trigger.rawValue)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("When to Send")
            } footer: {
                Text("Choose when to receive notifications about entering fat-burning, ketosis, and autophagy stages.")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    TriggerOptionRow(
                        title: "When entering stage",
                        description: "Learn what's happening the moment you transition (recommended)",
                        isSelected: stagesTrigger == StagesTrigger.whenEntering.rawValue
                    )

                    Divider()

                    TriggerOptionRow(
                        title: "30 min into stage",
                        description: "Get stage insights after you've settled in",
                        isSelected: stagesTrigger == StagesTrigger.min30Into.rawValue
                    )

                    Divider()

                    TriggerOptionRow(
                        title: "1 hour into stage",
                        description: "Delayed notification for deeper stage understanding",
                        isSelected: stagesTrigger == StagesTrigger.hour1Into.rawValue
                    )
                }
            } header: {
                Text("Options")
            }
        }
        .navigationTitle("Stage Transitions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GoalRemindersTriggersView: View {
    @AppStorage("trigger_goalreminder") private var goalReminderTrigger = GoalReminderTrigger.min15Before.rawValue

    var body: some View {
        List {
            Section {
                Picker("Goal Reminder Timing", selection: $goalReminderTrigger) {
                    ForEach(GoalReminderTrigger.allCases, id: \.self) { trigger in
                        Text(trigger.displayName).tag(trigger.rawValue)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("When to Send")
            } footer: {
                Text("Choose when to receive reminders about your fasting goal based on your start and goal times.")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    TriggerOptionRow(
                        title: "15 min before goal",
                        description: "Perfect for final prep like weighing in or meal planning",
                        isSelected: goalReminderTrigger == GoalReminderTrigger.min15Before.rawValue
                    )

                    Divider()

                    TriggerOptionRow(
                        title: "30 min before goal",
                        description: "Get ready to break your fast with healthy choices",
                        isSelected: goalReminderTrigger == GoalReminderTrigger.min30Before.rawValue
                    )

                    Divider()

                    TriggerOptionRow(
                        title: "1 hour before goal",
                        description: "Early reminder to prepare for your eating window",
                        isSelected: goalReminderTrigger == GoalReminderTrigger.hour1Before.rawValue
                    )

                    Divider()

                    TriggerOptionRow(
                        title: "When goal is reached",
                        description: "Celebrate the moment you hit your fasting goal",
                        isSelected: goalReminderTrigger == GoalReminderTrigger.atGoal.rawValue
                    )
                }
            } header: {
                Text("Options")
            }
        }
        .navigationTitle("Goal Reminders")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Trigger Option Row Component

struct TriggerOptionRow: View {
    let title: String
    let description: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .blue : .primary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
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
