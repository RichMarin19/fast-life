import Foundation
import OSLog
import UIKit
import Firebase
import FirebaseCrashlytics

/// Centralized crash reporting and analytics manager
/// Following Apple best practices for production error tracking
/// Reference: https://firebase.google.com/docs/crashlytics/get-started?platform=ios
public class CrashReportManager {
    public static let shared = CrashReportManager()

#if DEBUG
    static var metricRecorderOverride: ((String, [String: String]) -> Void)?
#endif

    private let logger = AppLogger.general
    private var isInitialized = false
    private let fileManager = FileManager.default

    // MARK: - Secure Storage Configuration
    // Following Apple File System Programming Guide for secure data storage
    // Reference: https://developer.apple.com/documentation/foundation/filemanager

    private lazy var secureLogsDirectory: URL = {
        // Use Application Support directory for app-specific data that should be backed up
        // but isn't user-facing content (following Apple guidelines)
        guard let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory,
                                                                 in: .userDomainMask).first else {
            fatalError("Unable to access Application Support directory")
        }

        let crashLogsDirectory = applicationSupportDirectory.appendingPathComponent("CrashLogs", isDirectory: true)

        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: crashLogsDirectory,
                                         withIntermediateDirectories: true,
                                         attributes: [.protectionKey: FileProtectionType.completeUnlessOpen])

        return crashLogsDirectory
    }()

    // MARK: - Categories from Beta Readiness Master Plan
    // Required categories: healthkit, hydration, weight, sleep, fasting, charts, notifications

    private enum CrashCategory: String {
        case healthkit = "healthkit"
        case hydration = "hydration"
        case weight = "weight"
        case sleep = "sleep"
        case fasting = "fasting"
        case charts = "charts"
        case notifications = "notifications"
        case general = "general"
        case ui = "ui"
        case persistence = "persistence"
    }

    private init() {
        // Private initializer for singleton pattern
    }

    // MARK: - Initialization

    /// Initialize crash reporting system asynchronously (non-blocking)
    /// Call this from FastingTrackerApp.init() following Firebase setup guide
    /// Initialization happens on background thread to prevent main thread blocking
    public func initialize() {
        guard !isInitialized else {
            AppLogger.warning("CrashReportManager already initialized", category: AppLogger.general)
            return
        }

        // Mark as initialized immediately to prevent duplicate calls
        isInitialized = true

        // Move Firebase configuration to background thread to prevent blocking
        // This is critical: Firebase can block when processing pending crash reports
        DispatchQueue.global(qos: .utility).async {
            AppLogger.info("Starting Firebase configuration on background thread...", category: AppLogger.general)

            // Configure Firebase off main thread
            FirebaseApp.configure()

            // Enable Crashlytics collection
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)

            AppLogger.info("CrashReportManager initialized successfully", category: AppLogger.general)
        }
    }

    // MARK: - Crash Reporting Methods

    /// Record a non-fatal error for HealthKit operations
    public func recordHealthKitError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .healthkit, context: context)
    }

    /// Record a non-fatal error for hydration tracking
    public func recordHydrationError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .hydration, context: context)
    }

    /// Record a non-fatal error for weight tracking
    public func recordWeightError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .weight, context: context)
    }

    /// Record a non-fatal error for sleep tracking
    public func recordSleepError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .sleep, context: context)
    }

    /// Record a non-fatal error for fasting operations
    public func recordFastingError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .fasting, context: context)
    }

    /// Record a non-fatal error for chart rendering
    public func recordChartError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .charts, context: context)
    }

    /// Record a non-fatal error for notifications
    public func recordNotificationError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .notifications, context: context)
    }

    /// Record a non-fatal error for UI operations
    public func recordUIError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .ui, context: context)
    }

    /// Record a non-fatal error for persistence operations
    public func recordPersistenceError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .persistence, context: context)
    }

    /// Record a general non-fatal error
    public func recordGeneralError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .general, context: context)
    }

    // MARK: - Private Implementation

    private func recordError(_ error: Error, category: CrashCategory, context: [String: Any]) {
        let sanitizedContext = CrashTelemetrySanitizer.sanitizeContext(context)
        let contextSummary = CrashTelemetrySanitizer.summarizeContext(sanitizedContext)
        let sanitizedMessage = CrashTelemetrySanitizer.sanitizedDescription(for: error, category: category.rawValue)
        let fullMessage = contextSummary.isEmpty ? sanitizedMessage : "\(sanitizedMessage) | \(contextSummary)"

        AppLogger.error(fullMessage, category: AppLogger.general, error: error)

        // PHASE 0: Persist crash logs securely to Application Support
        persistCrashLogSecurely(error: error, category: category, context: sanitizedContext)

        #if DEBUG
        // In debug mode, just log the error
        AppLogger.debug("🚨 CrashReport[\(category.rawValue)]: \(error.localizedDescription)", category: AppLogger.safety)
        if !sanitizedContext.isEmpty {
            AppLogger.debug("   Context: \(contextSummary)", category: AppLogger.safety)
        }
        #else
        // In production, record to Firebase Crashlytics
        let crashlytics = Crashlytics.crashlytics()
        let sanitizedError = CrashTelemetrySanitizer.sanitizedNSError(from: error)
        crashlytics.setCustomValue(category.rawValue, forKey: "crash_category")
        crashlytics.setCustomValue(sanitizedMessage, forKey: "sanitized_error")
        if !contextSummary.isEmpty {
            crashlytics.setCustomValue(contextSummary, forKey: "context_summary")
        }
        if let contextKeys = sanitizedContext["context_keys"] {
            crashlytics.setCustomValue(contextKeys, forKey: "context_keys")
        }
        sanitizedContext
            .filter { $0.key != "context_keys" }
            .forEach { crashlytics.setCustomValue($0.value, forKey: $0.key) }
        crashlytics.record(error: sanitizedError)
        #endif
    }

    // MARK: - Secure Crash Log Persistence
    // Following Apple security guidelines: NSFileProtectionComplete for sensitive data
    // Reference: https://developer.apple.com/documentation/foundation/nsfileprotectioncomplete

    private func persistCrashLogSecurely(error: Error, category: CrashCategory, context: [String: Any]) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = CrashLogEntry(
            timestamp: timestamp,
            category: category.rawValue,
            error: error.localizedDescription,
            context: context
        )

        do {
            let logData = try JSONEncoder().encode(logEntry)
            let filename = "\(timestamp.replacingOccurrences(of: ":", with: "-"))_\(category.rawValue).json"
            let fileURL = secureLogsDirectory.appendingPathComponent(filename)

            // Write with NSFileProtectionComplete for maximum security
            try logData.write(to: fileURL, options: [.atomic])
            try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: fileURL.path)

            AppLogger.info("Crash log persisted securely: \(filename)", category: AppLogger.general)
        } catch {
            AppLogger.error("Failed to persist crash log securely", category: AppLogger.general, error: error)
        }
    }

    // MARK: - Custom Logging

    /// Log a custom message for debugging production issues
    /// Useful for tracking user actions that lead to crashes
    public func logCustomMessage(_ message: String, level: LogLevel = .info) {
        logCustomMessage(message, category: .general, level: level)
    }

    /// Record a PHI-safe metric event so QA/observers can review telemetry in Crashlytics.
    /// Metadata should already be sanitized upstream (aggregate counts, booleans, enums).
    public func recordMetricEvent(_ name: String, metadata: [String: String] = [:]) {
#if DEBUG
        if let override = CrashReportManager.metricRecorderOverride {
            override(name, metadata)
            return
        }
#endif
        let summary = sanitizedMetadataSummary(from: metadata)
        let logMessage = summary.isEmpty ? "METRIC[\(name)]" : "METRIC[\(name)] \(summary)"

        AppLogger.infoPublic(logMessage, category: AppLogger.weightTracking)

        #if !DEBUG
        Crashlytics.crashlytics().log(logMessage)
        #endif
    }

    /// Internal method with category parameter
    private func logCustomMessage(_ message: String, category: CrashCategory = .general, level: LogLevel = .info) {
        let sanitizedMessage = CrashTelemetrySanitizer.sanitizeMessage(message)
        let logMessage = "Custom[\(category.rawValue)]: \(sanitizedMessage)"

        switch level {
        case .debug:
            AppLogger.debug(logMessage, category: AppLogger.general)
        case .info:
            AppLogger.info(logMessage, category: AppLogger.general)
        case .notice:
            AppLogger.info(logMessage, category: AppLogger.general)
        case .warning:
            AppLogger.warning(logMessage, category: AppLogger.general)
        case .error:
            AppLogger.error(logMessage, category: AppLogger.general)
        case .fault:
            AppLogger.error(logMessage, category: AppLogger.general)
        }

        #if !DEBUG
        // In production, log to Firebase Crashlytics
        Crashlytics.crashlytics().log(logMessage)
        #endif
    }

    // MARK: - User Context

    /// Set user identifier for crash reports (use anonymized ID, never personal info)
    /// Following Apple privacy guidelines - use hashed identifiers only
    public func setUserIdentifier(_ identifier: String) {
        let hashedID = identifier.hash.description // Simple hash for anonymization

        AppLogger.info("Setting user context: \(hashedID)", category: AppLogger.general)

        #if !DEBUG
        // In production, set user context in Firebase Crashlytics
        Crashlytics.crashlytics().setUserID(hashedID)
        #endif
    }

    /// Set custom key-value pairs for crash context
    public func setCustomValue(_ value: Any, forKey key: String) {
        let sanitizedValue = CrashTelemetrySanitizer.sanitizeCustomValue(value, forKey: key)
        AppLogger.debug("Setting custom value: \(key)=\(sanitizedValue)", category: AppLogger.general)

        #if !DEBUG
        // In production, set custom keys in Firebase Crashlytics
        Crashlytics.crashlytics().setCustomValue(sanitizedValue, forKey: key)
        #endif
    }
}

// LogLevel is defined in Logging.swift

// MARK: - Convenience Extensions

extension CrashReportManager {

    /// Quick method to record and log an error in one call
    private func handleError(_ error: Error, in component: String, category: CrashCategory = .general, context: [String: Any] = [:]) {
        var fullContext = context
        fullContext["component"] = component

        recordError(error, category: category, context: fullContext)
    }

    /// Record performance issues (slow operations)
    public func recordPerformanceIssue(operation: String, duration: TimeInterval, threshold: TimeInterval = 2.0) {
        if duration > threshold {
            let context = [
                "operation": operation,
                "duration": String(format: "%.3f", duration),
                "threshold": String(format: "%.3f", threshold)
            ]

            logCustomMessage("Performance issue detected", category: .general, level: .warning)

            #if !DEBUG
            // In production, record as non-fatal error
            let error = NSError(
                domain: "Performance",
                code: 1001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Operation '\(operation)' took \(String(format: "%.3f", duration))s (threshold: \(String(format: "%.3f", threshold))s)"
                ]
            )
            recordError(error, category: .general, context: context)
            #endif
        }
    }

    private func sanitizedMetadataSummary(from metadata: [String: String]) -> String {
        guard !metadata.isEmpty else { return "" }
        let rawContext = metadata.reduce(into: [String: Any]()) { partialResult, entry in
            partialResult[entry.key] = entry.value
        }
        let sanitized = CrashTelemetrySanitizer.sanitizeContext(rawContext)
        return CrashTelemetrySanitizer.summarizeContext(sanitized)
    }
}

// MARK: - Secure Crash Log Data Model
// Following Apple Codable best practices for secure JSON serialization
// Reference: https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types

private struct CrashLogEntry: Codable {
    let timestamp: String
    let category: String
    let error: String
    let context: [String: AnyCodable]

    init(timestamp: String, category: String, error: String, context: [String: Any]) {
        self.timestamp = timestamp
        self.category = category
        self.error = error
        // Convert Any values to AnyCodable for JSON serialization
        self.context = context.mapValues { AnyCodable($0) }
    }
}

// Helper for encoding Any values in JSON
private struct AnyCodable: Codable {
    private let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else {
            // Fallback: convert to string
            try container.encode(String(describing: value))
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
}

// MARK: - Telemetry Sanitization Utilities

struct CrashTelemetrySanitizer {
    private static let redactedMarker = "[REDACTED]"
    private static let sensitiveTokens: [String] = [
        "weight",
        "goal",
        "bmi",
        "bodyfat",
        "hydration",
        "sleep",
        "fast",
        "lbs",
        "kg"
    ]

    private static let sensitiveValueRegex: NSRegularExpression = {
        // Matches values like "180.5 lbs", "75kg", etc.
        let pattern = #"(-?\d+(\.\d+)?)\s?(lbs|pounds|kg|kilograms)"#
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()

    static func sanitizeContext(_ context: [String: Any]) -> [String: Any] {
        guard !context.isEmpty else { return [:] }

        var sanitized: [String: Any] = [:]
        var containsSensitive = false

        for (key, value) in context {
            let sanitizedValue = sanitizeCustomValue(value, forKey: key)
            if let stringValue = sanitizedValue as? String, stringValue == redactedMarker {
                containsSensitive = true
            }
            sanitized[key] = sanitizedValue
        }

        if containsSensitive {
            sanitized["containsSensitiveTelemetry"] = true
        }

        sanitized["context_keys"] = Array(context.keys).sorted().joined(separator: "|")
        return sanitized
    }

    static func summarizeContext(_ context: [String: Any]) -> String {
        context
            .filter { $0.key != "context_keys" }
            .map { "\($0.key)=\($0.value)" }
            .sorted()
            .joined(separator: ", ")
    }

    static func sanitizeCustomValue(_ value: Any, forKey key: String) -> Any {
        let lowerKey = key.lowercased()
        if containsSensitiveToken(in: lowerKey) {
            return redactedMarker
        }

        switch value {
        case let string as String:
            if containsSensitiveToken(in: string.lowercased()) || matchesSensitivePattern(string) {
                return redactedMarker
            }
            return string
        case let number as NSNumber:
            if containsSensitiveToken(in: lowerKey) {
                return redactedMarker
            }
            return number
        case let bool as Bool:
            return bool
        case let dict as [String: Any]:
            let nested = sanitizeContext(dict)
            if nested.isEmpty { return "[:]" }
            return nested.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: ", ")
        case let array as [Any]:
            let sanitizedArray = array.map { sanitizeCustomValue($0, forKey: key) }
            return sanitizedArray.map { "\($0)" }.joined(separator: ", ")
        default:
            return String(describing: value)
        }
    }

    static func sanitizeMessage(_ message: String) -> String {
        guard !message.isEmpty else { return message }
        var sanitized = message
        let range = NSRange(location: 0, length: sanitized.utf16.count)
        sanitized = sensitiveValueRegex.stringByReplacingMatches(in: sanitized, options: [], range: range, withTemplate: redactedMarker)

        if containsSensitiveToken(in: sanitized.lowercased()) {
            sensitiveTokens.forEach { token in
                sanitized = sanitized.replacingOccurrences(of: token, with: redactedMarker, options: [.caseInsensitive], range: nil)
            }
        }

        return sanitized
    }

    static func sanitizedDescription(for error: Error, category: String? = nil) -> String {
        let nsError = error as NSError
        var components: [String] = []
        if let category, !category.isEmpty {
            components.append("[\(category)]")
        }
        components.append("\(nsError.domain)#\(nsError.code)")

        if !nsError.userInfo.isEmpty {
            let sanitizedUserInfo = sanitizeContext(nsError.userInfo)
            let summary = summarizeContext(sanitizedUserInfo)
            if !summary.isEmpty {
                components.append("userInfo{\(summary)}")
            }
        }

        return sanitizeMessage(components.joined(separator: " "))
    }

    static func sanitizedNSError(from error: Error) -> NSError {
        let nsError = error as NSError
        if nsError.userInfo.isEmpty {
            return nsError
        }
        let sanitizedUserInfo = sanitizeContext(nsError.userInfo)
        return NSError(domain: nsError.domain, code: nsError.code, userInfo: sanitizedUserInfo)
    }

    private static func containsSensitiveToken(in text: String) -> Bool {
        sensitiveTokens.contains { token in
            text.contains(token)
        }
    }

    private static func matchesSensitivePattern(_ text: String) -> Bool {
        let range = NSRange(location: 0, length: text.utf16.count)
        return sensitiveValueRegex.firstMatch(in: text, options: [], range: range) != nil
    }
}
