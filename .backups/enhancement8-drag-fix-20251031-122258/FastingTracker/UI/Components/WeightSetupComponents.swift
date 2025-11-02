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

    // UI state
    @State private var showError: Bool = false
    @State private var isQueryingHealthKit: Bool = false
    @State private var healthKitAuthorized: Bool = false

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

                    // Start Weight Section (Date-Driven HealthKit Auto-Population)
                    VStack(alignment: .leading, spacing: DSSpacing.cardSmallSpacing) {
                        Text("Start Weight")
                            .font(DSTypography.cardTitle)
                            .foregroundColor(Theme.ColorToken.textPrimary)

                        Text("This represents your weight at the beginning of your journey")
                            .font(DSTypography.cardCaption)
                            .foregroundColor(Theme.ColorToken.textSecondary)

                        VStack(spacing: DSSpacing.cardPadding) {
                            // Weight input (auto-populates from HealthKit or manual entry)
                            HStack {
                                TextField("Enter weight", text: $startWeightString)
                                    .keyboardType(.decimalPad)
                                    .font(DSTypography.statValueLarge)
                                    .multilineTextAlignment(.center)
                                    .padding(DSSpacing.cardPadding)
                                    .background(Theme.ColorToken.cardAlt)
                                    .cornerRadius(DSSpacing.cardSmallSpacing)
                                    .overlay(
                                        Group {
                                            if isQueryingHealthKit {
                                                HStack {
                                                    Spacer()
                                                    ProgressView()
                                                        .padding(.trailing, 12)
                                                }
                                            }
                                        }
                                    )

                                Text("lbs")
                                    .font(DSTypography.displayS)
                                    .foregroundColor(Theme.ColorToken.textSecondary)
                            }

                            // Date picker (drives HealthKit query)
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
                                .onChange(of: startDate) { _, newDate in
                                    // Query HealthKit for weight on this date
                                    queryHealthKitForDate(newDate)
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
                checkHealthKitAuthorization()
                // Query for today's date on initial load
                queryHealthKitForDate(startDate)
            }
        }
    }

    // MARK: - HealthKit Integration

    /// Check if HealthKit is authorized for weight data
    private func checkHealthKitAuthorization() {
        healthKitAuthorized = HealthKitManager.shared.isWeightAuthorized()
        AppLogger.info("HealthKit weight authorization: \(healthKitAuthorized)", category: AppLogger.weightTracking)
    }

    /// Query HealthKit for weight data on a specific date
    /// If weight found, auto-populate the startWeightString field
    /// If no weight found, clear the field for manual entry
    private func queryHealthKitForDate(_ date: Date) {
        // Only query if HealthKit is authorized
        guard healthKitAuthorized else {
            AppLogger.info("❌ HealthKit not authorized, skipping query", category: AppLogger.weightTracking)
            return
        }

        isQueryingHealthKit = true

        AppLogger.info("🔍 Querying HealthKit for date: \(date.formatted(date: .abbreviated, time: .omitted))", category: AppLogger.weightTracking)

        // Get start and end of the selected date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            isQueryingHealthKit = false
            AppLogger.error("❌ Failed to calculate end of day", category: AppLogger.weightTracking)
            return
        }

        AppLogger.info("📅 Query range: \(startOfDay.formatted(date: .complete, time: .shortened)) to \(endOfDay.formatted(date: .complete, time: .shortened))", category: AppLogger.weightTracking)

        // Query HealthKit directly using HealthKitManager
        // CRITICAL: resetAnchor: true forces fresh query for historical dates
        // Without this, anchored queries skip data before the saved anchor
        HealthKitManager.shared.fetchWeightData(startDate: startOfDay, endDate: endOfDay, resetAnchor: true) { entries in
            DispatchQueue.main.async {
                AppLogger.info("📊 HealthKit returned \(entries.count) weight entries for date", category: AppLogger.weightTracking)

                if let latestEntry = entries.sorted(by: { $0.date > $1.date }).first {
                    // Weight found for this date - auto-populate
                    self.startWeightString = String(format: "%.1f", latestEntry.weight)
                    AppLogger.info("✅ Auto-populated weight: \(latestEntry.weight) lbs from HealthKit", category: AppLogger.weightTracking)
                    AppLogger.info("   Entry date: \(latestEntry.date.formatted(date: .complete, time: .shortened))", category: AppLogger.weightTracking)
                } else {
                    // No weight found for this date - clear field for manual entry
                    self.startWeightString = ""
                    AppLogger.info("⚠️ No HealthKit data found for date \(date.formatted(date: .abbreviated, time: .omitted))", category: AppLogger.weightTracking)
                }

                self.isQueryingHealthKit = false
            }
        }
    }

    private func saveAndContinue() {
        // Validate start weight (from either HealthKit auto-population or manual entry)
        guard let startWeight = Double(startWeightString), startWeight > 0 else {
            showError = true
            return
        }

        // Validate goal weight
        guard let goalWeight = Double(goalWeightString), goalWeight > 0 else {
            showError = true
            return
        }

        // Save start weight entry with the selected date
        let entry = WeightEntry(
            id: UUID(),
            date: startDate,
            weight: startWeight,
            bmi: nil,
            bodyFat: nil,
            source: .manual
        )
        weightManager.addWeightEntry(entry)

        // Save start weight and date to UserDefaults for future reference
        UserDefaults.standard.set(startWeight, forKey: "startWeight")
        UserDefaults.standard.set(startDate, forKey: "startDate")

        AppLogger.info("Saved start weight: \(startWeight) lbs on \(startDate.formatted(date: .abbreviated, time: .omitted))", category: AppLogger.weightTracking)

        // Save goal weight
        self.weightGoal = goalWeight
        UserDefaults.standard.set(goalWeight, forKey: "goalWeight")

        // Enable goal line by default
        showGoalLine = true

        // Dismiss the sheet
        dismiss()
    }
}
