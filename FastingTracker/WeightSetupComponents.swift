import SwiftUI

// MARK: - Weight Setup Components

struct FirstTimeWeightSetupView: View {
    @ObservedObject var weightManager: WeightManager
    @Binding var weightGoal: Double
    @Binding var showGoalLine: Bool
    @Environment(\.dismiss) var dismiss

    // Start Weight fields (renamed from "Current Weight")
    @State private var startWeightString: String = ""
    @State private var startDate: Date = Date()

    // Goal Weight fields
    @State private var goalWeightString: String = ""

    // Smart HealthKit selection
    @State private var hasHealthKitData: Bool = false
    @State private var historicalEntries: [WeightEntry] = []
    @State private var selectedEntry: WeightEntry? = nil
    @State private var useManualEntry: Bool = false

    // UI state
    @State private var showError: Bool = false
    @State private var isLoadingHealthKitData: Bool = true

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

                    // Start Weight Section (Smart HealthKit Selection or Manual Entry)
                    VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
                        Text("Start Weight")
                            .font(DSTypography.cardTitle)
                            .foregroundColor(Theme.ColorToken.textPrimary)

                        Text("This represents your weight at the beginning of your journey")
                            .font(DSTypography.cardCaption)
                            .foregroundColor(Theme.ColorToken.textSecondary)

                        if isLoadingHealthKitData {
                            // Loading state
                            HStack {
                                ProgressView()
                                Text("Checking HealthKit data...")
                                    .font(DSTypography.cardBody)
                                    .foregroundColor(Theme.ColorToken.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else if hasHealthKitData && !useManualEntry {
                            // HealthKit Picker Mode
                            VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
                                Text("Pick from your HealthKit history:")
                                    .font(DSTypography.cardBody)
                                    .foregroundColor(Theme.ColorToken.textSecondary)

                                // Scrollable list of historical entries
                                VStack(spacing: 0) {
                                    ForEach(historicalEntries.prefix(10)) { entry in
                                        Button(action: {
                                            selectedEntry = entry
                                            startWeightString = String(format: "%.1f", entry.weight)
                                            startDate = entry.date
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                                        .font(DSTypography.cardTitle)
                                                        .foregroundColor(Theme.ColorToken.textPrimary)
                                                    Text(entry.date.formatted(date: .complete, time: .shortened))
                                                        .font(DSTypography.cardCaption)
                                                        .foregroundColor(Theme.ColorToken.textSecondary)
                                                }

                                                Spacer()

                                                Text("\(String(format: "%.1f", entry.weight)) lbs")
                                                    .font(DSTypography.statValueMedium)
                                                    .foregroundColor(Theme.ColorToken.accentPrimary)

                                                if selectedEntry?.id == entry.id {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(Theme.ColorToken.stateSuccess)
                                                        .font(DSTypography.cardTitle)
                                                }
                                            }
                                            .padding()
                                            .background(selectedEntry?.id == entry.id ? Theme.ColorToken.accentPrimary.opacity(0.1) : Theme.ColorToken.cardAlt)
                                            .cornerRadius(DSSpacing.cardSmallSpacing)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .frame(maxHeight: 300)

                                // Manual entry toggle button
                                Button(action: {
                                    useManualEntry = true
                                    selectedEntry = nil
                                    startWeightString = ""
                                    startDate = Date()
                                }) {
                                    Text("Or Enter Manually")
                                        .font(DSTypography.cardTitle)
                                        .foregroundColor(Theme.ColorToken.accentPrimary)
                                        .padding(.vertical, DSSpacing.cardSmallSpacing)
                                }
                                .padding(.top, DSSpacing.cardSmallSpacing)
                            }
                        } else {
                            // Manual Entry Mode
                            VStack(spacing: DSSpacing.cardPadding) {
                                // Weight input
                                HStack {
                                    TextField("Enter weight", text: $startWeightString)
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

                                // Date picker
                                VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
                                    Text("Start Date")
                                        .font(DSTypography.cardBody)
                                        .foregroundColor(Theme.ColorToken.textSecondary)

                                    DatePicker(
                                        "Start Date",
                                        selection: $startDate,
                                        in: ...Date(),
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding(DSSpacing.cardSmallSpacing)
                                    .background(Theme.ColorToken.cardAlt)
                                    .cornerRadius(DSSpacing.cardSmallSpacing)
                                }

                                // Back to HealthKit picker (if data is available)
                                if hasHealthKitData {
                                    Button(action: {
                                        useManualEntry = false
                                        selectedEntry = nil
                                        startWeightString = ""
                                    }) {
                                        Text("Or Pick from HealthKit")
                                            .font(DSTypography.cardTitle)
                                            .foregroundColor(Theme.ColorToken.accentPrimary)
                                            .padding(.vertical, DSSpacing.cardSmallSpacing)
                                    }
                                }
                            }
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
            .onAppear {
                loadHealthKitData()
            }
        }
    }

    // MARK: - HealthKit Data Loading

    private func loadHealthKitData() {
        isLoadingHealthKitData = true

        // Check if HealthKit is authorized and has data
        let isAuthorized = HealthKitManager.shared.isWeightAuthorized()

        if isAuthorized {
            // Load last 90 days of weight entries
            let threeMonthsAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())!

            // Sync from HealthKit first to ensure we have latest data
            weightManager.syncFromHealthKit(startDate: threeMonthsAgo) { _, _ in
                DispatchQueue.main.async {
                    // Filter entries from last 90 days
                    historicalEntries = weightManager.weightEntries
                        .filter { $0.date >= threeMonthsAgo }
                        .sorted { $0.date > $1.date } // Most recent first

                    hasHealthKitData = !historicalEntries.isEmpty
                    isLoadingHealthKitData = false

                    AppLogger.info("Loaded \(historicalEntries.count) historical weight entries for setup", category: AppLogger.weightTracking)
                }
            }
        } else {
            // No authorization, use manual entry
            hasHealthKitData = false
            isLoadingHealthKitData = false
            useManualEntry = true
        }
    }

    private func saveAndContinue() {
        // Determine start weight from either selected entry or manual entry
        let startWeight: Double
        let startWeightDate: Date

        if let selected = selectedEntry {
            // Using HealthKit selected entry
            startWeight = selected.weight
            startWeightDate = selected.date
        } else {
            // Using manual entry
            guard let weight = Double(startWeightString), weight > 0 else {
                showError = true
                return
            }
            startWeight = weight
            startWeightDate = startDate
        }

        // Validate goal weight
        guard let goalWeight = Double(goalWeightString), goalWeight > 0 else {
            showError = true
            return
        }

        // Save start weight entry with the selected date
        let entry = WeightEntry(
            id: UUID(),
            date: startWeightDate,
            weight: startWeight,
            bmi: nil,
            bodyFat: nil,
            source: .manual
        )
        weightManager.addWeightEntry(entry)

        // Save start weight and date to UserDefaults for future reference
        UserDefaults.standard.set(startWeight, forKey: "startWeight")
        UserDefaults.standard.set(startWeightDate, forKey: "startDate")

        AppLogger.info("Saved start weight: \(startWeight) lbs on \(startWeightDate.formatted(date: .abbreviated, time: .omitted))", category: AppLogger.weightTracking)

        // Save goal weight
        self.weightGoal = goalWeight
        UserDefaults.standard.set(goalWeight, forKey: "goalWeight")

        // Enable goal line by default
        showGoalLine = true

        // Dismiss the sheet
        dismiss()
    }
}
