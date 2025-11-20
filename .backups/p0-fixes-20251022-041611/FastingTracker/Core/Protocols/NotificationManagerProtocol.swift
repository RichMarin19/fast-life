import Foundation
import UserNotifications

/// Protocol abstraction for notification operations
/// Enables dependency injection and mocking for tests
/// Following Apple's UserNotifications framework patterns
/// Phase 1 of MVVM Strategy: Protocol abstractions (testability foundation)
protocol NotificationManagerProtocol: AnyObject {

    // MARK: - Authorization
    func requestAuthorization(completion: ((Bool) -> Void)?)
    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void)

    // MARK: - Goal & Milestone Notifications
    func scheduleGoalNotification(for session: FastingSession, goalHours: Double, currentStreak: Int, longestStreak: Int)
    func cancelGoalNotification()

    // MARK: - Comprehensive Notification Scheduling
    func scheduleAllNotifications(for session: FastingSession, goalHours: Double, currentStreak: Int, longestStreak: Int)
    func rescheduleNotifications(for session: FastingSession, goalHours: Double, currentStreak: Int, longestStreak: Int)

    // MARK: - Cancellation
    func cancelAllNotifications()

    // MARK: - Debug Helpers
    func debugPrintPendingNotifications()
}

// MARK: - Protocol Conformance
// Existing NotificationManager adopts protocol without code changes
extension NotificationManager: NotificationManagerProtocol { }
