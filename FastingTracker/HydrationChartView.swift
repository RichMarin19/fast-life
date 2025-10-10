import SwiftUI
import Charts

// MARK: - Hydration Chart View
// Extracted from HydrationHistoryView.swift for better code organization
// Following Apple MVVM patterns and SwiftUI Charts best practices

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

// MARK: - Preview

#Preview {
    HydrationChartView(
        hydrationManager: HydrationManager(),
        timeRange: .week
    )
    .padding()
}