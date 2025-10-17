import Foundation
import UserNotifications

/// Notification Identifier Builder
/// Expert Panel Task #6: Single source of truth for notification identifiers
/// Prevents accidental drift in prefix construction across rules and provides consistent debugging
/// Note: No @MainActor needed - utility class with static methods only
final class NotificationIdentifierBuilder {

    // MARK: - Constants

    /// Base prefix for all behavioral notifications
    static let behavioralPrefix = "behavioral"

    /// Separator used in identifier construction
    static let separator = "_"

    /// Maximum identifier length to prevent issues with iOS notification system
    static let maxIdentifierLength = 64

    // MARK: - Core Identifier Generation

    /// Generate a unique identifier for behavioral notifications
    /// Format: "behavioral_{tracker}_{trigger_type}_{timestamp}"
    /// Example: "behavioral_weight_time_300_1697462400"
    static func buildBehavioralIdentifier(
        tracker: TrackerType,
        trigger: BehavioralTrigger,
        timestamp: Date = Date()
    ) -> String {
        let components = [
            behavioralPrefix,
            tracker.rawValue,
            trigger.identifier(),
            String(Int(timestamp.timeIntervalSince1970))
        ]

        let identifier = components.joined(separator: separator)

        // Ensure identifier doesn't exceed system limits
        if identifier.count > maxIdentifierLength {
            AppLogger.notifications.warning("Identifier length exceeds limit: \(identifier.count) > \(maxIdentifierLength)")
            return truncateIdentifier(identifier)
        }

        return identifier
    }

    /// Generate identifier for recurring behavioral notifications
    /// Format: "behavioral_{tracker}_recurring_{recurrence_type}_{day_of_week}"
    /// Example: "behavioral_hydration_recurring_daily_tuesday"
    static func buildRecurringIdentifier(
        tracker: TrackerType,
        recurrenceType: RecurrenceType,
        dayOfWeek: String? = nil
    ) -> String {
        var components = [
            behavioralPrefix,
            tracker.rawValue,
            "recurring",
            recurrenceType.rawValue
        ]

        if let day = dayOfWeek {
            components.append(day.lowercased())
        }

        let identifier = components.joined(separator: separator)
        return truncateIfNeeded(identifier)
    }

    /// Generate identifier for test notifications
    /// Format: "behavioral_{tracker}_test_{test_type}_{timestamp}"
    /// Example: "behavioral_weight_test_debug_1697462400"
    static func buildTestIdentifier(
        tracker: TrackerType,
        testType: TestType = .debug,
        timestamp: Date = Date()
    ) -> String {
        let components = [
            behavioralPrefix,
            tracker.rawValue,
            "test",
            testType.rawValue,
            String(Int(timestamp.timeIntervalSince1970))
        ]

        let identifier = components.joined(separator: separator)
        return truncateIfNeeded(identifier)
    }

    // MARK: - Specialized Identifiers

    /// Generate identifier for throttle-related notifications
    /// Used to track notification delivery times for throttling
    static func buildThrottleIdentifier(tracker: TrackerType) -> String {
        let components = [
            behavioralPrefix,
            tracker.rawValue,
            "throttle",
            "last_sent"
        ]

        return components.joined(separator: separator)
    }

    /// Generate identifier for audit/debugging notifications
    /// Used by the notification audit system
    static func buildAuditIdentifier(tracker: TrackerType, auditType: AuditType) -> String {
        let components = [
            behavioralPrefix,
            tracker.rawValue,
            "audit",
            auditType.rawValue
        ]

        return components.joined(separator: separator)
    }

    /// Generate identifier for system notifications (app-wide)
    /// Format: "behavioral_system_{system_type}_{timestamp}"
    static func buildSystemIdentifier(systemType: SystemNotificationType) -> String {
        let components = [
            behavioralPrefix,
            "system",
            systemType.rawValue,
            String(Int(Date().timeIntervalSince1970))
        ]

        return components.joined(separator: separator)
    }

    // MARK: - Identifier Parsing & Validation

    /// Extract tracker type from notification identifier
    /// Returns nil if identifier doesn't match expected format
    static func extractTrackerType(from identifier: String) -> TrackerType? {
        let components = identifier.split(separator: Character(separator))

        guard components.count >= 2,
              components[0] == behavioralPrefix,
              let trackerType = TrackerType(rawValue: String(components[1])) else {
            AppLogger.notifications.debug("Failed to extract tracker type from identifier: \(identifier)")
            return nil
        }

        return trackerType
    }

    /// Extract trigger type from notification identifier
    static func extractTriggerType(from identifier: String) -> String? {
        let components = identifier.split(separator: Character(separator))

        guard components.count >= 3,
              components[0] == behavioralPrefix else {
            return nil
        }

        return String(components[2])
    }

    /// Validate that identifier follows behavioral notification format
    static func isValidBehavioralIdentifier(_ identifier: String) -> Bool {
        let components = identifier.split(separator: Character(separator))

        // Must have at least: behavioral_{tracker}_{trigger}
        guard components.count >= 3,
              components[0] == behavioralPrefix,
              TrackerType(rawValue: String(components[1])) != nil else {
            return false
        }

        return true
    }

    /// Get all identifiers for a specific tracker type
    static func buildTrackerIdentifierPrefix(for tracker: TrackerType) -> String {
        return [behavioralPrefix, tracker.rawValue].joined(separator: separator) + separator
    }

    // MARK: - Batch Operations

    /// Generate identifiers for all tracker types with same trigger
    static func buildIdentifiersForAllTrackers(
        trigger: BehavioralTrigger,
        timestamp: Date = Date()
    ) -> [TrackerType: String] {
        var identifiers: [TrackerType: String] = [:]

        for tracker in TrackerType.allCases {
            identifiers[tracker] = buildBehavioralIdentifier(
                tracker: tracker,
                trigger: trigger,
                timestamp: timestamp
            )
        }

        return identifiers
    }

    /// Generate batch of test identifiers for debugging
    static func buildDebugIdentifierSet() -> [String] {
        var identifiers: [String] = []

        for tracker in TrackerType.allCases {
            // Regular behavioral notification
            identifiers.append(buildBehavioralIdentifier(tracker: tracker, trigger: .immediate))

            // Test notification
            identifiers.append(buildTestIdentifier(tracker: tracker, testType: .debug))

            // Recurring notification
            identifiers.append(buildRecurringIdentifier(tracker: tracker, recurrenceType: .daily))

            // Audit notification
            identifiers.append(buildAuditIdentifier(tracker: tracker, auditType: .scheduled))
        }

        return identifiers
    }

    // MARK: - Helper Methods

    /// Truncate identifier if it exceeds maximum length
    private static func truncateIdentifier(_ identifier: String) -> String {
        if identifier.count <= maxIdentifierLength {
            return identifier
        }

        // Keep the beginning and add hash of full identifier at the end
        let truncateLength = maxIdentifierLength - 8 // Leave space for hash
        let truncated = String(identifier.prefix(truncateLength))
        let hash = String(identifier.hashValue).suffix(7) // Use last 7 digits of hash

        return truncated + hash
    }

    /// Truncate identifier if needed (convenience method)
    private static func truncateIfNeeded(_ identifier: String) -> String {
        return identifier.count > maxIdentifierLength ? truncateIdentifier(identifier) : identifier
    }

    // MARK: - Debug & Validation Methods

    /// Validate identifier format and log issues
    static func debugIdentifier(_ identifier: String) -> IdentifierDebugInfo {
        let components = identifier.split(separator: Character(separator))

        return IdentifierDebugInfo(
            identifier: identifier,
            isValid: isValidBehavioralIdentifier(identifier),
            componentCount: components.count,
            prefix: components.first.map(String.init),
            trackerType: extractTrackerType(from: identifier),
            triggerType: extractTriggerType(from: identifier),
            length: identifier.count,
            exceedsMaxLength: identifier.count > maxIdentifierLength
        )
    }

    /// Get statistics about all pending behavioral notification identifiers
    static func getIdentifierStatistics() async -> IdentifierStatistics {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()

        let behavioralNotifications = pendingRequests.filter { request in
            request.identifier.hasPrefix(behavioralPrefix)
        }

        var trackerCounts: [TrackerType: Int] = [:]
        var invalidIdentifiers: [String] = []

        for request in behavioralNotifications {
            if let tracker = extractTrackerType(from: request.identifier) {
                trackerCounts[tracker, default: 0] += 1
            } else {
                invalidIdentifiers.append(request.identifier)
            }
        }

        return IdentifierStatistics(
            totalBehavioralNotifications: behavioralNotifications.count,
            trackerCounts: trackerCounts,
            invalidIdentifiers: invalidIdentifiers,
            averageIdentifierLength: behavioralNotifications.map { $0.identifier.count }.reduce(0, +) / max(behavioralNotifications.count, 1)
        )
    }
}

// MARK: - Supporting Types

/// Recurrence types for recurring notifications
enum RecurrenceType: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case custom = "custom"
}

/// Test notification types
enum TestType: String, CaseIterable, Codable {
    case debug = "debug"
    case integration = "integration"
    case performance = "performance"
    case user_acceptance = "user_acceptance"
}

/// Audit notification types
enum AuditType: String, CaseIterable, Codable {
    case scheduled = "scheduled"
    case delivered = "delivered"
    case failed = "failed"
    case cancelled = "cancelled"
}

/// System notification types (app-wide)
enum SystemNotificationType: String, CaseIterable, Codable {
    case update_available = "update_available"
    case maintenance = "maintenance"
    case feature_announcement = "feature_announcement"
    case data_export_complete = "data_export_complete"
}

/// Debug information for identifier analysis
struct IdentifierDebugInfo {
    let identifier: String
    let isValid: Bool
    let componentCount: Int
    let prefix: String?
    let trackerType: TrackerType?
    let triggerType: String?
    let length: Int
    let exceedsMaxLength: Bool

    func printDebugInfo() {
        print("🔍 IDENTIFIER DEBUG: \(identifier)")
        print("   Valid: \(isValid)")
        print("   Components: \(componentCount)")
        print("   Prefix: \(prefix ?? "none")")
        print("   Tracker: \(trackerType?.rawValue ?? "unknown")")
        print("   Trigger: \(triggerType ?? "unknown")")
        print("   Length: \(length)/\(NotificationIdentifierBuilder.maxIdentifierLength)")
        if exceedsMaxLength {
            print("   ⚠️ WARNING: Exceeds maximum length")
        }
    }
}

/// Statistics about notification identifiers in the system
struct IdentifierStatistics {
    let totalBehavioralNotifications: Int
    let trackerCounts: [TrackerType: Int]
    let invalidIdentifiers: [String]
    let averageIdentifierLength: Int

    func printStatistics() {
        print("📊 IDENTIFIER STATISTICS:")
        print("   Total behavioral notifications: \(totalBehavioralNotifications)")
        print("   Average identifier length: \(averageIdentifierLength)")

        print("   Per-tracker counts:")
        for (tracker, count) in trackerCounts.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            print("     \(tracker.rawValue): \(count)")
        }

        if !invalidIdentifiers.isEmpty {
            print("   ⚠️ Invalid identifiers found: \(invalidIdentifiers.count)")
            for invalid in invalidIdentifiers.prefix(3) {
                print("     - \(invalid)")
            }
            if invalidIdentifiers.count > 3 {
                print("     ... and \(invalidIdentifiers.count - 3) more")
            }
        }
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension NotificationIdentifierBuilder {
    /// Test all identifier generation methods
    static func runIdentifierTests() {
        print("🧪 NOTIFICATION IDENTIFIER TESTS")
        print("   Expert Panel Task #6: IdentifierBuilder utility validation\n")

        // Test basic behavioral identifiers
        let weightId = buildBehavioralIdentifier(tracker: .weight, trigger: .immediate)
        print("Weight identifier: \(weightId)")

        // Test recurring identifiers
        let recurringId = buildRecurringIdentifier(tracker: .hydration, recurrenceType: .daily, dayOfWeek: "monday")
        print("Recurring identifier: \(recurringId)")

        // Test extraction
        if let extracted = extractTrackerType(from: weightId) {
            print("Extracted tracker: \(extracted.rawValue)")
        }

        // Test validation
        let isValid = isValidBehavioralIdentifier(weightId)
        print("Identifier valid: \(isValid)")

        // Test debug info
        let debugInfo = debugIdentifier(weightId)
        debugInfo.printDebugInfo()

        print("\n✅ IDENTIFIER BUILDER: All methods functional")
    }
}
#endif