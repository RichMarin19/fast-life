//
// ThreadSafeUserDefaults.swift
// FastLIFe
//
// Created for Task 1A: Thread Safety Fixes
// Purpose: Thread-safe wrapper around UserDefaults using NSLock
// Industry Pattern: Spotify, Instagram, Facebook use this pattern for shared resources
//

import Foundation

/// Thread-safe wrapper for UserDefaults operations
/// **Problem:** UserDefaults is NOT thread-safe - concurrent writes can corrupt the plist file
/// **Solution:** NSLock synchronizes all read/write operations
/// **Industry Pattern:** Standard approach for wrapping shared mutable state
/// **Reference:** https://developer.apple.com/documentation/foundation/userdefaults
final class ThreadSafeUserDefaults {

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let lock = NSLock()

    // MARK: - Initialization

    /// Initialize with specific UserDefaults suite
    /// - Parameter userDefaults: The UserDefaults instance to wrap (default: .standard)
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Thread-Safe Write Operations

    /// Thread-safe set value for key
    /// All writes are synchronized using NSLock
    func set<T>(_ value: T, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }

        userDefaults.set(value, forKey: key)
    }

    /// Thread-safe set data for key
    func set(_ value: Data?, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }

        userDefaults.set(value, forKey: key)
    }

    /// Thread-safe set bool for key
    func set(_ value: Bool, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }

        userDefaults.set(value, forKey: key)
    }

    /// Thread-safe remove object for key
    func removeObject(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }

        userDefaults.removeObject(forKey: key)
    }

    // MARK: - Thread-Safe Read Operations

    /// Thread-safe get data for key
    func data(forKey key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }

        return userDefaults.data(forKey: key)
    }

    /// Thread-safe get bool for key
    func bool(forKey key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        return userDefaults.bool(forKey: key)
    }

    /// Thread-safe get object for key
    func object(forKey key: String) -> Any? {
        lock.lock()
        defer { lock.unlock() }

        return userDefaults.object(forKey: key)
    }

    /// Thread-safe get string for key
    func string(forKey key: String) -> String? {
        lock.lock()
        defer { lock.unlock() }

        return userDefaults.string(forKey: key)
    }

    /// Thread-safe get integer for key
    func integer(forKey key: String) -> Int {
        lock.lock()
        defer { lock.unlock() }

        return userDefaults.integer(forKey: key)
    }

    /// Thread-safe get double for key
    func double(forKey key: String) -> Double {
        lock.lock()
        defer { lock.unlock() }

        return userDefaults.double(forKey: key)
    }

    // MARK: - Batch Operations

    /// Execute multiple operations atomically
    /// Useful when you need to read-modify-write without interleaving from other threads
    func synchronized<T>(_ block: (UserDefaults) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }

        return block(userDefaults)
    }
}

// MARK: - Usage Examples (for documentation)

/*
 Example 1: Simple write
 ```swift
 let safeDefaults = ThreadSafeUserDefaults()
 safeDefaults.set(encodedData, forKey: "weightEntries")
 ```

 Example 2: Simple read
 ```swift
 let data = safeDefaults.data(forKey: "weightEntries")
 ```

 Example 3: Atomic read-modify-write
 ```swift
 safeDefaults.synchronized { defaults in
     // Multiple operations execute atomically
     let data = defaults.data(forKey: "weightEntries")
     // ... process data ...
     defaults.set(newData, forKey: "weightEntries")
 }
 ```

 Why This Works:
 - NSLock ensures only ONE thread can access UserDefaults at a time
 - defer ensures lock is always released (even if error occurs)
 - All UserDefaults operations go through the lock
 - Prevents plist corruption from concurrent writes
 */
