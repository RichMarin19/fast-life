//
//  NotificationsViewModelTests.swift
//  FastingTrackerTests
//
//  Created by Claude Code
//  Task 1B: Comprehensive Testing - ViewModel Test Suite
//  Reference: Industry TDD patterns (Google/Facebook test methodology)
//

import XCTest
@testable import FastLIFe

@MainActor
final class NotificationsViewModelTests: XCTestCase {

    var viewModel: NotificationsViewModel!
    var userDefaults: UserDefaults!
    var mockNotificationManager: MockWeightNotificationManager!

    override func setUp() {
        super.setUp()

        // Use a separate UserDefaults suite for testing
        userDefaults = UserDefaults(suiteName: "NotificationsViewModelTests")!

        // Clear all test data before each test
        userDefaults.removePersistentDomain(forName: "NotificationsViewModelTests")

        // Note: NotificationsViewModel uses UserDefaults.standard
        // For true unit testing, this would need dependency injection
        // However, we can test behavior by clearing standard UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        mockNotificationManager = MockWeightNotificationManager()
        viewModel = NotificationsViewModel(notificationManager: mockNotificationManager)
    }

    override func tearDown() {
        viewModel = nil
        userDefaults = nil
        mockNotificationManager = nil
        super.tearDown()
    }

    private func makeViewModel() -> NotificationsViewModel {
        NotificationsViewModel(notificationManager: mockNotificationManager)
    }

    // MARK: - Initialization Tests

    func test_init_setsDefaultValues() {
        // Given - fresh ViewModel (no saved state)

        // Then - should have default values
        XCTAssertFalse(viewModel.weightRemindersEnabled, "weightRemindersEnabled should default to false")
        XCTAssertEqual(viewModel.timingMode, .specificTime, "timingMode should default to .specificTime")
        XCTAssertEqual(viewModel.minutesOffset, 30, "minutesOffset should default to 30")
        XCTAssertFalse(viewModel.quietHoursEnabled, "quietHoursEnabled should default to false")
        XCTAssertTrue(viewModel.skipWeekdays.isEmpty, "skipWeekdays should default to empty set")
    }

    func test_init_loadsDefaultTimes() {
        // Given - fresh ViewModel (no saved state)

        // When - check default times
        let calendar = Calendar.current
        let preferredComponents = calendar.dateComponents([.hour, .minute], from: viewModel.preferredReminderTime)
        let quietStartComponents = calendar.dateComponents([.hour, .minute], from: viewModel.quietHoursStart)
        let quietEndComponents = calendar.dateComponents([.hour, .minute], from: viewModel.quietHoursEnd)

        // Then - should have default times
        XCTAssertEqual(preferredComponents.hour, 7, "Default preferred time should be 7:30 AM")
        XCTAssertEqual(preferredComponents.minute, 30)

        XCTAssertEqual(quietStartComponents.hour, 21, "Default quiet start should be 9:00 PM")
        XCTAssertEqual(quietStartComponents.minute, 0)

        XCTAssertEqual(quietEndComponents.hour, 6, "Default quiet end should be 6:30 AM")
        XCTAssertEqual(quietEndComponents.minute, 30)
    }

    func test_init_loadsNewNotificationTypesDefaults() {
        // Given - fresh ViewModel (no saved state)

        // Then - all new notification types should be disabled
        XCTAssertFalse(viewModel.didYouKnowEnabled, "Did You Know should default to false")
        XCTAssertEqual(viewModel.didYouKnowFrequency, .daily, "Did You Know frequency should default to .daily")

        XCTAssertFalse(viewModel.motivationalEnabled, "Motivational should default to false")
        XCTAssertEqual(viewModel.motivationalFrequency, .daily, "Motivational frequency should default to .daily")

        XCTAssertFalse(viewModel.actionStepsEnabled, "Action Steps should default to false")
        XCTAssertEqual(viewModel.actionStepsFrequency, .daily, "Action Steps frequency should default to .daily")
    }

    // MARK: - Enum Tests

    func test_timingMode_allCasesExist() {
        // Given - TimingMode enum

        // Then - should have all 3 cases
        let allCases = NotificationsViewModel.TimingMode.allCases
        XCTAssertEqual(allCases.count, 3, "TimingMode should have 3 cases")
        XCTAssertTrue(allCases.contains(.specificTime))
        XCTAssertTrue(allCases.contains(.beforeFastingGoal))
        XCTAssertTrue(allCases.contains(.afterWakingUp))
    }

    func test_timingMode_rawValues() {
        // Given - TimingMode cases

        // Then - should have correct raw values
        XCTAssertEqual(NotificationsViewModel.TimingMode.specificTime.rawValue, "Specific Time")
        XCTAssertEqual(NotificationsViewModel.TimingMode.beforeFastingGoal.rawValue, "Before Fasting Goal")
        XCTAssertEqual(NotificationsViewModel.TimingMode.afterWakingUp.rawValue, "After Waking Up")
    }

    func test_notificationFrequency_allCasesExist() {
        // Given - NotificationFrequency enum

        // Then - should have all 4 cases
        let allCases = NotificationsViewModel.NotificationFrequency.allCases
        XCTAssertEqual(allCases.count, 4, "NotificationFrequency should have 4 cases")
        XCTAssertTrue(allCases.contains(.daily))
        XCTAssertTrue(allCases.contains(.everyOtherDay))
        XCTAssertTrue(allCases.contains(.twiceWeek))
        XCTAssertTrue(allCases.contains(.weekly))
    }

    func test_notificationFrequency_rawValues() {
        // Given - NotificationFrequency cases

        // Then - should have correct raw values
        XCTAssertEqual(NotificationsViewModel.NotificationFrequency.daily.rawValue, "Daily")
        XCTAssertEqual(NotificationsViewModel.NotificationFrequency.everyOtherDay.rawValue, "Every Other Day")
        XCTAssertEqual(NotificationsViewModel.NotificationFrequency.twiceWeek.rawValue, "Twice a Week")
        XCTAssertEqual(NotificationsViewModel.NotificationFrequency.weekly.rawValue, "Weekly")
    }

    // MARK: - Save Methods Tests

    func test_saveTimingMode_persistsToUserDefaults() {
        // Given - change timing mode
        viewModel.timingMode = .beforeFastingGoal

        // When
        viewModel.saveTimingMode()

        // Then - should persist to UserDefaults
        let saved = UserDefaults.standard.string(forKey: "weightReminderTimingMode")
        XCTAssertEqual(saved, "Before Fasting Goal",
                      "Timing mode should persist to UserDefaults")

        // Create new ViewModel to verify
        let newViewModel = makeViewModel()
        XCTAssertEqual(newViewModel.timingMode, .beforeFastingGoal,
                      "Timing mode should be restored in new ViewModel")
    }

    func test_saveMinutesOffset_persistsToUserDefaults() {
        // Given - change minutes offset
        viewModel.minutesOffset = 60

        // When
        viewModel.saveMinutesOffset()

        // Then - should persist to UserDefaults
        let saved = UserDefaults.standard.integer(forKey: "weightReminderMinutesOffset")
        XCTAssertEqual(saved, 60,
                      "Minutes offset should persist to UserDefaults")

        // Create new ViewModel to verify
        let newViewModel = makeViewModel()
        XCTAssertEqual(newViewModel.minutesOffset, 60,
                      "Minutes offset should be restored in new ViewModel")
    }

    func test_savePreferredTime_persistsToUserDefaults() {
        // Given - change preferred time to 8:00 AM
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        viewModel.preferredReminderTime = calendar.date(from: components) ?? Date()

        // When
        viewModel.savePreferredTime()

        // Then - should persist to UserDefaults
        XCTAssertNotNil(UserDefaults.standard.data(forKey: "weightReminderTime"),
                       "Preferred time should be saved to UserDefaults")

        // Create new ViewModel to verify
        let newViewModel = makeViewModel()
        let restoredComponents = calendar.dateComponents([.hour, .minute], from: newViewModel.preferredReminderTime)
        XCTAssertEqual(restoredComponents.hour, 8,
                      "Preferred time hour should be restored")
        XCTAssertEqual(restoredComponents.minute, 0,
                      "Preferred time minute should be restored")
    }

    func test_saveQuietHours_persistsToUserDefaults() {
        // Given - enable quiet hours and set times
        viewModel.quietHoursEnabled = true

        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.hour = 22
        startComponents.minute = 0
        viewModel.quietHoursStart = calendar.date(from: startComponents) ?? Date()

        var endComponents = DateComponents()
        endComponents.hour = 7
        endComponents.minute = 0
        viewModel.quietHoursEnd = calendar.date(from: endComponents) ?? Date()

        // When
        viewModel.saveQuietHours()

        // Then - should persist enabled state
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "quietHoursEnabled"),
                     "Quiet hours enabled should persist")

        // Create new ViewModel to verify
        let newViewModel = makeViewModel()
        XCTAssertTrue(newViewModel.quietHoursEnabled,
                     "Quiet hours enabled should be restored")

        let restoredStart = calendar.dateComponents([.hour, .minute], from: newViewModel.quietHoursStart)
        let restoredEnd = calendar.dateComponents([.hour, .minute], from: newViewModel.quietHoursEnd)

        XCTAssertEqual(restoredStart.hour, 22, "Quiet hours start should be restored")
        XCTAssertEqual(restoredEnd.hour, 7, "Quiet hours end should be restored")
    }

    func test_saveSkipWeekdays_persistsToUserDefaults() {
        // Given - set skip weekdays (skip Saturday and Sunday)
        viewModel.skipWeekdays = [1, 7] // Sunday = 1, Saturday = 7

        // When
        viewModel.saveSkipWeekdays()

        // Then - should persist to UserDefaults
        let saved = UserDefaults.standard.array(forKey: "skipWeekdays") as? [Int]
        XCTAssertNotNil(saved, "Skip weekdays should be saved to UserDefaults")
        XCTAssertTrue(saved?.contains(1) ?? false, "Should save Sunday")
        XCTAssertTrue(saved?.contains(7) ?? false, "Should save Saturday")

        // Create new ViewModel to verify
        let newViewModel = makeViewModel()
        XCTAssertEqual(newViewModel.skipWeekdays, [1, 7],
                      "Skip weekdays should be restored")
    }

    // MARK: - New Notification Types Save Tests

    func test_saveDidYouKnowSettings_persistsToUserDefaults() {
        // Given - enable Did You Know notifications
        viewModel.didYouKnowEnabled = true
        viewModel.didYouKnowFrequency = .weekly

        // When
        viewModel.saveDidYouKnowSettings()

        // Then - should persist to UserDefaults
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "didYouKnowEnabled"),
                     "Did You Know enabled should persist")

        let savedFrequency = UserDefaults.standard.string(forKey: "didYouKnowFrequency")
        XCTAssertEqual(savedFrequency, "Weekly",
                      "Did You Know frequency should persist")

        // Create new ViewModel to verify
        let newViewModel = makeViewModel()
        XCTAssertTrue(newViewModel.didYouKnowEnabled)
        XCTAssertEqual(newViewModel.didYouKnowFrequency, .weekly)
    }

    func test_saveMotivationalSettings_persistsToUserDefaults() {
        // Given - enable Motivational notifications
        viewModel.motivationalEnabled = true
        viewModel.motivationalFrequency = .everyOtherDay

        // When
        viewModel.saveMotivationalSettings()

        // Then - should persist to UserDefaults
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "motivationalEnabled"),
                     "Motivational enabled should persist")

        let savedFrequency = UserDefaults.standard.string(forKey: "motivationalFrequency")
        XCTAssertEqual(savedFrequency, "Every Other Day",
                      "Motivational frequency should persist")

        // Create new ViewModel to verify
        let newViewModel = makeViewModel()
        XCTAssertTrue(newViewModel.motivationalEnabled)
        XCTAssertEqual(newViewModel.motivationalFrequency, .everyOtherDay)
    }

    func test_saveActionStepsSettings_persistsToUserDefaults() {
        // Given - enable Action Steps notifications
        viewModel.actionStepsEnabled = true
        viewModel.actionStepsFrequency = .twiceWeek

        // When
        viewModel.saveActionStepsSettings()

        // Then - should persist to UserDefaults
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "actionStepsEnabled"),
                     "Action Steps enabled should persist")

        let savedFrequency = UserDefaults.standard.string(forKey: "actionStepsFrequency")
        XCTAssertEqual(savedFrequency, "Twice a Week",
                      "Action Steps frequency should persist")

        // Create new ViewModel to verify
        let newViewModel = makeViewModel()
        XCTAssertTrue(newViewModel.actionStepsEnabled)
        XCTAssertEqual(newViewModel.actionStepsFrequency, .twiceWeek)
    }

    // MARK: - Weekdays Array Tests

    func test_weekdays_hasAllSevenDays() {
        // Given - weekdays array

        // Then - should have 7 days
        XCTAssertEqual(viewModel.weekdays.count, 7,
                      "Weekdays array should have 7 days")
    }

    func test_weekdays_hasCorrectNumbers() {
        // Given - weekdays array

        // Then - should have numbers 1-7
        let numbers = viewModel.weekdays.map { $0.number }
        XCTAssertEqual(numbers, [1, 2, 3, 4, 5, 6, 7],
                      "Weekday numbers should be 1-7 (Sunday-Saturday)")
    }

    func test_weekdays_hasCorrectNames() {
        // Given - weekdays array

        // Then - should have correct day names
        let names = viewModel.weekdays.map { $0.name }
        XCTAssertEqual(names, ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
                      "Weekday names should be in correct order")
    }

    // MARK: - Edge Cases

    func test_saveSkipWeekdays_emptySet() {
        // Given - empty skip weekdays set
        viewModel.skipWeekdays = []

        // When
        viewModel.saveSkipWeekdays()

        // Then - should save empty array
        let saved = UserDefaults.standard.array(forKey: "skipWeekdays") as? [Int]
        XCTAssertNotNil(saved, "Should save empty array")
        XCTAssertTrue(saved?.isEmpty ?? false, "Saved array should be empty")

        // Create new ViewModel to verify
        let newViewModel = makeViewModel()
        XCTAssertTrue(newViewModel.skipWeekdays.isEmpty,
                     "Empty skip weekdays should be restored")
    }

    func test_saveSkipWeekdays_allDays() {
        // Given - skip all days (edge case)
        viewModel.skipWeekdays = [1, 2, 3, 4, 5, 6, 7]

        // When
        viewModel.saveSkipWeekdays()

        // Then - should save all days
        let saved = UserDefaults.standard.array(forKey: "skipWeekdays") as? [Int]
        XCTAssertEqual(saved?.count, 7, "Should save all 7 days")

        // Create new ViewModel to verify
        let newViewModel = makeViewModel()
        XCTAssertEqual(newViewModel.skipWeekdays.count, 7,
                      "All skip weekdays should be restored")
    }
}
