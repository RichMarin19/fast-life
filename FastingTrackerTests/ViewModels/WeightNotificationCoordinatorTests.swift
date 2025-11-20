import XCTest
@testable import FastLIFe

@MainActor
final class WeightNotificationCoordinatorTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var weightManager: MockWeightManager!
    private var notificationManager: StubNotificationManager!
    private var coordinator: WeightNotificationCoordinator!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "WeightNotificationCoordinatorTests")
        userDefaults.removePersistentDomain(forName: "WeightNotificationCoordinatorTests")
        weightManager = MockWeightManager()
        notificationManager = StubNotificationManager()
        coordinator = WeightNotificationCoordinator(
            weightManager: weightManager,
            userDefaults: userDefaults,
            notificationManager: notificationManager
        )
    }

    override func tearDown() {
        coordinator = nil
        notificationManager = nil
        weightManager = nil
        userDefaults.removePersistentDomain(forName: "WeightNotificationCoordinatorTests")
        userDefaults = nil
        super.tearDown()
    }

    func testInit_loadsSavedSettings() {
        // Given
        userDefaults.set(true, forKey: "weightRemindersEnabled")
        userDefaults.set("Before Fasting Goal", forKey: "weightReminderTimingMode")
        userDefaults.set(45, forKey: "weightReminderMinutesOffset")
        let preferredDate = Date(timeIntervalSince1970: 1000)
        userDefaults.set(preferredDate, forKey: "weightReminderTime")
        userDefaults.set(true, forKey: "quietHoursEnabled")
        userDefaults.set(preferredDate, forKey: "quietHoursStart")
        userDefaults.set(preferredDate, forKey: "quietHoursEnd")
        userDefaults.set([2, 6], forKey: "skipWeekdays")
        userDefaults.set(true, forKey: "didYouKnowEnabled")
        userDefaults.set("Weekly", forKey: "didYouKnowFrequency")
        userDefaults.set(true, forKey: "motivationalEnabled")
        userDefaults.set("Twice a Week", forKey: "motivationalFrequency")
        userDefaults.set(true, forKey: "actionStepsEnabled")
        userDefaults.set("Every Other Day", forKey: "actionStepsFrequency")

        // When
        coordinator.loadSettings()

        // Then
        XCTAssertTrue(coordinator.weightRemindersEnabled)
        XCTAssertEqual(coordinator.timingMode, .beforeFastingGoal)
        XCTAssertEqual(coordinator.minutesOffset, 45)
        XCTAssertEqual(coordinator.preferredReminderTime, preferredDate)
        XCTAssertTrue(coordinator.quietHoursEnabled)
        XCTAssertEqual(coordinator.skipWeekdays, [2, 6])
        XCTAssertTrue(coordinator.didYouKnowEnabled)
        XCTAssertEqual(coordinator.didYouKnowFrequency, .weekly)
        XCTAssertTrue(coordinator.motivationalEnabled)
        XCTAssertEqual(coordinator.motivationalFrequency, .twiceWeek)
        XCTAssertTrue(coordinator.actionStepsEnabled)
        XCTAssertEqual(coordinator.actionStepsFrequency, .everyOtherDay)
    }

    func testHandleReminderToggle_grantedSchedulesReminder() async {
        // Given
        notificationManager.authorizationResult = true
        coordinator.preferredReminderTime = Date()
        let scheduleExpectation = expectation(description: "schedule called")
        notificationManager.onSchedule = { scheduleExpectation.fulfill() }

        // When
        coordinator.handleReminderToggle(true)
        await fulfillment(of: [scheduleExpectation], timeout: 1.0)

        // Then
        XCTAssertTrue(coordinator.weightRemindersEnabled)
        XCTAssertEqual(notificationManager.scheduleCallCount, 1)
        XCTAssertTrue(notificationManager.requestAuthorizationCalled)
    }

    func testHandleReminderToggle_deniedResetsToggle() async {
        // Given
        notificationManager.authorizationResult = false

        // When
        coordinator.handleReminderToggle(true)
        await Task.yield()

        // Then
        XCTAssertFalse(coordinator.weightRemindersEnabled)
        XCTAssertEqual(notificationManager.scheduleCallCount, 0)
    }

    func testSaveTimingMode_whenEnabledSchedulesReminder() async {
        // Given
        coordinator.weightRemindersEnabled = true
        coordinator.timingMode = .afterWakingUp

        // When
        let scheduleExpectation = expectation(description: "schedule called")
        notificationManager.onSchedule = { scheduleExpectation.fulfill() }

        coordinator.saveTimingMode()
        await fulfillment(of: [scheduleExpectation], timeout: 1.0)

        // Then
        XCTAssertEqual(userDefaults.string(forKey: "weightReminderTimingMode"), WeightReminderTimingMode.afterWakingUp.rawValue)
        XCTAssertEqual(notificationManager.scheduleCallCount, 1)
    }

    func testSavePreferredTime_persistsAndSchedules() async {
        // Given
        coordinator.weightRemindersEnabled = true
        let time = Date(timeIntervalSince1970: 2000)
        coordinator.preferredReminderTime = time

        // When
        let scheduleExpectation = expectation(description: "schedule called")
        notificationManager.onSchedule = { scheduleExpectation.fulfill() }

        coordinator.savePreferredTime()
        await fulfillment(of: [scheduleExpectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(userDefaults.object(forKey: "weightReminderTime") as? Data)
        XCTAssertEqual(notificationManager.scheduleCallCount, 1)
    }

    func testSaveSkipWeekdays_whenEnabledSchedulesReminder() async {
        // Given
        coordinator.weightRemindersEnabled = true
        coordinator.skipWeekdays = [1]

        // When
        let scheduleExpectation = expectation(description: "schedule called")
        notificationManager.onSchedule = { scheduleExpectation.fulfill() }

        coordinator.saveSkipWeekdays()
        await fulfillment(of: [scheduleExpectation], timeout: 1.0)

        // Then
        let stored = userDefaults.array(forKey: "skipWeekdays") as? [Int]
        XCTAssertEqual(stored, [1])
        XCTAssertEqual(notificationManager.scheduleCallCount, 1)
    }
}

// MARK: - Test Doubles

@MainActor
private final class StubNotificationManager: WeightNotificationManaging {
    var authorizationResult: Bool = true
    private(set) var requestAuthorizationCalled = false
    private(set) var cancelCallCount = 0
    private(set) var scheduleCallCount = 0
    var onSchedule: (() -> Void)?

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        requestAuthorizationCalled = true
        completion(authorizationResult)
    }

    func cancelAllWeightReminders() async {
        cancelCallCount += 1
    }

    func scheduleNextReminder(
        preferredTime: DateComponents,
        quietHours: WeightQuietHours?,
        skipWeekdays: Set<Int>
    ) async throws {
        scheduleCallCount += 1
        onSchedule?()
    }

    func debugPrintPendingWeightReminders() async { }
}
