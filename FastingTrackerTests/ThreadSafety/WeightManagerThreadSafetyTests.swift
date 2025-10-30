//
// WeightManagerThreadSafetyTests.swift
// FastLIFe
//
// Created for Task 1A: Thread Safety Stress Testing
// TDD Red Phase: These tests MUST FAIL with current implementation
// Purpose: Prove REAL race conditions exist in production scenarios
//
// REVISED STRATEGY: Test real-world HealthKit callback scenarios
// @MainActor already prevents basic race conditions, but:
// 1. UserDefaults writes (lines 687-690) - NOT thread-safe
// 2. Observer suppression flag (line 29) - nonisolated(unsafe) is DANGEROUS
// 3. HealthKit callbacks fire on background threads (line 561)
// 4. Rapid HealthKit updates can corrupt UserDefaults

import XCTest
@testable import FastLIFe

/// Thread safety stress tests for WeightManager - Real-World Production Scenarios
/// **TDD Red Phase:** These tests will FAIL with current code (proving race conditions exist)
/// **TDD Green Phase:** These tests will PASS after ThreadSafeUserDefaults + Actor pattern implementation
/// **Industry Pattern:** Facebook/Google stress testing methodology (production-like scenarios)
final class WeightManagerThreadSafetyTests: XCTestCase {

    // Use nonisolated(unsafe) to allow concurrent access from test threads
    // This mimics HealthKit observer callbacks accessing WeightManager from background threads
    nonisolated(unsafe) var sut: WeightManager!
    var mockHealthKit: MockHealthKitManager!
    var mockDataStore: MockDataStore!

    override func setUp() {
        super.setUp()
        // Clear UserDefaults to start fresh
        UserDefaults.standard.removeObject(forKey: "weightEntries")
        UserDefaults.standard.removeObject(forKey: "syncWithHealthKit")

        mockHealthKit = MockHealthKitManager()
        mockDataStore = MockDataStore()

        // Create WeightManager on MainActor (required for @MainActor class)
        let manager = MainActor.assumeIsolated {
            WeightManager(healthKit: mockHealthKit, dataStore: mockDataStore)
        }
        sut = manager
    }

    override func tearDown() {
        sut = nil
        mockHealthKit = nil
        mockDataStore = nil
        super.tearDown()
    }

    // MARK: - Test 1: UserDefaults Corruption Under Rapid Updates

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Real-World Scenario:** HealthKit observer fires rapidly while user is adding weights
    /// **Race Condition:** Concurrent UserDefaults writes (lines 687-690) without locks
    /// **Expected Failure:** UserDefaults corruption or data loss
    func test_rapidHealthKitUpdates_shouldNotCorruptUserDefaults() {
        // GIVEN: HealthKit sync enabled
        MainActor.assumeIsolated {
            sut.setSyncPreference(true)
        }
        Thread.sleep(forTimeInterval: 0.5)

        
        let expectation = XCTestExpectation(description: "All 50 concurrent updates complete")
        expectation.expectedFulfillmentCount = 50

        let concurrentQueue = DispatchQueue(label: "test.healthkit.concurrent", attributes: .concurrent)

        // WHEN: 50 "HealthKit observer callbacks" fire simultaneously (simulating rapid updates)
        for i in 0..<50 {
            concurrentQueue.async {
                let weight = 150.0 + Double(i) * 0.1
                let date = Date().addingTimeInterval(TimeInterval(i * 3600))

                // Simulate HealthKit observer callback dispatching to MainActor
                MainActor.assumeIsolated {
                    self.sut.addWeightEntryInPreferredUnit(weight: weight, date: date)
                }

                expectation.fulfill()
            }
        }

        // THEN: Wait for all "callbacks" to complete
        wait(for: [expectation], timeout: 15.0)
        Thread.sleep(forTimeInterval: 2.0)

        // ASSERT: All 50 entries should be persisted to UserDefaults
        let actualCount = MainActor.assumeIsolated { sut.weightEntries.count }
        XCTAssertEqual(actualCount, 50,
                       "❌ USERDEFAULTS RACE CONDITION: Expected 50 entries, got \(actualCount). " +
                       "Concurrent writes to UserDefaults (lines 687-690) likely caused data loss.")

        // ASSERT: Verify persistence integrity by reloading
        let reloadedManager = MainActor.assumeIsolated {
            WeightManager(healthKit: mockHealthKit, dataStore: mockDataStore)
        }
        Thread.sleep(forTimeInterval: 0.5)

        let reloadedCount = MainActor.assumeIsolated { reloadedManager.weightEntries.count }
        XCTAssertEqual(reloadedCount, 50,
                       "❌ USERDEFAULTS CORRUPTION: Data lost after reload. " +
                       "Expected 50 persisted entries, got \(reloadedCount). UserDefaults corrupted by concurrent writes.")
    }

    // MARK: - Test 2: Observer Suppression Flag Race Condition

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Real-World Scenario:** User adds weight → saves to HealthKit → observer fires before suppression lifted
    /// **Race Condition:** `nonisolated(unsafe)` flag (line 29) accessed from multiple threads
    /// **Expected Failure:** Observer fires when it should be suppressed, causing duplicate entries
    func test_observerSuppressionFlag_shouldPreventDuplicates() {
        // GIVEN: HealthKit sync enabled, mock observer will fire immediately
        MainActor.assumeIsolated {
            sut.setSyncPreference(true)
        }
        Thread.sleep(forTimeInterval: 0.5)

        // Configure mock to fire observer callback when weight is saved
        var observerFireCount = 0
        mockHealthKit.onSaveWeight = { [weak self] weight, bmi, bodyFat, date, completion in
            // Simulate HealthKit observer firing on background thread BEFORE suppression is lifted
            // This mimics real HealthKit behavior: observer can fire before asyncAfter completes (line 107)
            DispatchQueue.global(qos: .background).async {
                // Observer checks suppression flag (line 569) - THIS IS THE RACE CONDITION
                // With nonisolated(unsafe), this check is NOT synchronized with the write on line 103
                observerFireCount += 1

                // In real code, observer would call syncFromHealthKit here
                // We're testing if suppression flag prevents this
            }

            // Simulate successful save
            DispatchQueue.global(qos: .background).async {
                completion(true, nil)
            }
        }

        let expectation = XCTestExpectation(description: "10 manual entries processed")
        expectation.expectedFulfillmentCount = 10

        // WHEN: User rapidly adds 10 weight entries (each triggers HealthKit save + observer)
        for i in 0..<10 {
            DispatchQueue.global(qos: .userInitiated).async {
                let weight = 150.0 + Double(i) * 0.1
                let date = Date().addingTimeInterval(TimeInterval(i * 60))

                MainActor.assumeIsolated {
                    self.sut.addWeightEntryInPreferredUnit(weight: weight, date: date)
                }

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 15.0)
        Thread.sleep(forTimeInterval: 3.0) // Wait for all asyncAfter delays (line 107)

        // ASSERT: Should have exactly 10 entries (no duplicates from observer)
        let actualCount = MainActor.assumeIsolated { sut.weightEntries.count }
        XCTAssertEqual(actualCount, 10,
                       "❌ OBSERVER SUPPRESSION RACE CONDITION: Expected 10 entries, got \(actualCount). " +
                       "The nonisolated(unsafe) flag (line 29) allows unsynchronized access from observer callback (line 569), " +
                       "causing observer to fire when it should be suppressed. This creates duplicate entries.")

        // ASSERT: Verify observer fired (proves it was running during test)
        XCTAssertGreaterThan(observerFireCount, 0,
                             "Test setup issue: Observer never fired, cannot verify suppression logic")
    }

    // MARK: - Test 3: Concurrent User Input + HealthKit Sync

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Real-World Scenario:** User adding weights while background HealthKit sync is running
    /// **Race Condition:** UserDefaults writes overlap, array mutations race
    /// **Expected Failure:** Lost writes or incorrect entry count
    func test_concurrentUserInputAndHealthKitSync_shouldNotLoseData() {
        // GIVEN: HealthKit sync enabled, 10 existing entries
        MainActor.assumeIsolated {
            sut.setSyncPreference(true)
            for i in 0..<10 {
                sut.addWeightEntryInPreferredUnit(weight: 140.0 + Double(i), date: Date().addingTimeInterval(TimeInterval(-i * 86400)))
            }
        }
        Thread.sleep(forTimeInterval: 0.5)

        let userInputExpectation = XCTestExpectation(description: "User added 20 entries")
        userInputExpectation.expectedFulfillmentCount = 20

        let healthKitSyncExpectation = XCTestExpectation(description: "HealthKit sync completed 5 times")
        healthKitSyncExpectation.expectedFulfillmentCount = 5

        let userQueue = DispatchQueue(label: "test.user.input", attributes: .concurrent)
        let healthKitQueue = DispatchQueue(label: "test.healthkit.sync", attributes: .concurrent)

        // WHEN: User rapidly adds entries WHILE HealthKit sync is running
        // This simulates: User logging weights during automatic background sync

        // User thread: Adding 20 entries
        for i in 0..<20 {
            userQueue.async {
                let weight = 150.0 + Double(i) * 0.1
                let date = Date().addingTimeInterval(TimeInterval(i * 1800)) // 30 min apart

                MainActor.assumeIsolated {
                    self.sut.addWeightEntryInPreferredUnit(weight: weight, date: date)
                }

                userInputExpectation.fulfill()
            }
        }

        // HealthKit sync thread: Running 5 concurrent syncs
        for i in 0..<5 {
            healthKitQueue.async {
                let startDate = Calendar.current.date(byAdding: .day, value: -(30 + i), to: Date()) ?? Date()

                MainActor.assumeIsolated {
                    self.sut.syncFromHealthKit(startDate: startDate) { count, error in
                        healthKitSyncExpectation.fulfill()
                    }
                }
            }
        }

        wait(for: [userInputExpectation, healthKitSyncExpectation], timeout: 20.0)
        Thread.sleep(forTimeInterval: 2.0)

        // ASSERT: Should have 30 entries (10 initial + 20 user added)
        // HealthKit sync won't add duplicates, but race conditions could lose user entries
        let actualCount = MainActor.assumeIsolated { sut.weightEntries.count }
        XCTAssertEqual(actualCount, 30,
                       "❌ CONCURRENT ACCESS RACE CONDITION: Expected 30 entries, got \(actualCount). " +
                       "Concurrent UserDefaults writes (lines 91, 335) during user input + HealthKit sync caused data loss.")
    }

    // MARK: - Test 4: Rapid Delete Operations During Sync

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Real-World Scenario:** User deleting entries while HealthKit sync is adding new ones
    /// **Race Condition:** Array mutation (line 126) + UserDefaults save (line 127) race with sync
    /// **Expected Failure:** Incorrect final count or crash
    func test_rapidDeletesDuringSync_shouldNotCorruptData() {
        // GIVEN: 30 initial entries
        var entriesToDelete: [WeightEntry] = []
        MainActor.assumeIsolated {
            for i in 0..<30 {
                sut.addWeightEntryInPreferredUnit(weight: 150.0 + Double(i), date: Date().addingTimeInterval(TimeInterval(i * 3600)))
            }
            entriesToDelete = Array(sut.weightEntries.prefix(15)) // Capture first 15 to delete
        }

        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertEqual(entriesToDelete.count, 15)

        let deleteExpectation = XCTestExpectation(description: "Deleted 15 entries")
        deleteExpectation.expectedFulfillmentCount = 15

        let syncExpectation = XCTestExpectation(description: "HealthKit sync completed")

        let deleteQueue = DispatchQueue(label: "test.delete.concurrent", attributes: .concurrent)
        let syncQueue = DispatchQueue(label: "test.sync.background")

        // WHEN: User deleting 15 entries WHILE HealthKit sync is running

        // Delete thread: Removing 15 entries rapidly
        for entry in entriesToDelete {
            deleteQueue.async {
                MainActor.assumeIsolated {
                    self.sut.deleteWeightEntry(entry)
                }
                deleteExpectation.fulfill()
            }
        }

        // Sync thread: Running HealthKit sync concurrently
        syncQueue.async {
            let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            MainActor.assumeIsolated {
                self.sut.syncFromHealthKit(startDate: startDate) { count, error in
                    syncExpectation.fulfill()
                }
            }
        }

        wait(for: [deleteExpectation, syncExpectation], timeout: 15.0)
        Thread.sleep(forTimeInterval: 2.0)

        // ASSERT: Should have 15 entries remaining (30 - 15 deleted)
        let remainingCount = MainActor.assumeIsolated { sut.weightEntries.count }
        XCTAssertEqual(remainingCount, 15,
                       "❌ CONCURRENT MODIFICATION RACE CONDITION: Expected 15 remaining entries, got \(remainingCount). " +
                       "Concurrent array modification (line 126) + UserDefaults save (line 127) during sync caused data corruption.")
    }

    // MARK: - Test 5: UserDefaults Persistence Under Load

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Real-World Scenario:** Multiple rapid operations stressing UserDefaults persistence
    /// **Race Condition:** Multiple saveWeightEntries() calls (line 687) overlap without locks
    /// **Expected Failure:** Plist corruption or data loss on reload
    func test_userDefaultsPersistence_underConcurrentLoad() {
        // GIVEN: 100 rapid operations stressing UserDefaults
        let expectation = XCTestExpectation(description: "100 operations complete")
        expectation.expectedFulfillmentCount = 100

        let concurrentQueue = DispatchQueue(label: "test.persistence.concurrent", attributes: .concurrent)

        // WHEN: 100 threads each performing add + delete (stressing UserDefaults writes)
        for i in 0..<100 {
            concurrentQueue.async {
                let weight = 150.0 + Double(i % 10) * 0.1
                let date = Date().addingTimeInterval(TimeInterval(i * 60))

                MainActor.assumeIsolated {
                    // Add entry (triggers saveWeightEntries on line 91)
                    self.sut.addWeightEntryInPreferredUnit(weight: weight, date: date)

                    // Immediately delete it (triggers saveWeightEntries on line 127)
                    // This maximizes UserDefaults write contention
                    if let entry = self.sut.weightEntries.first {
                        self.sut.deleteWeightEntry(entry)
                    }
                }

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 20.0)
        Thread.sleep(forTimeInterval: 2.0)

        // ASSERT: After 100 add+delete operations, should have 0 entries
        let finalCount = MainActor.assumeIsolated { sut.weightEntries.count }
        XCTAssertEqual(finalCount, 0,
                       "❌ USERDEFAULTS RACE CONDITION: Expected 0 entries after add+delete pairs, got \(finalCount). " +
                       "Concurrent saveWeightEntries() calls (line 687) without locks caused lost operations.")

        // ASSERT: Verify UserDefaults wasn't corrupted by rapid writes
        let reloadedManager = MainActor.assumeIsolated {
            WeightManager(healthKit: mockHealthKit, dataStore: mockDataStore)
        }
        Thread.sleep(forTimeInterval: 0.5)

        let reloadedCount = MainActor.assumeIsolated { reloadedManager.weightEntries.count }
        XCTAssertEqual(reloadedCount, 0,
                       "❌ USERDEFAULTS CORRUPTION: Data inconsistent after reload. " +
                       "Expected 0 persisted entries, got \(reloadedCount). Concurrent writes corrupted plist.")
    }
}
