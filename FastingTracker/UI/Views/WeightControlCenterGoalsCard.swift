import SwiftUI

/// Goals configuration card within the Weight Control Center.
struct WeightControlCenterGoalsCard: View {
    @ObservedObject var viewModel: WeightControlCenterViewModel
    @ObservedObject var goalCoordinator: WeightGoalCoordinator
    @Binding var showGoalLine: Bool
    @Binding var weightGoal: Double

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardPadding) {
            Text("Tracking your weight helps you see progress from the inside out — long before it shows in the mirror.")
                .font(DSTypography.iconButton)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            startWeightEditor

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            goalWeightEditor

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            milestonesSection

            Divider()
                .background(Theme.ColorToken.dividerOnDark)

            Toggle(isOn: $showGoalLine) {
                VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
                    Text("Show Goal Line on Chart")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Display your target weight on the progress chart")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)
        }
        .onAppear {
            goalCoordinator.prepareStartWeightDefaults()
        }
    }

    private var startWeightEditor: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardElementSpacing) {
            Text("Start Weight")
                .font(DSTypography.listTitle)
                .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

            Text("Set the baseline for your weight-loss journey. Choose a date and we’ll pull your average weight from that day automatically. If no data exists, enter it manually.")
                .font(DSTypography.cardCaption)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center, spacing: DSSpacing.cardSmallSpacing) {
                DatePicker(
                    "Start Date",
                    selection: $goalCoordinator.startWeightDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .colorScheme(.dark)
                .tint(Theme.ColorToken.textPrimaryOnDark)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, DSSpacing.cardExtraSmallSpacing)
                .accessibilityLabel("Start date")
                .onChange(of: goalCoordinator.startWeightDate) { _, newDate in
                    goalCoordinator.handleStartWeightDateChange(newDate)
                }

                ZStack(alignment: .trailing) {
                    TextField("Enter start weight", text: $goalCoordinator.startWeightString)
                        .keyboardType(.decimalPad)
                        .font(DSTypography.displayS)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                        .multilineTextAlignment(.center)
                        .monospacedDigit()
                        .fixedSize()
                        .padding(.vertical, DSSpacing.cardExtraSmallSpacing)
                        .onChange(of: goalCoordinator.startWeightString) { _, newValue in
                            goalCoordinator.formatStartWeightInput(newValue)
                        }

                    if goalCoordinator.isFetchingStartWeight {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.trailing, DSSpacing.cardExtraSmallSpacing)
                    }
                }

                Text(goalCoordinator.unitAbbreviation)
                    .font(DSTypography.statValueSmall)
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    .padding(.vertical, DSSpacing.cardExtraSmallSpacing)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, DSSpacing.cardPadding)
            .padding(.vertical, DSSpacing.cardElementSpacing)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(Theme.ColorToken.accentPrimary.opacity(0.2))
            )
            .overlay(
                Capsule()
                    .stroke(Theme.ColorToken.accentPrimary.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Theme.ColorToken.accentPrimary.opacity(0.25), radius: 12, x: 0, y: 6)

            if let status = goalCoordinator.startWeightStatusMessage {
                Text(status)
                    .font(DSTypography.cardCaption)
                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
            }

            if let error = goalCoordinator.startWeightErrorMessage {
                Text(error)
                    .font(DSTypography.cardCaption)
                    .foregroundColor(Theme.ColorToken.stateError)
            }

            Button(action: goalCoordinator.saveStartWeight) {
                Text("Save Start Weight")
                    .font(DSTypography.buttonPrimary)
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    .frame(maxWidth: .infinity)
                    .padding(DSSpacing.cardElementSpacing)
                    .background(Theme.ColorToken.accentPrimary)
                    .cornerRadius(DSSpacing.cardSmallSpacing)
            }
            .disabled(!goalCoordinator.canSaveStartWeight)
            .opacity(goalCoordinator.canSaveStartWeight ? 1.0 : 0.5)
        }
    }

    private var goalWeightEditor: some View {
        VStack(alignment: .center, spacing: DSSpacing.cardSmallSpacing) {
            Text("Goal Weight")
                .font(DSTypography.iconButton)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

            HStack(spacing: DSSpacing.cardExtraSmallSpacing) {
                TextField("Enter goal", text: $goalCoordinator.weightGoalString)
                    .keyboardType(.decimalPad)
                    .font(DSTypography.displayM)
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    .multilineTextAlignment(.center)
                    .monospacedDigit()
                    .fixedSize()
                .onChange(of: goalCoordinator.weightGoalString) { _, newValue in
                    goalCoordinator.formatWeightGoalInput(newValue)
                }

                Text(goalCoordinator.unitAbbreviation)
                    .font(DSTypography.statValueSmall)
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Goal weight \(goalCoordinator.weightGoalString) pounds")
            .accessibilityHint("Double tap to edit")
            .padding(.leading, 28)
            .padding(.trailing, DSSpacing.cardPadding)
            .padding(.vertical, DSSpacing.cardElementSpacing)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.ColorToken.accentPrimary.opacity(0.2))
            )

            if let goal = Double(goalCoordinator.weightGoalString),
               goal > 0,
               let currentWeight = viewModel.weightManager.latestWeight?.weight {
                let toGo = currentWeight - goal
                if toGo > 0 {
                    HStack(spacing: DSSpacing.cardSmallSpacing) {
                        Image(systemName: "target")
                            .font(DSTypography.iconButton)
                            .foregroundColor(Theme.ColorToken.accentGold)
                        Text("\(String(format: "%.1f", toGo)) lbs to go")
                            .font(DSTypography.cardTitle)
                            .foregroundColor(Theme.ColorToken.accentGold)
                    }
                    .padding(.horizontal, DSSpacing.cardPadding)
                    .padding(.vertical, DSSpacing.cardElementSpacing)
                    .background(
                        Capsule()
                            .fill(Theme.ColorToken.accentGold.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(Theme.ColorToken.accentGold.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .shadow(color: Theme.ColorToken.accentGold.opacity(0.2), radius: 8, x: 0, y: 4)
                    .frame(maxWidth: .infinity)
                    .padding(.top, DSSpacing.cardElementSpacing)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardElementSpacing) {
            Text("Milestones")
                .font(DSTypography.listTitle)
                .foregroundColor(Theme.ColorToken.textPrimaryOnDark)

            Text("Choose how many milestones to show in your progress journey.")
                .font(DSTypography.cardCaption)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

            Stepper(value: $goalCoordinator.milestoneCount, in: 0...10) {
                Text(goalCoordinator.milestoneCount == 1 ? "1 milestone" : "\(goalCoordinator.milestoneCount) milestones")
                    .font(DSTypography.cardTitle)
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
            }
            .colorScheme(.dark)
            .onChange(of: goalCoordinator.milestoneCount) { _, newValue in
                goalCoordinator.updateMilestoneCount(newValue)
            }

            if goalCoordinator.milestoneCount == 0 {
                Text("Milestones hidden. The progress ring will show a continuous arc.")
                    .font(DSTypography.cardCaption)
                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
            }
        }
    }
}
