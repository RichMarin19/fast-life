import SwiftUI
import Charts

struct HydrationHistoryView: View {
    @ObservedObject var hydrationManager: HydrationManager
    @State private var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case year = "Year"
        case all = "All"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            case .all: return 10000 // Large number for "all"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Range Picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)

                // Hydration Chart
                HydrationChartView(
                    hydrationManager: hydrationManager,
                    timeRange: selectedTimeRange
                )
                .padding()

                // Daily Average Stats
                HydrationStatsView(
                    hydrationManager: hydrationManager,
                    timeRange: selectedTimeRange
                )
                .padding()

                // Drink Type Breakdown
                DrinkTypeBreakdownView(
                    hydrationManager: hydrationManager,
                    timeRange: selectedTimeRange
                )
                .padding()

                // Daily History List
                VStack(spacing: 0) {
                    Text("Daily Log")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom, 10)

                    ForEach(groupedDailyData(), id: \.date) { dayData in
                        DailyHydrationRowView(
                            date: dayData.date,
                            totalOunces: dayData.total,
                            breakdown: dayData.breakdown,
                            goalOunces: hydrationManager.dailyGoalOunces
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        Divider()
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Hydration History")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Data Grouping

    private func groupedDailyData() -> [(date: Date, total: Double, breakdown: [DrinkType: Double])] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()

        // Filter entries within time range
        let filteredEntries = hydrationManager.drinkEntries.filter { $0.date >= cutoffDate }

        // Group by day
        var dailyData: [Date: (total: Double, breakdown: [DrinkType: Double])] = [:]

        for entry in filteredEntries {
            let dayStart = calendar.startOfDay(for: entry.date)

            if dailyData[dayStart] == nil {
                dailyData[dayStart] = (total: 0.0, breakdown: [:])
            }

            dailyData[dayStart]?.total += entry.amount
            dailyData[dayStart]?.breakdown[entry.type, default: 0.0] += entry.amount
        }

        // Convert to sorted array (most recent first)
        return dailyData.map { (date: $0.key, total: $0.value.total, breakdown: $0.value.breakdown) }
            .sorted { $0.date > $1.date }
    }
}

// MARK: - Hydration Chart View

struct HydrationChartView: View {
    @ObservedObject var hydrationManager: HydrationManager
    let timeRange: HydrationHistoryView.TimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Hydration")
                .font(.headline)

            Chart {
                ForEach(chartData(), id: \.date) { data in
                    // Water bar (stacked bottom)
                    BarMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Water", data.water)
                    )
                    .foregroundStyle(Color.cyan)

                    // Coffee bar (stacked middle)
                    BarMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Coffee", data.coffee)
                    )
                    .foregroundStyle(Color.brown)

                    // Tea bar (stacked top)
                    BarMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Tea", data.tea)
                    )
                    .foregroundStyle(Color.green)

                    // Goal line
                    RuleMark(y: .value("Goal", hydrationManager.dailyGoalOunces))
                        .foregroundStyle(Color.orange.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
            }
            .chartXAxis {
                AxisMarks(values: getXAxisValues()) { value in
                    AxisGridLine()
                    AxisTick()
                    if timeRange == .year || timeRange == .all {
                        // Show month abbreviations for year/all view
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    } else if timeRange == .month || timeRange == .threeMonths {
                        // Show day numbers for month/3-month view
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                let day = Calendar.current.component(.day, from: date)
                                Text("\(day)")
                                    .font(.caption2)
                            }
                        }
                    } else {
                        // Show month and day for week view
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func getXAxisValues() -> AxisMarkValues {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
        let daysDifference = calendar.dateComponents([.day], from: cutoffDate, to: Date()).day ?? 1

        switch timeRange {
        case .week:
            // Show every day (7 days)
            return .stride(by: .day, count: 1)

        case .month:
            // Show approximately 12 date labels across the month (every 2-3 days)
            let stride = max(2, (daysDifference + 11) / 12)
            return .stride(by: .day, count: stride)

        case .threeMonths:
            // Show approximately 12-15 labels (every 6-7 days)
            let stride = max(6, daysDifference / 12)
            return .stride(by: .day, count: stride)

        case .year:
            // Show each month (12 labels)
            return .stride(by: .month, count: 1)

        case .all:
            // Calculate stride to show 10-12 labels total
            if daysDifference > 365 {
                // More than a year - show months
                let months = daysDifference / 30
                let stride = max(1, months / 10)
                return .stride(by: .month, count: stride)
            } else {
                // Less than a year - show every ~30 days
                let stride = max(30, daysDifference / 10)
                return .stride(by: .day, count: stride)
            }
        }
    }

    private func chartData() -> [(date: Date, water: Double, coffee: Double, tea: Double)] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()

        // Create daily buckets
        var dailyData: [Date: (water: Double, coffee: Double, tea: Double)] = [:]

        // Fill in data
        for entry in hydrationManager.drinkEntries.filter({ $0.date >= cutoffDate }) {
            let dayStart = calendar.startOfDay(for: entry.date)

            if dailyData[dayStart] == nil {
                dailyData[dayStart] = (water: 0, coffee: 0, tea: 0)
            }

            switch entry.type {
            case .water:
                dailyData[dayStart]?.water += entry.amount
            case .coffee:
                dailyData[dayStart]?.coffee += entry.amount
            case .tea:
                dailyData[dayStart]?.tea += entry.amount
            }
        }

        // Convert to array and sort by date
        return dailyData.map { (date: $0.key, water: $0.value.water, coffee: $0.value.coffee, tea: $0.value.tea) }
            .sorted { $0.date < $1.date }
    }
}

// MARK: - Hydration Stats View

struct HydrationStatsView: View {
    @ObservedObject var hydrationManager: HydrationManager
    let timeRange: HydrationHistoryView.TimeRange

    var body: some View {
        VStack(spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                HydrationStatCard(
                    title: "Avg Daily",
                    value: "\(Int(averageDaily())) oz",
                    icon: "chart.bar.fill",
                    color: .cyan
                )

                HydrationStatCard(
                    title: "Total",
                    value: "\(Int(totalOunces())) oz",
                    icon: "drop.fill",
                    color: .blue
                )

                HydrationStatCard(
                    title: "Goal Met",
                    value: "\(goalMetDays())",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func averageDaily() -> Double {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
        let entries = hydrationManager.drinkEntries.filter { $0.date >= cutoffDate }

        if entries.isEmpty { return 0.0 }

        let total = entries.reduce(0.0) { $0 + $1.amount }
        let days = Set(entries.map { calendar.startOfDay(for: $0.date) }).count

        return total / Double(max(days, 1))
    }

    private func totalOunces() -> Double {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
        return hydrationManager.drinkEntries
            .filter { $0.date >= cutoffDate }
            .reduce(0.0) { $0 + $1.amount }
    }

    private func goalMetDays() -> Int {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
        let entries = hydrationManager.drinkEntries.filter { $0.date >= cutoffDate }

        // Group by day and count days that met goal
        var dailyTotals: [Date: Double] = [:]
        for entry in entries {
            let dayStart = calendar.startOfDay(for: entry.date)
            dailyTotals[dayStart, default: 0.0] += entry.amount
        }

        return dailyTotals.values.filter { $0 >= hydrationManager.dailyGoalOunces }.count
    }
}

// MARK: - Hydration Stat Card Component

struct HydrationStatCard: View {
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
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Drink Type Breakdown View

struct DrinkTypeBreakdownView: View {
    @ObservedObject var hydrationManager: HydrationManager
    let timeRange: HydrationHistoryView.TimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drink Breakdown")
                .font(.headline)

            ForEach(DrinkType.allCases, id: \.self) { type in
                HStack {
                    Image(systemName: type.icon)
                        .foregroundColor(colorForType(type))
                        .frame(width: 24)

                    Text(type.rawValue)
                        .font(.subheadline)

                    Spacer()

                    Text("\(Int(totalForType(type))) oz")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("(\(percentageForType(type))%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func colorForType(_ type: DrinkType) -> Color {
        switch type {
        case .water: return .cyan
        case .coffee: return .brown
        case .tea: return .green
        }
    }

    private func totalForType(_ type: DrinkType) -> Double {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()

        return hydrationManager.drinkEntries
            .filter { $0.date >= cutoffDate && $0.type == type }
            .reduce(0.0) { $0 + $1.amount }
    }

    private func percentageForType(_ type: DrinkType) -> Int {
        let total = totalForType(type)
        let allTotal = DrinkType.allCases.reduce(0.0) { $0 + totalForType($1) }

        guard allTotal > 0 else { return 0 }
        return Int((total / allTotal) * 100)
    }
}

// MARK: - Daily Hydration Row View

struct DailyHydrationRowView: View {
    let date: Date
    let totalOunces: Double
    let breakdown: [DrinkType: Double]
    let goalOunces: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(date))
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if let water = breakdown[.water], water > 0 {
                        DrinkBadge(type: .water, amount: water)
                    }
                    if let coffee = breakdown[.coffee], coffee > 0 {
                        DrinkBadge(type: .coffee, amount: coffee)
                    }
                    if let tea = breakdown[.tea], tea > 0 {
                        DrinkBadge(type: .tea, amount: tea)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(totalOunces)) oz")
                    .font(.headline)
                    .fontWeight(.bold)

                if totalOunces >= goalOunces {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Goal Met")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("\(Int(goalOunces - totalOunces)) oz short")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Drink Badge Component

struct DrinkBadge: View {
    let type: DrinkType
    let amount: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.caption2)
            Text("\(Int(amount))")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(colorForType(type))
        .cornerRadius(6)
    }

    private func colorForType(_ type: DrinkType) -> Color {
        switch type {
        case .water: return .cyan
        case .coffee: return .brown
        case .tea: return .green
        }
    }
}

#Preview {
    NavigationStack {
        HydrationHistoryView(hydrationManager: HydrationManager())
    }
}
