import Foundation
import OSLog
import UIKit

/// Centralized crash reporting and analytics manager
/// Following Apple best practices for production error tracking
/// Reference: https://firebase.google.com/docs/crashlytics/get-started?platform=ios
public class CrashReportManager {
    public static let shared = CrashReportManager()

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

    /// Initialize crash reporting system
    /// Call this from FastingTrackerApp.init() following Firebase setup guide
    public func initialize() {
        guard !isInitialized else {
            AppLogger.warning("CrashReportManager already initialized", category: AppLogger.general)
            return
        }

        #if DEBUG
        AppLogger.info("CrashReportManager: Debug mode - crash reporting disabled", category: AppLogger.general)
        #else
        // In production, this would initialize Firebase Crashlytics
        // FirebaseApp.configure()
        // Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        AppLogger.info("CrashReportManager initialized for production", category: AppLogger.general)
        #endif

        isInitialized = true
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
        // Log locally using AppLogger
        let contextString = context.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        let logMessage = "Non-fatal error in \(category.rawValue): \(error.localizedDescription)"
        let fullMessage = contextString.isEmpty ? logMessage : "\(logMessage) | \(contextString)"

        AppLogger.error(fullMessage, category: AppLogger.general, error: error)

        // PHASE 0: Persist crash logs securely to Application Support
        persistCrashLogSecurely(error: error, category: category, context: context)

        #if DEBUG
        // In debug mode, just log the error
        print("🚨 CrashReport[\(category.rawValue)]: \(error.localizedDescription)")
        if !context.isEmpty {
            print("   Context: \(contextString)")
        }
        #else
        // In production, this would record to Firebase Crashlytics
        // Crashlytics.crashlytics().record(error: error)
        // Crashlytics.crashlytics().setCustomKeys(context)
        // Crashlytics.crashlytics().log("Category: \(category.rawValue)")
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

    /// Internal method with category parameter
    private func logCustomMessage(_ message: String, category: CrashCategory = .general, level: LogLevel = .info) {
        let logMessage = "Custom[\(category.rawValue)]: \(message)"

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
        // In production, this would log to Firebase Crashlytics
        // Crashlytics.crashlytics().log(logMessage)
        #endif
    }

    // MARK: - User Context

    /// Set user identifier for crash reports (use anonymized ID, never personal info)
    /// Following Apple privacy guidelines - use hashed identifiers only
    public func setUserIdentifier(_ identifier: String) {
        let hashedID = identifier.hash.description // Simple hash for anonymization

        AppLogger.info("Setting user context: \(hashedID)", category: AppLogger.general)

        #if !DEBUG
        // In production, this would set user context in Firebase Crashlytics
        // Crashlytics.crashlytics().setUserID(hashedID)
        #endif
    }

    /// Set custom key-value pairs for crash context
    public func setCustomValue(_ value: Any, forKey key: String) {
        AppLogger.debug("Setting custom value: \(key)=\(value)", category: AppLogger.general)

        #if !DEBUG
        // In production, this would set custom keys in Firebase Crashlytics
        // Crashlytics.crashlytics().setCustomValue(value, forKey: key)
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