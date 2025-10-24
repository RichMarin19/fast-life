import SwiftUI

// MARK: - Weight Setup Components

struct FirstTimeWeightSetupView: View {
    @ObservedObject var weightManager: WeightManager
    @Binding var weightGoal: Double
    @Binding var showGoalLine: Bool
    @Environment(\.dismiss) var dismiss

    @State private var currentWeightString: String = ""
    @State private var goalWeightString: String = ""
    @State private var showError: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: DSSpacing.cardElementSpacing) {
                        Image(systemName: "scalemass.fill")
                            .font(DSTypography.displayXXL)
                            .foregroundColor(Theme.ColorToken.accentPrimary)

                        Text("Welcome to Weight Tracking")
                            .font(DSTypography.displayM)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Let's get started by setting up your weight goals")
                            .font(DSTypography.cardBody)
                            .foregroundColor(Theme.ColorToken.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)

                    // Current Weight Input
                    VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
                        Text("Current Weight")
                            .font(DSTypography.cardTitle)
                            .foregroundColor(Theme.ColorToken.textPrimary)

                        HStack {
                            TextField("Enter weight", text: $currentWeightString)
                                .keyboardType(.decimalPad)
                                .font(DSTypography.statValueLarge)
                                .multilineTextAlignment(.center)
                                .padding(DSSpacing.cardPadding)
                                .background(Theme.ColorToken.cardAlt)
                                .cornerRadius(DSSpacing.cardSmallSpacing)

                            Text("lbs")
                                .font(DSTypography.displayS)
                                .foregroundColor(Theme.ColorToken.textSecondary)
                        }
                    }
                    .padding(.horizontal)

                    // Goal Weight Input
                    VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
                        Text("Goal Weight")
                            .font(DSTypography.cardTitle)
                            .foregroundColor(Theme.ColorToken.textPrimary)

                        HStack {
                            TextField("Enter goal", text: $goalWeightString)
                                .keyboardType(.decimalPad)
                                .font(DSTypography.statValueLarge)
                                .multilineTextAlignment(.center)
                                .padding(DSSpacing.cardPadding)
                                .background(Theme.ColorToken.cardAlt)
                                .cornerRadius(DSSpacing.cardSmallSpacing)

                            Text("lbs")
                                .font(DSTypography.displayS)
                                .foregroundColor(Theme.ColorToken.textSecondary)
                        }
                    }
                    .padding(.horizontal)

                    // Error message
                    if showError {
                        Text("Please enter valid weights")
                            .font(DSTypography.listCaption)
                            .foregroundColor(Theme.ColorToken.stateError)
                    }

                    // Get Started Button
                    Button(action: saveAndContinue) {
                        Text("Get Started")
                            .font(DSTypography.buttonPrimary)
                            .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                            .frame(maxWidth: .infinity)
                            .padding(DSSpacing.cardPadding)
                            .background(Theme.ColorToken.accentPrimary)
                            .cornerRadius(DSSpacing.cardSmallSpacing)
                    }
                    .accessibilityLabel("Save weight setup and continue")
                    .padding(.horizontal)
                    .padding(.top, DSSpacing.cardSectionSpacing)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled() // Prevent dismissal without entering data
        }
    }

    private func saveAndContinue() {
        // Validate inputs
        guard let currentWeight = Double(currentWeightString),
              let goalWeight = Double(goalWeightString),
              currentWeight > 0,
              goalWeight > 0 else {
            showError = true
            return
        }

        // Save current weight entry
        let entry = WeightEntry(
            id: UUID(),
            date: Date(),
            weight: currentWeight,
            bmi: nil,
            bodyFat: nil,
            source: .manual
        )
        weightManager.addWeightEntry(entry)

        // Save goal weight
        weightGoal = goalWeight

        // Enable goal line by default
        showGoalLine = true

        // Dismiss the sheet
        dismiss()
    }
}
