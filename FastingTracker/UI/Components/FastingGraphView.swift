import SwiftUI
import Charts

enum GraphTimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case custom = "Custom"
}

struct FastingGraphView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @State private var selectedRange: GraphTimeRange = .week
    @State private var showingCustomPicker = false
    @State private var showGoalLine = true
    @State private var customStartDate = Date(timeIntervalSinceNow: -30*24*60*60)
    @State private var customEndDate = Date()
    @State private var selectedDataPoint: ChartDataPoint? = nil

    // Navigation state for each time range
    @State private var selectedWeekOffset: Int = 0  // 0 = current week, -1 = last week, etc.
    @State private var selectedMonthOffset: Int = 0 // 0 = current month, -1 = last month, etc. (max -11)
    @State private var selectedYearOffset: Int = 0  // 0 = current year, -1 = last year, etc. (max -4)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            rangePickerView
            if selectedRange == .custom {
                customDateButton
            }
            chartContentView
            if let selected = selectedDataPoint, selected.hours > 0 {
                selectedDataView(for: selected)
            }
            legendView
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        .sheet(isPresented: $showingCustomPicker) {
            CustomDateRangePickerView(startDate: $customStartDate, endDate: $customEndDate)
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Fasting Progress")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Subtitle with navigation arrows
                HStack(spacing: 8) {
                    if selectedRange != .custom {
                        // Previous button
                        Button(action: navigatePrevious) {
                            Image(systemName: "chevron.left")
                                .font(.subheadline)
                                .foregroundColor(canNavigatePrevious() ? Color("FLPrimary") : .gray.opacity(0.3))
                        }
                        .disabled(!canNavigatePrevious())
                    }

                    Text(getRangeSubtitle())
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if selectedRange != .custom {
                        // Next button
                        Button(action: navigateNext) {
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundColor(canNavigateNext() ? Color("FLPrimary") : .gray.opacity(0.3))
                        }
                        .disabled(!canNavigateNext())
                    }
                }
            }

            Spacer()

            Button(action: { showGoalLine.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: showGoalLine ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(Color("FLSecondary"))
                        .font(.system(size: 16))
                    Text("Goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var rangePickerView: some View {
        Picker("Range", selection: $selectedRange) {
            ForEach(GraphTimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedRange) { _, newValue in
            if newValue == .custom {
                showingCustomPicker = true
            }
            // Reset offsets when switching view types
            selectedWeekOffset = 0
            selectedMonthOffset = 0
            selectedYearOffset = 0

            // Intelligently initialize Month view to show most recent data
            if newValue == .month {
                initializeMonthView()
            }
        }
    }

    private var customDateButton: some View {
        Button(action: { showingCustomPicker = true }) {
            HStack {
                Text("\(formattedDate(customStartDate)) - \(formattedDate(customEndDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "calendar")
                    .foregroundColor(Color("FLSecondary"))
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var chartContentView: some View {
        let chartData = getChartData()
        // Check if all data points are zero (no real data for this period)
        let hasRealData = chartData.contains { $0.hours > 0 }

        if chartData.isEmpty || !hasRealData {
            VStack(spacing: 12) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.5))
                Text("No data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
        } else if chartData.count > 100 {
            // Safety check - don't try to render too many points
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                Text("Too much data to display")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(chartData.count) data points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
        } else {
                Chart {
                    // Goal line
                    if showGoalLine {
                        RuleMark(y: .value("Goal", fastingManager.fastingGoalHours))
                            .foregroundStyle(Color("FLSecondary").opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Goal: \(Int(fastingManager.fastingGoalHours))h")
                                    .font(.caption2)
                                    .foregroundColor(Color("FLSecondary"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(8)
                            }
                    }

                    // Selection indicator line
                    if let selected = selectedDataPoint {
                        RuleMark(x: .value("Selected", selected.date))
                            .foregroundStyle(Color("FLPrimary").opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .zIndex(-1)
                    }

                    // Line with gradient
                    ForEach(chartData) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Hours", dataPoint.hours)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("FLSuccess"), Color("FLSuccess")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    }

                    // Data points
                    ForEach(chartData) { dataPoint in
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Hours", dataPoint.hours)
                        )
                        .foregroundStyle(dataPoint.metGoal ? Color("FLSuccess") : Color.orange)
                        .symbolSize(dataPoint.date == selectedDataPoint?.date ? 120 : 80)
                    }
                }
                .chartYScale(domain: 0...24)
                .chartXScale(domain: getXAxisDomain())
                .chartXAxis {
                    AxisMarks(values: getXAxisValues()) { value in
                        AxisGridLine()
                        AxisTick()
                        if selectedRange == .year {
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                        } else if selectedRange == .month {
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    let day = Calendar.current.component(.day, from: date)
                                    Text("\(day)")
                                        .font(.caption2)
                                }
                            }
                        } else {
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 4, 8, 12, 16, 20, 24]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(Int(hours))h")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.clear)
                            .contentShape(RoundedRectangle(cornerRadius: 8))
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard let plotFrame = proxy.plotFrame else { return }
                                        let x = value.location.x - geometry[plotFrame].origin.x
                                        if let date: Date = proxy.value(atX: x) {
                                            if let dataPoint = chartData.first(where: {
                                                Calendar.current.isDate($0.date, inSameDayAs: date)
                                            }) {
                                                selectedDataPoint = dataPoint
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        // Keep selection visible after tap
                                    }
                            )
                    }
                }
                .frame(height: 220)
        }
    }

    private func selectedDataView(for selected: ChartDataPoint) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(formattedDetailDate(selected.date))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if selected.metGoal {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("FLSuccess"))
                        Text("Goal Met")
                            .foregroundColor(Color("FLSuccess"))
                    }
                    .font(.caption)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("Incomplete")
                            .foregroundColor(.orange)
                    }
                    .font(.caption)
                }
            }
            HStack {
                Text("Duration:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1fh", selected.hours))
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private var legendView: some View {
        HStack(spacing: 20) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color("FLSuccess"))
                    .frame(width: 10, height: 10)
                Text("Goal Met")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 10, height: 10)
                Text("Incomplete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if showGoalLine {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("FLSecondary").opacity(0.5))
                        .frame(width: 16, height: 2)
                    Text("Goal Line")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Navigation Functions

    private func navigatePrevious() {
        switch selectedRange {
        case .week:
            selectedWeekOffset -= 1
        case .month:
            if selectedMonthOffset > -11 {
                selectedMonthOffset -= 1
            }
        case .year:
            if selectedYearOffset > -4 {
                selectedYearOffset -= 1
            }
        case .custom:
            break
        }
    }

    private func navigateNext() {
        switch selectedRange {
        case .week:
            if selectedWeekOffset < 0 {
                selectedWeekOffset += 1
            }
        case .month:
            if selectedMonthOffset < 0 {
                selectedMonthOffset += 1
            }
        case .year:
            if selectedYearOffset < 0 {
                selectedYearOffset += 1
            }
        case .custom:
            break
        }
    }

    private func canNavigatePrevious() -> Bool {
        switch selectedRange {
        case .week:
            return true // No limit on going back for weeks
        case .month:
            return selectedMonthOffset > -11 // Max 12 months back
        case .year:
            return selectedYearOffset > -4 // Max 5 years back
        case .custom:
            return false
        }
    }

    private func canNavigateNext() -> Bool {
        switch selectedRange {
        case .week, .month, .year:
            // Can only go forward if not at current period
            return selectedWeekOffset < 0 || selectedMonthOffset < 0 || selectedYearOffset < 0
        case .custom:
            return false
        }
    }

    private func initializeMonthView() {
        // Only initialize once - don't reset if user has already navigated
        guard selectedMonthOffset == 0 else { return }

        let calendar = Calendar.current
        let now = Date()

        // Get the current month's data
        guard let currentMonthInterval = calendar.dateInterval(of: .month, for: now) else { return }
        let currentMonthStart = calendar.startOfDay(for: currentMonthInterval.start)
        let currentMonthEnd = calendar.startOfDay(for: now)

        // Check if there's any data in the current month
        let hasDataInCurrentMonth = fastingManager.fastingHistory.contains { session in
            session.isComplete && session.startTime >= currentMonthStart && session.startTime <= currentMonthEnd
        }

        // If no data in current month, find the most recent month with data
        if !hasDataInCurrentMonth, let mostRecentSession = fastingManager.fastingHistory.first(where: { $0.isComplete }) {
            // Calculate how many months back the most recent session is
            let sessionMonth = calendar.startOfDay(for: calendar.dateInterval(of: .month, for: mostRecentSession.startTime)?.start ?? mostRecentSession.startTime)
            let currentMonth = calendar.startOfDay(for: currentMonthInterval.start)

            let monthDiff = calendar.dateComponents([.month], from: sessionMonth, to: currentMonth).month ?? 0

            // Set the offset to show that month (limit to -11 for max 12 months back)
            selectedMonthOffset = max(-monthDiff, -11)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    private func formattedDetailDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func getRangeSubtitle() -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        switch selectedRange {
        case .week:
            // "Week of Sep 28"
            let targetDate = calendar.date(byAdding: .weekOfYear, value: selectedWeekOffset, to: Date()) ?? Date()
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: targetDate) else {
                return "Week"
            }
            formatter.dateFormat = "MMM d"
            return "Week of \(formatter.string(from: weekInterval.start))"

        case .month:
            // "October" or "September" etc.
            let targetDate = calendar.date(byAdding: .month, value: selectedMonthOffset, to: Date()) ?? Date()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: targetDate)

        case .year:
            // "2025" or "2024" etc.
            let targetDate = calendar.date(byAdding: .year, value: selectedYearOffset, to: Date()) ?? Date()
            formatter.dateFormat = "yyyy"
            return formatter.string(from: targetDate)

        case .custom:
            // "Sep 1 - Sep 30"
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: customStartDate)
            let end = formatter.string(from: customEndDate)
            return "\(start) - \(end)"
        }
    }

    private func getChartData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let sessions = getFilteredSessions()
        let now = calendar.startOfDay(for: Date())

        // Get date range based on selected view
        let dateRange = getDateRange()

        // Create a dictionary of sessions by date
        var sessionsByDate: [Date: FastingSession] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.startTime)
            sessionsByDate[day] = session
        }

        // For year view, only show data points where we have actual data
        // Don't generate 365 zero-value points
        if selectedRange == .year {
            return sessions.map { session in
                ChartDataPoint(
                    date: session.startTime,
                    hours: session.duration / 3600,
                    metGoal: session.metGoal
                )
            }.sorted { $0.date < $1.date }
        }

        // For week/month, generate data points for all dates in range
        var dataPoints: [ChartDataPoint] = []
        var currentDate = dateRange.start
        var iterationCount = 0
        let maxIterations = 100 // Safety limit to prevent infinite loops

        while currentDate <= dateRange.end && iterationCount < maxIterations {
            let day = calendar.startOfDay(for: currentDate)

            if let session = sessionsByDate[day] {
                // Has actual data - use normalized day for proper alignment
                dataPoints.append(ChartDataPoint(
                    date: day,
                    hours: session.duration / 3600,
                    metGoal: session.metGoal
                ))
            } else if day < now {
                // Past date with no data - show 0
                dataPoints.append(ChartDataPoint(
                    date: currentDate,
                    hours: 0,
                    metGoal: false
                ))
            }
            // Don't add data points for today or future dates without data

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
            iterationCount += 1
        }

        return dataPoints.sorted { $0.date < $1.date }
    }

    private func getXAxisDomain() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()

        switch selectedRange {
        case .month:
            // Show full month range on X-axis using selected month offset
            let targetDate = calendar.date(byAdding: .month, value: selectedMonthOffset, to: now) ?? now
            guard let monthInterval = calendar.dateInterval(of: .month, for: targetDate) else {
                return now...now
            }
            let monthStart = calendar.startOfDay(for: monthInterval.start)
            let monthEnd = calendar.date(byAdding: .day, value: -1, to: monthInterval.end) ?? targetDate
            return monthStart...monthEnd

        case .year:
            // Show full year range on X-axis using selected year offset
            let targetDate = calendar.date(byAdding: .year, value: selectedYearOffset, to: now) ?? now
            guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: targetDate)),
                  let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) else {
                return now...now
            }
            return startOfYear...endOfYear

        default:
            // For week and custom, use data range
            let dateRange = getDateRange()
            return dateRange.start...dateRange.end
        }
    }

    private func getXAxisValues() -> AxisMarkValues {
        let calendar = Calendar.current
        let dateRange = getDateRange()
        let daysDifference = calendar.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 1

        switch selectedRange {
        case .week:
            // Show every day
            return .stride(by: .day, count: 1)

        case .month:
            // Show approximately 12 date labels across the month
            let stride = max(2, (daysDifference + 11) / 12)
            return .stride(by: .day, count: stride)

        case .year:
            // Show each month
            return .stride(by: .month, count: 1)

        case .custom:
            // Calculate stride to show 12-15 dates
            let stride = max(1, daysDifference / 15)
            return .stride(by: .day, count: stride)
        }
    }

    private func getDateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch selectedRange {
        case .week:
            // Get the selected week (Sunday to Saturday)
            let targetDate = calendar.date(byAdding: .weekOfYear, value: selectedWeekOffset, to: now) ?? now
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: targetDate) else {
                let weekAgo = calendar.date(byAdding: .day, value: -6, to: targetDate) ?? targetDate
                return (calendar.startOfDay(for: weekAgo), calendar.startOfDay(for: targetDate))
            }
            let weekStart = calendar.startOfDay(for: weekInterval.start)
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? targetDate
            return (weekStart, calendar.startOfDay(for: weekEnd))

        case .month:
            // Get the selected month
            let targetDate = calendar.date(byAdding: .month, value: selectedMonthOffset, to: now) ?? now
            guard let monthInterval = calendar.dateInterval(of: .month, for: targetDate) else {
                let monthAgo = calendar.date(byAdding: .month, value: -1, to: targetDate) ?? targetDate
                return (calendar.startOfDay(for: monthAgo), calendar.startOfDay(for: targetDate))
            }
            let monthStart = calendar.startOfDay(for: monthInterval.start)
            // For past months, show entire month. For current month, only show up to today
            let monthEnd: Date
            if selectedMonthOffset == 0 {
                // Current month - show up to today
                monthEnd = calendar.startOfDay(for: now)
            } else {
                // Past month - show entire month
                monthEnd = calendar.date(byAdding: .day, value: -1, to: monthInterval.end) ?? targetDate
            }
            return (monthStart, calendar.startOfDay(for: monthEnd))

        case .year:
            // Get the selected year
            let targetDate = calendar.date(byAdding: .year, value: selectedYearOffset, to: now) ?? now
            guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: targetDate)) else {
                return (targetDate, targetDate)
            }
            // For past years, show entire year. For current year, show up to today or end of year
            let endOfYear: Date
            if selectedYearOffset == 0 {
                // Current year - show up to today
                endOfYear = calendar.startOfDay(for: now)
            } else {
                // Past year - show entire year
                guard let yearEnd = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) else {
                    return (calendar.startOfDay(for: startOfYear), calendar.startOfDay(for: targetDate))
                }
                endOfYear = calendar.startOfDay(for: yearEnd)
            }
            return (calendar.startOfDay(for: startOfYear), endOfYear)

        case .custom:
            return (calendar.startOfDay(for: customStartDate), calendar.startOfDay(for: customEndDate))
        }
    }

    private func getFilteredSessions() -> [FastingSession] {
        // Get the date range for the selected period (respects navigation offsets)
        let dateRange = getDateRange()

        // Filter sessions within the date range
        return fastingManager.fastingHistory.filter {
            let sessionDay = Calendar.current.startOfDay(for: $0.startTime)
            return sessionDay >= dateRange.start && sessionDay <= dateRange.end
        }
    }
}

struct ChartDataPoint: Identifiable, Equatable {
    var id: Date { date }  // Use date as unique ID instead of UUID
    let date: Date
    let hours: Double
    let metGoal: Bool

    static func == (lhs: ChartDataPoint, rhs: ChartDataPoint) -> Bool {
        lhs.date == rhs.date
    }
}

// Custom Date Range Picker
struct CustomDateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Start Date")) {
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }

                Section(header: Text("End Date")) {
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}