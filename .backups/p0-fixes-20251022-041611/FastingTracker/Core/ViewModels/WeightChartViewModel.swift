import SwiftUI
import Combine

/// ViewModel for Weight Chart View
/// Industry Pattern: MVVM (Apple WWDC 2023 recommendation - extract logic from views > 400 LOC)
/// Extracts chart calculations, axis logic, and data filtering from WeightChartView
/// Reference: Phase 2 Complete - Following WeightControlCenterViewModel proven pattern
@MainActor
class WeightChartViewModel: ObservableObject {
    // MARK: - Dependencies (Injected)

    let weightManager: WeightManager

    // MARK: - Published State (was @State/@Binding in View)

    @Published var selectedTimeRange: WeightTimeRange
    @Published var showGoalLine: Bool
    @Published var weightGoal: Double
    @Published var selectedDate: Date?

    // MARK: - Initialization

    init(
        weightManager: WeightManager,
        selectedTimeRange: WeightTimeRange = .week,
        showGoalLine: Bool = false,
        weightGoal: Double = 0.0
    ) {
        self.weightManager = weightManager
        self.selectedTimeRange = selectedTimeRange
        self.showGoalLine = showGoalLine
        self.weightGoal = weightGoal
    }

    // MARK: - Computed Properties (Chart Data Calculations)

    /// Filters entries based on selected time range
    /// Day view: Current calendar day (12am to now)
    /// Other views: Rolling time window (last N days)
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

    /// For Week/Month/3Months/Year/All view: Groups entries by calendar day and averages weights
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
    /// Day view: Show ALL individual data points (no averaging)
    /// Week/Month/3Months/Year/All view: Show daily averaged data (one point per day)
    var chartData: [WeightEntry] {
        switch selectedTimeRange {
        case .day:
            // Day view: Show ALL individual data points (no averaging)
            return filteredEntries
        case .week, .month, .threeMonths, .year, .all:
            // Week/Month/3Months/Year/All view: Show daily averaged data (one point per day)
            return dailyAveragedEntries
        }
    }

    /// Find the weight entry closest to the selected date
    var selectedEntry: WeightEntry? {
        guard let selectedDate = selectedDate else { return nil }

        return chartData.min(by: { entry1, entry2 in
            abs(entry1.date.timeIntervalSince(selectedDate)) < abs(entry2.date.timeIntervalSince(selectedDate))
        })
    }

    /// Get current time range label for display (e.g., "September 2025" for Month view)
    var timeRangeLabel: String? {
        guard selectedTimeRange == .month else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    /// For Week/Month/3Months/Year/All view: Returns actual time if day has single entry, nil if multiple entries
    /// This ensures we show accurate weigh-in times or omit time for averaged data
    var selectedEntryDisplayTime: Date? {
        guard let selectedEntry = selectedEntry else { return nil }

        // For Day view (without averaging), always show the actual time
        guard selectedTimeRange == .week || selectedTimeRange == .month || selectedTimeRange == .threeMonths || selectedTimeRange == .year || selectedTimeRange == .all else {
            return selectedEntry.date
        }

        // For Week/Month/3Months/Year/All view: Check how many entries exist for the selected day
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: selectedEntry.date)

        let entriesForDay = filteredEntries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: selectedDay)
        }

        // If exactly one entry for this day, return its actual time
        // If multiple entries (averaged), return nil to hide time
        return entriesForDay.count == 1 ? entriesForDay.first?.date : nil
    }

    // MARK: - X-Axis Label Formatting
    // Following Apple WWDC 2022: Use narrow formats and intuitive time divisions

    func xAxisLabel(for date: Date) -> String {
        let calendar = Calendar.current

        switch selectedTimeRange {
        case .day:
            // Day view: Show hour (e.g., "12a", "3p", "6p")
            // Using narrow format for compact display
            let formatter = DateFormatter()
            formatter.dateFormat = "ha"
            return formatter.string(from: date).lowercased()

        case .week:
            // Week view: Show narrow month + day (e.g., "S 24", "O 1")
            // Following Apple's narrow month recommendation
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMMd")
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)

        case .month:
            // Month view: Show day of month (1, 5, 10, 15, 20, 25, 30)
            // Numbers are inherently intuitive for calendar dates
            let day = calendar.component(.day, from: date)
            return "\(day)"

        case .threeMonths:
            // 3 Months view: Show narrow month/day (e.g., "S 15", "O 1", "N 15")
            // Using first letter of month for compact display at this scale
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let fullString = formatter.string(from: date)
            // Extract first letter of month + day
            if let firstChar = fullString.first {
                let day = calendar.component(.day, from: date)
                return "\(firstChar) \(day)"
            }
            return fullString

        case .year:
            // Year view: Show narrow month (e.g., "J", "F", "M", "A"...)
            // Following Apple's .dateTime.month(.narrow) recommendation
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            let monthStr = formatter.string(from: date)
            return String(monthStr.prefix(1)) // First letter only

        case .all:
            // All view: Show narrow month/year (e.g., "J 23", "J 24")
            // Using first letter of month for maximum compactness
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yy"
            let fullString = formatter.string(from: date)
            if let firstChar = fullString.first {
                let year = calendar.component(.year, from: date) % 100 // Last 2 digits
                return "\(firstChar) \(year)"
            }
            return fullString
        }
    }

    // MARK: - X-Axis Domain Calculations

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

        case .threeMonths:
            guard !chartData.isEmpty else { return nil }

            // Extend domain by 2 days on each side for easier point selection
            let dates = chartData.map { $0.date }
            guard let minDate = dates.min(), let maxDate = dates.max() else { return nil }

            guard let rangeStart = calendar.date(byAdding: .day, value: -2, to: minDate),
                  let rangeEnd = calendar.date(byAdding: .day, value: 2, to: maxDate) else {
                return nil
            }

            return rangeStart...rangeEnd

        case .year:
            guard !chartData.isEmpty else { return nil }

            // Extend domain by 3 days on each side for easier point selection
            let dates = chartData.map { $0.date }
            guard let minDate = dates.min(), let maxDate = dates.max() else { return nil }

            guard let rangeStart = calendar.date(byAdding: .day, value: -3, to: minDate),
                  let rangeEnd = calendar.date(byAdding: .day, value: 3, to: maxDate) else {
                return nil
            }

            return rangeStart...rangeEnd

        case .all:
            guard !chartData.isEmpty else { return nil }

            // Extend domain by 5 days on each side for easier point selection
            let dates = chartData.map { $0.date }
            guard let minDate = dates.min(), let maxDate = dates.max() else { return nil }

            guard let rangeStart = calendar.date(byAdding: .day, value: -5, to: minDate),
                  let rangeEnd = calendar.date(byAdding: .day, value: 5, to: maxDate) else {
                return nil
            }

            return rangeStart...rangeEnd

        default:
            return nil
        }
    }

    // MARK: - X-Axis Values Generation

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

    /// Generates X-axis marks for 3 Months view: 12 marks over last 90 days (4 per month)
    var threeMonthsXAxisValues: [Date] {
        guard selectedTimeRange == .threeMonths else { return [] }
        guard !chartData.isEmpty else { return [] }

        let calendar = Calendar.current
        let dates = chartData.map { $0.date }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return [] }

        let daysBetween = calendar.dateComponents([.day], from: minDate, to: maxDate).day ?? 0
        let numberOfMarks = 12

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

    /// Generates X-axis marks for Year view: 12 marks (one per month) over last 365 days
    var yearXAxisValues: [Date] {
        guard selectedTimeRange == .year else { return [] }
        guard !chartData.isEmpty else { return [] }

        let calendar = Calendar.current
        let dates = chartData.map { $0.date }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return [] }

        let monthsBetween = calendar.dateComponents([.month], from: minDate, to: maxDate).month ?? 0
        let numberOfMarks = 12

        var values: [Date] = []
        let interval = Double(monthsBetween) / Double(numberOfMarks - 1)

        for i in 0..<numberOfMarks {
            let monthsToAdd = Int(round(Double(i) * interval))
            if let date = calendar.date(byAdding: .month, value: monthsToAdd, to: calendar.startOfDay(for: minDate)) {
                values.append(date)
            }
        }

        return values
    }

    /// Generates X-axis marks for All view: Adaptive based on total data span
    var allXAxisValues: [Date] {
        guard selectedTimeRange == .all else { return [] }
        guard !chartData.isEmpty else { return [] }

        let calendar = Calendar.current
        let dates = chartData.map { $0.date }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return [] }

        let monthsBetween = calendar.dateComponents([.month], from: minDate, to: maxDate).month ?? 0
        let numberOfMarks: Int
        let intervalComponent: Calendar.Component

        if monthsBetween <= 12 {
            numberOfMarks = min(monthsBetween + 1, 12)
            intervalComponent = .month
        } else if monthsBetween <= 36 {
            numberOfMarks = 12
            intervalComponent = .month
        } else {
            numberOfMarks = 12
            intervalComponent = .month
        }

        var values: [Date] = []
        let interval = Double(monthsBetween) / Double(numberOfMarks - 1)

        for i in 0..<numberOfMarks {
            let unitsToAdd = Int(round(Double(i) * interval))
            if let date = calendar.date(byAdding: intervalComponent, value: unitsToAdd, to: calendar.startOfDay(for: minDate)) {
                values.append(date)
            }
        }

        return values
    }

    // MARK: - Y-Axis Values Generation
    // Following Apple WWDC 2022: "approximately 4 horizontal grid lines" with "intuitive values"

    /// Calculates intuitive step size for Y-axis marks following Apple's guidelines
    /// Returns multiples of 1, 2, 5, 10, 20, 50 depending on range
    private func calculateIntuitiveStep(for range: Double, targetMarks: Int = 5) -> Double {
        // Calculate rough step size
        let roughStep = range / Double(targetMarks - 1)

        // Find the magnitude (power of 10)
        let magnitude = pow(10.0, floor(log10(roughStep)))

        // Normalize to 1-10 range
        let normalized = roughStep / magnitude

        // Round to intuitive values: 1, 2, 5, 10
        let intuitive: Double
        if normalized <= 1.5 {
            intuitive = 1.0
        } else if normalized <= 3.0 {
            intuitive = 2.0
        } else if normalized <= 7.0 {
            intuitive = 5.0
        } else {
            intuitive = 10.0
        }

        return intuitive * magnitude
    }

    var dayYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound

        // Day view: Use 2 lb steps (5 marks for 10 lb range)
        let step = 2.0
        let minRounded = floor(min / step) * step
        return stride(from: minRounded, through: max, by: step).map { $0 }
    }

    var weekYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound
        let range = max - min

        // Week view: Use intuitive steps, target 5 marks
        let step = calculateIntuitiveStep(for: range, targetMarks: 5)
        let minRounded = floor(min / step) * step
        return stride(from: minRounded, through: max, by: step).map { $0 }
    }

    var monthYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound
        let range = max - min

        // Month view: Use intuitive steps, target 5 marks
        let step = calculateIntuitiveStep(for: range, targetMarks: 5)
        let minRounded = floor(min / step) * step
        return stride(from: minRounded, through: max, by: step).map { $0 }
    }

    var threeMonthsYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound
        let range = max - min

        // 3 Months view: Use intuitive steps, target 5 marks
        let step = calculateIntuitiveStep(for: range, targetMarks: 5)
        let minRounded = floor(min / step) * step
        return stride(from: minRounded, through: max, by: step).map { $0 }
    }

    var yearYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound
        let range = max - min

        // Year view: Use intuitive steps, target 5 marks
        let step = calculateIntuitiveStep(for: range, targetMarks: 5)
        let minRounded = floor(min / step) * step
        return stride(from: minRounded, through: max, by: step).map { $0 }
    }

    var allYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound
        let range = max - min

        // All view: Use intuitive steps, target 5 marks
        let step = calculateIntuitiveStep(for: range, targetMarks: 5)
        let minRounded = floor(min / step) * step
        return stride(from: minRounded, through: max, by: step).map { $0 }
    }

    // MARK: - Y-Axis Domain Calculation

    var yAxisDomain: ClosedRange<Double> {
        guard !chartData.isEmpty else {
            return 0...200 // Default range
        }

        let weights = chartData.map { $0.weight }
        let minWeight = weights.min() ?? 0
        let maxWeight = weights.max() ?? 200

        switch selectedTimeRange {
        case .day:
            let avgWeight = weights.reduce(0.0, +) / Double(weights.count)
            let rangeMin = round(avgWeight) - 5
            let rangeMax = round(avgWeight) + 5
            return rangeMin...rangeMax

        case .week:
            let avgWeight = weights.reduce(0.0, +) / Double(weights.count)
            let centerWeight = round(avgWeight)
            let defaultRangeMin = centerWeight - 2.5
            let defaultRangeMax = centerWeight + 2.5
            let dataRange = maxWeight - minWeight

            if dataRange <= 5 {
                return defaultRangeMin...defaultRangeMax
            } else {
                let padding = dataRange * 0.1
                let rangeMin = floor(minWeight - padding)
                let rangeMax = ceil(maxWeight + padding)
                return rangeMin...rangeMax
            }

        case .month:
            let dataRange = maxWeight - minWeight

            if showGoalLine {
                let highestValue = max(maxWeight, weightGoal)
                let belowGoalPadding: Double
                if dataRange < 5 {
                    belowGoalPadding = 5.0
                } else if dataRange < 10 {
                    belowGoalPadding = 10.0
                } else {
                    belowGoalPadding = 20.0
                }
                let rangeMin = weightGoal - belowGoalPadding
                let rangeMax = max(highestValue + 2, rangeMin + 10)
                return rangeMin...rangeMax
            } else {
                let padding = max(dataRange * 0.15, 3.0)
                let rangeMin = floor(minWeight - padding)
                let rangeMax = ceil(maxWeight + padding)
                return rangeMin...rangeMax
            }

        case .threeMonths:
            let dataRange = maxWeight - minWeight

            if showGoalLine {
                let highestValue = max(maxWeight, weightGoal)
                let belowGoalPadding: Double
                if dataRange < 5 {
                    belowGoalPadding = 8.0
                } else if dataRange < 10 {
                    belowGoalPadding = 15.0
                } else {
                    belowGoalPadding = 25.0
                }
                let rangeMin = weightGoal - belowGoalPadding
                let rangeMax = max(highestValue + 3, rangeMin + 15)
                return rangeMin...rangeMax
            } else {
                let padding = max(dataRange * 0.2, 5.0)
                let rangeMin = floor(minWeight - padding)
                let rangeMax = ceil(maxWeight + padding)
                return rangeMin...rangeMax
            }

        case .year:
            let dataRange = maxWeight - minWeight

            if showGoalLine {
                let highestValue = max(maxWeight, weightGoal)
                let belowGoalPadding: Double
                if dataRange < 10 {
                    belowGoalPadding = 15.0
                } else if dataRange < 20 {
                    belowGoalPadding = 25.0
                } else {
                    belowGoalPadding = 35.0
                }
                let rangeMin = weightGoal - belowGoalPadding
                let rangeMax = max(highestValue + 5, rangeMin + 20)
                return rangeMin...rangeMax
            } else {
                let padding = max(dataRange * 0.25, 8.0)
                let rangeMin = floor(minWeight - padding)
                let rangeMax = ceil(maxWeight + padding)
                return rangeMin...rangeMax
            }

        case .all:
            let dataRange = maxWeight - minWeight

            if showGoalLine {
                let highestValue = max(maxWeight, weightGoal)
                let belowGoalPadding: Double
                if dataRange < 15 {
                    belowGoalPadding = 20.0
                } else if dataRange < 30 {
                    belowGoalPadding = 30.0
                } else {
                    belowGoalPadding = 40.0
                }
                let rangeMin = weightGoal - belowGoalPadding
                let rangeMax = max(highestValue + 5, rangeMin + 25)
                return rangeMin...rangeMax
            } else {
                let padding = max(dataRange * 0.3, 10.0)
                let rangeMin = floor(minWeight - padding)
                let rangeMax = ceil(maxWeight + padding)
                return rangeMin...rangeMax
            }
        }
    }
}
