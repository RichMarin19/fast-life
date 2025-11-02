import SwiftUI

/// Notifications configuration card shown inside the Weight Control Center.
struct WeightControlCenterNotificationsCard: View {
    @ObservedObject var viewModel: WeightControlCenterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardPadding) {
            Text("Receive daily reminders for your weigh-in routine.")
                .font(DSTypography.iconButton)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            Toggle(isOn: $viewModel.weightRemindersEnabled) {
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
            .onChange(of: viewModel.weightRemindersEnabled) { _, newValue in
                viewModel.handleReminderToggle(newValue)
            }

            if viewModel.weightRemindersEnabled {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

                timingModeSection

                if viewModel.timingMode == .specificTime {
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

            Picker("Timing Mode", selection: $viewModel.timingMode) {
                ForEach(WeightControlCenterViewModel.TimingMode.allCases, id: \.self) { mode in
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
            .onChange(of: viewModel.timingMode) { _, _ in
                viewModel.saveTimingMode()
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
                selection: $viewModel.preferredReminderTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .colorScheme(.dark)
            .accessibilityLabel("Set preferred weigh-in reminder time")
            .onChange(of: viewModel.preferredReminderTime) { _, _ in
                viewModel.savePreferredTime()
            }
        }
    }

    private var offsetSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
            Text(viewModel.timingMode == .beforeFastingGoal ? "Minutes Before Fasting Goal" : "Minutes After Waking Up")
                .font(DSTypography.listTitle)
                .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

            Stepper(value: $viewModel.minutesOffset, in: 5...120, step: 5) {
                Text("\(viewModel.minutesOffset) minutes")
                    .font(DSTypography.cardTitle)
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
            }
            .onChange(of: viewModel.minutesOffset) { _, _ in
                viewModel.saveMinutesOffset()
            }

            Text("Ideal for weighing in right before your fasting goal or after you wake up.")
                .font(DSTypography.cardCaption)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
        }
    }

    private var quietHoursSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
            Toggle(isOn: $viewModel.quietHoursEnabled) {
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
            .onChange(of: viewModel.quietHoursEnabled) { _, _ in
                viewModel.saveQuietHours()
            }

            if viewModel.quietHoursEnabled {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Start")
                            .font(DSTypography.statLabel)
                            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                        DatePicker(
                            "Quiet Hours Start",
                            selection: $viewModel.quietHoursStart,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: viewModel.quietHoursStart) { _, _ in
                            viewModel.saveQuietHours()
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("End")
                            .font(DSTypography.statLabel)
                            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                        DatePicker(
                            "Quiet Hours End",
                            selection: $viewModel.quietHoursEnd,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: viewModel.quietHoursEnd) { _, _ in
                            viewModel.saveQuietHours()
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

                ForEach(viewModel.weekdays, id: \.number) { day in
                    Toggle(isOn: Binding(
                        get: { viewModel.skipWeekdays.contains(day.number) },
                        set: { isSkipped in
                            if isSkipped {
                                viewModel.skipWeekdays.insert(day.number)
                            } else {
                                viewModel.skipWeekdays.remove(day.number)
                            }
                            viewModel.saveSkipWeekdays()
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

            Toggle(isOn: $viewModel.didYouKnowEnabled) {
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
            .onChange(of: viewModel.didYouKnowEnabled) { _, _ in
                viewModel.saveDidYouKnowSettings()
            }

            if viewModel.didYouKnowEnabled {
                Picker("Frequency", selection: $viewModel.didYouKnowFrequency) {
                    ForEach(WeightControlCenterViewModel.NotificationFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.didYouKnowFrequency) { _, _ in
                    viewModel.saveDidYouKnowSettings()
                }
            }

            Toggle(isOn: $viewModel.motivationalEnabled) {
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
            .onChange(of: viewModel.motivationalEnabled) { _, _ in
                viewModel.saveMotivationalSettings()
            }

            if viewModel.motivationalEnabled {
                Picker("Frequency", selection: $viewModel.motivationalFrequency) {
                    ForEach(WeightControlCenterViewModel.NotificationFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.motivationalFrequency) { _, _ in
                    viewModel.saveMotivationalSettings()
                }
            }

            Toggle(isOn: $viewModel.actionStepsEnabled) {
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
            .onChange(of: viewModel.actionStepsEnabled) { _, _ in
                viewModel.saveActionStepsSettings()
            }

            if viewModel.actionStepsEnabled {
                Picker("Frequency", selection: $viewModel.actionStepsFrequency) {
                    ForEach(WeightControlCenterViewModel.NotificationFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.actionStepsFrequency) { _, _ in
                    viewModel.saveActionStepsSettings()
                }
            }
        }
    }
}
