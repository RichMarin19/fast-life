import Foundation

// MARK: - DateComponents Extensions

/// Make DateComponents Comparable for convenience comparisons
/// Note: DateComponents is already Codable in Foundation (iOS 17+)
extension DateComponents: Comparable {
    /// Compare DateComponents based on hour and minute
    /// Used for time comparisons (not for Range creation)
    public static func < (lhs: DateComponents, rhs: DateComponents) -> Bool {
        let lhsHour = lhs.hour ?? 0
        let rhsHour = rhs.hour ?? 0

        if lhsHour != rhsHour {
            return lhsHour < rhsHour
        }

        let lhsMinute = lhs.minute ?? 0
        let rhsMinute = rhs.minute ?? 0
        return lhsMinute < rhsMinute
    }
}

// MARK: - Weight Tracker Notification Planner
/// Pure scheduling logic with zero UserNotifications dependencies
/// 100% testable, deterministic, time-zone aware
///
/// Following technical plan: fastlife_notifications_plan.md
/// Architecture: Separate from Fasting notification system
/// Reference: .claude/PHASE-2-NOTIFICATION-ARCHITECTURE-ANALYSIS.md

// MARK: - Weight Notification Plan

/// Represents a scheduled weight notification
struct WeightNotificationPlan {
    let id: String
    let fireDate: Date
}

// MARK: - Weight Reminder ID Builder

/// Deterministic ID generation for one-per-day policy
/// Format: "weight-YYYY-MM-DD" (e.g., "weight-2025-10-23")
enum WeightReminderID {
    /// Generate unique ID for a specific date
    /// - Parameters:
    ///   - date: The date for the reminder
    ///   - tz: Time zone for date calculation (default: current)
    /// - Returns: Deterministic ID string
    static func forDate(_ date: Date, tz: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = tz
        let ymd = formatter.string(from: date)
        return "weight-\(ymd)"
    }
}

// MARK: - Weight Notification Planner

/// Pure scheduling logic for weight tracker daily reminders
/// Zero side effects - all functions are deterministic
struct WeightNotificationPlanner {

    // MARK: - Main Scheduling Function

    /// Calculate next daily weight reminder
    /// Pure function - no side effects, 100% testable
    ///
    /// - Parameters:
    ///   - now: Current date/time (injectable for testing)
    ///   - preferred: Preferred reminder time (hour/minute components)
    ///   - tz: User's time zone
    ///   - quietHours: Optional quiet hours (can span midnight)
    ///   - skipWeekdays: Weekdays to skip (1=Sunday, 2=Monday, ..., 7=Saturday)
    ///
    /// - Returns: Next weight notification plan, or nil if scheduling not possible
    static func nextPlan(
        from now: Date = Date(),
        preferred: DateComponents,
        tz: TimeZone = .current,
        quietHours: WeightQuietHours? = nil,
        skipWeekdays: Set<Int> = []
    ) -> WeightNotificationPlan? {

        var calendar = Calendar.current
        calendar.timeZone = tz

        var candidateDate = calendar.startOfDay(for: now)

        // Step 1: Find next eligible day (not in skipWeekdays)
        // Max lookahead: 1 week to prevent infinite loops
        var attempts = 0
        while attempts < 8 {
            let weekday = calendar.component(.weekday, from: candidateDate)

            if !skipWeekdays.contains(weekday) {
                // Valid day found
                break
            }

            // Skip to next day
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: candidateDate) else {
                AppLogger.notifications.error("Failed to advance to next day")
                return nil
            }
            candidateDate = nextDay
            attempts += 1
        }

        guard attempts < 8 else {
            AppLogger.notifications.warning("No valid day found within 1 week (all days skipped)")
            return nil
        }

        // Step 2: Build candidate fire time at preferred time
        var components = calendar.dateComponents([.year, .month, .day], from: candidateDate)
        components.hour = preferred.hour
        components.minute = preferred.minute
        components.timeZone = tz

        guard var fireDate = calendar.date(from: components) else {
            AppLogger.notifications.error("Failed to create fire date from components")
            return nil
        }

        // Step 3: If fire time is in past, move to next valid day
        if fireDate <= now {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: candidateDate) else {
                AppLogger.notifications.error("Failed to advance to next day after past check")
                return nil
            }
            candidateDate = nextDay

            // Re-check skipWeekdays for next day
            let nextWeekday = calendar.component(.weekday, from: candidateDate)
            if skipWeekdays.contains(nextWeekday) {
                // Recursively find next valid day
                return nextPlan(
                    from: candidateDate,
                    preferred: preferred,
                    tz: tz,
                    quietHours: quietHours,
                    skipWeekdays: skipWeekdays
                )
            }

            components = calendar.dateComponents([.year, .month, .day], from: candidateDate)
            components.hour = preferred.hour
            components.minute = preferred.minute
            components.timeZone = tz

            guard let nextFireDate = calendar.date(from: components) else {
                AppLogger.notifications.error("Failed to create next day fire date")
                return nil
            }

            fireDate = nextFireDate
        }

        // Step 4: Check quiet hours and adjust if needed
        if let quietHours = quietHours {
            fireDate = adjustForQuietHours(
                fireDate,
                quietHours: quietHours,
                calendar: calendar
            )
        }

        // Step 5: Generate deterministic ID
        let id = WeightReminderID.forDate(fireDate, tz: tz)

        return WeightNotificationPlan(id: id, fireDate: fireDate)
    }

    // MARK: - Quiet Hours Logic

    /// Adjust fire date if it falls within quiet hours
    /// Moves notification to first minute after quiet window ends
    ///
    /// - Parameters:
    ///   - fireDate: Original scheduled fire date
    ///   - quietHours: Quiet hours (can span midnight)
    ///   - calendar: Calendar with correct time zone
    ///
    /// - Returns: Adjusted fire date (same date if not in quiet hours)
    private static func adjustForQuietHours(
        _ fireDate: Date,
        quietHours: WeightQuietHours,
        calendar: Calendar
    ) -> Date {

        let fireComponents = calendar.dateComponents([.hour, .minute], from: fireDate)
        let fireHour = fireComponents.hour ?? 0
        let fireMinute = fireComponents.minute ?? 0

        let quietStart = quietHours.start
        let quietEnd = quietHours.end

        let quietStartHour = quietStart.hour ?? 0
        let quietStartMinute = quietStart.minute ?? 0
        let quietEndHour = quietEnd.hour ?? 0
        let quietEndMinute = quietEnd.minute ?? 0

        // Check if fire time falls within quiet hours
        let isInQuietHours: Bool

        if quietStartHour > quietEndHour || (quietStartHour == quietEndHour && quietStartMinute > quietEndMinute) {
            // Overnight quiet hours (e.g., 9 PM - 6:30 AM)
            let afterStart = (fireHour > quietStartHour) || (fireHour == quietStartHour && fireMinute >= quietStartMinute)
            let beforeEnd = (fireHour < quietEndHour) || (fireHour == quietEndHour && fireMinute < quietEndMinute)
            isInQuietHours = afterStart || beforeEnd
        } else {
            // Same-day quiet hours (e.g., 1 PM - 3 PM)
            let afterStart = (fireHour > quietStartHour) || (fireHour == quietStartHour && fireMinute >= quietStartMinute)
            let beforeEnd = (fireHour < quietEndHour) || (fireHour == quietEndHour && fireMinute < quietEndMinute)
            isInQuietHours = afterStart && beforeEnd
        }

        if isInQuietHours {
            // Move to first minute after quiet hours end
            var adjustedComponents = calendar.dateComponents([.year, .month, .day], from: fireDate)
            adjustedComponents.hour = quietEndHour
            adjustedComponents.minute = quietEndMinute
            adjustedComponents.timeZone = calendar.timeZone

            if let adjustedDate = calendar.date(from: adjustedComponents) {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                formatter.timeZone = calendar.timeZone

                AppLogger.notifications.debug(
                    "Adjusted fire time from quiet hours: \(formatter.string(from: fireDate)) → \(formatter.string(from: adjustedDate))"
                )
                return adjustedDate
            } else {
                AppLogger.notifications.warning("Failed to adjust for quiet hours, using original time")
            }
        }

        return fireDate
    }

    // MARK: - Helper Functions

    /// Check if a given date/time falls within quiet hours
    /// Useful for testing and validation
    ///
    /// - Parameters:
    ///   - date: Date to check
    ///   - quietHours: Quiet hours range
    ///   - tz: Time zone
    ///
    /// - Returns: True if date is in quiet hours
    static func isInQuietHours(
        _ date: Date,
        quietHours: WeightQuietHours,
        tz: TimeZone = .current
    ) -> Bool {

        var calendar = Calendar.current
        calendar.timeZone = tz

        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        let startHour = quietHours.start.hour ?? 0
        let startMinute = quietHours.start.minute ?? 0
        let endHour = quietHours.end.hour ?? 0
        let endMinute = quietHours.end.minute ?? 0

        // Handle overnight quiet hours
        if startHour > endHour || (startHour == endHour && startMinute > endMinute) {
            let afterStart = (hour > startHour) || (hour == startHour && minute >= startMinute)
            let beforeEnd = (hour < endHour) || (hour == endHour && minute < endMinute)
            return afterStart || beforeEnd
        } else {
            let afterStart = (hour > startHour) || (hour == startHour && minute >= startMinute)
            let beforeEnd = (hour < endHour) || (hour == endHour && minute < endMinute)
            return afterStart && beforeEnd
        }
    }
}
