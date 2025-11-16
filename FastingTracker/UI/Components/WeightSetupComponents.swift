import SwiftUI

// MARK: - Weight Setup Components

struct FirstTimeWeightSetupView: View {
    @ObservedObject var weightManager: WeightManager
    @Binding var weightGoal: Double
    @Binding var showGoalLine: Bool
    @ObservedObject var measurementObserver: MeasurementSystemObserver
    private let measurementProvider: MeasurementSystemProviding
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

    init(
        weightManager: WeightManager,
        weightGoal: Binding<Double>,
        showGoalLine: Binding<Bool>,
        measurementObserver: MeasurementSystemObserver = MeasurementSystemObserver.shared,
        measurementProvider: MeasurementSystemProviding = MeasurementSystemProvider.shared
    ) {
        self._weightManager = ObservedObject(wrappedValue: weightManager)
        self._weightGoal = weightGoal
        self._showGoalLine = showGoalLine
        self._measurementObserver = ObservedObject(wrappedValue: measurementObserver)
        self.measurementProvider = measurementProvider
    }

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

                                // PHASE 1 FIX (Task 1.2): Dynamic unit abbreviation instead of hardcoded "lbs"
                                Text(weightManager.currentUnitAbbreviation)
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

                            // PHASE 1 FIX (Task 1.2): Dynamic unit abbreviation instead of hardcoded "lbs"
                            Text(weightManager.currentUnitAbbreviation)
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
            .onChange(of: measurementObserver.system) { oldSystem, newSystem in
                handleMeasurementSystemChange(from: oldSystem, to: newSystem)
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
                    AppLogger.info("✅ Auto-populated weight from HealthKit during setup", category: AppLogger.weightTracking)
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

        #if DEBUG
        AppLogger.debug(
            """
            🧪 Onboarding instrumentation – start weight input
              rawField: \(startWeightString)
              parsedValue: \(startWeight)
              observerSystem: \(describeMeasurementSystem(measurementObserver.system))
              providerSystem: \(describeMeasurementSystem(measurementProvider.currentMeasurementSystem))
              providerUnit: \(measurementProvider.currentUnit.abbreviation)
            """,
            category: AppLogger.weightTracking
        )
        #endif

        weightManager.addWeightEntryInPreferredUnit(weight: startWeight, date: startDate)
        weightManager.setStartWeightOverride(startWeight, date: startDate, unit: measurementProvider.currentUnit)

        #if DEBUG
        let canonicalStartWeight = measurementProvider.currentUnit.toPounds(startWeight)
        AppLogger.debug(
            "🧪 Onboarding instrumentation – canonical start weight (lbs): \(canonicalStartWeight)",
            category: AppLogger.weightTracking
        )
        #endif

        AppLogger.info("Saved start weight selection during onboarding", category: AppLogger.weightTracking)

        // RECOVERY TASK #1: Restore goal weight persistence via WeightManager
        // Following industry standard MVVM pattern - Manager owns persistence, View calls manager
        // WeightManager.setGoalWeight() persists to ThreadSafeUserDefaults + updates @Published property
        // Reference: Apple's Data Management in SwiftUI guide
        let goalWeightPounds = measurementProvider.currentUnit.toPounds(goalWeight)

        #if DEBUG
        AppLogger.debug(
            """
            🧪 Onboarding instrumentation – goal weight input
              rawField: \(goalWeightString)
              parsedValue: \(goalWeight)
              observerSystem: \(describeMeasurementSystem(measurementObserver.system))
              providerSystem: \(describeMeasurementSystem(measurementProvider.currentMeasurementSystem))
              providerUnit: \(measurementProvider.currentUnit.abbreviation)
              canonicalGoalWeightLbs: \(goalWeightPounds)
            """,
            category: AppLogger.weightTracking
        )
        #endif
        weightManager.setGoalWeight(goalWeightPounds)

        // Update parent binding (for backward compatibility with existing views)
        self.weightGoal = goalWeight

        // Enable goal line by default
        showGoalLine = true

        // Dismiss the sheet
        dismiss()

        MeasurementSystemProvider.shared.refresh()
    }

    private func handleMeasurementSystemChange(from oldSystem: Locale.MeasurementSystem, to newSystem: Locale.MeasurementSystem) {
        if let pounds = poundsFromInput(startWeightString, system: oldSystem) {
            startWeightString = weightManager.formattedDisplayWeight(pounds)
        }
        if let pounds = poundsFromInput(goalWeightString, system: oldSystem) {
            goalWeightString = weightManager.formattedDisplayWeight(pounds)
        }
    }

    private func poundsFromInput(_ input: String, system: Locale.MeasurementSystem) -> Double? {
        let normalized = input.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized) else { return nil }
        return pounds(fromDisplayValue: value, system: system)
    }

    private func pounds(fromDisplayValue value: Double) -> Double {
        measurementObserver.system == .metric ? WeightUnit.kilograms.toPounds(value) : value
    }

    private func pounds(fromDisplayValue value: Double, system: Locale.MeasurementSystem) -> Double {
        switch system {
        case .metric:
            return WeightUnit.kilograms.toPounds(value)
        default:
            return WeightUnit.pounds.toPounds(value)
        }
    }

}

extension FirstTimeWeightSetupView {
    private func describeMeasurementSystem(_ system: Locale.MeasurementSystem) -> String {
        switch system {
        case .metric: return "metric"
        case .us: return "us"
        case .uk: return "uk"
        default: return "unknown"
        }
    }
}
