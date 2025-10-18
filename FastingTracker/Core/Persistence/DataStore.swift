import Foundation

/// Protocol-based data store for reliable persistence with error handling
/// Following Apple Data Management best practices
/// Reference: https://developer.apple.com/documentation/foundation/userdefaults
protocol DataStore {
    func save<T: Codable>(_ object: T, forKey key: String) throws
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
    func remove(forKey key: String) throws
    func exists(forKey key: String) -> Bool
}

/// UserDefaults wrapper with size limits and comprehensive error handling
/// Implements protocol-based data store pattern for production reliability
class UserDefaultsDataStore: DataStore {

    private let userDefaults: UserDefaults
    private let maxDataSize: Int = 1_048_576 // 1MB limit per key (iOS UserDefaults best practice)

    // MARK: - Errors

    enum DataStoreError: LocalizedError {
        case encodingFailed(String)
        case decodingFailed(String)
        case dataTooLarge(String, Int, Int) // key, size, limit
        case keyNotFound(String)
        case persistenceFailed(String)
        case invalidData(String)

        var errorDescription: String? {
            switch self {
            case .encodingFailed(let key):
                return "Failed to encode data for key '\(key)'"
            case .decodingFailed(let key):
                return "Failed to decode data for key '\(key)'"
            case .dataTooLarge(let key, let size, let limit):
                return "Data for key '\(key)' is too large (\(size) bytes, limit: \(limit) bytes)"
            case .keyNotFound(let key):
                return "No data found for key '\(key)'"
            case .persistenceFailed(let key):
                return "Failed to persist data for key '\(key)'"
            case .invalidData(let key):
                return "Invalid data format for key '\(key)'"
            }
        }
    }

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - DataStore Protocol Implementation

    func save<T: Codable>(_ object: T, forKey key: String) throws {
        do {
            // Encode object to Data
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601 // Consistent date handling
            let data = try encoder.encode(object)

            // Check size limits to prevent UserDefaults bloat
            if data.count > maxDataSize {
                let error = DataStoreError.dataTooLarge(key, data.count, maxDataSize)
                CrashReportManager.shared.recordPersistenceError(error, context: [
                    "operation": "save",
                    "key": key,
                    "dataSize": data.count,
                    "limit": maxDataSize
                ])
                throw error
            }

            // Save to UserDefaults
            userDefaults.set(data, forKey: key)

            // Verify persistence (iOS can silently fail UserDefaults operations)
            guard userDefaults.data(forKey: key) != nil else {
                let error = DataStoreError.persistenceFailed(key)
                CrashReportManager.shared.recordPersistenceError(error, context: [
                    "operation": "save_verification",
                    "key": key
                ])
                throw error
            }

            // Log successful save for debugging
            AppLogger.debug("Successfully saved data for key '\(key)' (\(data.count) bytes)", category: AppLogger.general)

        } catch let encodingError as EncodingError {
            let error = DataStoreError.encodingFailed(key)
            CrashReportManager.shared.recordPersistenceError(error, context: [
                "operation": "encode",
                "key": key,
                "underlyingError": encodingError.localizedDescription
            ])
            throw error
        } catch {
            // Re-throw DataStoreError, wrap others
            if error is DataStoreError {
                throw error
            } else {
                let wrappedError = DataStoreError.persistenceFailed(key)
                CrashReportManager.shared.recordPersistenceError(wrappedError, context: [
                    "operation": "save_general",
                    "key": key,
                    "underlyingError": error.localizedDescription
                ])
                throw wrappedError
            }
        }
    }

    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        // Check if key exists
        guard exists(forKey: key) else {
            return nil // Not an error - key might not exist yet
        }

        guard let data = userDefaults.data(forKey: key) else {
            // Key exists but no data - this shouldn't happen
            let error = DataStoreError.invalidData(key)
            CrashReportManager.shared.recordPersistenceError(error, context: [
                "operation": "load_missing_data",
                "key": key
            ])
            throw error
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 // Consistent date handling
            let object = try decoder.decode(type, from: data)

            AppLogger.debug("Successfully loaded data for key '\(key)' (\(data.count) bytes)", category: AppLogger.general)
            return object

        } catch let decodingError as DecodingError {
            let error = DataStoreError.decodingFailed(key)
            CrashReportManager.shared.recordPersistenceError(error, context: [
                "operation": "decode",
                "key": key,
                "dataSize": data.count,
                "underlyingError": decodingError.localizedDescription
            ])
            throw error
        } catch {
            let wrappedError = DataStoreError.decodingFailed(key)
            CrashReportManager.shared.recordPersistenceError(wrappedError, context: [
                "operation": "load_general",
                "key": key,
                "underlyingError": error.localizedDescription
            ])
            throw wrappedError
        }
    }

    func remove(forKey key: String) throws {
        guard exists(forKey: key) else {
            // Not an error - key might already be removed
            return
        }

        userDefaults.removeObject(forKey: key)

        // Verify removal
        if exists(forKey: key) {
            let error = DataStoreError.persistenceFailed(key)
            CrashReportManager.shared.recordPersistenceError(error, context: [
                "operation": "remove_verification",
                "key": key
            ])
            throw error
        }

        AppLogger.debug("Successfully removed data for key '\(key)'", category: AppLogger.general)
    }

    func exists(forKey key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }

    // MARK: - Data Migration Methods
    // Following Apple Data Migration Guidelines
    // Reference: https://developer.apple.com/documentation/coredata/lightweight_migration

    /// Migrates old UserDefaults data to new Codable format
    /// Call this once during app upgrade to preserve existing user data
    func migrateIfNeeded() {
        var migrationCount = 0

        // Migrate simple value types
        if hasOldFormatData(forKey: "fastingGoalHours") {
            migrateDoubleValue(forKey: "fastingGoalHours")
            migrationCount += 1
        }

        if hasOldFormatData(forKey: "currentStreak") {
            migrateIntValue(forKey: "currentStreak")
            migrationCount += 1
        }

        if hasOldFormatData(forKey: "longestStreak") {
            migrateIntValue(forKey: "longestStreak")
            migrationCount += 1
        }

        // Migrate complex types (arrays)
        if hasOldFormatData(forKey: "fastingHistory") {
            migrateFastingHistory()
            migrationCount += 1
        }

        if hasOldFormatData(forKey: "currentFastingSession") {
            migrateCurrentSession()
            migrationCount += 1
        }

        if migrationCount > 0 {
            AppLogger.info("Migrated \(migrationCount) data keys from old format", category: AppLogger.general)
            CrashReportManager.shared.logCustomMessage("Data migration completed successfully", level: .info)
        }
    }

    /// Checks if key exists in old UserDefaults format (not JSON data)
    private func hasOldFormatData(forKey key: String) -> Bool {
        guard let object = userDefaults.object(forKey: key) else { return false }

        // If it's Data, it's likely our new JSON format
        if object is Data { return false }

        // If it's a basic type (String, Number, Array, Dict), it's old format
        return object is String || object is NSNumber || object is Array<Any> || object is Dictionary<String, Any>
    }

    /// Migrates Double value from old format
    private func migrateDoubleValue(forKey key: String) {
        guard let value = userDefaults.object(forKey: key) as? Double else { return }

        do {
            try save(value, forKey: key)
            AppLogger.debug("Migrated \(key): \(value)", category: AppLogger.general)
        } catch {
            AppLogger.error("Failed to migrate \(key): \(error)", category: AppLogger.general)
        }
    }

    /// Migrates Int value from old format
    private func migrateIntValue(forKey key: String) {
        guard let value = userDefaults.object(forKey: key) as? Int else { return }

        do {
            try save(value, forKey: key)
            AppLogger.debug("Migrated \(key): \(value)", category: AppLogger.general)
        } catch {
            AppLogger.error("Failed to migrate \(key): \(error)", category: AppLogger.general)
        }
    }

    /// Migrates fasting history array from old UserDefaults format
    private func migrateFastingHistory() {
        guard let historyData = userDefaults.array(forKey: "fastingHistory") as? [[String: Any]] else { return }

        var migratedSessions: [FastingSession] = []

        for sessionDict in historyData {
            if let session = createFastingSession(from: sessionDict) {
                migratedSessions.append(session)
            }
        }

        do {
            try save(migratedSessions, forKey: "fastingHistory")
            AppLogger.debug("Migrated fastingHistory: \(migratedSessions.count) sessions", category: AppLogger.general)
        } catch {
            AppLogger.error("Failed to migrate fastingHistory: \(error)", category: AppLogger.general)
        }
    }

    /// Migrates current session from old UserDefaults format
    private func migrateCurrentSession() {
        guard let sessionDict = userDefaults.dictionary(forKey: "currentFastingSession") else { return }

        if let session = createFastingSession(from: sessionDict) {
            do {
                try save(session, forKey: "currentFastingSession")
                AppLogger.debug("Migrated currentFastingSession", category: AppLogger.general)
            } catch {
                AppLogger.error("Failed to migrate currentFastingSession: \(error)", category: AppLogger.general)
            }
        }
    }

    /// Creates FastingSession from old dictionary format
    private func createFastingSession(from dict: [String: Any]) -> FastingSession? {
        // Extract required fields with safe conversion
        guard let startTimeInterval = dict["startTime"] as? TimeInterval else { return nil }

        let startTime = Date(timeIntervalSince1970: startTimeInterval)
        let endTime: Date? = {
            if let endTimeInterval = dict["endTime"] as? TimeInterval {
                return Date(timeIntervalSince1970: endTimeInterval)
            }
            return nil
        }()

        let goalHours = dict["goalHours"] as? Double ?? 16.0

        return FastingSession(
            startTime: startTime,
            endTime: endTime,
            goalHours: goalHours
        )
    }
}

// MARK: - Safe DataStore Extension

extension DataStore {

    /// Safe save with automatic error handling and logging
    func safeSave<T: Codable>(_ object: T, forKey key: String) -> Bool {
        do {
            try save(object, forKey: key)
            return true
        } catch {
            AppLogger.error("Failed to save data for key '\(key)': \(error.localizedDescription)", category: AppLogger.general)
            return false
        }
    }

    /// Safe load with automatic error handling and default value
    func safeLoad<T: Codable>(_ type: T.Type, forKey key: String, default defaultValue: T? = nil) -> T? {
        do {
            return try load(type, forKey: key) ?? defaultValue
        } catch {
            AppLogger.error("Failed to load data for key '\(key)': \(error.localizedDescription)", category: AppLogger.general)
            return defaultValue
        }
    }

    /// Safe remove with automatic error handling
    func safeRemove(forKey key: String) -> Bool {
        do {
            try remove(forKey: key)
            return true
        } catch {
            AppLogger.error("Failed to remove data for key '\(key)': \(error.localizedDescription)", category: AppLogger.general)
            return false
        }
    }
}

// MARK: - Shared Instance for App-wide Use

/// Shared data store instance for the entire app
/// Replace direct UserDefaults.standard usage with this
class AppDataStore {
    static let shared: DataStore = {
        let store = UserDefaultsDataStore()
        // Perform migration on first access to preserve existing user data
        // Following Apple's data migration pattern for app updates
        store.migrateIfNeeded()
        return store
    }()

    private init() {}

    /// Access to migration functionality for testing
    static var dataStore: UserDefaultsDataStore {
        return shared as! UserDefaultsDataStore
    }
}

// MARK: - Migration Helper

/// Helper class for migrating existing UserDefaults usage to protocol-based store
class DataStoreMigrationHelper {

    private let dataStore: DataStore

    init(dataStore: DataStore = AppDataStore.shared) {
        self.dataStore = dataStore
    }

    /// Migrate existing UserDefaults string value to protocol-based store
    func migrateStringValue(oldKey: String, newKey: String? = nil) {
        let targetKey = newKey ?? oldKey
        let userDefaults = UserDefaults.standard

        if let value = userDefaults.string(forKey: oldKey) {
            let success = dataStore.safeSave(value, forKey: targetKey)
            if success {
                userDefaults.removeObject(forKey: oldKey)
                AppLogger.info("Migrated string value from '\(oldKey)' to protocol-based store", category: AppLogger.general)
            }
        }
    }

    /// Migrate existing UserDefaults bool value to protocol-based store
    func migrateBoolValue(oldKey: String, newKey: String? = nil) {
        let targetKey = newKey ?? oldKey
        let userDefaults = UserDefaults.standard

        if userDefaults.object(forKey: oldKey) != nil {
            let value = userDefaults.bool(forKey: oldKey)
            let success = dataStore.safeSave(value, forKey: targetKey)
            if success {
                userDefaults.removeObject(forKey: oldKey)
                AppLogger.info("Migrated bool value from '\(oldKey)' to protocol-based store", category: AppLogger.general)
            }
        }
    }

    /// Migrate existing UserDefaults date value to protocol-based store
    func migrateDateValue(oldKey: String, newKey: String? = nil) {
        let targetKey = newKey ?? oldKey
        let userDefaults = UserDefaults.standard

        if let value = userDefaults.object(forKey: oldKey) as? Date {
            let success = dataStore.safeSave(value, forKey: targetKey)
            if success {
                userDefaults.removeObject(forKey: oldKey)
                AppLogger.info("Migrated date value from '\(oldKey)' to protocol-based store", category: AppLogger.general)
            }
        }
    }
}

// MARK: - Testing Support

#if DEBUG
/// Mock data store for unit testing
class MockDataStore: DataStore {
    private var storage: [String: Data] = [:]
    var shouldThrowError = false
    var throwErrorOnKeys: Set<String> = []

    func save<T: Codable>(_ object: T, forKey key: String) throws {
        if shouldThrowError || throwErrorOnKeys.contains(key) {
            throw UserDefaultsDataStore.DataStoreError.persistenceFailed(key)
        }

        let data = try JSONEncoder().encode(object)
        storage[key] = data
    }

    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        if shouldThrowError || throwErrorOnKeys.contains(key) {
            throw UserDefaultsDataStore.DataStoreError.decodingFailed(key)
        }

        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }

    func remove(forKey key: String) throws {
        if shouldThrowError || throwErrorOnKeys.contains(key) {
            throw UserDefaultsDataStore.DataStoreError.persistenceFailed(key)
        }

        storage.removeValue(forKey: key)
    }

    func exists(forKey key: String) -> Bool {
        return storage[key] != nil
    }

    func clearAll() {
        storage.removeAll()
    }
}
#endif