import Foundation
import UserNotifications

/// Protocol abstraction for behavioral notification scheduling
/// Enables dependency injection and mocking for tests
/// Following Apple's UserNotifications framework + behavioral design patterns
/// Phase 1 of MVVM Strategy: Protocol abstractions (testability foundation)
protocol BehavioralSchedulerProtocol: AnyObject {

    // MARK: - Scheduling API
    func scheduleGuidance(for trackerType: TrackerType, trigger: BehavioralTrigger, context: BehavioralContext) async

    // MARK: - Rule Management
    func updateRule<T: BehavioralNotificationRule>(_ rule: T)
    func getRule(for trackerType: TrackerType) -> (any BehavioralNotificationRule)?

    // MARK: - Testing API
    func sendTestNotification(for trackerType: TrackerType) async

    // MARK: - Permissions
    func requestPermissions() async -> Bool
    func getAuthorizationStatus() async -> UNAuthorizationStatus
}

// MARK: - Protocol Conformance
// Existing BehavioralNotificationScheduler adopts protocol without code changes
extension BehavioralNotificationScheduler: BehavioralSchedulerProtocol { }
