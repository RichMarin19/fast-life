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
                // Request HealthKit authorization and sync if needed
                if weightManager.syncWithHealthKit && !healthKitManager.isAuthorized {
                    healthKitManager.requestAuthorization { success, error in
                        if success {
                            weightManager.syncFromHealthKit()
                        }
                    }
                } else if weightManager.syncWithHealthKit {
                    weightManager.syncFromHealthKit()
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

    // MARK: - Daily Averaged Entries for Week View

    /// For Week view: Groups entries by calendar day and averages weights for each day
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
        case .week:
            // Week view: Show daily averaged data (one point per day)
            return dailyAveragedEntries
        default:
            // Other views: Show all filtered data
            return filteredEntries
        }
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
                }
                .frame(height: 250)
                .chartXAxis {
                    // Dynamic X-axis for all views based on actual data points
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
                        // Week view: Show 10 slots dynamically based on weight range
                        AxisMarks(position: .leading, values: weekYAxisValues) { value in
                            AxisValueLabel()
                            AxisGridLine()
                            AxisTick()
                        }
                    } else {
                        AxisMarks(position: .leading)
                    }
                }
                .chartYScale(domain: yAxisDomain)
            } else {
                Text("No data for selected time range")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
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
            // Show day of month for last 7 days (e.g., "29", "30", "1")
            let calendar = Calendar.current
            let day = calendar.component(.day, from: date)
            return "\(day)"

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

    /// For Week view: Generates 11 evenly-spaced values for 10 slots
    private var weekYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound
        let step = (max - min) / 10.0 // 10 slots = 11 points

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
            // For Week view: Dynamic 30lb range with 10 slots based on actual weights
            // Find the midpoint of user's weight range
            let avgWeight = (minWeight + maxWeight) / 2

            // Create 30lb range centered on average weight, rounded to nearest whole number
            let rangeMin = round(avgWeight - 15)
            let rangeMax = round(avgWeight + 15)

            return rangeMin...rangeMax

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

#Preview {
    WeightTrackingView()
}
