import SwiftUI

// MARK: - Weight History Components

struct WeightHistoryListView: View {
    @ObservedObject var weightManager: WeightManager
    @ObservedObject private var measurementObserver: MeasurementSystemObserver

    init(weightManager: WeightManager, measurementObserver: MeasurementSystemObserver = MeasurementSystemObserver.shared) {
        self.weightManager = weightManager
        _measurementObserver = ObservedObject(initialValue: measurementObserver)
    }

    // Task 1F: Time range filtering for performance optimization
    // Industry Pattern: Apple Health - default to recent data with expandable ranges
    @AppStorage("weightHistoryTimeRange") private var selectedRangeRawValue: String = WeightHistoryTimeRange.day.rawValue

    // Task 1F Enhancement 2: Custom date range support (start date)
    @AppStorage("weightHistoryCustomStartDate") private var customStartDateTimestamp: Double = Date().timeIntervalSince1970

    // Task 1F Enhancement 3: Custom date range support (end date)
    @AppStorage("weightHistoryCustomEndDate") private var customEndDateTimestamp: Double = Date().timeIntervalSince1970

    @State private var showingCustomDatePicker = false

    // Computed property to convert raw value to enum
    private var selectedRange: WeightHistoryTimeRange {
        WeightHistoryTimeRange(rawValue: selectedRangeRawValue) ?? .day
    }

    // Computed property for custom start date
    private var customStartDate: Date {
        Date(timeIntervalSince1970: customStartDateTimestamp)
    }

    // Computed property for custom end date
    private var customEndDate: Date {
        Date(timeIntervalSince1970: customEndDateTimestamp)
    }

    // Filtered entries based on selected time range
    private var filteredEntries: [WeightEntry] {
        if selectedRange == .custom {
            return weightManager.weightEntries(for: .custom, customStartDate: customStartDate, customEndDate: customEndDate)
        } else {
            return weightManager.weightEntries(for: selectedRange)
        }
    }

    var body: some View {
        VStack(spacing: DSSpacing.cardElementSpacing) {
            // REMOVED: "Weight History" header - DSCard now provides title in header
            // Following Universal Standardization Architecture pattern

            // Time Range Picker (Option 1: Picker at top)
            HStack {
                Text("Time Range:")
                    .font(DSTypography.cardCaption)
                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

                Picker("", selection: $selectedRangeRawValue) {
                    ForEach(WeightHistoryTimeRange.allCases, id: \.rawValue) { range in
                        Text(range.displayName)
                            .tag(range.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.ColorToken.accentPrimary)

                // Task 1F Enhancement 1: Entry count display
                // Industry Pattern: Apple Mail "Inbox (24)", GitHub "Pull Requests (5)"
                Text("(\(filteredEntries.count) \(filteredEntries.count == 1 ? "entry" : "entries"))")
                    .font(DSTypography.cardCaption)
                    .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

                Spacer()
            }
            .padding(.bottom, DSSpacing.cardSmallSpacing)

            ForEach(filteredEntries) { entry in
                WeightHistoryRow(entry: entry, weightManager: weightManager)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            weightManager.deleteWeightEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .accessibilityLabel("Delete this weight entry")
                    }
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)
            }
        }
        .id(measurementObserver.system)
        .animation(.easeInOut(duration: 0.3), value: selectedRangeRawValue)
        // Task 1F Enhancement 2: Auto-present custom date picker when Custom selected
        .onChange(of: selectedRangeRawValue) { oldValue, newValue in
            if newValue == WeightHistoryTimeRange.custom.rawValue {
                showingCustomDatePicker = true
            }
        }
        .sheet(isPresented: $showingCustomDatePicker) {
            CustomDatePickerSheet(
                customStartDate: customStartDate,
                customEndDate: customEndDate,
                onSave: { newStartDate, newEndDate in
                    customStartDateTimestamp = newStartDate.timeIntervalSince1970
                    customEndDateTimestamp = newEndDate.timeIntervalSince1970
                }
            )
        }
        // REMOVED: Card styling (padding, background, cornerRadius, shadow)
        // DSCard universal container now provides all standardized styling
        // Following Universal Standardization Architecture pattern
    }
}

// MARK: - Custom Date Picker Sheet

struct CustomDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStartDate: Date
    @State private var selectedEndDate: Date
    let onSave: (Date, Date) -> Void

    // Task 1F Enhancement 3: Dual date picker with validation
    init(customStartDate: Date, customEndDate: Date, onSave: @escaping (Date, Date) -> Void) {
        // Default start date to 30 days ago if not set
        let defaultStartDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let startDate = customStartDate < Date() ? customStartDate : defaultStartDate

        // Default end date to today
        let endDate = customEndDate

        // Ensure end >= start (validation)
        let validatedEndDate = endDate >= startDate ? endDate : startDate

        _selectedStartDate = State(initialValue: startDate)
        _selectedEndDate = State(initialValue: validatedEndDate)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                // START Date Section
                Section {
                    DatePicker(
                        "Start Date",
                        selection: $selectedStartDate,
                        in: ...Date(), // Can't select future dates
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .onChange(of: selectedStartDate) { oldValue, newValue in
                        // Task 1F Enhancement 3: Validation - ensure end >= start
                        if selectedEndDate < newValue {
                            selectedEndDate = newValue
                        }
                    }
                } header: {
                    Text("Start Date")
                        .font(DSTypography.cardBody)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                } footer: {
                    Text("Beginning of date range")
                        .font(DSTypography.listCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }

                // END Date Section
                Section {
                    DatePicker(
                        "End Date",
                        selection: $selectedEndDate,
                        in: selectedStartDate...Date(), // Must be >= start date and <= today
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                } header: {
                    Text("End Date")
                        .font(DSTypography.cardBody)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                } footer: {
                    Text("End of date range (defaults to today)")
                        .font(DSTypography.listCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.ColorToken.accentPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(selectedStartDate, selectedEndDate)
                        dismiss()
                    }
                    .foregroundColor(Theme.ColorToken.accentPrimary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct WeightHistoryRow: View {
    let entry: WeightEntry
    let weightManager: WeightManager
    @State private var showingDeleteAlert = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
                HStack(spacing: DSSpacing.cardExtraSmallSpacing) {
                    Text(entry.date, style: .date)
                        .font(DSTypography.cardTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("•")
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                    Text(entry.date, style: .time)
                        .font(DSTypography.cardBody)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }

                HStack(spacing: DSSpacing.cardSmallSpacing) {
                    // Task 1F Enhancement 4: Display actual HealthKit source name
                    // Industry Pattern: Apple Health shows actual app/device names
                    // Fallback to source.rawValue for backward compatibility
                    Text(entry.sourceName ?? entry.source.rawValue)
                        .font(DSTypography.listCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

                    if let bmi = entry.bmi {
                        Text("BMI: \(bmi, specifier: "%.1f")")
                            .font(DSTypography.listCaption)
                            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                    }

                    if let bodyFat = entry.bodyFat {
                        Text("BF: \(bodyFat, specifier: "%.1f")%")
                            .font(DSTypography.listCaption)
                            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                    }
                }
            }

            Spacer()

            Text("\(weightManager.formattedDisplayWeight(entry.weight)) \(weightManager.currentUnitAbbreviation)")
                .font(DSTypography.statValueMedium)
                .fontWeight(.semibold)
                .foregroundColor(Theme.ColorToken.accentPrimary)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive, action: { showingDeleteAlert = true }) {
                Label("Delete", systemImage: "trash")
            }
            .accessibilityLabel("Delete weight entry")
        }
        .alert("Delete Weight Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
                .accessibilityLabel("Cancel weight entry deletion")

            Button("Delete", role: .destructive) {
                weightManager.deleteWeightEntry(entry)
            }
            .accessibilityLabel("Confirm weight entry deletion")
        } message: {
            Text("Are you sure you want to delete this weight entry?")
        }
    }
}
