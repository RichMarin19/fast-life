import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @State private var selectedDate: Date?
    @State private var showingAddFast = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if fastingManager.fastingHistory.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "clock.badge.questionmark")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No fasting history yet")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            Text("Start your first fast to see it here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxHeight: .infinity)
                        Spacer()
                    } else {
                        // Streak Calendar Visualization (First)
                        StreakCalendarView(selectedDate: $selectedDate, showingAddFast: $showingAddFast)
                            .environmentObject(fastingManager)
                            .padding()

                        // Fasting Graph (Second)
                        FastingGraphView()
                            .environmentObject(fastingManager)
                            .padding()

                        // Total Stats Card (Third)
                        TotalStatsView()
                            .environmentObject(fastingManager)
                            .padding()

                        // History List
                        VStack(spacing: 0) {
                            Text("Recent Fasts")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.bottom, 10)

                            ForEach(fastingManager.fastingHistory.filter { $0.isComplete }) { session in
                                HistoryRowView(session: session)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .sheet(isPresented: $showingAddFast) {
                if let date = selectedDate {
                    AddEditFastView(date: date, fastingManager: fastingManager)
                        .environmentObject(fastingManager)
                }
            }
        }
    }
}

struct HistoryRowView: View {
    let session: FastingSession

    // Pre-calculate these values once
    private let formattedDateValue: String
    private let formattedDurationValue: String

    init(session: FastingSession) {
        self.session = session

        // Calculate formatted strings in init to avoid repeated calculations
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        self.formattedDateValue = dateFormatter.string(from: session.startTime)

        let durationSeconds = session.duration
        let hours = Int(durationSeconds) / 3600
        let minutes = Int(durationSeconds) / 60 % 60
        self.formattedDurationValue = "\(hours)h \(minutes)m"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formattedDateValue)
                    .font(.headline)

                Spacer()

                if session.metGoal {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Goal Met")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("Incomplete")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }

            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("Duration: \(formattedDurationValue)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Total Stats View

struct TotalStatsView: View {
    @EnvironmentObject var fastingManager: FastingManager

    var body: some View {
        let completedSessions = fastingManager.fastingHistory.filter { $0.isComplete }
        let totalDays = completedSessions.filter { $0.metGoal }.count
        let totalHours = completedSessions.reduce(0.0) { $0 + $1.duration / 3600 }

        HStack(spacing: 16) {
            // Total Days
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.95))
                Text("\(totalDays)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Lifetime Days Fasted")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)

            // Total Hours
            VStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                Text("\(Int(totalHours))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Lifetime Hours Fasted")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        }
    }
}

// MARK: - Fasting Graph View

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
        .cornerRadius(16)
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
                Text(getRangeSubtitle())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { showGoalLine.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: showGoalLine ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.95))
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
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.95))
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var chartContentView: some View {
        let chartData = getChartData()

        if chartData.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.5))
                Text("No fasting data yet")
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
                            .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 0.95).opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Goal: \(Int(fastingManager.fastingGoalHours))h")
                                    .font(.caption2)
                                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.95))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(4)
                            }
                    }

                    // Selection indicator line
                    if let selected = selectedDataPoint {
                        RuleMark(x: .value("Selected", selected.date))
                            .foregroundStyle(Color.blue.opacity(0.3))
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
                                colors: [Color(red: 0.4, green: 0.8, blue: 0.6), Color(red: 0.3, green: 0.7, blue: 0.5)],
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
                        .foregroundStyle(dataPoint.metGoal ? Color(red: 0.4, green: 0.8, blue: 0.6) : Color(red: 0.9, green: 0.6, blue: 0.4))
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
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
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
                            .foregroundColor(.green)
                        Text("Goal Met")
                            .foregroundColor(.green)
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
                    .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                    .frame(width: 10, height: 10)
                Text("Goal Met")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(Color(red: 0.9, green: 0.6, blue: 0.4))
                    .frame(width: 10, height: 10)
                Text("Incomplete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if showGoalLine {
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Color(red: 0.4, green: 0.7, blue: 0.95).opacity(0.5))
                        .frame(width: 16, height: 2)
                    Text("Goal Line")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
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
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
                return "Week"
            }
            formatter.dateFormat = "MMM d"
            return "Week of \(formatter.string(from: weekInterval.start))"

        case .month:
            // "October"
            formatter.dateFormat = "MMMM"
            return formatter.string(from: Date())

        case .year:
            // "2025"
            formatter.dateFormat = "yyyy"
            return formatter.string(from: Date())

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
                // Has actual data
                dataPoints.append(ChartDataPoint(
                    date: session.startTime,
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
            // Show full month range on X-axis
            guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
                return now...now
            }
            let monthStart = calendar.startOfDay(for: monthInterval.start)
            let monthEnd = calendar.date(byAdding: .day, value: -1, to: monthInterval.end) ?? now
            return monthStart...monthEnd

        case .year:
            // Show full year range on X-axis
            guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)),
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
            // Show every 2-3 days to get 12-15 labels
            let stride = max(1, daysDifference / 15)
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
            // Get the current week (Sunday to Saturday)
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
                let weekAgo = calendar.date(byAdding: .day, value: -6, to: now) ?? now
                return (calendar.startOfDay(for: weekAgo), calendar.startOfDay(for: now))
            }
            let weekStart = calendar.startOfDay(for: weekInterval.start)
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? now
            return (weekStart, calendar.startOfDay(for: weekEnd))

        case .month:
            // Get from start of current month to today
            guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
                let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
                return (calendar.startOfDay(for: monthAgo), calendar.startOfDay(for: now))
            }
            let monthStart = calendar.startOfDay(for: monthInterval.start)
            return (monthStart, calendar.startOfDay(for: now))

        case .year:
            // Get start of year to end of year
            guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) else {
                return (now, now)
            }
            guard let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) else {
                return (calendar.startOfDay(for: startOfYear), calendar.startOfDay(for: now))
            }
            return (calendar.startOfDay(for: startOfYear), calendar.startOfDay(for: endOfYear))

        case .custom:
            return (calendar.startOfDay(for: customStartDate), calendar.startOfDay(for: customEndDate))
        }
    }

    private func getFilteredSessions() -> [FastingSession] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedRange {
        case .week:
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return [] }
            return fastingManager.fastingHistory.filter { $0.startTime >= weekAgo }
        case .month:
            guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return [] }
            return fastingManager.fastingHistory.filter { $0.startTime >= monthAgo }
        case .year:
            guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) else { return [] }
            return fastingManager.fastingHistory.filter { $0.startTime >= startOfYear }
        case .custom:
            return fastingManager.fastingHistory.filter {
                $0.startTime >= customStartDate && $0.startTime <= customEndDate
            }
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

// MARK: - Streak Calendar View

struct StreakCalendarView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @Binding var selectedDate: Date?
    @Binding var showingAddFast: Bool
    @State private var displayedMonth: Date = Date()

    var body: some View {
        VStack(spacing: 16) {
            // Header with Month/Year
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.title2)

                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                        .font(.title3)
                }

                Text(currentMonthYear)
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(minWidth: 180)

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                        .font(.title3)
                }

                Spacer()
                if fastingManager.currentStreak > 0 {
                    Text("\(fastingManager.currentStreak) day\(fastingManager.currentStreak == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }

            // Calendar Grid (Current Month)
            VStack(spacing: 12) {
                // Weekday headers
                HStack(spacing: 8) {
                    ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar days grid
                calendarGridView
            }

            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Goal Met")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("Incomplete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 12, height: 12)
                    Text("No Fast")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }

    @ViewBuilder
    private var calendarGridView: some View {
        let monthDays = getMonthDays()
        let daysByWeek = monthDays.chunked(into: 7)

        ForEach(0..<daysByWeek.count, id: \.self) { weekIndex in
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    if weekIndex * 7 + dayIndex < monthDays.count {
                        let dateItem = daysByWeek[weekIndex][dayIndex]
                        if let date = dateItem {
                            CalendarDayView(date: date, selectedDate: $selectedDate, showingAddFast: $showingAddFast)
                                .environmentObject(fastingManager)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }

    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func getMonthDays() -> [Date?] {
        let calendar = Calendar.current

        // Get the first day of the displayed month
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthInterval.start)) else {
            return []
        }

        // Get number of days in month
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count else {
            return []
        }

        // Get weekday of first day (0 = Sunday, 1 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let leadingEmptyDays = firstWeekday - 1 // Number of empty slots before month starts

        // Create array with leading nils, then dates
        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)

        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        // Pad to fill last week (ensure multiple of 7)
        let totalSlots = ((days.count + 6) / 7) * 7
        while days.count < totalSlots {
            days.append(nil)
        }

        return days
    }
}

struct CalendarDayView: View {
    let date: Date
    @Binding var selectedDate: Date?
    @Binding var showingAddFast: Bool
    @EnvironmentObject var fastingManager: FastingManager

    var body: some View {
        let calendar = Calendar.current
        let dayNumber = calendar.component(.day, from: date)
        let dayStatus = getDayStatus()

        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(dayStatus == .goalMet ? Color.orange.opacity(0.1) :
                      dayStatus == .incomplete ? Color.red.opacity(0.1) :
                      Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isToday() ? Color.blue : Color.clear, lineWidth: 2)
                )

            VStack(spacing: 4) {
                // Day number
                Text("\(dayNumber)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)

                // Status icon
                Group {
                    if dayStatus == .goalMet {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 16))
                    } else if dayStatus == .incomplete {
                        Image(systemName: "xmark")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                    }
                }
            }
            .padding(4)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture {
            selectedDate = date
            showingAddFast = true
        }
    }

    private func isToday() -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func getDayStatus() -> DayStatus {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)

        // Find fasts that started on this day
        for session in fastingManager.fastingHistory {
            let sessionDay = calendar.startOfDay(for: session.startTime)
            if sessionDay == targetDay {
                return session.metGoal ? .goalMet : .incomplete
            }
        }

        return .noFast
    }
}

enum DayStatus {
    case goalMet
    case incomplete
    case noFast
}

// Helper extension to chunk array into groups
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Add/Edit Fast View

struct AddEditFastView: View {
    let date: Date
    @EnvironmentObject var fastingManager: FastingManager
    @Environment(\.dismiss) var dismiss

    @State private var hours: Int = 16
    @State private var minutes: Int = 0
    @State private var goalHours: Double = 16
    @State private var startTime: Date

    private var existingSession: FastingSession?

    init(date: Date, fastingManager: FastingManager) {
        self.date = date

        // Check if there's an existing fast for this date
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        self.existingSession = fastingManager.fastingHistory.first(where: {
            calendar.startOfDay(for: $0.startTime) == targetDay
        })

        // Initialize with existing data or defaults
        if let existing = existingSession {
            _startTime = State(initialValue: existing.startTime)
            _hours = State(initialValue: Int(existing.duration / 3600))
            _minutes = State(initialValue: Int(existing.duration / 60) % 60)
            _goalHours = State(initialValue: existing.goalHours ?? 16)
        } else {
            // Default to 6 PM on the selected date
            let startOfDay = calendar.startOfDay(for: date)
            let defaultStart = calendar.date(byAdding: .hour, value: 18, to: startOfDay) ?? date
            _startTime = State(initialValue: defaultStart)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text(existingSession == nil ? "Add Fast" : "Edit Fast")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Start Time Picker
                    VStack(spacing: 12) {
                        Text("Start Time")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $startTime, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    .padding(.horizontal)

                    // Duration Display
                    VStack(spacing: 16) {
                        Text("Fast Duration")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("\(hours)h \(minutes)m")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(durationColor)
                    }

                    // Duration Pickers
                    HStack(spacing: 40) {
                        // Hours Picker
                        VStack(spacing: 12) {
                            Text("Hours")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Picker("Hours", selection: $hours) {
                                ForEach(0..<49) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100, height: 150)
                        }

                        // Minutes Picker
                        VStack(spacing: 12) {
                            Text("Minutes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Picker("Minutes", selection: $minutes) {
                                ForEach(0..<60) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100, height: 150)
                        }
                    }
                    .padding()

                    Divider()
                        .padding(.horizontal)

                    // Goal Picker
                    VStack(spacing: 16) {
                        Text("Goal")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("\(Int(goalHours)) hours")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.95))

                        Picker("Goal", selection: $goalHours) {
                            ForEach([8.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 36.0, 48.0], id: \.self) { goal in
                                Text("\(Int(goal))h").tag(goal)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)

                    // Save Button
                    Button(action: saveFast) {
                        Text("Save Fast")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.4, green: 0.7, blue: 0.95), Color(red: 0.5, green: 0.6, blue: 0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(hours == 0 && minutes == 0)
                    .opacity((hours == 0 && minutes == 0) ? 0.5 : 1.0)

                    Spacer().frame(height: 40)
                }
            }
            .background(Color.gray.opacity(0.05).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            goalHours = fastingManager.fastingGoalHours
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private var totalDurationHours: Double {
        Double(hours) + Double(minutes) / 60.0
    }

    private var durationColor: Color {
        if totalDurationHours >= goalHours {
            return Color(red: 0.4, green: 0.8, blue: 0.6)
        } else {
            return Color(red: 0.9, green: 0.6, blue: 0.4)
        }
    }

    private func saveFast() {
        guard hours > 0 || minutes > 0 else { return }

        // Calculate end time based on start time and duration
        let totalSeconds = TimeInterval(hours * 3600 + minutes * 60)
        let endTime = startTime.addingTimeInterval(totalSeconds)

        fastingManager.addManualFast(startTime: startTime, endTime: endTime, goalHours: goalHours)
        dismiss()
    }
}
