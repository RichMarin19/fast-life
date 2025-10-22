import XCTest
@testable import Fast_lIFe

/// Unit tests for WeightNotificationPlanner
/// Target: 100% code coverage
/// Following technical plan: fastlife_notifications_plan.md
///
/// Test Categories:
/// 1. Basic scheduling (today before/after preferred time)
/// 2. Quiet hours handling
/// 3. Skip weekdays
/// 4. Time zone awareness
/// 5. Edge cases (DST, midnight transitions)

final class WeightNotificationPlannerTests: XCTestCase {

    // MARK: - Test Fixtures

    /// Create date at specific time in given time zone
    func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int, tz: TimeZone = .current) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = tz
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = tz
        return calendar.date(from: components)!
    }

    /// Create time components (hour + minute only)
    func makeTime(hour: Int, minute: Int) -> DateComponents {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return components
    }

    // MARK: - Basic Scheduling Tests

    func testSchedulesToday_WhenBeforePreferredTime() {
        // Given: Current time is 6:00 AM
        let now = makeDate(year: 2025, month: 10, day: 23, hour: 6, minute: 0)

        // When: Preferred time is 7:30 AM
        let preferred = makeTime(hour: 7, minute: 30)

        // Then: Should schedule for today at 7:30 AM
        let plan = WeightNotificationPlanner.nextPlan(
            from: now,
            preferred: preferred,
            tz: .current
        )

        XCTAssertNotNil(plan)
        XCTAssertEqual(plan?.id, "weight-2025-10-23")

        let expectedFire = makeDate(year: 2025, month: 10, day: 23, hour: 7, minute: 30)
        XCTAssertEqual(plan?.fireDate, expectedFire)
    }

    func testSchedulesTomorrow_WhenAfterPreferredTime() {
        // Given: Current time is 8:00 AM
        let now = makeDate(year: 2025, month: 10, day: 23, hour: 8, minute: 0)

        // When: Preferred time is 7:30 AM (already passed)
        let preferred = makeTime(hour: 7, minute: 30)

        // Then: Should schedule for tomorrow at 7:30 AM
        let plan = WeightNotificationPlanner.nextPlan(
            from: now,
            preferred: preferred,
            tz: .current
        )

        XCTAssertNotNil(plan)
        XCTAssertEqual(plan?.id, "weight-2025-10-24")

        let expectedFire = makeDate(year: 2025, month: 10, day: 24, hour: 7, minute: 30)
        XCTAssertEqual(plan?.fireDate, expectedFire)
    }

    func testSchedulesTomorrow_WhenExactlyAtPreferredTime() {
        // Given: Current time is exactly 7:30 AM
        let now = makeDate(year: 2025, month: 10, day: 23, hour: 7, minute: 30)

        // When: Preferred time is 7:30 AM
        let preferred = makeTime(hour: 7, minute: 30)

        // Then: Should schedule for tomorrow (fireDate <= now condition)
        let plan = WeightNotificationPlanner.nextPlan(
            from: now,
            preferred: preferred,
            tz: .current
        )

        XCTAssertNotNil(plan)
        XCTAssertEqual(plan?.id, "weight-2025-10-24")
    }

    // MARK: - Quiet Hours Tests

    func testAdjustsForQuietHours_OvernightRange() {
        // Given: Current time is 6:00 AM, quiet hours are 9 PM - 7 AM
        let now = makeDate(year: 2025, month: 10, day: 23, hour: 6, minute: 0)
        let preferred = makeTime(hour: 6, minute: 30) // Would fire during quiet hours

        let quietStart = makeTime(hour: 21, minute: 0) // 9 PM
        let quietEnd = makeTime(hour: 7, minute: 0)    // 7 AM
        let quietHours = quietStart..<quietEnd

        // When: Scheduling with quiet hours
        let plan = WeightNotificationPlanner.nextPlan(
            from: now,
            preferred: preferred,
            tz: .current,
            quietHours: quietHours
        )

        // Then: Should adjust to 7:00 AM (first minute after quiet hours)
        XCTAssertNotNil(plan)
        let expectedFire = makeDate(year: 2025, month: 10, day: 23, hour: 7, minute: 0)
        XCTAssertEqual(plan?.fireDate, expectedFire)
    }

    func testAdjustsForQuietHours_SameDayRange() {
        // Given: Current time is 12:00 PM, quiet hours are 1 PM - 3 PM
        let now = makeDate(year: 2025, month: 10, day: 23, hour: 12, minute: 0)
        let preferred = makeTime(hour: 14, minute: 0) // 2 PM - during quiet hours

        let quietStart = makeTime(hour: 13, minute: 0) // 1 PM
        let quietEnd = makeTime(hour: 15, minute: 0)   // 3 PM
        let quietHours = quietStart..<quietEnd

        // When: Scheduling with quiet hours
        let plan = WeightNotificationPlanner.nextPlan(
            from: now,
            preferred: preferred,
            tz: .current,
            quietHours: quietHours
        )

        // Then: Should adjust to 3:00 PM (first minute after quiet hours)
        XCTAssertNotNil(plan)
        let expectedFire = makeDate(year: 2025, month: 10, day: 23, hour: 15, minute: 0)
        XCTAssertEqual(plan?.fireDate, expectedFire)
    }

    func testDoesNotAdjust_WhenOutsideQuietHours() {
        // Given: Current time is 6:00 AM, quiet hours are 9 PM - 6 AM
        let now = makeDate(year: 2025, month: 10, day: 23, hour: 6, minute: 0)
        let preferred = makeTime(hour: 8, minute: 0) // 8 AM - outside quiet hours

        let quietStart = makeTime(hour: 21, minute: 0) // 9 PM
        let quietEnd = makeTime(hour: 6, minute: 0)    // 6 AM
        let quietHours = quietStart..<quietEnd

        // When: Scheduling with quiet hours
        let plan = WeightNotificationPlanner.nextPlan(
            from: now,
            preferred: preferred,
            tz: .current,
            quietHours: quietHours
        )

        // Then: Should NOT adjust (8 AM is outside 9 PM - 6 AM range)
        XCTAssertNotNil(plan)
        let expectedFire = makeDate(year: 2025, month: 10, day: 23, hour: 8, minute: 0)
        XCTAssertEqual(plan?.fireDate, expectedFire)
    }

    // MARK: - Skip Weekdays Tests

    func testSkipsSunday() {
        // Given: Current time is Saturday 6:00 AM
        // Sunday is weekday 1 in Calendar
        let now = makeDate(year: 2025, month: 10, day: 25, hour: 6, minute: 0) // Saturday
        let preferred = makeTime(hour: 7, minute: 30)
        let skipWeekdays: Set<Int> = [1] // Skip Sunday

        // When: Scheduling would normally be Sunday
        let plan = WeightNotificationPlanner.nextPlan(
            from: now,
            preferred: preferred,
            tz: .current,
            skipWeekdays: skipWeekdays
        )

        // Then: Should schedule for Monday instead
        XCTAssertNotNil(plan)
        XCTAssertEqual(plan?.id, "weight-2025-10-27") // Monday
    }

    func testSkipsMultipleWeekdays() {
        // Given: Current time is Friday 8:00 AM (past preferred time)
        let now = makeDate(year: 2025, month: 10, day: 24, hour: 8, minute: 0) // Friday
        let preferred = makeTime(hour: 7, minute: 30)
        let skipWeekdays: Set<Int> = [7, 1] // Skip Saturday (7) and Sunday (1)

        // When: Next day would be Saturday, then Sunday
        let plan = WeightNotificationPlanner.nextPlan(
            from: now,
            preferred: preferred,
            tz: .current,
            skipWeekdays: skipWeekdays
        )

        // Then: Should schedule for Monday
        XCTAssertNotNil(plan)
        XCTAssertEqual(plan?.id, "weight-2025-10-27") // Monday
    }

    func testReturnsNil_WhenAllWeekdaysSkipped() {
        // Given: All weekdays skipped (impossible scenario)
        let now = makeDate(year: 2025, month: 10, day: 23, hour: 6, minute: 0)
        let preferred = makeTime(hour: 7, minute: 30)
        let skipWeekdays: Set<Int> = [1, 2, 3, 4, 5, 6, 7] // All days

        // When: Scheduling with all days skipped
        let plan = WeightNotificationPlanner.nextPlan(
            from: now,
            preferred: preferred,
            tz: .current,
            skipWeekdays: skipWeekdays
        )

        // Then: Should return nil (no valid day within lookahead)
        XCTAssertNil(plan)
    }

    // MARK: - Time Zone Tests

    func testHandlesTimeZoneCorrectly() {
        // Given: New York time zone (UTC-5 or UTC-4 depending on DST)
        let nyTimeZone = TimeZone(identifier: "America/New_York")!

        // Current time: 6:00 AM NY time on Oct 23, 2025
        var calendar = Calendar.current
        calendar.timeZone = nyTimeZone
        var components = DateComponents()
        components.year = 2025
        components.month = 10
        components.day = 23
        components.hour = 6
        components.minute = 0
        components.timeZone = nyTimeZone
        let now = calendar.date(from: components)!

        let preferred = makeTime(hour: 7, minute: 30)

        // When: Scheduling in NY time zone
        let plan = WeightNotificationPlanner.nextPlan(
            from: now,
            preferred: preferred,
            tz: nyTimeZone
        )

        // Then: Should schedule for today at 7:30 AM NY time
        XCTAssertNotNil(plan)
        XCTAssertEqual(plan?.id, "weight-2025-10-23")

        // Verify fire date is correct in NY time zone
        components.hour = 7
        components.minute = 30
        let expectedFire = calendar.date(from: components)!
        XCTAssertEqual(plan?.fireDate, expectedFire)
    }

    // MARK: - ID Generation Tests

    func testIDGeneratesCorrectFormat() {
        // Given: A date
        let date = makeDate(year: 2025, month: 10, day: 23, hour: 7, minute: 30)

        // When: Generating ID
        let id = WeightReminderID.forDate(date, tz: .current)

        // Then: Should be "weight-YYYY-MM-DD" format
        XCTAssertEqual(id, "weight-2025-10-23")
    }

    func testIDIsDeterministic() {
        // Given: Same date called multiple times
        let date = makeDate(year: 2025, month: 10, day: 23, hour: 7, minute: 30)

        // When: Generating IDs
        let id1 = WeightReminderID.forDate(date, tz: .current)
        let id2 = WeightReminderID.forDate(date, tz: .current)
        let id3 = WeightReminderID.forDate(date, tz: .current)

        // Then: All IDs should be identical
        XCTAssertEqual(id1, id2)
        XCTAssertEqual(id2, id3)
    }

    // MARK: - Helper Function Tests

    func testIsInQuietHours_OvernightRange() {
        // Given: Quiet hours 9 PM - 7 AM
        let quietStart = makeTime(hour: 21, minute: 0)
        let quietEnd = makeTime(hour: 7, minute: 0)
        let quietHours = quietStart..<quietEnd

        // When: Checking various times
        let midnight = makeDate(year: 2025, month: 10, day: 23, hour: 0, minute: 0)
        let earlyMorning = makeDate(year: 2025, month: 10, day: 23, hour: 6, minute: 30)
        let morning = makeDate(year: 2025, month: 10, day: 23, hour: 8, minute: 0)
        let evening = makeDate(year: 2025, month: 10, day: 23, hour: 22, minute: 0)

        // Then: Correct quiet hours detection
        XCTAssertTrue(WeightNotificationPlanner.isInQuietHours(midnight, quietHours: quietHours))
        XCTAssertTrue(WeightNotificationPlanner.isInQuietHours(earlyMorning, quietHours: quietHours))
        XCTAssertFalse(WeightNotificationPlanner.isInQuietHours(morning, quietHours: quietHours))
        XCTAssertTrue(WeightNotificationPlanner.isInQuietHours(evening, quietHours: quietHours))
    }

    func testIsInQuietHours_SameDayRange() {
        // Given: Quiet hours 1 PM - 3 PM
        let quietStart = makeTime(hour: 13, minute: 0)
        let quietEnd = makeTime(hour: 15, minute: 0)
        let quietHours = quietStart..<quietEnd

        // When: Checking various times
        let noon = makeDate(year: 2025, month: 10, day: 23, hour: 12, minute: 0)
        let afternoon = makeDate(year: 2025, month: 10, day: 23, hour: 14, minute: 0)
        let lateAfternoon = makeDate(year: 2025, month: 10, day: 23, hour: 16, minute: 0)

        // Then: Correct quiet hours detection
        XCTAssertFalse(WeightNotificationPlanner.isInQuietHours(noon, quietHours: quietHours))
        XCTAssertTrue(WeightNotificationPlanner.isInQuietHours(afternoon, quietHours: quietHours))
        XCTAssertFalse(WeightNotificationPlanner.isInQuietHours(lateAfternoon, quietHours: quietHours))
    }

    // MARK: - Edge Case Tests

    func testHandlesMidnightTransition() {
        // Given: Current time is 11:59 PM
        let now = makeDate(year: 2025, month: 10, day: 23, hour: 23, minute: 59)
        let preferred = makeTime(hour: 7, minute: 30)

        // When: Scheduling (should roll to next day)
        let plan = WeightNotificationPlanner.nextPlan(
            from: now,
            preferred: preferred,
            tz: .current
        )

        // Then: Should schedule for tomorrow
        XCTAssertNotNil(plan)
        XCTAssertEqual(plan?.id, "weight-2025-10-24")
    }

    func testHandlesMonthTransition() {
        // Given: Current time is Oct 31, 8:00 AM (past preferred time)
        let now = makeDate(year: 2025, month: 10, day: 31, hour: 8, minute: 0)
        let preferred = makeTime(hour: 7, minute: 30)

        // When: Scheduling (should roll to November)
        let plan = WeightNotificationPlanner.nextPlan(
            from: now,
            preferred: preferred,
            tz: .current
        )

        // Then: Should schedule for Nov 1
        XCTAssertNotNil(plan)
        XCTAssertEqual(plan?.id, "weight-2025-11-01")
    }

    func testHandlesYearTransition() {
        // Given: Current time is Dec 31, 8:00 AM (past preferred time)
        let now = makeDate(year: 2025, month: 12, day: 31, hour: 8, minute: 0)
        let preferred = makeTime(hour: 7, minute: 30)

        // When: Scheduling (should roll to next year)
        let plan = WeightNotificationPlanner.nextPlan(
            from: now,
            preferred: preferred,
            tz: .current
        )

        // Then: Should schedule for Jan 1, 2026
        XCTAssertNotNil(plan)
        XCTAssertEqual(plan?.id, "weight-2026-01-01")
    }
}
