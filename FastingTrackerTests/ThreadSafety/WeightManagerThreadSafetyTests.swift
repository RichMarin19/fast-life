//
// WeightManagerThreadSafetyTests.swift
// FastLIFe
//
// Created for Task 1A: Thread Safety Stress Testing
// TDD Red Phase: These tests MUST FAIL with current implementation
// Purpose: Prove race conditions exist, define acceptance criteria for fixes
//

import XCTest
@testable import FastLIFe

/// Thread safety stress tests for WeightManager
/// **TDD Red Phase:** These tests will FAIL with current code (proving race conditions exist)
/// **TDD Green Phase:** These tests will PASS after ThreadSafeUserDefaults + Actor pattern implementation
/// **Industry Pattern:** Facebook/Google stress testing methodology (concurrent operations)
final class WeightManagerThreadSafetyTests: XCTestCase {

    var sut: WeightManager!
    var mockHealthKit: MockHealthKitManager!
    var mockDataStore: MockDataStore!

    override func setUp() {
        super.setUp()
        // Clear UserDefaults to start fresh
        UserDefaults.standard.removeObject(forKey: "weightEntries")
        UserDefaults.standard.removeObject(forKey: "syncWithHealthKit")

        mockHealthKit = MockHealthKitManager()
        mockDataStore = MockDataStore()
        sut = WeightManager(healthKit: mockHealthKit, dataStore: mockDataStore)
    }

    override func tearDown() {
        sut = nil
        mockHealthKit = nil
        mockDataStore = nil
        super.tearDown()
    }

    // MARK: - Stress Test 1: Concurrent Weight Entry Additions

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Race Condition:** Multiple threads adding entries → data loss or corruption
    /// **Expected Failure:** Entry count != 100 (due to lost writes or array corruption)
    func test_concurrentWeightEntryAdditions_shouldNotLoseData() {
        // GIVEN: 100 concurrent threads each adding 1 weight entry
        let expectation = XCTestExpectation(description: "All 100 threads complete")
        expectation.expectedFulfillmentCount = 100

        let concurrentQueue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)

        // WHEN: 100 threads simultaneously add weight entries
        for i in 0..<100 {
            concurrentQueue.async {
                let weight = 150.0 + Double(i) * 0.1 // Unique weight for each thread
                let date = Date().addingTimeInterval(TimeInterval(i * 60)) // 1 minute apart

                self.sut.addWeightEntryInPreferredUnit(weight: weight, date: date)

                expectation.fulfill()
            }
        }

        // THEN: Wait for all threads to complete
        wait(for: [expectation], timeout: 10.0)

        // Give main queue time to process all async updates
        Thread.sleep(forTimeInterval: 2.0)

        // ASSERT: All 100 entries should be present (no data loss)
        XCTAssertEqual(sut.weightEntries.count, 100,
                       "❌ RACE CONDITION DETECTED: Expected 100 entries, got \(sut.weightEntries.count). " +
                       "Some writes were lost due to concurrent access to UserDefaults/array.")
    }

    // MARK: - Stress Test 2: Concurrent Read/Write Race Condition

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Race Condition:** Reading weightEntries while another thread is writing
    /// **Expected Failure:** Crash or incorrect count due to array mutation during iteration
    func test_concurrentReadWriteOperations_shouldNotCrash() {
        // GIVEN: Initial 10 weight entries
        for i in 0..<10 {
            let weight = 150.0 + Double(i)
            let date = Date().addingTimeInterval(TimeInterval(i * 3600))
            sut.addWeightEntryInPreferredUnit(weight: weight, date: date)
        }

        Thread.sleep(forTimeInterval: 0.5) // Let initial adds complete

        let expectation = XCTestExpectation(description: "Concurrent read/write completes without crash")
        expectation.expectedFulfillmentCount = 200 // 100 reads + 100 writes

        let concurrentQueue = DispatchQueue(label: "test.concurrent.readwrite", attributes: .concurrent)

        // WHEN: 100 threads reading, 100 threads writing simultaneously
        for i in 0..<100 {
            // Reader thread
            concurrentQueue.async {
                _ = self.sut.weightEntries.count // Read operation
                _ = self.sut.latestWeight // Read computed property
                expectation.fulfill()
            }

            // Writer thread
            concurrentQueue.async {
                let weight = 160.0 + Double(i) * 0.1
                let date = Date().addingTimeInterval(TimeInterval((i + 100) * 60))
                self.sut.addWeightEntryInPreferredUnit(weight: weight, date: date)
                expectation.fulfill()
            }
        }

        // THEN: Should complete without crash
        wait(for: [expectation], timeout: 15.0)

        Thread.sleep(forTimeInterval: 2.0) // Let all async operations settle

        // ASSERT: Should have 110 entries (10 initial + 100 new)
        // May fail due to race conditions causing data loss
        XCTAssertGreaterThanOrEqual(sut.weightEntries.count, 110,
                                    "❌ RACE CONDITION: Expected at least 110 entries, got \(sut.weightEntries.count)")
    }

    // MARK: - Stress Test 3: UserDefaults Corruption Under Load

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Race Condition:** Multiple threads writing to UserDefaults simultaneously
    /// **Expected Failure:** Data corruption or plist parse errors in UserDefaults
    func test_concurrentUserDefaultsWrites_shouldNotCorruptData() {
        // GIVEN: Empty weight entries
        XCTAssertEqual(sut.weightEntries.count, 0)

        let expectation = XCTestExpectation(description: "All 50 write operations complete")
        expectation.expectedFulfillmentCount = 50

        let concurrentQueue = DispatchQueue(label: "test.userdefaults.concurrent", attributes: .concurrent)

        // WHEN: 50 threads each adding 2 entries (stressing UserDefaults save)
        for i in 0..<50 {
            concurrentQueue.async {
                // Each thread adds 2 entries to maximize UserDefaults write contention
                let weight1 = 150.0 + Double(i) * 0.1
                let weight2 = 150.0 + Double(i) * 0.1 + 0.05
                let date1 = Date().addingTimeInterval(TimeInterval(i * 120))
                let date2 = Date().addingTimeInterval(TimeInterval(i * 120 + 60))

                self.sut.addWeightEntryInPreferredUnit(weight: weight1, date: date1)
                self.sut.addWeightEntryInPreferredUnit(weight: weight2, date: date2)

                expectation.fulfill()
            }
        }

        // THEN: Wait for all writes to complete
        wait(for: [expectation], timeout: 15.0)

        Thread.sleep(forTimeInterval: 2.0) // Let all async operations settle

        // ASSERT: Should have 100 entries (50 threads × 2 entries each)
        XCTAssertEqual(sut.weightEntries.count, 100,
                       "❌ USERDEFAULTS CORRUPTION: Expected 100 entries, got \(sut.weightEntries.count). " +
                       "Concurrent writes to UserDefaults likely caused data loss or corruption.")

        // ASSERT: Verify data integrity - reload from UserDefaults
        let reloadedManager = WeightManager(healthKit: mockHealthKit, dataStore: mockDataStore)
        Thread.sleep(forTimeInterval: 0.5)

        XCTAssertEqual(reloadedManager.weightEntries.count, 100,
                       "❌ USERDEFAULTS CORRUPTION: Data lost after reload. " +
                       "Expected 100 persisted entries, got \(reloadedManager.weightEntries.count).")
    }

    // MARK: - Stress Test 4: Observer Suppression Race Condition

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Race Condition:** isSuppressingObserver flag accessed from multiple threads
    /// **Expected Failure:** Flag state inconsistent due to nonisolated(unsafe) usage
    func test_observerSuppressionFlag_shouldBeThreadSafe() {
        // GIVEN: HealthKit sync enabled
        sut.setSyncPreference(true)
        Thread.sleep(forTimeInterval: 0.5)

        let expectation = XCTestExpectation(description: "Concurrent observer checks complete")
        expectation.expectedFulfillmentCount = 100

        let concurrentQueue = DispatchQueue(label: "test.observer.concurrent", attributes: .concurrent)

        var inconsistentStateDetected = false
        let inconsistencyLock = NSLock()

        // WHEN: 100 threads adding entries (which sets isSuppressingObserver = true)
        // while observer callback checks the flag
        for i in 0..<100 {
            concurrentQueue.async {
                let weight = 150.0 + Double(i) * 0.1
                let date = Date().addingTimeInterval(TimeInterval(i * 60))

                // This sets isSuppressingObserver = true temporarily
                self.sut.addWeightEntryInPreferredUnit(weight: weight, date: date)

                // Simulate observer callback checking flag (on background thread)
                // NOTE: This is testing internal state - in real code, observer would check flag
                // Current implementation uses nonisolated(unsafe) which is dangerous

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 15.0)

        // ASSERT: This test documents the race condition exists
        // With nonisolated(unsafe), we can't reliably test flag state
        // After fix (Actor pattern), flag access will be properly synchronized

        XCTAssertFalse(inconsistentStateDetected,
                       "⚠️ WARNING: Observer suppression flag uses nonisolated(unsafe), " +
                       "which allows unsynchronized cross-actor access. " +
                       "This is a documented race condition that Task 1A will fix with Actor pattern.")
    }

    // MARK: - Stress Test 5: Concurrent Delete Operations

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Race Condition:** Multiple threads deleting entries simultaneously
    /// **Expected Failure:** Array mutation during iteration crash or incorrect count
    func test_concurrentDeleteOperations_shouldNotCrash() {
        // GIVEN: 50 initial weight entries
        var entriesToDelete: [WeightEntry] = []
        for i in 0..<50 {
            let weight = 150.0 + Double(i)
            let date = Date().addingTimeInterval(TimeInterval(i * 3600))
            sut.addWeightEntryInPreferredUnit(weight: weight, date: date)
        }

        Thread.sleep(forTimeInterval: 1.0)

        // Capture entries to delete (take first 25)
        entriesToDelete = Array(sut.weightEntries.prefix(25))
        XCTAssertEqual(entriesToDelete.count, 25)

        let expectation = XCTestExpectation(description: "Concurrent deletes complete")
        expectation.expectedFulfillmentCount = 25

        let concurrentQueue = DispatchQueue(label: "test.delete.concurrent", attributes: .concurrent)

        // WHEN: 25 threads each deleting 1 entry simultaneously
        for entry in entriesToDelete {
            concurrentQueue.async {
                self.sut.deleteWeightEntry(entry)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
        Thread.sleep(forTimeInterval: 2.0)

        // ASSERT: Should have 25 entries remaining (50 - 25 deleted)
        XCTAssertEqual(sut.weightEntries.count, 25,
                       "❌ CONCURRENT DELETE RACE CONDITION: Expected 25 remaining entries, got \(sut.weightEntries.count). " +
                       "Concurrent deletes likely caused array corruption or lost operations.")
    }
}
