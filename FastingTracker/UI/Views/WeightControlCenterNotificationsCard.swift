import SwiftUI

/// Notifications configuration card shown inside the Weight Control Center.
struct WeightControlCenterNotificationsCard: View {
    @ObservedObject var coordinator: WeightNotificationCoordinator

    private typealias TimingMode = WeightReminderTimingMode
    private typealias NotificationFrequency = WeightNotificationFrequency

    private let weekdays: [(number: Int, name: String)] = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardPadding) {
            Text("Receive daily reminders for your weigh-in routine.")
                .font(DSTypography.iconButton)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            Toggle(isOn: $coordinator.weightRemindersEnabled) {
                VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
                    Text("Enable Weight Reminders")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Get notified at your preferred time each day")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)
            .accessibilityLabel("Toggle daily weight reminders")
            .onChange(of: coordinator.weightRemindersEnabled) { _, newValue in
                coordinator.handleReminderToggle(newValue)
            }

            if coordinator.weightRemindersEnabled {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                timingModeSection

                if coordinator.timingMode == .specificTime {
                    specificTimeSection
                } else {
                    offsetSection
                }

                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                quietHoursSection

                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                skipDaysSection
            }

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            advancedOptionsSection
        }
    }

    private var timingModeSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
            Text("Timing")
                .font(DSTypography.listTitle)
                .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

            Picker("Timing Mode", selection: $coordinator.timingMode) {
                ForEach(TimingMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .tint(Theme.ColorToken.accentCyan)
            .onAppear {
                let appearance = UISegmentedControl.appearance()
                appearance.setTitleTextAttributes([.foregroundColor: UIColor(Theme.ColorToken.accentCyan)], for: .normal)
                appearance.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
            }
            .onChange(of: coordinator.timingMode) { _, _ in
                coordinator.saveTimingMode()
            }
        }
    }

    private var specificTimeSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
            Text("Reminder Time")
                .font(DSTypography.listTitle)
                .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

            DatePicker(
                "Reminder Time",
                selection: $coordinator.preferredReminderTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .colorScheme(.dark)
            .accessibilityLabel("Set preferred weigh-in reminder time")
            .onChange(of: coordinator.preferredReminderTime) { _, _ in
                coordinator.savePreferredTime()
            }
        }
    }

    private var offsetSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
            Text(coordinator.timingMode == .beforeFastingGoal ? "Minutes Before Fasting Goal" : "Minutes After Waking Up")
                .font(DSTypography.listTitle)
                .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

            Stepper(value: $coordinator.minutesOffset, in: 5...120, step: 5) {
                Text("\(coordinator.minutesOffset) minutes")
                    .font(DSTypography.cardTitle)
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
            }
            .onChange(of: coordinator.minutesOffset) { _, _ in
                coordinator.saveMinutesOffset()
            }

            Text("Ideal for weighing in right before your fasting goal or after you wake up.")
                .font(DSTypography.cardCaption)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
        }
    }

    private var quietHoursSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
            Toggle(isOn: $coordinator.quietHoursEnabled) {
                VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
                    Text("Quiet Hours")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("No reminders during your quiet hours")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)
            .onChange(of: coordinator.quietHoursEnabled) { _, _ in
                coordinator.saveQuietHours()
            }

            if coordinator.quietHoursEnabled {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Start")
                            .font(DSTypography.statLabel)
                            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                        DatePicker(
                            "Quiet Hours Start",
                            selection: $coordinator.quietHoursStart,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: coordinator.quietHoursStart) { _, _ in
                            coordinator.saveQuietHours()
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("End")
                            .font(DSTypography.statLabel)
                            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                        DatePicker(
                            "Quiet Hours End",
                            selection: $coordinator.quietHoursEnd,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: coordinator.quietHoursEnd) { _, _ in
                            coordinator.saveQuietHours()
                        }
                    }
                }
            }
        }
    }

    private var skipDaysSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
                Text("Don't send reminders on these days")
                    .font(DSTypography.cardCaption)
                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                    .padding(.bottom, DSSpacing.cardExtraSmallSpacing)

                ForEach(weekdays, id: \.number) { day in
                    Toggle(isOn: Binding(
                        get: { coordinator.skipWeekdays.contains(day.number) },
                        set: { isSkipped in
                            if isSkipped {
                                coordinator.skipWeekdays.insert(day.number)
                            } else {
                                coordinator.skipWeekdays.remove(day.number)
                            }
                            coordinator.saveSkipWeekdays()
                        }
                    )) {
                        Text(day.name)
                            .font(DSTypography.labelSecondary)
                            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    }
                    .tint(Theme.ColorToken.accentPrimary)
                    .accessibilityLabel("Skip weight reminders on \(day.name)")
                }
            }
            .padding(.top, DSSpacing.cardSmallSpacing)
        } label: {
            Text("Skip Days")
                .font(DSTypography.listTitle)
                .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
        }
    }

    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardElementSpacing) {
            Text("Advanced Options")
                .font(DSTypography.listTitle)
                .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

            Toggle(isOn: $coordinator.didYouKnowEnabled) {
                VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
                    Text("Did You Know Tips")
                        .font(DSTypography.cardTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Science-backed education to keep you engaged")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)
            .onChange(of: coordinator.didYouKnowEnabled) { _, _ in
                coordinator.saveDidYouKnowSettings()
            }

            if coordinator.didYouKnowEnabled {
                Picker("Frequency", selection: $coordinator.didYouKnowFrequency) {
                    ForEach(NotificationFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: coordinator.didYouKnowFrequency) { _, _ in
                    coordinator.saveDidYouKnowSettings()
                }
            }

            Toggle(isOn: $coordinator.motivationalEnabled) {
                VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
                    Text("Motivational Messages")
                        .font(DSTypography.cardTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Celebrate progress milestones with uplifting messages")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)
            .onChange(of: coordinator.motivationalEnabled) { _, _ in
                coordinator.saveMotivationalSettings()
            }

            if coordinator.motivationalEnabled {
                Picker("Frequency", selection: $coordinator.motivationalFrequency) {
                    ForEach(NotificationFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: coordinator.motivationalFrequency) { _, _ in
                    coordinator.saveMotivationalSettings()
                }
            }

            Toggle(isOn: $coordinator.actionStepsEnabled) {
                VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
                    Text("Action Steps")
                        .font(DSTypography.cardTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Small, actionable behaviors to stay consistent")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)
            .onChange(of: coordinator.actionStepsEnabled) { _, _ in
                coordinator.saveActionStepsSettings()
            }

            if coordinator.actionStepsEnabled {
                Picker("Frequency", selection: $coordinator.actionStepsFrequency) {
                    ForEach(NotificationFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: coordinator.actionStepsFrequency) { _, _ in
                    coordinator.saveActionStepsSettings()
                }
            }
        }
    }
}
