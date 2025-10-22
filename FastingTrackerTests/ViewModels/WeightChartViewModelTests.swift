import XCTest
import Combine
@testable import Fast_lIFe

/// Tests for WeightChartViewModel
/// Industry Pattern: Unit tests following Apple WWDC 2017 "Testing in Xcode"
/// Reference: WeightManagerTests proven pattern (Given-When-Then)
@MainActor
final class WeightChartViewModelTests: XCTestCase {
    var sut: WeightChartViewModel!
    var mockWeightManager: MockWeightManager!

    override func setUp() {
        super.setUp()
        mockWeightManager = MockWeightManager()
        sut = WeightChartViewModel(
            weightManager: mockWeightManager,
            selectedTimeRange: .week,
            showGoalLine: false,
            weightGoal: 180.0
        )
    }

    override func tearDown() {
        sut = nil
        mockWeightManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_SetsDefaultValues() {
        // Given/When: ViewModel initialized in setUp with defaults

        // Then
        XCTAssertEqual(sut.selectedTimeRange, .week)
        XCTAssertFalse(sut.showGoalLine)
        XCTAssertEqual(sut.weightGoal, 180.0)
        XCTAssertNil(sut.selectedDate)
    }

    func testInit_StoresWeightManagerReference() {
        // Given/When: ViewModel initialized in setUp

        // Then: Should have reference to injected weightManager
        XCTAssertTrue(sut.weightManager === mockWeightManager)
    }

    // MARK: - Chart Data Filtering Tests

    func testFilteredEntries_DayView_ReturnsCurrentDayOnly() {
        // Given: Multiple entries across different days
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!

        let todayEntry = WeightEntry(date: today, weight: 150.0, source: .manual)
        let yesterdayEntry = WeightEntry(date: yesterday, weight: 151.0, source: .manual)
        let oldEntry = WeightEntry(date: twoDaysAgo, weight: 152.0, source: .manual)

        mockWeightManager.setTestData([todayEntry, yesterdayEntry, oldEntry])

        // When: Set to day view
        sut.selectedTimeRange = .day

        // Then: Should only return today's entries (from 12am onwards)
        let filtered = sut.filteredEntries
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.weight, 150.0)
    }

    func testFilteredEntries_WeekView_Returns7Days() {
        // Given: Entries spanning 10 days
        let calendar = Calendar.current
        var entries: [WeightEntry] = []

        for daysAgo in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            entries.append(WeightEntry(date: date, weight: 150.0 + Double(daysAgo), source: .manual))
        }

        mockWeightManager.setTestData(entries)

        // When: Set to week view
        sut.selectedTimeRange = .week

        // Then: Should only return last 7 days
        let filtered = sut.filteredEntries
        XCTAssertEqual(filtered.count, 7)
    }

    func testFilteredEntries_AllView_ReturnsAllEntries() {
        // Given: 20 entries spanning various dates
        let calendar = Calendar.current
        var entries: [WeightEntry] = []

        for daysAgo in 0..<20 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            entries.append(WeightEntry(date: date, weight: 150.0, source: .manual))
        }

        mockWeightManager.setTestData(entries)

        // When: Set to all view
        sut.selectedTimeRange = .all

        // Then: Should return all entries
        let filtered = sut.filteredEntries
        XCTAssertEqual(filtered.count, 20)
    }

    // MARK: - Chart Data Processing Tests

    func testChartData_DayView_ReturnsRawEntries() {
        // Given: Multiple entries within today
        let today = Date()
        let entry1 = WeightEntry(date: today, weight: 150.0, source: .manual)
        let entry2 = WeightEntry(date: today.addingTimeInterval(-3600), weight: 150.5, source: .manual)

        mockWeightManager.setTestData([entry1, entry2])

        // When: Set to day view
        sut.selectedTimeRange = .day

        // Then: Should return raw entries (no averaging)
        let chartData = sut.chartData
        XCTAssertEqual(chartData.count, 2)
    }

    func testChartData_WeekView_AveragesEntriesByDay() {
        // Given: Multiple entries on same day
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let entry1 = WeightEntry(date: today.addingTimeInterval(3600), weight: 150.0, source: .manual) // 1am
        let entry2 = WeightEntry(date: today.addingTimeInterval(7200), weight: 152.0, source: .manual) // 2am

        mockWeightManager.setTestData([entry1, entry2])

        // When: Set to week view
        sut.selectedTimeRange = .week

        // Then: Should return single averaged entry (151.0)
        let chartData = sut.chartData
        XCTAssertEqual(chartData.count, 1)
        XCTAssertEqual(chartData.first?.weight, 151.0)
    }

    func testDailyAveragedEntries_CalculatesCorrectAverage() {
        // Given: 3 entries on same day with different weights
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let entry1 = WeightEntry(date: today.addingTimeInterval(3600), weight: 150.0, source: .manual)
        let entry2 = WeightEntry(date: today.addingTimeInterval(7200), weight: 153.0, source: .manual)
        let entry3 = WeightEntry(date: today.addingTimeInterval(10800), weight: 156.0, source: .manual)

        mockWeightManager.setTestData([entry1, entry2, entry3])
        sut.selectedTimeRange = .week

        // When: Get averaged entries
        let averaged = sut.dailyAveragedEntries

        // Then: Should average to 153.0 (150+153+156)/3
        XCTAssertEqual(averaged.count, 1)
        XCTAssertEqual(averaged.first?.weight, 153.0)
    }

    // MARK: - Selected Entry Tests

    func testSelectedEntry_NilWhenNoDateSelected() {
        // Given: Chart data exists
        let entry = WeightEntry(date: Date(), weight: 150.0, source: .manual)
        mockWeightManager.setTestData([entry])

        // When: No date selected
        sut.selectedDate = nil

        // Then
        XCTAssertNil(sut.selectedEntry)
    }

    func testSelectedEntry_ReturnsClosestEntry() {
        // Given: Multiple entries
        let calendar = Calendar.current
        let baseDate = Date()

        let entry1 = WeightEntry(date: calendar.date(byAdding: .hour, value: -2, to: baseDate)!, weight: 150.0, source: .manual)
        let entry2 = WeightEntry(date: calendar.date(byAdding: .hour, value: -1, to: baseDate)!, weight: 151.0, source: .manual)
        let entry3 = WeightEntry(date: baseDate, weight: 152.0, source: .manual)

        mockWeightManager.setTestData([entry1, entry2, entry3])
        sut.selectedTimeRange = .day

        // When: Select date closest to entry2
        sut.selectedDate = calendar.date(byAdding: .minute, value: -65, to: baseDate)

        // Then: Should return entry2 (151.0)
        XCTAssertEqual(sut.selectedEntry?.weight, 151.0)
    }

    // MARK: - Time Range Label Tests

    func testTimeRangeLabel_MonthView_ReturnsCurrentMonth() {
        // Given: Month view
        sut.selectedTimeRange = .month

        // When: Get time range label
        let label = sut.timeRangeLabel

        // Then: Should return current month and year
        XCTAssertNotNil(label)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let expectedLabel = formatter.string(from: Date())
        XCTAssertEqual(label, expectedLabel)
    }

    func testTimeRangeLabel_NonMonthView_ReturnsNil() {
        // Given: Week view
        sut.selectedTimeRange = .week

        // When: Get time range label
        let label = sut.timeRangeLabel

        // Then
        XCTAssertNil(label)
    }

    // MARK: - X-Axis Label Tests

    func testXAxisLabel_DayView_ReturnsHourFormat() {
        // Given: Day view and specific time
        sut.selectedTimeRange = .day
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!

        // When: Get x-axis label
        let label = sut.xAxisLabel(for: date)

        // Then: Should return "2p" (hour format)
        XCTAssertEqual(label, "2p")
    }

    func testXAxisLabel_MonthView_ReturnsDayNumber() {
        // Given: Month view and date with day 15
        sut.selectedTimeRange = .month
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2025, month: 10, day: 15))!

        // When: Get x-axis label
        let label = sut.xAxisLabel(for: date)

        // Then: Should return "15"
        XCTAssertEqual(label, "15")
    }

    func testXAxisLabel_YearView_ReturnsMonthLetter() {
        // Given: Year view and January date
        sut.selectedTimeRange = .year
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!

        // When: Get x-axis label
        let label = sut.xAxisLabel(for: date)

        // Then: Should return "J" (first letter of January)
        XCTAssertEqual(label, "J")
    }

    // MARK: - Y-Axis Domain Tests

    func testYAxisDomain_EmptyData_ReturnsDefaultRange() {
        // Given: No weight entries
        mockWeightManager.setTestData([])

        // When: Get y-axis domain
        let domain = sut.yAxisDomain

        // Then: Should return default 0...200
        XCTAssertEqual(domain.lowerBound, 0)
        XCTAssertEqual(domain.upperBound, 200)
    }

    func testYAxisDomain_DayView_ReturnsTenPoundRange() {
        // Given: Single entry at 150 lbs
        let entry = WeightEntry(date: Date(), weight: 150.0, source: .manual)
        mockWeightManager.setTestData([entry])
        sut.selectedTimeRange = .day

        // When: Get y-axis domain
        let domain = sut.yAxisDomain

        // Then: Should return ±5 pounds (145...155)
        XCTAssertEqual(domain.lowerBound, 145.0)
        XCTAssertEqual(domain.upperBound, 155.0)
    }

    func testYAxisDomain_WithGoalLine_IncludesGoal() {
        // Given: Weight entry at 150 lbs, goal at 140 lbs
        let entry = WeightEntry(date: Date(), weight: 150.0, source: .manual)
        mockWeightManager.setTestData([entry])

        sut.selectedTimeRange = .month
        sut.showGoalLine = true
        sut.weightGoal = 140.0

        // When: Get y-axis domain
        let domain = sut.yAxisDomain

        // Then: Domain should include goal with padding
        XCTAssertLessThanOrEqual(domain.lowerBound, 140.0)
        XCTAssertGreaterThanOrEqual(domain.upperBound, 150.0)
    }

    // MARK: - Y-Axis Values Tests (Smart Step Algorithm)

    func testCalculateIntuitiveStep_ReturnsMultipleOf1_2_5_10() {
        // Given: Week view with narrow range (3 lbs)
        let entry1 = WeightEntry(date: Date(), weight: 150.0, source: .manual)
        let entry2 = WeightEntry(date: Date().addingTimeInterval(-86400), weight: 153.0, source: .manual)
        mockWeightManager.setTestData([entry1, entry2])
        sut.selectedTimeRange = .week

        // When: Get Y-axis values
        let values = sut.weekYAxisValues

        // Then: Values should be intuitive (multiples of 1, 2, 5, 10)
        XCTAssertGreaterThan(values.count, 0)

        // Check that step size is intuitive
        if values.count > 1 {
            let step = values[1] - values[0]
            let validSteps = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0]
            XCTAssertTrue(validSteps.contains(step), "Step \(step) is not an intuitive value")
        }
    }

    func testDayYAxisValues_UsesFixedTwoLbSteps() {
        // Given: Day view with entries
        let entry = WeightEntry(date: Date(), weight: 150.0, source: .manual)
        mockWeightManager.setTestData([entry])
        sut.selectedTimeRange = .day

        // When: Get day Y-axis values
        let values = sut.dayYAxisValues

        // Then: Should use 2 lb steps
        XCTAssertGreaterThan(values.count, 0)
        if values.count > 1 {
            let step = values[1] - values[0]
            XCTAssertEqual(step, 2.0, accuracy: 0.01)
        }
    }

    func testYAxisValues_TargetsFiveMarks() {
        // Given: Month view with moderate range
        let entry1 = WeightEntry(date: Date(), weight: 150.0, source: .manual)
        let entry2 = WeightEntry(date: Date().addingTimeInterval(-86400), weight: 160.0, source: .manual)
        mockWeightManager.setTestData([entry1, entry2])
        sut.selectedTimeRange = .month

        // When: Get Y-axis values
        let values = sut.monthYAxisValues

        // Then: Should target approximately 4-5 marks per Apple WWDC 2022
        XCTAssertGreaterThanOrEqual(values.count, 4)
        XCTAssertLessThanOrEqual(values.count, 6)
    }

    // MARK: - X-Axis Domain Tests

    func testXAxisDomain_DayView_Returns6amToMidnight() {
        // Given: Day view with entry at 10am
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tenAM = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!

        let entry = WeightEntry(date: tenAM, weight: 150.0, source: .manual)
        mockWeightManager.setTestData([entry])
        sut.selectedTimeRange = .day

        // When: Get x-axis domain
        let domain = sut.xAxisDomain

        // Then: Should start at 6am and end at midnight next day
        XCTAssertNotNil(domain)
        if let domain = domain {
            let startHour = calendar.component(.hour, from: domain.lowerBound)
            XCTAssertEqual(startHour, 6)

            let endDay = calendar.component(.day, from: domain.upperBound)
            let tomorrowDay = calendar.component(.day, from: calendar.date(byAdding: .day, value: 1, to: today)!)
            XCTAssertEqual(endDay, tomorrowDay)
        }
    }

    func testXAxisDomain_MonthView_ExtendsByOneDay() {
        // Given: Month view with single entry
        let today = Date()
        let entry = WeightEntry(date: today, weight: 150.0, source: .manual)
        mockWeightManager.setTestData([entry])
        sut.selectedTimeRange = .month

        // When: Get x-axis domain
        let domain = sut.xAxisDomain

        // Then: Should extend 1 day on each side
        XCTAssertNotNil(domain)
        if let domain = domain {
            let calendar = Calendar.current
            let daysBefore = calendar.dateComponents([.day], from: domain.lowerBound, to: today).day ?? 0
            let daysAfter = calendar.dateComponents([.day], from: today, to: domain.upperBound).day ?? 0

            XCTAssertEqual(daysBefore, 1)
            XCTAssertEqual(daysAfter, 1)
        }
    }

    // MARK: - X-Axis Values Generation Tests

    func testDayXAxisValues_GeneratesThreeHourIncrements() {
        // Given: Day view
        let entry = WeightEntry(date: Date(), weight: 150.0, source: .manual)
        mockWeightManager.setTestData([entry])
        sut.selectedTimeRange = .day

        // When: Get day X-axis values
        let values = sut.dayXAxisValues

        // Then: Should have values every 3 hours from 6am
        XCTAssertGreaterThan(values.count, 0)

        if values.count > 1 {
            let calendar = Calendar.current
            let hourDiff = calendar.dateComponents([.hour], from: values[0], to: values[1]).hour ?? 0
            XCTAssertEqual(hourDiff, 3)
        }
    }

    func testWeekXAxisValues_GeneratesSevenDays() {
        // Given: Week view
        let entry = WeightEntry(date: Date(), weight: 150.0, source: .manual)
        mockWeightManager.setTestData([entry])
        sut.selectedTimeRange = .week

        // When: Get week X-axis values
        let values = sut.weekXAxisValues

        // Then: Should have exactly 7 values
        XCTAssertEqual(values.count, 7)
    }

    func testMonthXAxisValues_GeneratesAdaptiveMarks() {
        // Given: Month view with 30 days of data
        let calendar = Calendar.current
        var entries: [WeightEntry] = []

        for daysAgo in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            entries.append(WeightEntry(date: date, weight: 150.0, source: .manual))
        }

        mockWeightManager.setTestData(entries)
        sut.selectedTimeRange = .month

        // When: Get month X-axis values
        let values = sut.monthXAxisValues

        // Then: Should have 6-10 marks
        XCTAssertGreaterThanOrEqual(values.count, 6)
        XCTAssertLessThanOrEqual(values.count, 10)
    }

    func testYearXAxisValues_GeneratesTwelveMarks() {
        // Given: Year view with 365 days of data
        let calendar = Calendar.current
        var entries: [WeightEntry] = []

        for daysAgo in stride(from: 0, to: 365, by: 30) {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            entries.append(WeightEntry(date: date, weight: 150.0, source: .manual))
        }

        mockWeightManager.setTestData(entries)
        sut.selectedTimeRange = .year

        // When: Get year X-axis values
        let values = sut.yearXAxisValues

        // Then: Should have exactly 12 marks (one per month)
        XCTAssertEqual(values.count, 12)
    }

    // MARK: - Selected Entry Display Time Tests

    func testSelectedEntryDisplayTime_DayView_AlwaysShowsTime() {
        // Given: Day view with selected entry
        let today = Date()
        let entry = WeightEntry(date: today, weight: 150.0, source: .manual)
        mockWeightManager.setTestData([entry])

        sut.selectedTimeRange = .day
        sut.selectedDate = today

        // When: Get display time
        let displayTime = sut.selectedEntryDisplayTime

        // Then: Should return actual time
        XCTAssertNotNil(displayTime)
    }

    func testSelectedEntryDisplayTime_WeekView_ShowsTimeForSingleEntry() {
        // Given: Week view with single entry on a day
        let today = Date()
        let entry = WeightEntry(date: today, weight: 150.0, source: .manual)
        mockWeightManager.setTestData([entry])

        sut.selectedTimeRange = .week
        sut.selectedDate = today

        // When: Get display time
        let displayTime = sut.selectedEntryDisplayTime

        // Then: Should return actual time (single entry = not averaged)
        XCTAssertNotNil(displayTime)
    }

    func testSelectedEntryDisplayTime_WeekView_HidesTimeForMultipleEntries() {
        // Given: Week view with multiple entries on same day
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let entry1 = WeightEntry(date: today.addingTimeInterval(3600), weight: 150.0, source: .manual)
        let entry2 = WeightEntry(date: today.addingTimeInterval(7200), weight: 151.0, source: .manual)

        mockWeightManager.setTestData([entry1, entry2])

        sut.selectedTimeRange = .week
        sut.selectedDate = today

        // When: Get display time
        let displayTime = sut.selectedEntryDisplayTime

        // Then: Should return nil (multiple entries = averaged)
        XCTAssertNil(displayTime)
    }

    // MARK: - State Management Tests

    func testPublishedProperties_TriggerUpdates() {
        // Given: Initial state
        let expectation = expectation(description: "Published property changed")
        var receivedValue: WeightTimeRange?

        let cancellable = sut.$selectedTimeRange
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValue = value
                expectation.fulfill()
            }

        // When: Change published property
        sut.selectedTimeRange = .month

        // Then: Should publish change
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, .month)

        cancellable.cancel()
    }
}
