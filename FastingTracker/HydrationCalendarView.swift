import SwiftUI

// MARK: - Hydration Calendar View
// Extracted from HydrationHistoryView.swift for better code organization
// Following Apple MVVM patterns and SwiftUI component architecture

struct HydrationCalendarView: View {
    @ObservedObject var hydrationManager: HydrationManager
    @Binding var selectedDate: Date?
    @State private var displayedMonth: Date = Date()

    var body: some View {
        VStack(spacing: 16) {
            // Header with Month/Year
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.cyan)
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

                Text("\(hydrationManager.currentStreak) day\(hydrationManager.currentStreak == 1 ? "" : "s")")
                    .font(.headline)
                    .foregroundColor(.cyan)
            }

            // Calendar Grid (Current Month)
            VStack(spacing: 12) {
                // Weekday headers
                HStack(spacing: 8) {
                    ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
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
                    Text("No Data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
                            HydrationDayView(
                                date: date,
                                selectedDate: $selectedDate,
                                hydrationManager: hydrationManager
                            )
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

// MARK: - Hydration Day View

struct HydrationDayView: View {
    let date: Date
    @Binding var selectedDate: Date?
    @ObservedObject var hydrationManager: HydrationManager

    var body: some View {
        let calendar = Calendar.current
        let dayNumber = calendar.component(.day, from: date)
        let dayStatus = getDayStatus()

        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(dayStatus == .goalMet ? Color.orange.opacity(0.1) :
                      dayStatus == .partial ? Color.red.opacity(0.1) :
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
                    } else if dayStatus == .partial {
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
        }
    }

    private func isToday() -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func getDayStatus() -> DayStatus {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        // Today always shows as no data (day not complete yet)
        if calendar.isDateInToday(date) {
            return .noData
        }

        // Get drinks for this day
        let dayDrinks = hydrationManager.drinkEntries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: dayStart)
        }

        if dayDrinks.isEmpty {
            return .noData
        }

        let totalOunces = dayDrinks.reduce(0.0) { $0 + $1.amount }

        if totalOunces >= hydrationManager.dailyGoalOunces {
            return .goalMet
        } else {
            return .partial
        }
    }

    enum DayStatus {
        case goalMet
        case partial
        case noData
    }
}

// MARK: - Array Extension for Calendar Chunking

// MARK: - Preview

#Preview {
    HydrationCalendarView(
        hydrationManager: HydrationManager(),
        selectedDate: .constant(Date())
    )
    .padding()
}