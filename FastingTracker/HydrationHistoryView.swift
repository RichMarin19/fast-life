import Charts
import SwiftUI

// MARK: - Hydration History View

// Refactored from 1,087 → ~140 lines (87% reduction)
// Following Apple MVVM patterns and Phase 3a component extraction lessons

struct HydrationHistoryView: View {
    @ObservedObject var hydrationManager: HydrationManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedDate: Date?

    private var selectedIdentifiableDate: Binding<IdentifiableDate?> {
        Binding(
            get: { self.selectedDate.map { IdentifiableDate(date: $0) } },
            set: { self.selectedDate = $0?.date }
        )
    }

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
                // Calendar View
                HydrationCalendarView(
                    hydrationManager: self.hydrationManager,
                    selectedDate: self.$selectedDate
                )
                .padding(.horizontal)
                .padding(.top)

                // Time Range Picker
                Picker("Time Range", selection: self.$selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Hydration Chart
                HydrationChartView(
                    hydrationManager: self.hydrationManager,
                    timeRange: self.selectedTimeRange
                )
                .padding()

                // Daily Average Stats
                HydrationStatsView(
                    hydrationManager: self.hydrationManager,
                    timeRange: self.selectedTimeRange
                )
                .padding()

                // Drink Type Breakdown
                DrinkTypeBreakdownView(
                    hydrationManager: self.hydrationManager,
                    timeRange: self.selectedTimeRange
                )
                .padding()

                // Daily History List
                VStack(spacing: 0) {
                    Text("Daily Log")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom, 10)

                    ForEach(self.groupedDailyData(), id: \.date) { dayData in
                        DailyHydrationRowView(
                            date: dayData.date,
                            totalOunces: dayData.total,
                            breakdown: dayData.breakdown,
                            goalOunces: self.hydrationManager.dailyGoalOunces
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
        .sheet(item: self.selectedIdentifiableDate) { identifiableDate in
            AddEditHydrationView(date: identifiableDate.date, hydrationManager: self.hydrationManager)
        }
    }

    // MARK: - Data Grouping

    private func groupedDailyData() -> [(date: Date, total: Double, breakdown: [DrinkType: Double])] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -self.selectedTimeRange.days, to: Date()) ?? Date()

        // Filter entries within time range
        let filteredEntries = self.hydrationManager.drinkEntries.filter { $0.date >= cutoffDate }

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

// MARK: - Preview

#Preview {
    NavigationStack {
        HydrationHistoryView(hydrationManager: HydrationManager())
    }
}
