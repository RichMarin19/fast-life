//
// ObserverSuppressionActor.swift
// FastLIFe
//
// Created for Task 1A: Thread Safety Fixes
// Purpose: Thread-safe observer suppression flag using Swift Actor pattern
// Replaces: nonisolated(unsafe) var isSuppressingObserver (WeightManager line 29)
//

import Foundation

/// Thread-safe observer suppression coordinator using Swift Actor pattern
/// **Problem:** `nonisolated(unsafe)` bypasses ALL Swift concurrency safety checks
/// **Solution:** Actor provides automatic synchronization across threads
/// **Industry Pattern:** Swift Concurrency best practice for shared mutable state
/// **Reference:** https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html
actor ObserverSuppressionActor {

    // MARK: - State

    /// Whether observer callbacks should be suppressed
    /// Private - only accessible through actor-isolated methods
    private var isSuppressing: Bool = false

    // MARK: - Public API

    /// Check if observer should be suppressed
    /// - Returns: true if observer callbacks should be ignored, false otherwise
    func isSuppressed() -> Bool {
        return isSuppressing
    }

    /// Enable observer suppression
    /// Call before manual operations that will trigger HealthKit observer
    func suppress() {
        isSuppressing = true
    }

    /// Disable observer suppression
    /// Call after manual operation completes and observer can fire again
    func unsuppress() {
        isSuppressing = false
    }

    /// Temporarily suppress observer, then restore after delay
    /// Use for operations that trigger HealthKit saves + observer callbacks
    /// - Parameter delay: Time interval to wait before restoring observer (default: 2.0 seconds)
    func suppressTemporarily(delay: TimeInterval = 2.0) async {
        isSuppressing = true

        // Wait for delay before restoring
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        isSuppressing = false
    }
}

// MARK: - Usage Examples (for documentation)

/*
 Example 1: Check if suppressed (in HealthKit observer callback)
 ```swift
 let actor = ObserverSuppressionActor()

 // In HealthKit observer callback (on background thread)
 Task {
     let suppressed = await actor.isSuppressed()
     guard !suppressed else {
         AppLogger.info("Observer suppressed during manual operation")
         return
     }
     // Proceed with sync
 }
 ```

 Example 2: Manual suppress/unsuppress
 ```swift
 // Before manual operation
 await actor.suppress()

 // Perform operation that triggers HealthKit + observer
 healthKit.saveWeight(...) { success, error in
     Task {
         await actor.unsuppress()
     }
 }
 ```

 Example 3: Temporary suppression (recommended)
 ```swift
 // Suppress for 2 seconds, then auto-restore
 Task {
     await actor.suppressTemporarily(delay: 2.0)
 }

 // Meanwhile, perform operation
 healthKit.saveWeight(...)
 ```

 Why Actors Work:
 - Actor methods are async - automatically synchronized
 - Only ONE task can access actor state at a time
 - Swift runtime enforces this - no manual locks needed
 - Replaces dangerous nonisolated(unsafe) with type-safe concurrency
 - HealthKit observer callback can safely check flag from background thread

 Performance Note:
 - Actor access requires `await` (potential suspension point)
 - This is acceptable for observer suppression (not a hot path)
 - Much safer than nonisolated(unsafe) data races
 */
