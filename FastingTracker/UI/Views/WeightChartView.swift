import SwiftUI
import Charts
// MARK: - Weight Chart View

enum WeightTimeRange: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"
    case all = "All"

    var days: Int? {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        case .all: return nil
        }
    }
}

struct WeightChartView: View {
    // MARK: - ViewModel (Phase 3: MVVM Architecture)
    // Following Apple WWDC 2023 guidance: Extract business logic to ViewModel for views > 400 LOC
    // Reference: WeightControlCenterViewModel proven pattern (Phase v1.7)
    @StateObject private var viewModel: WeightChartViewModel

    // MARK: - Bindings (passed from parent)
    @Binding var selectedTimeRange: WeightTimeRange
    @Binding var showGoalLine: Bool
    @Binding var weightGoal: Double

    // MARK: - Initialization
    // Industry Pattern: Dependency injection with convenience init for backward compatibility
    init(
        weightManager: WeightManager,
        selectedTimeRange: Binding<WeightTimeRange>,
        showGoalLine: Binding<Bool>,
        weightGoal: Binding<Double>
    ) {
        self._viewModel = StateObject(wrappedValue: WeightChartViewModel(
            weightManager: weightManager,
            selectedTimeRange: selectedTimeRange.wrappedValue,
            showGoalLine: showGoalLine.wrappedValue,
            weightGoal: weightGoal.wrappedValue
        ))
        self._selectedTimeRange = selectedTimeRange
        self._showGoalLine = showGoalLine
        self._weightGoal = weightGoal
    }

    // MARK: - Computed Properties (delegate to ViewModel)
    // All business logic moved to WeightChartViewModel following MVVM pattern

    var body: some View {
        VStack(spacing: 16) {
            // REMOVED: Header HStack with "Weight Chart" title and Picker
            // DSCard now provides title in header, Picker moved down to align with time range label

            // Display current time range (Month/Year) for Month view + Picker control
            // UX Fix: Picker aligned with time range label (related controls grouped together)
            // Following Apple HIG: Related controls should be grouped together
            HStack {
                if let label = viewModel.timeRangeLabel {
                    Text(label)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color("FLPrimary"))
                } else {
                    // If no time range label, show empty spacer to push Picker to right
                    Spacer()
                }

                Spacer()

                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(WeightTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.menu)
            }

            // Progress percentage moved to CurrentWeightCard (below goal pill)
            // This keeps related information grouped together per Apple HIG

            if !viewModel.chartData.isEmpty {
                Chart {
                    ForEach(viewModel.chartData) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(Color("FLPrimary"))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(Color("FLPrimary"))
                    }

                    if showGoalLine {
                        RuleMark(y: .value("Goal", weightGoal))
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Goal")
                                    .font(.caption)
                                    .foregroundColor(Color("FLSuccess"))
                            }
                    }

                    // Selection indicator: vertical line at selected point
                    if let selectedEntry = viewModel.selectedEntry {
                        RuleMark(x: .value("Selected", selectedEntry.date))
                            .foregroundStyle(.gray.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .annotation(position: .top, alignment: .center) {
                                VStack(spacing: 4) {
                                    Text("\(viewModel.weightManager.displayWeight(for: selectedEntry), specifier: "%.1f") \("lbs")")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color("FLPrimary"))
                                        .cornerRadius(DSCornerRadius.button)
                                }
                            }
                    }
                }
                .frame(height: 250)
                .chartXAxis {
                    if selectedTimeRange == .day {
                        // Day view: Show 3-hour increments starting from 6am
                        AxisMarks(values: viewModel.dayXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(viewModel.xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else if selectedTimeRange == .week {
                        // Week view: Show all 7 days
                        AxisMarks(values: viewModel.weekXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(viewModel.xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else if selectedTimeRange == .month {
                        // Month view: Adaptive marks based on data range
                        AxisMarks(values: viewModel.monthXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(viewModel.xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else if selectedTimeRange == .threeMonths {
                        // 3 Months view: Show 12 marks (4 per month)
                        AxisMarks(values: viewModel.threeMonthsXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(viewModel.xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else if selectedTimeRange == .year {
                        // Year view: Show 12 marks (one per month)
                        AxisMarks(values: viewModel.yearXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(viewModel.xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else if selectedTimeRange == .all {
                        // All view: Adaptive marks based on data span
                        AxisMarks(values: viewModel.allXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(viewModel.xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else {
                        // Fallback: automatic marks
                        AxisMarks(values: .automatic) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(viewModel.xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    }
                }
                .chartYAxis {
                    if selectedTimeRange == .day {
                        // Day view: Show fewer marks with "lbs" suffix
                        AxisMarks(position: .leading, values: viewModel.dayYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text("\(Int(weight)) lbs")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .week {
                        // Week view: Show weight values at 1lb intervals with "lbs" suffix
                        AxisMarks(position: .leading, values: viewModel.weekYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text("\(Int(weight)) lbs")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .month {
                        // Month view: Show 10 evenly-spaced marks with "lbs" suffix
                        AxisMarks(position: .leading, values: viewModel.monthYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text("\(Int(round(weight))) lbs")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .threeMonths {
                        // 3 Months view: Show 10 evenly-spaced marks with "lbs" suffix
                        AxisMarks(position: .leading, values: viewModel.threeMonthsYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text("\(Int(round(weight))) lbs")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .year {
                        // Year view: Show 10 evenly-spaced marks with "lbs" suffix
                        AxisMarks(position: .leading, values: viewModel.yearYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text("\(Int(round(weight))) lbs")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .all {
                        // All view: Show 10 evenly-spaced marks with "lbs" suffix
                        AxisMarks(position: .leading, values: viewModel.allYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text("\(Int(round(weight))) lbs")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else {
                        AxisMarks(position: .leading)
                    }
                }
                .chartYScale(domain: viewModel.yAxisDomain)
                .modifier(XAxisScaleModifier(domain: viewModel.xAxisDomain))
                .chartXSelection(value: $viewModel.selectedDate)
            } else {
                Text("No data for selected time range")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
            }

            // Selected data point details
            if let selectedEntry = viewModel.selectedEntry {
                VStack(spacing: 8) {
                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected Point")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(viewModel.weightManager.displayWeight(for: selectedEntry), specifier: "%.1f") \("lbs")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color("FLPrimary"))

                            HStack(spacing: 8) {
                                Text(selectedEntry.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if let displayTime = viewModel.selectedEntryDisplayTime {
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(displayTime, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Spacer()

                        if selectedEntry.bmi != nil || selectedEntry.bodyFat != nil {
                            VStack(alignment: .trailing, spacing: 4) {
                                if let bmi = selectedEntry.bmi {
                                    HStack(spacing: 4) {
                                        Text("BMI:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(bmi, specifier: "%.1f")")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                }

                                if let bodyFat = selectedEntry.bodyFat {
                                    HStack(spacing: 4) {
                                        Text("Body Fat:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(bodyFat, specifier: "%.1f")%")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }

                        Button(action: {
                            viewModel.selectedDate = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.title3)
                        }
                    }
                }
                .transition(.opacity)
            }

            Toggle("Show Goal Line", isOn: $showGoalLine)
                .font(.subheadline)
        }
        // Sync state changes to ViewModel
        .onChange(of: selectedTimeRange) { _, newValue in
            viewModel.selectedTimeRange = newValue
        }
        .onChange(of: showGoalLine) { _, newValue in
            viewModel.showGoalLine = newValue
        }
        .onChange(of: weightGoal) { _, newValue in
            viewModel.weightGoal = newValue
        }
        // REMOVED: Card styling (padding, background, cornerRadius, shadow)
        // DSCard universal container now provides all standardized styling
        // Following Universal Standardization Architecture pattern
    }
}

// MARK: - XAxisScaleModifier

struct XAxisScaleModifier: ViewModifier {
    let domain: ClosedRange<Date>?

    func body(content: Content) -> some View {
        if let domain = domain {
            content.chartXScale(domain: domain)
        } else {
            content
        }
    }
}
