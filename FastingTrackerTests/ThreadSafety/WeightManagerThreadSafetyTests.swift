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
    var persistence: WeightPersistenceManaging!
    var suiteName: String!
    var secureStorage: InMemorySecureWeightStorage!

    override func setUp() {
        super.setUp()
        mockHealthKit = MockHealthKitManager()
        mockDataStore = MockDataStore()

        suiteName = "WeightManagerThreadSafetyTests-\(UUID().uuidString)"

        guard let suiteDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Unable to create isolated UserDefaults suite")
            return
        }
        suiteDefaults.removePersistentDomain(forName: suiteName)
        secureStorage = InMemorySecureWeightStorage()
        persistence = WeightPersistenceAdapter(
            defaults: ThreadSafeUserDefaults(userDefaults: suiteDefaults),
            storage: secureStorage
        )

        // Create WeightManager on MainActor (required for @MainActor class)
        let manager = MainActor.assumeIsolated {
            WeightManager(
                healthKit: mockHealthKit,
                dataStore: mockDataStore,
                persistence: persistence
            )
        }
        sut = manager
    }

    override func tearDown() {
        sut = nil
        mockHealthKit = nil
        mockDataStore = nil
        if let suiteName,
           let suiteDefaults = UserDefaults(suiteName: suiteName) {
            suiteDefaults.removePersistentDomain(forName: suiteName)
        }
        persistence = nil
        secureStorage = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Test 1: UserDefaults Corruption Under Rapid Updates

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Real-World Scenario:** HealthKit observer fires rapidly while user is adding weights
    /// **Race Condition:** Concurrent UserDefaults writes (lines 687-690) without locks
    /// **Expected Failure:** UserDefaults corruption or data loss
    func test_rapidHealthKitUpdates_shouldNotCorruptUserDefaults() async throws {
        let iterations = 200
        try await addEntriesConcurrently(count: iterations, source: .healthKit)

        let inMemoryCount = await MainActor.run { self.sut.weightEntries.count }
        let persistedCount = persistence.loadWeightEntries().count

        XCTAssertEqual(inMemoryCount, iterations, "Expected all HealthKit entries to be retained in memory.")
        XCTAssertEqual(persistedCount, iterations, "Secure snapshot should contain every entry after rapid updates.")
    }

    // MARK: - Test 2: Observer Suppression Flag Race Condition

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Real-World Scenario:** User adds weight → saves to HealthKit → observer fires before suppression lifted
    /// **Race Condition:** `nonisolated(unsafe)` flag (line 29) accessed from multiple threads
    /// **Expected Failure:** Observer fires when it should be suppressed, causing duplicate entries
    func test_observerSuppressionFlag_shouldPreventDuplicates() async throws {
        await MainActor.run {
            self.sut.syncWithHealthKit = true
        }

        let manualEntry = WeightEntry(
            date: Date(),
            weight: 185.0,
            source: .manual
        )

        await MainActor.run {
            self.sut.addWeightEntry(manualEntry)
        }

        // HealthKit sends the same entry back almost immediately.
        mockHealthKit.setMockWeightEntries([
            WeightEntry(
                date: manualEntry.date.addingTimeInterval(5),
                weight: manualEntry.weight,
                source: .healthKit
            )
        ])

        await performSync(startDate: manualEntry.date.addingTimeInterval(-3600))
        let count = await MainActor.run { self.sut.weightEntries.count }

        XCTAssertEqual(count, 1, "Observer suppression + duplicate detection should prevent re-adding the same entry.")
    }

    // MARK: - Test 3: Concurrent User Input + HealthKit Sync

    /// **TDD RED PHASE:** This test WILL FAIL with current code
    /// **Real-World Scenario:** User adding weights while background HealthKit sync is running
    /// **Race Condition:** UserDefaults writes overlap, array mutations race
    /// **Expected Failure:** Lost writes or incorrect entry count
    func test_concurrentUserInputAndHealthKitSync_shouldNotLoseData() async throws {
        let manualCount = 80
        let syncCount = 40
        let baseDate = Date()

        let syncEntries: [WeightEntry] = (0..<syncCount).map { index in
            WeightEntry(
                date: baseDate.addingTimeInterval(TimeInterval(index * 90)),
                weight: 190 + Double(index),
                source: .healthKit
            )
        }
        mockHealthKit.setMockWeightEntries(syncEntries)

        async let manualTask: Void = addEntriesConcurrently(count: manualCount, source: .manual)
        async let syncTask: Void = performSync(startDate: baseDate.addingTimeInterval(-86_400))

        try await manualTask
        await syncTask

        let count = await MainActor.run { self.sut.weightEntries.count }
        XCTAssertEqual(count, manualCount + syncCount)
    }

    func test_rapidDeletesDuringSync_shouldNotCorruptData() async throws {
        let initialCount = 60
        try await addEntriesConcurrently(count: initialCount, source: .manual)

        let entriesToDelete = await MainActor.run {
            Array(self.sut.weightEntries.prefix(20))
        }

        let newSyncEntries: [WeightEntry] = (0..<10).map { index in
            WeightEntry(
                date: Date().addingTimeInterval(TimeInterval(index * 600)),
                weight: 210 + Double(index),
                source: .healthKit
            )
        }
        mockHealthKit.setMockWeightEntries(newSyncEntries)

        async let deletionTask: Void = deleteEntries(entriesToDelete)
        async let syncTask: Void = performSync(startDate: Date().addingTimeInterval(-172_800))

        await deletionTask
        await syncTask

        let finalCount = await MainActor.run { self.sut.weightEntries.count }
        XCTAssertEqual(finalCount, initialCount - entriesToDelete.count + newSyncEntries.count)
    }

    func test_userDefaultsPersistence_underConcurrentLoad() async throws {
        let manualCount = 50
        try await addEntriesConcurrently(count: manualCount, source: .manual)

        let syncEntries: [WeightEntry] = (0..<30).map { index in
            WeightEntry(
                date: Date().addingTimeInterval(TimeInterval(index * 45)),
                weight: 175 + Double(index) * 0.5,
                source: .healthKit
            )
        }
        mockHealthKit.setMockWeightEntries(syncEntries)

        async let syncTask: Void = performSync(startDate: Date().addingTimeInterval(-604_800))
        async let deleteTask: Void = deleteEveryOtherEntry()

        await deleteTask
        await syncTask

        let inMemoryEntries = await MainActor.run { self.sut.weightEntries }
        let persistedEntries = persistence.loadWeightEntries()

        XCTAssertEqual(inMemoryEntries.count, persistedEntries.count)
        XCTAssertEqual(
            Set(inMemoryEntries.map(\.id)),
            Set(persistedEntries.map(\.id)),
            "Secure persistence snapshot should always mirror in-memory entries."
        )
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

    // MARK: - Concurrency Helpers

    private func addEntriesConcurrently(count: Int, source: WeightSource) async throws {
        let baseDate = Date()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<count {
                group.addTask { [sut] in
                    let entry = WeightEntry(
                        date: baseDate.addingTimeInterval(TimeInterval(index)),
                        weight: 160 + Double(index % 5),
                        source: source
                    )
                    await MainActor.run {
                        sut?.addWeightEntry(entry)
                    }
                }
            }
            try await group.waitForAll()
        }
    }

    private func deleteEntries(_ entries: [WeightEntry]) async {
        await withTaskGroup(of: Void.self) { group in
            for entry in entries {
                group.addTask { [sut] in
                    await MainActor.run {
                        sut?.deleteWeightEntry(entry)
                    }
                }
            }
            await group.waitForAll()
        }
    }

    private func deleteEveryOtherEntry() async {
        let targets = await MainActor.run {
            self.sut.weightEntries.enumerated().compactMap { index, entry in
                index.isMultiple(of: 2) ? entry : nil
            }
        }
        await deleteEntries(targets)
    }
}
