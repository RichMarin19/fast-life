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
    @State private var visibleDomain: ClosedRange<Date>?
    @State private var visibleYDomain: ClosedRange<Double>?
    @State private var pinchStartDomain: ClosedRange<Date>?
    @State private var pinchStartYDomain: ClosedRange<Double>?
    @State private var panStartDomain: ClosedRange<Date>?

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
                        .foregroundColor(Theme.ColorToken.accentPrimary)
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
                        .foregroundStyle(Theme.ColorToken.accentPrimary)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(Theme.ColorToken.accentPrimary)
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
                                    Text(weightLabel(for: selectedEntry))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Theme.ColorToken.accentPrimary)
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
                        // Day view: Show fewer marks with localized unit labels
                        AxisMarks(position: .leading, values: viewModel.dayYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text(viewModel.axisLabel(for: weight))
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .week {
                        // Week view: Show weight values at intuitive intervals with localized unit labels
                        AxisMarks(position: .leading, values: viewModel.weekYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text(viewModel.axisLabel(for: weight))
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .month {
                        // Month view: Show evenly-spaced marks with localized unit labels
                        AxisMarks(position: .leading, values: viewModel.monthYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text(viewModel.axisLabel(for: weight))
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .threeMonths {
                        // 3 Months view: Show evenly-spaced marks with localized unit labels
                        AxisMarks(position: .leading, values: viewModel.threeMonthsYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text(viewModel.axisLabel(for: weight))
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .year {
                        // Year view: Show evenly-spaced marks with localized unit labels
                        AxisMarks(position: .leading, values: viewModel.yearYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text(viewModel.axisLabel(for: weight))
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .all {
                        // All view: Show evenly-spaced marks with localized unit labels
                        AxisMarks(position: .leading, values: viewModel.allYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text(viewModel.axisLabel(for: weight))
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
                .chartXScale(domain: visibleDomain ?? viewModel.xAxisDomain ?? (viewModel.defaultDomain() ?? Date()...Date()))
                .chartYScale(domain: visibleYDomain ?? viewModel.yAxisDomain)
                .chartXSelection(value: $viewModel.selectedDate)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        overlayLayer(proxy: proxy, geometry: geometry)
                    }
                }
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

                            Text(weightLabel(for: selectedEntry))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.ColorToken.accentPrimary)

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
            visibleDomain = nil
            visibleYDomain = nil
            pinchStartDomain = nil
            pinchStartYDomain = nil
            panStartDomain = nil
            viewModel.selectedTimeRange = newValue
            viewModel.updateVisibleDomain(nil)
        }
        .onChange(of: showGoalLine) { _, newValue in
            viewModel.showGoalLine = newValue
            visibleYDomain = nil
        }
        .onChange(of: weightGoal) { _, newValue in
            viewModel.weightGoal = newValue
            visibleYDomain = nil
        }
        .onChange(of: visibleDomain) { _, newValue in
            viewModel.updateVisibleDomain(newValue)
        }
        // REMOVED: Card styling (padding, background, cornerRadius, shadow)
        // DSCard universal container now provides all standardized styling
        // Following Universal Standardization Architecture pattern
    }
}

// MARK: - Overlay Gestures

private extension WeightChartView {
    func weightLabel(for entry: WeightEntry, digits: Int = 1) -> String {
        "\(viewModel.formattedWeight(for: entry, maximumFractionDigits: digits)) \(viewModel.unitAbbreviation)"
    }

    func overlayLayer(proxy: ChartProxy, geometry: GeometryProxy) -> some View {
        let plotRect: CGRect
        if #available(iOS 17.0, *) {
            if let frame = proxy.plotFrame {
                plotRect = geometry[frame]
            } else {
                plotRect = .zero
            }
        } else {
            plotRect = geometry[proxy.plotAreaFrame]
        }

        let tapGesture = SpatialTapGesture()
            .onEnded { value in
                let location = value.location
                let xInPlot = location.x - plotRect.origin.x
                if let tappedDate: Date = proxy.value(atX: xInPlot) {
                    viewModel.selectedDate = tappedDate
                }
            }

        let resetGesture = TapGesture(count: 2)
            .onEnded {
                visibleDomain = nil
                visibleYDomain = nil
                pinchStartDomain = nil
                pinchStartYDomain = nil
                panStartDomain = nil
            }

        let magnificationGesture = MagnificationGesture()
            .onChanged { scale in
                guard scale.isFinite, scale > 0,
                      let fullDomain = (viewModel.defaultDomain() ?? viewModel.xAxisDomain) else {
                    return
                }

                if pinchStartDomain == nil {
                    pinchStartDomain = visibleDomain ?? fullDomain
                    pinchStartYDomain = visibleYDomain ?? viewModel.yAxisDomain
                }

                guard let startDomain = pinchStartDomain,
                      let startYDomain = pinchStartYDomain else {
                    return
                }

                let newDomain = viewModel.zoomedDomain(
                    startDomain: startDomain,
                    fullDomain: fullDomain,
                    scale: scale
                )
                let newYDomain = zoomedYDomain(
                    startDomain: startYDomain,
                    fullDomain: viewModel.yAxisDomain,
                    scale: scale
                )

                visibleDomain = newDomain
                visibleYDomain = newYDomain
            }
            .onEnded { _ in
                pinchStartDomain = nil
                pinchStartYDomain = nil
            }

        let dragGesture = DragGesture(minimumDistance: 5)
            .onChanged { value in
                guard let fullDomain = viewModel.defaultDomain() ?? viewModel.xAxisDomain,
                      let currentDomain = visibleDomain ?? viewModel.xAxisDomain else {
                    return
                }

                // Only allow panning when zoomed beyond the full range.
                if currentDomain == fullDomain { return }

                if panStartDomain == nil {
                    panStartDomain = currentDomain
                }

                guard let startDomain = panStartDomain else { return }
                let translation = value.translation.width
                let plotWidth = max(plotRect.width, 1)
                let newDomain = viewModel.pannedDomain(
                    startDomain: startDomain,
                    fullDomain: fullDomain,
                    translation: translation,
                    plotWidth: plotWidth
                )
                visibleDomain = newDomain
            }
            .onEnded { _ in
                panStartDomain = nil
            }

        return Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .gesture(tapGesture)
            .simultaneousGesture(resetGesture)
            .simultaneousGesture(magnificationGesture)
            .simultaneousGesture(dragGesture)
    }

    func zoomedYDomain(startDomain: ClosedRange<Double>, fullDomain: ClosedRange<Double>, scale: CGFloat) -> ClosedRange<Double> {
        guard scale.isFinite, scale > 0 else { return startDomain }

        let clampedScale = max(min(scale, 3.0), 0.3)
        let baseRange = startDomain.upperBound - startDomain.lowerBound
        let newRange = baseRange / Double(clampedScale)
        let midPoint = (startDomain.lowerBound + startDomain.upperBound) / 2

        var lower = midPoint - newRange / 2
        var upper = midPoint + newRange / 2

        // Clamp to full domain
        if lower < fullDomain.lowerBound {
            let offset = fullDomain.lowerBound - lower
            lower += offset
            upper += offset
        }
        if upper > fullDomain.upperBound {
            let offset = upper - fullDomain.upperBound
            lower -= offset
            upper -= offset
        }

        // Maintain minimum window (10% of full range)
        let minimumWindow = (fullDomain.upperBound - fullDomain.lowerBound) * 0.1
        if (upper - lower) < minimumWindow {
            return startDomain
        }

        return lower...upper
    }
}
