import Charts
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @State private var selectedDate: Date?

    private var selectedIdentifiableDate: Binding<IdentifiableDate?> {
        Binding(
            get: { self.selectedDate.map { IdentifiableDate(date: $0) } },
            set: { self.selectedDate = $0?.date }
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if self.fastingManager.fastingHistory.isEmpty {
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
                        StreakCalendarView(selectedDate: self.$selectedDate)
                            .environmentObject(self.fastingManager)
                            .padding()

                        // Fasting Graph (Second)
                        FastingGraphView()
                            .environmentObject(self.fastingManager)
                            .padding()

                        // Total Stats Card (Third)
                        TotalStatsView()
                            .environmentObject(self.fastingManager)
                            .padding()

                        // History List
                        VStack(spacing: 0) {
                            Text("Recent Fasts")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.bottom, 10)

                            ForEach(self.fastingManager.fastingHistory.filter(\.isComplete)) { session in
                                HistoryRowView(session: session)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .contentShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture {
                                        self.selectedDate = session.startTime
                                    }
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .sheet(item: self.selectedIdentifiableDate) { identifiableDate in
                AddEditFastView(date: identifiableDate.date, fastingManager: self.fastingManager)
                    .environmentObject(self.fastingManager)
            }
        }
    }
}

struct HistoryRowView: View {
    let session: FastingSession

    // Pre-calculate these values once
    private let formattedDateValue: String
    private let formattedDurationValue: String
    private let formattedEatingWindowValue: String?

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

        // Format eating window if available
        if let eatingWindow = session.eatingWindowDuration {
            let ewHours = Int(eatingWindow) / 3600
            let ewMinutes = Int(eatingWindow) / 60 % 60
            self.formattedEatingWindowValue = "\(ewHours)h \(ewMinutes)m"
        } else {
            self.formattedEatingWindowValue = nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(self.formattedDateValue)
                    .font(.headline)

                Spacer()

                if self.session.metGoal {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("FLSuccess"))
                        Text("Goal Met")
                            .font(.subheadline)
                            .foregroundColor(Color("FLSuccess"))
                    }
                } else {
                    Text("Incomplete")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("Fast: \(self.formattedDurationValue)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Show eating window if available
            if let eatingWindow = formattedEatingWindowValue {
                HStack(spacing: 4) {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.orange)
                    Text("Ate for: \(eatingWindow)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Total Stats View

struct TotalStatsView: View {
    @EnvironmentObject var fastingManager: FastingManager

    var body: some View {
        let completedSessions = self.fastingManager.fastingHistory.filter(\.isComplete)
        // Count all days with ≥14 hours OR goal met
        let totalDays = completedSessions.filter { $0.duration >= 14 * 3600 || $0.metGoal }.count
        let totalDaysToGoal = completedSessions.filter(\.metGoal).count
        let totalHours = completedSessions.reduce(0.0) { $0 + $1.duration / 3600 }
        let longestStreak = self.fastingManager.longestStreak

        VStack(spacing: 16) {
            // First row
            HStack(spacing: 16) {
                // Total Days (≥14h or goal met)
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2)
                        .foregroundColor(Color("FLSecondary"))
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
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)

                // Total Hours
                VStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(Color("FLSuccess"))
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
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
            }

            // Second row
            HStack(spacing: 16) {
                // Days to Goal
                VStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundColor(Color.orange)
                    Text("\(totalDaysToGoal)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Lifetime Days Fasted to Goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)

                // Longest Streak
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(Color.orange)
                    Text("\(longestStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Longest Lifetime Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
            }

            // Third row - Average Hours Per Fast (centered)
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(Color.purple)
                    Text(self.averageHoursText)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Average Hours Per Fast")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                Spacer()
            }
        }
    }

    // Calculate average hours per fast session
    private var averageHoursText: String {
        let completedSessions = self.fastingManager.fastingHistory.filter(\.isComplete)
        let totalDays = completedSessions.filter { $0.duration >= 14 * 3600 || $0.metGoal }.count
        let totalHours = completedSessions.reduce(0.0) { $0 + $1.duration / 3600 }

        // Avoid division by zero
        guard totalDays > 0 else { return "0" }

        let average = totalHours / Double(totalDays)
        return String(format: "%.1f", average)
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
    @State private var customStartDate = Date(timeIntervalSinceNow: -30 * 24 * 60 * 60)
    @State private var customEndDate = Date()
    @State private var selectedDataPoint: ChartDataPoint? = nil

    // Navigation state for each time range
    @State private var selectedWeekOffset: Int = 0 // 0 = current week, -1 = last week, etc.
    @State private var selectedMonthOffset: Int = 0 // 0 = current month, -1 = last month, etc. (max -11)
    @State private var selectedYearOffset: Int = 0 // 0 = current year, -1 = last year, etc. (max -4)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            self.headerView
            self.rangePickerView
            if self.selectedRange == .custom {
                self.customDateButton
            }
            self.chartContentView
            if let selected = selectedDataPoint, selected.hours > 0 {
                self.selectedDataView(for: selected)
            }
            self.legendView
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        .sheet(isPresented: self.$showingCustomPicker) {
            CustomDateRangePickerView(startDate: self.$customStartDate, endDate: self.$customEndDate)
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
                    if self.selectedRange != .custom {
                        // Previous button
                        Button(action: self.navigatePrevious) {
                            Image(systemName: "chevron.left")
                                .font(.subheadline)
                                .foregroundColor(self.canNavigatePrevious() ? Color("FLPrimary") : .gray.opacity(0.3))
                        }
                        .disabled(!self.canNavigatePrevious())
                    }

                    Text(self.getRangeSubtitle())
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if self.selectedRange != .custom {
                        // Next button
                        Button(action: self.navigateNext) {
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundColor(self.canNavigateNext() ? Color("FLPrimary") : .gray.opacity(0.3))
                        }
                        .disabled(!self.canNavigateNext())
                    }
                }
            }

            Spacer()

            Button(action: { self.showGoalLine.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: self.showGoalLine ? "checkmark.circle.fill" : "circle")
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
        Picker("Range", selection: self.$selectedRange) {
            ForEach(GraphTimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: self.selectedRange) { _, newValue in
            if newValue == .custom {
                self.showingCustomPicker = true
            }
            // Reset offsets when switching view types
            self.selectedWeekOffset = 0
            self.selectedMonthOffset = 0
            self.selectedYearOffset = 0

            // Intelligently initialize Month view to show most recent data
            if newValue == .month {
                self.initializeMonthView()
            }
        }
    }

    private var customDateButton: some View {
        Button(action: { self.showingCustomPicker = true }) {
            HStack {
                Text("\(self.formattedDate(self.customStartDate)) - \(self.formattedDate(self.customEndDate))")
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
        let chartData = self.getChartData()
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
                if self.showGoalLine {
                    RuleMark(y: .value("Goal", self.fastingManager.fastingGoalHours))
                        .foregroundStyle(Color("FLSecondary").opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Goal: \(Int(self.fastingManager.fastingGoalHours))h")
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
                    .symbolSize(dataPoint.date == self.selectedDataPoint?.date ? 120 : 80)
                }
            }
            .chartYScale(domain: 0 ... 24)
            .chartXScale(domain: self.getXAxisDomain())
            .chartXAxis {
                AxisMarks(values: self.getXAxisValues()) { value in
                    AxisGridLine()
                    AxisTick()
                    if self.selectedRange == .year {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    } else if self.selectedRange == .month {
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
                                            self.selectedDataPoint = dataPoint
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
                Text(self.formattedDetailDate(selected.date))
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

            if self.showGoalLine {
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
        switch self.selectedRange {
        case .week:
            self.selectedWeekOffset -= 1
        case .month:
            if self.selectedMonthOffset > -11 {
                self.selectedMonthOffset -= 1
            }
        case .year:
            if self.selectedYearOffset > -4 {
                self.selectedYearOffset -= 1
            }
        case .custom:
            break
        }
    }

    private func navigateNext() {
        switch self.selectedRange {
        case .week:
            if self.selectedWeekOffset < 0 {
                self.selectedWeekOffset += 1
            }
        case .month:
            if self.selectedMonthOffset < 0 {
                self.selectedMonthOffset += 1
            }
        case .year:
            if self.selectedYearOffset < 0 {
                self.selectedYearOffset += 1
            }
        case .custom:
            break
        }
    }

    private func canNavigatePrevious() -> Bool {
        switch self.selectedRange {
        case .week:
            return true // No limit on going back for weeks
        case .month:
            return self.selectedMonthOffset > -11 // Max 12 months back
        case .year:
            return self.selectedYearOffset > -4 // Max 5 years back
        case .custom:
            return false
        }
    }

    private func canNavigateNext() -> Bool {
        switch self.selectedRange {
        case .week, .month, .year:
            // Can only go forward if not at current period
            return self.selectedWeekOffset < 0 || self.selectedMonthOffset < 0 || self.selectedYearOffset < 0
        case .custom:
            return false
        }
    }

    private func initializeMonthView() {
        // Only initialize once - don't reset if user has already navigated
        guard self.selectedMonthOffset == 0 else { return }

        let calendar = Calendar.current
        let now = Date()

        // Get the current month's data
        guard let currentMonthInterval = calendar.dateInterval(of: .month, for: now) else { return }
        let currentMonthStart = calendar.startOfDay(for: currentMonthInterval.start)
        let currentMonthEnd = calendar.startOfDay(for: now)

        // Check if there's any data in the current month
        let hasDataInCurrentMonth = self.fastingManager.fastingHistory.contains { session in
            session.isComplete && session.startTime >= currentMonthStart && session.startTime <= currentMonthEnd
        }

        // If no data in current month, find the most recent month with data
        if !hasDataInCurrentMonth,
           let mostRecentSession = fastingManager.fastingHistory.first(where: { $0.isComplete }) {
            // Calculate how many months back the most recent session is
            let sessionMonth = calendar.startOfDay(for: calendar.dateInterval(
                of: .month,
                for: mostRecentSession.startTime
            )?.start ?? mostRecentSession.startTime)
            let currentMonth = calendar.startOfDay(for: currentMonthInterval.start)

            let monthDiff = calendar.dateComponents([.month], from: sessionMonth, to: currentMonth).month ?? 0

            // Set the offset to show that month (limit to -11 for max 12 months back)
            self.selectedMonthOffset = max(-monthDiff, -11)
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

        switch self.selectedRange {
        case .week:
            // "Week of Sep 28"
            let targetDate = calendar.date(byAdding: .weekOfYear, value: self.selectedWeekOffset, to: Date()) ?? Date()
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: targetDate) else {
                return "Week"
            }
            formatter.dateFormat = "MMM d"
            return "Week of \(formatter.string(from: weekInterval.start))"

        case .month:
            // "October" or "September" etc.
            let targetDate = calendar.date(byAdding: .month, value: self.selectedMonthOffset, to: Date()) ?? Date()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: targetDate)

        case .year:
            // "2025" or "2024" etc.
            let targetDate = calendar.date(byAdding: .year, value: self.selectedYearOffset, to: Date()) ?? Date()
            formatter.dateFormat = "yyyy"
            return formatter.string(from: targetDate)

        case .custom:
            // "Sep 1 - Sep 30"
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: self.customStartDate)
            let end = formatter.string(from: self.customEndDate)
            return "\(start) - \(end)"
        }
    }

    private func getChartData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let sessions = self.getFilteredSessions()
        let now = calendar.startOfDay(for: Date())

        // Get date range based on selected view
        let dateRange = self.getDateRange()

        // Create a dictionary of sessions by date
        var sessionsByDate: [Date: FastingSession] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.startTime)
            sessionsByDate[day] = session
        }

        // For year view, only show data points where we have actual data
        // Don't generate 365 zero-value points
        if self.selectedRange == .year {
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

        while currentDate <= dateRange.end, iterationCount < maxIterations {
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

        switch self.selectedRange {
        case .month:
            // Show full month range on X-axis using selected month offset
            let targetDate = calendar.date(byAdding: .month, value: self.selectedMonthOffset, to: now) ?? now
            guard let monthInterval = calendar.dateInterval(of: .month, for: targetDate) else {
                return now ... now
            }
            let monthStart = calendar.startOfDay(for: monthInterval.start)
            let monthEnd = calendar.date(byAdding: .day, value: -1, to: monthInterval.end) ?? targetDate
            return monthStart ... monthEnd

        case .year:
            // Show full year range on X-axis using selected year offset
            let targetDate = calendar.date(byAdding: .year, value: self.selectedYearOffset, to: now) ?? now
            guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: targetDate)),
                  let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) else {
                return now ... now
            }
            return startOfYear ... endOfYear

        default:
            // For week and custom, use data range
            let dateRange = self.getDateRange()
            return dateRange.start ... dateRange.end
        }
    }

    private func getXAxisValues() -> AxisMarkValues {
        let calendar = Calendar.current
        let dateRange = self.getDateRange()
        let daysDifference = calendar.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 1

        switch self.selectedRange {
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

        switch self.selectedRange {
        case .week:
            // Get the selected week (Sunday to Saturday)
            let targetDate = calendar.date(byAdding: .weekOfYear, value: self.selectedWeekOffset, to: now) ?? now
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: targetDate) else {
                let weekAgo = calendar.date(byAdding: .day, value: -6, to: targetDate) ?? targetDate
                return (calendar.startOfDay(for: weekAgo), calendar.startOfDay(for: targetDate))
            }
            let weekStart = calendar.startOfDay(for: weekInterval.start)
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? targetDate
            return (weekStart, calendar.startOfDay(for: weekEnd))

        case .month:
            // Get the selected month
            let targetDate = calendar.date(byAdding: .month, value: self.selectedMonthOffset, to: now) ?? now
            guard let monthInterval = calendar.dateInterval(of: .month, for: targetDate) else {
                let monthAgo = calendar.date(byAdding: .month, value: -1, to: targetDate) ?? targetDate
                return (calendar.startOfDay(for: monthAgo), calendar.startOfDay(for: targetDate))
            }
            let monthStart = calendar.startOfDay(for: monthInterval.start)
            // For past months, show entire month. For current month, only show up to today
            let monthEnd: Date
            if self.selectedMonthOffset == 0 {
                // Current month - show up to today
                monthEnd = calendar.startOfDay(for: now)
            } else {
                // Past month - show entire month
                monthEnd = calendar.date(byAdding: .day, value: -1, to: monthInterval.end) ?? targetDate
            }
            return (monthStart, calendar.startOfDay(for: monthEnd))

        case .year:
            // Get the selected year
            let targetDate = calendar.date(byAdding: .year, value: self.selectedYearOffset, to: now) ?? now
            guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: targetDate)) else {
                return (targetDate, targetDate)
            }
            // For past years, show entire year. For current year, show up to today or end of year
            let endOfYear: Date
            if self.selectedYearOffset == 0 {
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
            return (calendar.startOfDay(for: self.customStartDate), calendar.startOfDay(for: self.customEndDate))
        }
    }

    private func getFilteredSessions() -> [FastingSession] {
        // Get the date range for the selected period (respects navigation offsets)
        let dateRange = self.getDateRange()

        // Filter sessions within the date range
        return self.fastingManager.fastingHistory.filter {
            let sessionDay = Calendar.current.startOfDay(for: $0.startTime)
            return sessionDay >= dateRange.start && sessionDay <= dateRange.end
        }
    }
}

struct ChartDataPoint: Identifiable, Equatable {
    var id: Date { self.date } // Use date as unique ID instead of UUID
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
                    DatePicker("", selection: self.$startDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }

                Section(header: Text("End Date")) {
                    DatePicker("", selection: self.$endDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        self.dismiss()
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
    @State private var displayedMonth: Date = .init()

    var body: some View {
        VStack(spacing: 16) {
            // Header with Month/Year
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.title2)

                Button(action: self.previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                        .font(.title3)
                }

                Text(self.currentMonthYear)
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(minWidth: 180)

                Button(action: self.nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                        .font(.title3)
                }

                Spacer()

                Text("\(self.fastingManager.currentStreak) day\(self.fastingManager.currentStreak == 1 ? "" : "s")")
                    .font(.headline)
                    .foregroundColor(.orange)
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
                self.calendarGridView
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
        .cornerRadius(8)
    }

    @ViewBuilder
    private var calendarGridView: some View {
        let monthDays = self.getMonthDays()
        let daysByWeek = monthDays.chunked(into: 7)

        ForEach(0 ..< daysByWeek.count, id: \.self) { weekIndex in
            HStack(spacing: 8) {
                ForEach(0 ..< 7, id: \.self) { dayIndex in
                    if weekIndex * 7 + dayIndex < monthDays.count {
                        let dateItem = daysByWeek[weekIndex][dayIndex]
                        if let date = dateItem {
                            CalendarDayView(date: date, selectedDate: self.$selectedDate)
                                .environmentObject(self.fastingManager)
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
        return formatter.string(from: self.displayedMonth)
    }

    private func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            self.displayedMonth = newMonth
        }
    }

    private func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            self.displayedMonth = newMonth
        }
    }

    private func getMonthDays() -> [Date?] {
        let calendar = Calendar.current

        // Get the first day of the displayed month
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents(
                  [.year, .month],
                  from: monthInterval.start
              )) else {
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

        for day in 0 ..< daysInMonth {
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
    @EnvironmentObject var fastingManager: FastingManager

    var body: some View {
        let calendar = Calendar.current
        let dayNumber = calendar.component(.day, from: self.date)

        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(self.dayStatus == .goalMet ? Color.orange.opacity(0.1) :
                    self.dayStatus == .incomplete ? Color.red.opacity(0.1) :
                    Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(self.isToday() ? Color("FLPrimary") : Color.clear, lineWidth: 2)
                )

            VStack(spacing: 4) {
                // Day number
                Text("\(dayNumber)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)

                // Status icon
                Group {
                    if self.dayStatus == .goalMet {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 16))
                    } else if self.dayStatus == .incomplete {
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
            self.selectedDate = self.date
        }
    }

    private func isToday() -> Bool {
        Calendar.current.isDateInToday(self.date)
    }

    private var dayStatus: DayStatus {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: self.date)

        // Find fasts that started on this day
        for session in self.fastingManager.fastingHistory {
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

// MARK: - Add/Edit Fast View

struct AddEditFastView: View {
    let date: Date
    @EnvironmentObject var fastingManager: FastingManager
    @Environment(\.dismiss) var dismiss

    @State private var hours: Int = 16
    @State private var minutes: Int = 0
    @State private var goalHours: Double = 16
    @State private var startTime: Date
    @State private var showingDeleteAlert = false
    @State private var customGoalText: String = ""
    @State private var isCustomGoal: Bool = false
    @FocusState private var isCustomGoalFocused: Bool

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
                        Text(self.existingSession == nil ? "Add Fast" : "Edit Fast")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(self.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Start Time Picker
                    VStack(spacing: 12) {
                        Text("Start Time")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: self.$startTime, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    .padding(.horizontal)

                    // Duration Display
                    VStack(spacing: 16) {
                        Text("Fast Duration")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("\(self.hours)h \(self.minutes)m")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(self.durationColor)
                    }

                    // Duration Pickers
                    HStack(spacing: 40) {
                        // Hours Picker
                        VStack(spacing: 12) {
                            Text("Hours")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Picker("Hours", selection: self.$hours) {
                                ForEach(0 ..< 49) { hour in
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
                            Picker("Minutes", selection: self.$minutes) {
                                ForEach(0 ..< 60) { minute in
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
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("Goal")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("\(Int(self.goalHours)) hours")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(Color("FLSecondary"))
                        }

                        VStack(spacing: 12) {
                            HStack(spacing: 6) {
                                ForEach([8.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 36.0, 48.0], id: \.self) { goal in
                                    Button(action: {
                                        self.isCustomGoal = false
                                        self.goalHours = goal
                                        self.customGoalText = "" // Clear custom text when selecting preset
                                    }) {
                                        Text("\(Int(goal))h")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(self.goalHours == goal && !self
                                                .isCustomGoal ? .white : Color("FLSecondary"))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(self.goalHours == goal && !self
                                                .isCustomGoal ? Color("FLSecondary") :
                                                Color(UIColor.secondarySystemGroupedBackground))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(
                                                        self.goalHours == goal && !self.isCustomGoal ? Color
                                                            .clear : Color("FLSecondary").opacity(0.3),
                                                        lineWidth: 1
                                                    )
                                            )
                                    }
                                }
                            }

                            Button(action: {
                                // Always start with empty text field for custom input
                                self.customGoalText = ""
                                self.goalHours = 0 // Reset display to 0 when entering custom mode
                                self.isCustomGoal = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    self.isCustomGoalFocused = true
                                }
                            }) {
                                Text("Custom")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(self.isCustomGoal ? .white : Color("FLSecondary"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(self
                                        .isCustomGoal ? Color("FLSecondary") :
                                        Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                self.isCustomGoal ? Color.clear : Color("FLSecondary").opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                            }

                            if self.isCustomGoal {
                                HStack(spacing: 8) {
                                    TextField("Enter goal", text: self.$customGoalText)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: 20, weight: .semibold))
                                        .focused(self.$isCustomGoalFocused)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .cornerRadius(8)
                                        .onChange(of: self.customGoalText) { _, newValue in
                                            if let value = Double(newValue), value > 0 {
                                                self.goalHours = value
                                            }
                                        }
                                        .toolbar {
                                            ToolbarItemGroup(placement: .keyboard) {
                                                Spacer()
                                                Button("Done") {
                                                    self.isCustomGoalFocused = false
                                                }
                                                .foregroundColor(Color("FLSecondary"))
                                                .fontWeight(.semibold)
                                            }
                                        }
                                    Text("hours")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)

                    // Save Button
                    Button(action: self.saveFast) {
                        Text("Save Fast")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color("FLSecondary"), Color("FLSecondary")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .disabled(self.hours == 0 && self.minutes == 0)
                    .opacity((self.hours == 0 && self.minutes == 0) ? 0.5 : 1.0)

                    // Delete Button (only show if editing existing fast)
                    if self.existingSession != nil {
                        Button(action: { self.showingDeleteAlert = true }) {
                            Text("Delete Fast")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }

                    Spacer().frame(height: 40)
                }
            }
            .background(Color.gray.opacity(0.05).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.dismiss()
                    }
                }
            }
        }
        .onAppear {
            self.goalHours = self.fastingManager.fastingGoalHours
            // Check if current goal is a preset value or custom
            let presetGoals = [8.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 36.0, 48.0]
            if !presetGoals.contains(self.goalHours) {
                self.isCustomGoal = true
                self.customGoalText = String(Int(self.goalHours))
            }
        }
        .alert("Delete Fast", isPresented: self.$showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                self.deleteFast()
            }
        } message: {
            Text("Are you sure you want to delete this fast? This action cannot be undone.")
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: self.date)
    }

    private var totalDurationHours: Double {
        Double(self.hours) + Double(self.minutes) / 60.0
    }

    private var durationColor: Color {
        if self.totalDurationHours >= self.goalHours {
            return Color("FLSuccess")
        } else {
            return Color.orange
        }
    }

    private func saveFast() {
        guard self.hours > 0 || self.minutes > 0 else { return }

        // Calculate end time based on start time and duration
        let totalSeconds = TimeInterval(hours * 3600 + self.minutes * 60)
        let endTime = self.startTime.addingTimeInterval(totalSeconds)

        self.fastingManager.addManualFast(startTime: self.startTime, endTime: endTime, goalHours: self.goalHours)
        self.dismiss()
    }

    private func deleteFast() {
        self.fastingManager.deleteFast(for: self.date)
        self.dismiss()
    }
}
