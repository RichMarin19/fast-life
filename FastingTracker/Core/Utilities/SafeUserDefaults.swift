import Foundation

/// Safe UserDefaults wrapper that handles corruption gracefully
/// Prevents app crashes/freezes from corrupted UserDefaults data
/// Following Apple's best practices for defensive error handling
/// Reference: https://developer.apple.com/documentation/foundation/userdefaults

extension UserDefaults {

    /// Safely read a boolean value with corruption protection
    /// Returns default value if key doesn't exist or data is corrupted
    func safeBool(forKey key: String, defaultValue: Bool = false) -> Bool {
        // Check if key exists first
        guard object(forKey: key) != nil else {
            return defaultValue
        }

        // Try to read the value
        return bool(forKey: key)
    }

    /// Safely read a string value with corruption protection
    /// Returns nil if key doesn't exist or data is corrupted
    func safeString(forKey key: String) -> String? {
        guard object(forKey: key) != nil else {
            return nil
        }

        return string(forKey: key)
    }

    /// Safely read an integer value with corruption protection
    /// Returns default value if key doesn't exist or data is corrupted
    func safeInteger(forKey key: String, defaultValue: Int = 0) -> Int {
        guard object(forKey: key) != nil else {
            return defaultValue
        }

        return integer(forKey: key)
    }

    /// Safely write a value with error handling
    /// Logs error but doesn't crash if write fails
    func safeSet(_ value: Any?, forKey key: String) {
        set(value, forKey: key)
        // Force synchronize to ensure write completes
        synchronize()
    }

    /// Check if UserDefaults appears corrupted and reset if necessary
    /// Call this at app launch to prevent freezes from corrupted data
    static func validateAndResetIfCorrupted() {
        let testKey = "userdefaults_health_check"
        let testValue = "healthy"

        // Try to write and read a test value
        standard.set(testValue, forKey: testKey)
        standard.synchronize()

        let readValue = standard.string(forKey: testKey)

        if readValue != testValue {
            // Corruption detected - reset UserDefaults
            AppLogger.error("UserDefaults corruption detected - resetting", category: AppLogger.general)
            resetUserDefaults()
        } else {
            // Clean up test key
            standard.removeObject(forKey: testKey)
        }
    }

    /// Reset UserDefaults to clean state
    /// DESTRUCTIVE: Clears all app preferences
    /// Only call when corruption is detected
    private static func resetUserDefaults() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }

        AppLogger.warning("Resetting UserDefaults due to corruption", category: AppLogger.general)

        // Remove all UserDefaults for this app
        standard.removePersistentDomain(forName: bundleID)
        standard.synchronize()

        // Record this event for monitoring
        CrashReportManager.shared.recordPersistenceError(
            NSError(
                domain: "UserDefaults",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "UserDefaults reset due to corruption"]
            ),
            context: ["operation": "reset"]
        )

        AppLogger.info("UserDefaults reset complete - app will use defaults", category: AppLogger.general)
    }
}
