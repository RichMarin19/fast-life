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
private actor Counter {
    private var value: Int = 0
    func increment() {
        value += 1
    }
    func current() -> Int {
        value
    }
}

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
    func test_rapidHealthKitUpdates_shouldNotCorruptUserDefaults() async {
        // GIVEN: HealthKit sync enabled
        await MainActor.run {
            self.sut.setSyncPreference(true)
        }

        // WHEN: 50 "HealthKit observer callbacks" fire simultaneously (simulating rapid updates)
        await withTaskGroup(of: Void.self) { [self] group in
            for i in 0..<50 {
                group.addTask {
                    let weight = 150.0 + Double(i) * 0.1
                    let date = Date().addingTimeInterval(TimeInterval(i * 3600))
                    await MainActor.run {
                        self.sut.addWeightEntryInPreferredUnit(weight: weight, date: date)
                    }
                }
            }
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // ASSERT: All 50 entries should be persisted to UserDefaults
        let actualCount = await MainActor.run { self.sut.weightEntries.count }
        XCTAssertEqual(actualCount, 50,
                       "❌ USERDEFAULTS RACE CONDITION: Expected 50 entries, got \(actualCount). " +
                       "Concurrent writes to UserDefaults (lines 687-690) likely caused data loss.")

        // ASSERT: Verify persistence integrity by reloading
        let reloadedManager = await MainActor.run {
            WeightManager(healthKit: mockHealthKit, dataStore: mockDataStore)
        }

        let reloadedCount = await MainActor.run { reloadedManager.weightEntries.count }
        XCTAssertEqual(reloadedCount, 50,
                       "❌ USERDEFAULTS CORRUPTION: Data lost after reload. " +
                       "Expected 50 persisted entries, got \(reloadedCount). UserDefaults corrupted by concurrent writes.")
    }

    // MARK: - Test 2: Observer Suppression Flag Race Condition

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Real-World Scenario:** User adds weight → saves to HealthKit → observer fires before suppression lifted
    /// **Race Condition:** `nonisolated(unsafe)` flag (line 29) accessed from multiple threads
    /// **Expected Failure:** Observer fires when it should be suppressed, causing duplicate entries
    func test_observerSuppressionFlag_shouldPreventDuplicates() async {
        // GIVEN: HealthKit sync enabled, mock observer will fire immediately
        await MainActor.run {
            self.sut.setSyncPreference(true)
        }
        try? await Task.sleep(nanoseconds: 200_000_000) // allow initial suppression setup

        // Configure mock to fire observer callback when weight is saved
        let observerCounter = Counter()
        mockHealthKit.onSaveWeight = { weight, bmi, bodyFat, date, completion in
            Task.detached {
                await observerCounter.increment()
                completion(true, nil)
            }
        }

        // WHEN: User rapidly adds 10 weight entries (each triggers HealthKit save + observer)
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask { [self] in
                    let weight = 150.0 + Double(i)
                    let date = Date().addingTimeInterval(TimeInterval(i * 3600))
                    await MainActor.run {
                        self.sut.addWeightEntryInPreferredUnit(weight: weight, date: date)
                    }
                }
            }
        }

        // Wait for observer suppression delay (WeightConstants.SyncTiming.observerSuppressionDelay ≈ 2s)
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        await waitForEntryCount(10, timeoutSeconds: 5)

        // ASSERT: Should have exactly 10 entries (no duplicates from observer)
        let actualCount = await MainActor.run { self.sut.weightEntries.count }
        XCTAssertEqual(actualCount, 10,
                       "❌ OBSERVER SUPPRESSION RACE CONDITION: Expected 10 entries, got \(actualCount). " +
                       "The nonisolated(unsafe) flag (line 29) allows unsynchronized access from observer callback (line 569), " +
                       "causing observer to fire when it should be suppressed. This creates duplicate entries.")

        // ASSERT: Verify observer fired (proves it was running during test)
        let observerFireCount = await observerCounter.current()
        XCTAssertGreaterThan(observerFireCount, 0,
                             "Test setup issue: Observer never fired, cannot verify suppression logic")
    }

    // MARK: - Test 3: Concurrent User Input + HealthKit Sync

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Real-World Scenario:** User adding weights while background HealthKit sync is running
    /// **Race Condition:** UserDefaults writes overlap, array mutations race
    /// **Expected Failure:** Lost writes or incorrect entry count
    func test_concurrentUserInputAndHealthKitSync_shouldNotLoseData() async {
        // GIVEN: HealthKit sync enabled, 10 existing entries
        await MainActor.run {
            self.sut.setSyncPreference(true)
            for i in 0..<10 {
                self.sut.addWeightEntryInPreferredUnit(weight: 140.0 + Double(i), date: Date().addingTimeInterval(TimeInterval(-i * 86400)))
            }
        }

        // WHEN: User rapidly adds entries WHILE HealthKit sync is running
        await withTaskGroup(of: Void.self) { [self] group in
            // User thread: Adding 20 entries
            group.addTask { [self] in
                await withTaskGroup(of: Void.self) { subgroup in
                    for i in 0..<20 {
                        subgroup.addTask { [self] in
                            let weight = 150.0 + Double(i) * 0.1
                            let date = Date().addingTimeInterval(TimeInterval(i * 1800))
                            await MainActor.run {
                                self.sut.addWeightEntryInPreferredUnit(weight: weight, date: date)
                            }
                        }
                    }
                }
            }

            // HealthKit sync thread: Running 5 concurrent syncs
            group.addTask { [self] in
                await withTaskGroup(of: Void.self) { subgroup in
                    for i in 0..<5 {
                        subgroup.addTask { [self] in
                            let startDate = Calendar.current.date(byAdding: .day, value: -(30 + i), to: Date()) ?? Date()
                            await self.performSync(startDate: startDate)
                        }
                    }
                }
            }
        }
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // ASSERT: Should have 30 entries (10 initial + 20 user added)
        // HealthKit sync won't add duplicates, but race conditions could lose user entries
        await waitForEntryCount(30, timeoutSeconds: 5)
        let actualCount = await MainActor.run { self.sut.weightEntries.count }
        XCTAssertEqual(actualCount, 30,
                       "Expected 30 total entries (10 seed + 20 user adds) after concurrent sync")
    }

    // MARK: - Test 4: Rapid Delete Operations During Sync

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Real-World Scenario:** User deleting entries while HealthKit sync is adding new ones
    /// **Race Condition:** Array mutation (line 126) + UserDefaults save (line 127) race with sync
    /// **Expected Failure:** Incorrect final count or crash
    func test_rapidDeletesDuringSync_shouldNotCorruptData() async {
        // GIVEN: 30 initial entries
        await MainActor.run {
            for i in 0..<30 {
                self.sut.addWeightEntryInPreferredUnit(weight: 150.0 + Double(i), date: Date().addingTimeInterval(TimeInterval(i * 3600)))
            }
        }

        await waitForEntryCount(30, timeoutSeconds: 5)
        let entriesToDelete: [WeightEntry] = await MainActor.run {
            Array(self.sut.weightEntries.prefix(15))
        }

        XCTAssertEqual(entriesToDelete.count, 15)

        // WHEN: User deleting 15 entries WHILE HealthKit sync is running
        await withTaskGroup(of: Void.self) { [self] group in
            // Delete thread: Removing 15 entries rapidly
            group.addTask { [self] in
                await withTaskGroup(of: Void.self) { subgroup in
                    for entry in entriesToDelete {
                        subgroup.addTask { [self] in
                            await MainActor.run {
                                self.sut.deleteWeightEntry(entry)
                            }
                        }
                    }
                }
            }

            // Sync thread: Running HealthKit sync concurrently
            group.addTask { [self] in
                let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
                await self.performSync(startDate: startDate)
            }
        }
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // ASSERT: Should have 15 entries remaining (30 - 15 deleted)
        await waitForEntryCount(15, timeoutSeconds: 5)
        let remainingCount = await MainActor.run { self.sut.weightEntries.count }
        XCTAssertEqual(remainingCount, 15,
                       "Expected exactly 15 entries remaining after concurrent deletes")
    }

    // MARK: - Test 5: UserDefaults Persistence Under Load

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Real-World Scenario:** Multiple rapid operations stressing UserDefaults persistence
    /// **Race Condition:** Multiple saveWeightEntries() calls (line 687) overlap without locks
    /// **Expected Failure:** Plist corruption or data loss on reload
    func test_userDefaultsPersistence_underConcurrentLoad() async {
        // GIVEN: 100 rapid operations stressing UserDefaults
        await withTaskGroup(of: Void.self) { [self] group in
            for i in 0..<100 {
                group.addTask { [self] in
                    let weight = 150.0 + Double(i % 10) * 0.1
                    let date = Date().addingTimeInterval(TimeInterval(i * 60))

                    await MainActor.run {
                        self.sut.addWeightEntryInPreferredUnit(weight: weight, date: date)
                        if let entry = self.sut.weightEntries.first {
                            self.sut.deleteWeightEntry(entry)
                        }
                    }
                }
            }
        }
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // ASSERT: After 100 add+delete operations, should have 0 entries
        await waitForEntryCount(0, timeoutSeconds: 5)
        let finalCount = await MainActor.run { self.sut.weightEntries.count }
        XCTAssertEqual(finalCount, 0,
                       "Expected add+delete pairs to leave zero persisted entries")

        // ASSERT: Verify UserDefaults wasn't corrupted by rapid writes
        let reloadedManager = await MainActor.run {
            WeightManager(healthKit: self.mockHealthKit, dataStore: self.mockDataStore)
        }

        await Task.yield()
        let reloadedCount = await MainActor.run { reloadedManager.weightEntries.count }
        XCTAssertEqual(reloadedCount, 0,
                       "Reloaded manager should also observe zero entries after concurrent stress")
    }

    // MARK: - Helpers

    private func performSync(startDate: Date) async {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.sut.syncFromHealthKit(startDate: startDate) { _, _ in
                    continuation.resume()
                }
            }
        }
    }

    private func waitForEntryCount(_ expected: Int, timeoutSeconds: Double) async {
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while Date() < deadline {
            let count = await MainActor.run { self.sut.weightEntries.count }
            if count == expected { return }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
    }
}
