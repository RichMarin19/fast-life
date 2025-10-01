import SwiftUI
import Charts

struct WeightTrackingView: View {
    @StateObject private var weightManager = WeightManager()
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var showingAddWeight = false
    @State private var showingSettings = false
    @State private var selectedTimeRange: WeightTimeRange = .month
    @State private var showGoalLine = false
    @State private var weightGoal: Double = 180.0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if weightManager.weightEntries.isEmpty {
                        EmptyWeightStateView(showingAddWeight: $showingAddWeight, healthKitManager: healthKitManager, weightManager: weightManager)
                    } else {
                        // Current Weight Card
                        CurrentWeightCard(weightManager: weightManager)
                            .padding(.horizontal)

                        // Weight Chart
                        WeightChartView(
                            weightManager: weightManager,
                            selectedTimeRange: $selectedTimeRange,
                            showGoalLine: $showGoalLine,
                            weightGoal: $weightGoal
                        )
                        .padding(.horizontal)

                        // Weight Statistics
                        WeightStatsView(weightManager: weightManager)
                            .padding(.horizontal)

                        // Weight History List
                        WeightHistoryListView(weightManager: weightManager)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Weight Tracking")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWeight = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWeight) {
                AddWeightView(weightManager: weightManager)
            }
            .sheet(isPresented: $showingSettings) {
                WeightSettingsView(
                    weightManager: weightManager,
                    showGoalLine: $showGoalLine,
                    weightGoal: $weightGoal
                )
            }
            .onAppear {
                // Only request authorization on first appearance if needed
                // Don't auto-sync on every view appearance - user can manually sync
                if weightManager.syncWithHealthKit && !healthKitManager.isAuthorized {
                    healthKitManager.requestAuthorization { _, _ in
                        // Authorization requested, user can manually sync if they want
                    }
                }
            }
        }
    }
}

// MARK: - Empty State View

struct EmptyWeightStateView: View {
    @Binding var showingAddWeight: Bool
    let healthKitManager: HealthKitManager
    let weightManager: WeightManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "scalemass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Weight Data Yet")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("Add your first weight entry or sync with Apple Health")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button(action: { showingAddWeight = true }) {
                    Label("Add Weight Manually", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }

                Button(action: {
                    healthKitManager.requestAuthorization { success, _ in
                        if success {
                            weightManager.syncFromHealthKit()
                        }
                    }
                }) {
                    Label("Sync with Apple Health", systemImage: "heart.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Current Weight Card

struct CurrentWeightCard: View {
    @ObservedObject var weightManager: WeightManager

    var body: some View {
        VStack(spacing: 12) {
            Text("Current Weight")
                .font(.headline)
                .foregroundColor(.secondary)

            if let latest = weightManager.latestWeight {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(latest.weight, specifier: "%.1f")")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.86))
                    Text("lbs")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }

                Text(latest.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let trend = weightManager.weightTrend {
                    HStack(spacing: 4) {
                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text("\(abs(trend), specifier: "%.1f") lbs \(trend >= 0 ? "gained" : "lost")")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(trend >= 0 ? .red : .green)
                    .padding(.top, 4)
                }

                if let bmi = latest.bmi {
                    HStack(spacing: 16) {
                        VStack {
                            Text("BMI")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(bmi, specifier: "%.1f")")
                                .font(.headline)
                        }

                        if let bodyFat = latest.bodyFat {
                            VStack {
                                Text("Body Fat")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(bodyFat, specifier: "%.1f")%")
                                    .font(.headline)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

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
    @ObservedObject var weightManager: WeightManager
    @Binding var selectedTimeRange: WeightTimeRange
    @Binding var showGoalLine: Bool
    @Binding var weightGoal: Double

    @State private var selectedDate: Date?

    var filteredEntries: [WeightEntry] {
        let calendar = Calendar.current

        // Special handling for Day view: show current calendar day (12am to now)
        if selectedTimeRange == .day {
            let startOfToday = calendar.startOfDay(for: Date())
            return weightManager.weightEntries.filter { $0.date >= startOfToday }
        }

        // For other views: use rolling time window (last N days)
        guard let days = selectedTimeRange.days else {
            return weightManager.weightEntries
        }

        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return weightManager.weightEntries.filter { $0.date >= cutoffDate }
    }

    // MARK: - Daily Averaged Entries for Week/Month View

    /// For Week/Month view: Groups entries by calendar day and averages weights for each day
    /// This ensures one data point per day even if multiple weigh-ins occurred
    var dailyAveragedEntries: [WeightEntry] {
        let calendar = Calendar.current

        // Group entries by calendar day
        let groupedByDay = Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }

        // Calculate average weight for each day
        let averagedEntries = groupedByDay.map { (day, entries) -> WeightEntry in
            let avgWeight = entries.reduce(0.0) { $0 + $1.weight } / Double(entries.count)
            let avgBMI = entries.compactMap { $0.bmi }.isEmpty ? nil : entries.compactMap { $0.bmi }.reduce(0.0, +) / Double(entries.compactMap { $0.bmi }.count)
            let avgBodyFat = entries.compactMap { $0.bodyFat }.isEmpty ? nil : entries.compactMap { $0.bodyFat }.reduce(0.0, +) / Double(entries.compactMap { $0.bodyFat }.count)

            // Use the most recent entry's metadata for the day
            let mostRecentEntry = entries.sorted { $0.date > $1.date }.first!

            return WeightEntry(
                id: mostRecentEntry.id,
                date: day, // Use start of day for consistent X-axis positioning
                weight: avgWeight,
                bmi: avgBMI,
                bodyFat: avgBodyFat,
                source: mostRecentEntry.source
            )
        }

        // Sort by date (oldest to newest for chart rendering)
        return averagedEntries.sorted { $0.date < $1.date }
    }

    /// Returns the appropriate data set based on selected time range
    var chartData: [WeightEntry] {
        switch selectedTimeRange {
        case .day:
            // Day view: Show ALL individual data points (no averaging)
            return filteredEntries
        case .week, .month:
            // Week/Month view: Show daily averaged data (one point per day)
            return dailyAveragedEntries
        default:
            // Other views: Show all filtered data
            return filteredEntries
        }
    }

    /// Find the weight entry closest to the selected date
    var selectedEntry: WeightEntry? {
        guard let selectedDate = selectedDate else { return nil }

        return chartData.min(by: { entry1, entry2 in
            abs(entry1.date.timeIntervalSince(selectedDate)) < abs(entry2.date.timeIntervalSince(selectedDate))
        })
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weight Chart")
                    .font(.headline)
                Spacer()
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(WeightTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.menu)
            }

            if !chartData.isEmpty {
                Chart {
                    ForEach(chartData) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 0.86))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 0.86))
                    }

                    if showGoalLine {
                        RuleMark(y: .value("Goal", weightGoal))
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Goal")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                    }

                    // Selection indicator: vertical line at selected point
                    if let selectedEntry = selectedEntry {
                        RuleMark(x: .value("Selected", selectedEntry.date))
                            .foregroundStyle(.gray.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .annotation(position: .top, alignment: .center) {
                                VStack(spacing: 4) {
                                    Text("\(selectedEntry.weight, specifier: "%.1f") lbs")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(red: 0.2, green: 0.6, blue: 0.86))
                                        .cornerRadius(6)
                                }
                            }
                    }
                }
                .frame(height: 250)
                .chartXAxis {
                    if selectedTimeRange == .day {
                        // Day view: Show 3-hour increments starting from 6am
                        AxisMarks(values: dayXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else if selectedTimeRange == .week {
                        // Week view: Show all 7 days
                        AxisMarks(values: weekXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else if selectedTimeRange == .month {
                        // Month view: Show 12 evenly-spaced slots over last 30 days
                        AxisMarks(values: monthXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else {
                        // Other views: Dynamic X-axis based on actual data points
                        AxisMarks(values: .automatic) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(xAxisLabel(for: date))
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
                        AxisMarks(position: .leading, values: dayYAxisValues) { value in
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
                        AxisMarks(position: .leading, values: weekYAxisValues) { value in
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
                        AxisMarks(position: .leading, values: monthYAxisValues) { value in
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
                .chartYScale(domain: yAxisDomain)
                .modifier(XAxisScaleModifier(domain: xAxisDomain))
                .chartXSelection(value: $selectedDate)
            } else {
                Text("No data for selected time range")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
            }

            // Selected data point details
            if let selectedEntry = selectedEntry {
                VStack(spacing: 8) {
                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected Point")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(selectedEntry.weight, specifier: "%.1f") lbs")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.86))

                            HStack(spacing: 8) {
                                Text(selectedEntry.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if let displayTime = selectedEntryDisplayTime {
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
                            selectedDate = nil
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - X-Axis Labels

    private func xAxisLabel(for date: Date) -> String {
        let calendar = Calendar.current

        switch selectedTimeRange {
        case .day:
            // Show hour for Day view (e.g., "12am", "1am", "2pm")
            let formatter = DateFormatter()
            formatter.dateFormat = "ha" // Hour with am/pm
            return formatter.string(from: date).lowercased()

        case .week:
            // Show month/day for last 7 days (e.g., "Sep 24", "Sep 25", "Oct 1")
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d" // "Sep 24", "Oct 1"
            return formatter.string(from: date)

        case .month:
            // Show day of month (1, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30)
            let day = calendar.component(.day, from: date)
            return "\(day)"

        case .threeMonths:
            // Show month/day for 3 months
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)

        case .year:
            // Show month abbreviation (Jan, Feb, Mar...)
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)

        case .all:
            // Show month/year for all time
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yy"
            return formatter.string(from: date)
        }
    }


    // MARK: - X-Axis Domain for Day View

    /// Returns the X-axis date range for Day/Month view
    /// Day view: 6am to 12am (midnight) by default, adjusts if entries before 6am
    /// Month view: Extends slightly beyond data range for easier point selection
    var xAxisDomain: ClosedRange<Date>? {
        let calendar = Calendar.current

        switch selectedTimeRange {
        case .day:
            guard !chartData.isEmpty else { return nil }

            let today = calendar.startOfDay(for: Date())

            // Default start: 6am today
            guard let defaultStart = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: today) else {
                return nil
            }

            // Default end: 12am (midnight) next day
            guard let defaultEnd = calendar.date(byAdding: .day, value: 1, to: today) else {
                return nil
            }

            // Find the earliest entry time
            let dates = chartData.map { $0.date }
            guard let minDate = dates.min() else { return nil }

            // If earliest entry is before 6am, adjust start time to that entry
            let rangeStart = min(defaultStart, minDate)

            // Always end at midnight (12am next day)
            return rangeStart...defaultEnd

        case .month:
            guard !chartData.isEmpty else { return nil }

            // Extend domain by 1 day on each side for easier point selection
            let dates = chartData.map { $0.date }
            guard let minDate = dates.min(), let maxDate = dates.max() else { return nil }

            guard let rangeStart = calendar.date(byAdding: .day, value: -1, to: minDate),
                  let rangeEnd = calendar.date(byAdding: .day, value: 1, to: maxDate) else {
                return nil
            }

            return rangeStart...rangeEnd

        default:
            return nil
        }
    }

    // MARK: - X-Axis Values for Day View

    /// Generates X-axis time marks every 3 hours starting from 6am (or earlier if data exists)
    var dayXAxisValues: [Date] {
        guard selectedTimeRange == .day, let domain = xAxisDomain else { return [] }

        let calendar = Calendar.current
        let startDate = domain.lowerBound
        let endDate = domain.upperBound

        var values: [Date] = []

        // Get the starting hour (e.g., 6 for 6am, or earlier if adjusted)
        let startHour = calendar.component(.hour, from: startDate)

        // Round down to nearest 3-hour mark if needed
        let adjustedStartHour = (startHour / 3) * 3

        // Get today's midnight as reference
        let today = calendar.startOfDay(for: Date())

        // Generate marks every 3 hours from adjusted start to midnight (24:00)
        var currentHour = adjustedStartHour
        while currentHour <= 24 {
            if let date = calendar.date(bySettingHour: currentHour % 24, minute: 0, second: 0, of: currentHour < 24 ? today : calendar.date(byAdding: .day, value: 1, to: today)!) {
                if date >= startDate && date <= endDate {
                    values.append(date)
                }
            }
            currentHour += 3
        }

        return values
    }

    // MARK: - X-Axis Values for Week View

    /// Generates X-axis marks for each of the last 7 days
    var weekXAxisValues: [Date] {
        guard selectedTimeRange == .week else { return [] }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Generate last 7 days (including today)
        var values: [Date] = []
        for daysAgo in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                values.append(date)
            }
        }

        return values
    }

    /// Generates X-axis marks for Month view: Adaptive based on data range
    /// Shows 6-10 evenly-spaced dates depending on how much data exists
    var monthXAxisValues: [Date] {
        guard selectedTimeRange == .month else { return [] }
        guard !chartData.isEmpty else { return [] }

        let calendar = Calendar.current
        let dates = chartData.map { $0.date }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return [] }

        // Calculate the number of days in the actual data range
        let daysBetween = calendar.dateComponents([.day], from: minDate, to: maxDate).day ?? 0

        // Determine number of marks based on data range
        // 1-7 days: show every day (or every other day)
        // 8-15 days: show ~6 marks
        // 16-30 days: show ~8 marks
        let numberOfMarks: Int
        if daysBetween <= 7 {
            numberOfMarks = max(daysBetween + 1, 4) // Show all days, minimum 4 marks
        } else if daysBetween <= 15 {
            numberOfMarks = 6
        } else {
            numberOfMarks = 8
        }

        // Generate evenly-spaced dates
        var values: [Date] = []
        let interval = Double(daysBetween) / Double(numberOfMarks - 1)

        for i in 0..<numberOfMarks {
            let daysToAdd = Int(round(Double(i) * interval))
            if let date = calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: minDate)) {
                values.append(date)
            }
        }

        return values
    }

    /// For Week/Month view: Returns actual time if day has single entry, nil if multiple entries
    /// This ensures we show accurate weigh-in times or omit time for averaged data
    var selectedEntryDisplayTime: Date? {
        guard let selectedEntry = selectedEntry else { return nil }

        // For Day view (or other views), always show the actual time
        guard selectedTimeRange == .week || selectedTimeRange == .month else {
            return selectedEntry.date
        }

        // For Week/Month view: Check how many entries exist for the selected day
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: selectedEntry.date)

        let entriesForDay = filteredEntries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: selectedDay)
        }

        // If exactly one entry for this day, return its actual time
        // If multiple entries (averaged), return nil to hide time
        return entriesForDay.count == 1 ? entriesForDay.first?.date : nil
    }

    // MARK: - Y-Axis Values

    /// For Day view: Generates 5-6 evenly-spaced values for cleaner Y-axis
    private var dayYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound

        // Create ~5 marks: every 2 lbs for 10lb range
        let step = 2.0
        return stride(from: min, through: max, by: step).map { $0 }
    }

    /// For Week view: Generates evenly-spaced values at 1lb intervals for 5lb range
    private var weekYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound

        // Round boundaries to whole pounds to ensure axis marks align properly
        let minRounded = ceil(min)
        let maxRounded = floor(max)

        // Use 1lb steps for 5lb range (cleaner, easier to read)
        let step = 1.0
        return stride(from: minRounded, through: maxRounded, by: step).map { $0 }
    }

    /// For Month view: Generates 10 evenly-spaced Y-axis marks
    private var monthYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound

        // Generate 10 evenly-spaced values (11 marks including min and max)
        let range = max - min
        let step = range / 10.0

        return stride(from: min, through: max, by: step).map { $0 }
    }

    // MARK: - Y-Axis Domain

    private var yAxisDomain: ClosedRange<Double> {
        guard !chartData.isEmpty else {
            return 0...200 // Default range
        }

        let weights = chartData.map { $0.weight }
        let minWeight = weights.min() ?? 0
        let maxWeight = weights.max() ?? 200

        switch selectedTimeRange {
        case .day:
            // For Day view: 10lb range (average ± 5 lbs) with 1lb increments
            // Calculate average weight for the day
            let avgWeight = weights.reduce(0.0, +) / Double(weights.count)

            // Create 10lb range: 5 lbs above and 5 lbs below average
            let rangeMin = round(avgWeight) - 5
            let rangeMax = round(avgWeight) + 5

            return rangeMin...rangeMax

        case .week:
            // For Week view: Default 5lb range (average ± 2.5 lbs), adaptive if needed
            // Calculate average weight for the week
            let avgWeight = weights.reduce(0.0, +) / Double(weights.count)

            // Default 5lb range: 2.5 lbs above and below average
            // Round to whole numbers to ensure goal line aligns with axis marks
            let centerWeight = round(avgWeight)
            let defaultRangeMin = centerWeight - 2.5
            let defaultRangeMax = centerWeight + 2.5

            // Check if actual data fits within default range
            let dataRange = maxWeight - minWeight

            if dataRange <= 5 {
                // Data fits within 5lb range, use default
                return defaultRangeMin...defaultRangeMax
            } else {
                // Data exceeds 5lb range, expand adaptively
                // Add 10% padding to actual data range
                let padding = dataRange * 0.1
                let rangeMin = floor(minWeight - padding)
                let rangeMax = ceil(maxWeight + padding)
                return rangeMin...rangeMax
            }

        case .month:
            // For Month view: Adaptive range based on weight fluctuation over 30 days
            // With dynamic adjustment when goal line is shown
            let dataRange = maxWeight - minWeight

            if showGoalLine {
                // Goal line is shown: Start Y-axis just below goal weight
                // Determine appropriate padding based on relationship between data and goal
                let highestValue = max(maxWeight, weightGoal)

                // Start 5-20 lbs below goal depending on data spread
                let belowGoalPadding: Double
                if dataRange < 5 {
                    belowGoalPadding = 5.0 // Small fluctuation: 5 lb padding
                } else if dataRange < 10 {
                    belowGoalPadding = 10.0 // Moderate fluctuation: 10 lb padding
                } else {
                    belowGoalPadding = 20.0 // Large fluctuation: 20 lb padding
                }

                let rangeMin = weightGoal - belowGoalPadding
                let rangeMax = max(highestValue + 2, rangeMin + 10) // Ensure at least 10lb range

                return rangeMin...rangeMax
            } else {
                // No goal line: Center on data with adaptive padding
                let padding = max(dataRange * 0.15, 3.0) // At least 3 lbs padding
                let rangeMin = floor(minWeight - padding)
                let rangeMax = ceil(maxWeight + padding)

                return rangeMin...rangeMax
            }

        default:
            // For other views: auto-scale with padding
            let padding = (maxWeight - minWeight) * 0.1 // 10% padding
            let rangeMin = max(0, minWeight - padding)
            let rangeMax = maxWeight + padding
            return rangeMin...rangeMax
        }
    }
}

// MARK: - Weight Statistics View

struct WeightStatsView: View {
    @ObservedObject var weightManager: WeightManager

    var body: some View {
        VStack(spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                WeightChangeStatCard(
                    title: "7-Day Change",
                    weightChange: weightManager.weightChange(since: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
                )

                WeightChangeStatCard(
                    title: "30-Day Change",
                    weightChange: weightManager.weightChange(since: Calendar.current.date(byAdding: .day, value: -30, to: Date())!)
                )

                StatCard(
                    title: "Average Weight",
                    value: weightManager.averageWeight
                        .map { String(format: "%.1f lbs", $0) } ?? "N/A",
                    icon: "chart.bar",
                    color: .orange
                )

                StatCard(
                    title: "Total Entries",
                    value: "\(weightManager.weightEntries.count)",
                    icon: "number",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct WeightChangeStatCard: View {
    let title: String
    let weightChange: Double?

    var body: some View {
        VStack(spacing: 8) {
            if let change = weightChange {
                // Arrow icon based on gain/loss
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.title2)
                    .foregroundColor(change >= 0 ? .red : .green)

                // Weight change value with arrow
                HStack(spacing: 4) {
                    Text(String(format: "%.1f lbs", abs(change)))
                        .font(.title3)
                        .fontWeight(.bold)
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundColor(change >= 0 ? .red : .green)
            } else {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.gray)

                Text("N/A")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Weight History List View

struct WeightHistoryListView: View {
    @ObservedObject var weightManager: WeightManager

    var body: some View {
        VStack(spacing: 12) {
            Text("Weight History")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(weightManager.weightEntries.prefix(10))) { entry in
                WeightHistoryRow(entry: entry, weightManager: weightManager)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            weightManager.deleteWeightEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                Divider()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct WeightHistoryRow: View {
    let entry: WeightEntry
    let weightManager: WeightManager
    @State private var showingDeleteAlert = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(entry.date, style: .date)
                        .font(.headline)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(entry.date, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Text(entry.source.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let bmi = entry.bmi {
                        Text("BMI: \(bmi, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let bodyFat = entry.bodyFat {
                        Text("BF: \(bodyFat, specifier: "%.1f")%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Text("\(entry.weight, specifier: "%.1f") lbs")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.86))
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive, action: { showingDeleteAlert = true }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Weight Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                weightManager.deleteWeightEntry(entry)
            }
        } message: {
            Text("Are you sure you want to delete this weight entry?")
        }
    }
}

// MARK: - View Modifier for Conditional X-Axis Scale

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

#Preview {
    WeightTrackingView()
}
