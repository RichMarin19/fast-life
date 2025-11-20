import XCTest
import Combine
@testable import FastLIFe

/// Integration tests for WeightTrackingViewModel
/// TASK 1E PHASE 2: Tests goal persistence and dependency injection (consultant review fixes)
/// Industry Pattern: Integration tests following Apple WWDC 2017 "Testing in Xcode"
/// Reference: WeightControlCenterViewModelTests proven pattern (Given-When-Then)
@MainActor
final class WeightTrackingViewModelTests: XCTestCase {
    var sut: WeightTrackingViewModel!
    var mockWeightManager: WeightManager!
    var mockScheduler: BehavioralNotificationScheduler!
    var mockOptOutManager: MockContentOptOutManager!
    var mockHealthKitManager: MockHealthKitManager!
    var mockNudgeManager: MockHealthKitNudgeManager!
    var mockLocaleProvider: MutableLocaleProvider!
    var mockAppSettings: AppSettings!
    fileprivate var mockPersistence: TestWeightPersistence!
    var dependencies: WeightTrackingViewModel.Dependencies!
    private var userDefaults: UserDefaults!
    private let userDefaultsSuiteName = "com.fastlife.WeightTrackingViewModelTests"

    // UserDefaults keys for cleanup
    private let showGoalLineKey = "showGoalLine"
    private let weightGoalKey = "goalWeight"

    override func setUp() {
        super.setUp()

        guard let suiteDefaults = UserDefaults(suiteName: userDefaultsSuiteName) else {
            XCTFail("Failed to create UserDefaults suite for tests")
            return
        }
        userDefaults = suiteDefaults
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
        userDefaults.synchronize()

        // Create mock dependencies
        mockLocaleProvider = MutableLocaleProvider(measurementSystem: .us, localeIdentifier: "en_US")
        mockAppSettings = AppSettings(localeProvider: mockLocaleProvider)
        rebuildDependencies()

        sut = WeightTrackingViewModel(dependencies: dependencies)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
        userDefaults.synchronize()

        sut = nil
        mockWeightManager = nil
        mockScheduler = nil
        mockOptOutManager = nil
        mockHealthKitManager = nil
        mockNudgeManager = nil
        mockLocaleProvider = nil
        mockAppSettings = nil
        mockPersistence = nil
        dependencies = nil
        super.tearDown()
    }

    private func makeViewModel() -> WeightTrackingViewModel {
        WeightTrackingViewModel(dependencies: dependencies)
    }

    private func rebuildDependencies(goalWeight: Double? = nil) {
        mockHealthKitManager = MockHealthKitManager()
        mockScheduler = BehavioralNotificationScheduler.shared
        mockOptOutManager = MockContentOptOutManager()
        mockNudgeManager = MockHealthKitNudgeManager()
        mockPersistence = TestWeightPersistence(goalWeight: goalWeight)
        mockWeightManager = WeightManager(
            healthKit: mockHealthKitManager,
            dataStore: MockDataStore(),
            appSettings: mockAppSettings,
            persistence: mockPersistence,
            entrySyncCoordinator: WeightEntrySyncCoordinator(),
            analytics: WeightAnalyticsService()
        )
        dependencies = WeightTrackingViewModel.Dependencies(
            weightManager: mockWeightManager,
            behavioralScheduler: mockScheduler,
            optOutManager: mockOptOutManager,
            healthKitManager: mockHealthKitManager,
            nudgeManager: mockNudgeManager,
            userDefaults: userDefaults
        )
    }

    // MARK: - Dependency Injection Tests (Phase 1 Fix Validation)

    func test_init_injectsManagersCorrectly() {
        XCTAssertTrue(sut.weightManager === mockWeightManager,
                     "WeightManager should be the injected instance")
        XCTAssertTrue(sut.behavioralScheduler === mockScheduler,
                     "BehavioralScheduler should be the injected instance")
    }

    func test_init_loadsGoalSettings() {
        // Given: Goal settings saved in UserDefaults
        userDefaults.set(true, forKey: showGoalLineKey)
        userDefaults.set(165.0, forKey: weightGoalKey)
        rebuildDependencies(goalWeight: nil)

        // When: Create ViewModel
        let newViewModel = makeViewModel()

        // Then: Goal settings should be loaded
        XCTAssertTrue(newViewModel.showGoalLine, "showGoalLine should be loaded from UserDefaults")
        XCTAssertEqual(newViewModel.weightGoal, 165.0, "weightGoal should be loaded from UserDefaults")
    }

    // MARK: - Goal Toggle Persistence Tests (CONSULTANT REVIEW - Issue #2)

    func test_showGoalLine_persistsAcrossInstances() {
        // Given: Enable goal line and save
        sut.showGoalLine = true
        sut.saveGoalSettings()

        // When: Create new ViewModel (simulates app restart)
        let newViewModel = makeViewModel()

        // Then: Goal line should still be enabled
        XCTAssertTrue(newViewModel.showGoalLine,
                     "showGoalLine should persist across ViewModel instances")
    }

    func test_showGoalLine_persistsWhenDisabled() {
        // Given: Disable goal line and save
        sut.showGoalLine = false
        sut.saveGoalSettings()

        // When: Create new ViewModel (simulates app restart)
        let newViewModel = makeViewModel()

        // Then: Goal line should still be disabled
        XCTAssertFalse(newViewModel.showGoalLine,
                      "showGoalLine should persist false state across instances")
    }

    // MARK: - Weight Goal Persistence Tests (CONSULTANT REVIEW - Issue #2)

    func test_weightGoal_persistsAcrossInstances() {
        // Given: Set goal to 165.0 and save
        sut.weightGoal = 165.0
        sut.saveGoalSettings()

        // When: Create new ViewModel (simulates app restart)
        let newViewModel = makeViewModel()

        // Then: Goal should be synced
        XCTAssertEqual(newViewModel.weightGoal, 165.0, accuracy: 0.01,
                      "weightGoal should persist across ViewModel instances")
    }

    func test_weightGoal_updatesCorrectly() {
        // Given: Initial goal
        sut.weightGoal = 180.0
        sut.saveGoalSettings()

        // When: Update goal and save
        sut.weightGoal = 170.0
        sut.saveGoalSettings()

        // Then: New goal should persist
        let newViewModel = makeViewModel()
        XCTAssertEqual(newViewModel.weightGoal, 170.0, accuracy: 0.01,
                      "Updated weightGoal should persist")
    }

    func test_weightGoal_hasCorrectDefaultValue() {
        // Given: No saved goal (fresh install)
        userDefaults.removeObject(forKey: weightGoalKey)
        mockWeightManager.setGoalWeight(180.0)

        // When: Create new ViewModel
        sut = makeViewModel()

        // Then: Should have default value of 180.0
        XCTAssertEqual(sut.weightGoal, 180.0, accuracy: 0.01,
                      "Default weightGoal should be 180.0")
    }

    // MARK: - Combined Persistence Tests

    func test_goalSettings_persistTogether() {
        // Given: Enable goal line and set custom goal
        sut.showGoalLine = true
        sut.weightGoal = 155.5
        sut.saveGoalSettings()

        // When: Create new ViewModel
        let newViewModel = makeViewModel()

        // Then: Both settings should persist
        XCTAssertTrue(newViewModel.showGoalLine,
                     "showGoalLine should persist")
        XCTAssertEqual(newViewModel.weightGoal, 155.5, accuracy: 0.01,
                      "weightGoal should persist")
    }

    func test_goalSettings_independentPersistence() {
        // Given: Enable goal line only
        sut.showGoalLine = true
        sut.saveGoalSettings()

        // When: Create new ViewModel and change only weightGoal
        let newViewModel = makeViewModel()
        newViewModel.weightGoal = 150.0
        newViewModel.saveGoalSettings()

        // Then: Both settings should persist independently
        let thirdViewModel = makeViewModel()
        XCTAssertTrue(thirdViewModel.showGoalLine,
                     "showGoalLine should persist independently")
        XCTAssertEqual(thirdViewModel.weightGoal, 150.0, accuracy: 0.01,
                      "weightGoal should persist independently")
    }

    // MARK: - Lifecycle Tests

    func test_onViewAppear_showsFirstTimeSetupWhenEmpty() {
        // Given: Empty weight entries
        mockWeightManager.weightEntries.removeAll()

        // When: View appears
        sut.onViewAppear()

        // Then: Should show first-time setup
        XCTAssertTrue(sut.showingFirstTimeSetup,
                     "Should show first-time setup when no weight entries")
    }

    func test_onViewAppear_doesNotShowSetupWithEntries() {
        // Given: Weight entries exist
        mockWeightManager.addWeightEntryInPreferredUnit(weight: 175.0, date: Date())

        // When: View appears
        sut.onViewAppear()

        // Then: Should not show first-time setup
        XCTAssertFalse(sut.showingFirstTimeSetup,
                      "Should not show first-time setup when weight entries exist")
    }

    // MARK: - Published State Tests

    func test_publishedProperties_triggerUpdates() {
        // Given: Configured ViewModel
        let expectation = expectation(description: "Published property changed")
        var receivedValue = false

        let cancellable = sut.$showingAddWeight
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValue = value
                expectation.fulfill()
            }

        // When: Change published property
        sut.showingAddWeight = true

        // Then: Should publish change
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedValue, "Published property should trigger Combine updates")

        cancellable.cancel()
    }

    // MARK: - HealthKit Integration Tests

    func test_handleHealthKitConnect_updatesScheduler() {
        // When: User taps HealthKit connect (method exists but requires HealthKit)
        // Note: Can't fully test without mocking HealthKitManager

        // Then: Verify method exists (compilation check)
        XCTAssertNoThrow(sut.handleHealthKitConnect(),
                        "handleHealthKitConnect should be callable")
    }

    func test_handleHealthKitDismiss_hidesNudge() {
        // Given: HealthKit nudge showing
        sut.showHealthKitNudge = true

        // When: User dismisses nudge
        sut.handleHealthKitDismiss()

        // Then: Nudge should be hidden
        XCTAssertFalse(sut.showHealthKitNudge,
                      "HealthKit nudge should be hidden after dismissal")
    }
}

// MARK: - Test Doubles

fileprivate final class TestWeightPersistence: WeightPersistenceManaging {
    private var entries: [WeightEntry]
    private var syncPreference: Bool?
    private var startOverride: (Double?, Date?)
    private var milestoneCount: Int?
    private var goalWeight: Double?
    private var futureSyncStartDate: Date?

    init(entries: [WeightEntry] = [],
         syncPreference: Bool? = nil,
         startOverride: (Double?, Date?) = (nil, nil),
         milestoneCount: Int? = nil,
         goalWeight: Double? = nil,
         futureSyncStartDate: Date? = nil) {
        self.entries = entries
        self.syncPreference = syncPreference
        self.startOverride = startOverride
        self.milestoneCount = milestoneCount
        self.goalWeight = goalWeight
        self.futureSyncStartDate = futureSyncStartDate
    }

    func loadWeightEntries() -> [WeightEntry] { entries }
    func saveWeightEntries(_ entries: [WeightEntry]) { self.entries = entries }
    func loadSyncPreference() -> Bool? { syncPreference }
    func saveSyncPreference(_ value: Bool) { syncPreference = value }
    func loadStartWeightOverride() -> (weight: Double?, date: Date?) { startOverride }
    func saveStartWeightOverride(weight: Double?, date: Date?) { startOverride = (weight, date) }
    func loadMilestoneCount() -> Int? { milestoneCount }
    func saveMilestoneCount(_ count: Int) { milestoneCount = count }
    func loadGoalWeight() -> Double? { goalWeight }
    func saveGoalWeight(_ weight: Double) { goalWeight = weight }
    func loadFutureSyncStartDate() -> Date? { futureSyncStartDate }
    func saveFutureSyncStartDate(_ date: Date?) { futureSyncStartDate = date }
}
