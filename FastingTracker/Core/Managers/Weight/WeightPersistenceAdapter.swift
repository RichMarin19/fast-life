import Foundation
import CryptoKit
import Security

protocol WeightPersistenceManaging {
    func loadWeightEntries() -> [WeightEntry]
    func saveWeightEntries(_ entries: [WeightEntry])

    func loadSyncPreference() -> Bool?
    func saveSyncPreference(_ value: Bool)
    func loadFutureSyncStartDate() -> Date?
    func saveFutureSyncStartDate(_ date: Date?)

    func loadStartWeightOverride() -> (weight: Double?, date: Date?)
    func saveStartWeightOverride(weight: Double?, date: Date?)

    func loadMilestoneCount() -> Int?
    func saveMilestoneCount(_ count: Int)

    func loadGoalWeight() -> Double?
    func saveGoalWeight(_ weight: Double)
}

final class WeightPersistenceAdapter: WeightPersistenceManaging {

    private let storage: SecureWeightStoring
    private let legacyBridge: LegacyDefaultsBridge
    private var snapshot: WeightPersistenceSnapshot

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(defaults: ThreadSafeUserDefaults = ThreadSafeUserDefaults(),
         storage: SecureWeightStoring? = nil) {
        self.legacyBridge = LegacyDefaultsBridge(defaults: defaults)

        if let storage {
            self.storage = storage
        } else {
            do {
                self.storage = try SecureWeightStorage()
            } catch {
                CrashReportManager.shared.recordPersistenceError(
                    error,
                    context: ["operation": "secureStorageInit"]
                )
                // Fallback to an in-memory storage that never persists to disk.
                self.storage = InMemorySecureWeightStorage()
            }
        }

        if let encryptedData = try? self.storage.read(),
           let decoded = try? decoder.decode(WeightPersistenceSnapshot.self, from: encryptedData) {
            snapshot = decoded.upgradedSchema()
        } else if let migratedSnapshot = legacyBridge.loadSnapshot() {
            snapshot = migratedSnapshot.upgradedSchema()
            if persistSnapshot() {
                legacyBridge.clearLegacyKeys()
            }
        } else {
            snapshot = WeightPersistenceSnapshot(schemaVersion: WeightPersistenceSnapshot.currentSchemaVersion)
        }
    }

    // MARK: - Weight Entries

    func loadWeightEntries() -> [WeightEntry] {
        snapshot.entries.sorted { $0.date > $1.date }
    }

    func saveWeightEntries(_ entries: [WeightEntry]) {
        snapshot.entries = entries
        persistSnapshot()
    }

    // MARK: - Sync Preference

    func loadSyncPreference() -> Bool? {
        snapshot.syncEnabled
    }

    func saveSyncPreference(_ value: Bool) {
        snapshot.syncEnabled = value
        persistSnapshot()
    }

    func loadFutureSyncStartDate() -> Date? {
        snapshot.futureSyncStartDate
    }

    func saveFutureSyncStartDate(_ date: Date?) {
        snapshot.futureSyncStartDate = date
        persistSnapshot()
    }

    // MARK: - Start Weight Override

    func loadStartWeightOverride() -> (weight: Double?, date: Date?) {
        (snapshot.startWeight?.weight, snapshot.startWeight?.date)
    }

    func saveStartWeightOverride(weight: Double?, date: Date?) {
        if let weight, weight > 0 {
            snapshot.startWeight = StartWeightOverride(weight: weight, date: date)
        } else {
            snapshot.startWeight = nil
        }
        persistSnapshot()
    }

    // MARK: - Milestone Count

    func loadMilestoneCount() -> Int? {
        snapshot.milestoneCount
    }

    func saveMilestoneCount(_ count: Int) {
        snapshot.milestoneCount = count
        persistSnapshot()
    }

    // MARK: - Goal Weight

    func loadGoalWeight() -> Double? {
        snapshot.goalWeight
    }

    func saveGoalWeight(_ weight: Double) {
        snapshot.goalWeight = weight
        persistSnapshot()
    }

    // MARK: - Helpers

    @discardableResult
    private func persistSnapshot() -> Bool {
        do {
            let data = try encoder.encode(snapshot)
            try storage.write(data)
            return true
        } catch {
            CrashReportManager.shared.recordPersistenceError(
                error,
                context: ["operation": "persistSnapshot", "schemaVersion": snapshot.schemaVersion]
            )
            return false
        }
    }
}

// MARK: - Secure Storage

protocol SecureWeightStoring {
    func read() throws -> Data?
    func write(_ data: Data) throws
}

final class SecureWeightStorage: SecureWeightStoring {

    enum StorageError: Error {
        case invalidSealedBox
        case keychain(OSStatus)
    }

    private static let directoryName = "SecureStorage"
    private static let fileName = "weight_persistence_v1.json.enc"

    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "com.fastlife.weight.securestorage", qos: .utility)
    private let storageURL: URL
    private let key: SymmetricKey

    init(fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        self.storageURL = try SecureWeightStorage.makeDirectory(using: fileManager)
        self.key = try SecureKeyStore.shared.fetchKey()
    }

    func read() throws -> Data? {
        try queue.sync {
            let fileURL = storageURL.appendingPathComponent(Self.fileName)
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return nil
            }

            let encryptedData = try Data(contentsOf: fileURL)
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        }
    }

    func write(_ data: Data) throws {
        try queue.sync {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                throw StorageError.invalidSealedBox
            }

            let fileURL = storageURL.appendingPathComponent(Self.fileName)
            try combined.write(to: fileURL, options: [.atomic])
            try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: fileURL.path)
        }
    }

    private static func makeDirectory(using fileManager: FileManager) throws -> URL {
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw StorageError.invalidSealedBox
        }

        let directory = baseURL.appendingPathComponent(directoryName, isDirectory: true)

        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.completeUnlessOpen])
        }

        return directory
    }
}

// MARK: - In-Memory Fallback

final class InMemorySecureWeightStorage: SecureWeightStoring {
    private var data: Data?

    func read() throws -> Data? {
        data
    }

    func write(_ data: Data) throws {
        self.data = data
    }
}

// MARK: - Key Management

private final class SecureKeyStore {

    static let shared = SecureKeyStore()

    private let service = "com.fastlife.securestorage"
    private let account = "weight_persistence_key_v1"

    private init() {}

    func fetchKey() throws -> SymmetricKey {
        if let existingData = try loadKeyData() {
            return SymmetricKey(data: existingData)
        }

        let key = SymmetricKey(size: .bits256)
        try saveKey(key)
        return key
    }

    // MARK: - Private

    private func loadKeyData() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            return item as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw SecureWeightStorage.StorageError.keychain(status)
        }
    }

    private func saveKey(_ key: SymmetricKey) throws {
        let data = key.withUnsafeBytes { Data($0) }

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecureWeightStorage.StorageError.keychain(status)
        }
    }
}

// MARK: - Snapshot Model

private struct WeightPersistenceSnapshot: Codable {
    static let currentSchemaVersion = 2

    var schemaVersion: Int
    var entries: [WeightEntry]
    var syncEnabled: Bool?
    var futureSyncStartDate: Date?
    var startWeight: StartWeightOverride?
    var milestoneCount: Int?
    var goalWeight: Double?

    init(schemaVersion: Int,
         entries: [WeightEntry] = [],
         syncEnabled: Bool? = nil,
         startWeight: StartWeightOverride? = nil,
         milestoneCount: Int? = nil,
         goalWeight: Double? = nil,
         futureSyncStartDate: Date? = nil) {
        self.schemaVersion = schemaVersion
        self.entries = entries
        self.syncEnabled = syncEnabled
        self.futureSyncStartDate = futureSyncStartDate
        self.startWeight = startWeight
        self.milestoneCount = milestoneCount
        self.goalWeight = goalWeight
    }

    func upgradedSchema() -> WeightPersistenceSnapshot {
        guard schemaVersion < Self.currentSchemaVersion else { return self }
        return WeightPersistenceSnapshot(
            schemaVersion: Self.currentSchemaVersion,
            entries: entries,
            syncEnabled: syncEnabled,
            startWeight: startWeight,
            milestoneCount: milestoneCount,
            goalWeight: goalWeight,
            futureSyncStartDate: futureSyncStartDate
        )
    }
}

private struct StartWeightOverride: Codable {
    var weight: Double
    var date: Date?
}

// MARK: - Legacy Migration

private final class LegacyDefaultsBridge {

    private enum Keys {
        static let weightEntries = "weightEntries"
        static let syncHealthKit = "syncWithHealthKit"
        static let startWeight = "weightStartOverride"
        static let startWeightDate = "weightStartDate"
        static let legacyStartWeight = "startWeight"
        static let legacyStartDate = "startDate"
        static let milestoneCount = "weightMilestoneCount"
        static let goalWeight = "goalWeight"
    }

    private let defaults: ThreadSafeUserDefaults
    private let decoder = JSONDecoder()

    init(defaults: ThreadSafeUserDefaults) {
        self.defaults = defaults
    }

    func loadSnapshot() -> WeightPersistenceSnapshot? {
        var snapshot = WeightPersistenceSnapshot(schemaVersion: WeightPersistenceSnapshot.currentSchemaVersion)
        var migrated = false

        if let data = defaults.data(forKey: Keys.weightEntries),
           let entries = try? decoder.decode([WeightEntry].self, from: data) {
            snapshot.entries = entries
            migrated = true
        }

        if defaults.object(forKey: Keys.syncHealthKit) != nil {
            snapshot.syncEnabled = defaults.bool(forKey: Keys.syncHealthKit)
            migrated = true
        }

        let startOverride = loadStartWeight()
        if let startWeight = startOverride.weight {
            snapshot.startWeight = StartWeightOverride(weight: startWeight, date: startOverride.date)
            migrated = true
        }

        if let milestone = defaults.object(forKey: Keys.milestoneCount) as? Int {
            snapshot.milestoneCount = milestone
            migrated = true
        }

        if let goal = defaults.object(forKey: Keys.goalWeight) as? Double {
            snapshot.goalWeight = goal
            migrated = true
        }

        return migrated ? snapshot : nil
    }

    func clearLegacyKeys() {
        defaults.removeObject(forKey: Keys.weightEntries)
        defaults.removeObject(forKey: Keys.syncHealthKit)
        defaults.removeObject(forKey: Keys.startWeight)
        defaults.removeObject(forKey: Keys.startWeightDate)
        defaults.removeObject(forKey: Keys.legacyStartWeight)
        defaults.removeObject(forKey: Keys.legacyStartDate)
        defaults.removeObject(forKey: Keys.milestoneCount)
        defaults.removeObject(forKey: Keys.goalWeight)
    }

    private func loadStartWeight() -> (weight: Double?, date: Date?) {
        var weight: Double?
        var date: Date?

        if let stored = defaults.object(forKey: Keys.startWeight) as? Double, stored > 0 {
            weight = stored
        } else if let legacy = defaults.object(forKey: Keys.legacyStartWeight) as? Double, legacy > 0 {
            weight = legacy
        }

        if let storedDate = defaults.object(forKey: Keys.startWeightDate) as? Date {
            date = storedDate
        } else if let legacyDate = defaults.object(forKey: Keys.legacyStartDate) as? Date {
            date = legacyDate
        }

        return (weight, date)
    }
}
