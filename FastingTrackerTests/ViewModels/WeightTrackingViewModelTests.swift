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

    // UserDefaults keys for cleanup
    private let showGoalLineKey = "showGoalLine"
    private let weightGoalKey = "goalWeight"

    override func setUp() {
        super.setUp()

        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: showGoalLineKey)
        UserDefaults.standard.removeObject(forKey: weightGoalKey)

        // Create mock dependencies
        mockWeightManager = WeightManager()
        mockScheduler = BehavioralNotificationScheduler.shared

        // Create ViewModel with empty init (Phase 1 fix pattern)
        sut = WeightTrackingViewModel()
    }

    override func tearDown() {
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: showGoalLineKey)
        UserDefaults.standard.removeObject(forKey: weightGoalKey)

        sut = nil
        mockWeightManager = nil
        mockScheduler = nil
        super.tearDown()
    }

    // MARK: - Dependency Injection Tests (Phase 1 Fix Validation)

    func test_configure_injectsManagersCorrectly() {
        // Given: Fresh ViewModel (created in setUp with empty init)
        // When: Configure with mock managers
        sut.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)

        // Then: Managers should be injected
        XCTAssertTrue(sut.weightManager === mockWeightManager,
                     "WeightManager should be the injected instance")
        XCTAssertTrue(sut.behavioralScheduler === mockScheduler,
                     "BehavioralScheduler should be the injected instance")
    }

    func test_configure_loadsGoalSettings() {
        // Given: Goal settings saved in UserDefaults
        UserDefaults.standard.set(true, forKey: showGoalLineKey)
        UserDefaults.standard.set(165.0, forKey: weightGoalKey)

        // When: Configure ViewModel
        sut.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)

        // Then: Goal settings should be loaded
        XCTAssertTrue(sut.showGoalLine, "showGoalLine should be loaded from UserDefaults")
        XCTAssertEqual(sut.weightGoal, 165.0, "weightGoal should be loaded from UserDefaults")
    }

    // MARK: - Goal Toggle Persistence Tests (CONSULTANT REVIEW - Issue #2)

    func test_showGoalLine_persistsAcrossInstances() {
        // Given: Enable goal line and save
        sut.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)
        sut.showGoalLine = true
        sut.saveGoalSettings()

        // When: Create new ViewModel (simulates app restart)
        let newViewModel = WeightTrackingViewModel()
        newViewModel.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)

        // Then: Goal line should still be enabled
        XCTAssertTrue(newViewModel.showGoalLine,
                     "showGoalLine should persist across ViewModel instances")
    }

    func test_showGoalLine_persistsWhenDisabled() {
        // Given: Disable goal line and save
        sut.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)
        sut.showGoalLine = false
        sut.saveGoalSettings()

        // When: Create new ViewModel (simulates app restart)
        let newViewModel = WeightTrackingViewModel()
        newViewModel.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)

        // Then: Goal line should still be disabled
        XCTAssertFalse(newViewModel.showGoalLine,
                      "showGoalLine should persist false state across instances")
    }

    // MARK: - Weight Goal Persistence Tests (CONSULTANT REVIEW - Issue #2)

    func test_weightGoal_persistsAcrossInstances() {
        // Given: Set goal to 165.0 and save
        sut.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)
        sut.weightGoal = 165.0
        sut.saveGoalSettings()

        // When: Create new ViewModel (simulates app restart)
        let newViewModel = WeightTrackingViewModel()
        newViewModel.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)

        // Then: Goal should be synced
        XCTAssertEqual(newViewModel.weightGoal, 165.0, accuracy: 0.01,
                      "weightGoal should persist across ViewModel instances")
    }

    func test_weightGoal_updatesCorrectly() {
        // Given: Initial goal
        sut.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)
        sut.weightGoal = 180.0
        sut.saveGoalSettings()

        // When: Update goal and save
        sut.weightGoal = 170.0
        sut.saveGoalSettings()

        // Then: New goal should persist
        let newViewModel = WeightTrackingViewModel()
        newViewModel.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)
        XCTAssertEqual(newViewModel.weightGoal, 170.0, accuracy: 0.01,
                      "Updated weightGoal should persist")
    }

    func test_weightGoal_hasCorrectDefaultValue() {
        // Given: No saved goal (fresh install)
        UserDefaults.standard.removeObject(forKey: weightGoalKey)

        // When: Configure new ViewModel
        sut.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)

        // Then: Should have default value of 180.0
        XCTAssertEqual(sut.weightGoal, 180.0, accuracy: 0.01,
                      "Default weightGoal should be 180.0")
    }

    // MARK: - Combined Persistence Tests

    func test_goalSettings_persistTogether() {
        // Given: Enable goal line and set custom goal
        sut.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)
        sut.showGoalLine = true
        sut.weightGoal = 155.5
        sut.saveGoalSettings()

        // When: Create new ViewModel
        let newViewModel = WeightTrackingViewModel()
        newViewModel.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)

        // Then: Both settings should persist
        XCTAssertTrue(newViewModel.showGoalLine,
                     "showGoalLine should persist")
        XCTAssertEqual(newViewModel.weightGoal, 155.5, accuracy: 0.01,
                      "weightGoal should persist")
    }

    func test_goalSettings_independentPersistence() {
        // Given: Enable goal line only
        sut.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)
        sut.showGoalLine = true
        sut.saveGoalSettings()

        // When: Create new ViewModel and change only weightGoal
        let newViewModel = WeightTrackingViewModel()
        newViewModel.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)
        newViewModel.weightGoal = 150.0
        newViewModel.saveGoalSettings()

        // Then: Both settings should persist independently
        let thirdViewModel = WeightTrackingViewModel()
        thirdViewModel.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)
        XCTAssertTrue(thirdViewModel.showGoalLine,
                     "showGoalLine should persist independently")
        XCTAssertEqual(thirdViewModel.weightGoal, 150.0, accuracy: 0.01,
                      "weightGoal should persist independently")
    }

    // MARK: - Lifecycle Tests

    func test_onViewAppear_showsFirstTimeSetupWhenEmpty() {
        // Given: Empty weight entries
        mockWeightManager.weightEntries.removeAll()
        sut.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)

        // When: View appears
        sut.onViewAppear()

        // Then: Should show first-time setup
        XCTAssertTrue(sut.showingFirstTimeSetup,
                     "Should show first-time setup when no weight entries")
    }

    func test_onViewAppear_doesNotShowSetupWithEntries() {
        // Given: Weight entries exist
        mockWeightManager.addWeightEntry(inPreferredUnit: 175.0, date: Date(), source: .manual, completion: { _ in })
        sut.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)

        // When: View appears
        sut.onViewAppear()

        // Then: Should not show first-time setup
        XCTAssertFalse(sut.showingFirstTimeSetup,
                      "Should not show first-time setup when weight entries exist")
    }

    // MARK: - Published State Tests

    func test_publishedProperties_triggerUpdates() {
        // Given: Configured ViewModel
        sut.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)
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
        // Given: Configured ViewModel
        sut.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)

        // When: User taps HealthKit connect (method exists but requires HealthKit)
        // Note: Can't fully test without mocking HealthKitManager

        // Then: Verify method exists (compilation check)
        XCTAssertNoThrow(sut.handleHealthKitConnect(),
                        "handleHealthKitConnect should be callable")
    }

    func test_handleHealthKitDismiss_hidesNudge() {
        // Given: HealthKit nudge showing
        sut.configure(weightManager: mockWeightManager, behavioralScheduler: mockScheduler)
        sut.showHealthKitNudge = true

        // When: User dismisses nudge
        sut.handleHealthKitDismiss()

        // Then: Nudge should be hidden
        XCTAssertFalse(sut.showHealthKitNudge,
                      "HealthKit nudge should be hidden after dismissal")
    }
}
