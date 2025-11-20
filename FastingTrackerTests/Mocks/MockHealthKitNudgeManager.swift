import Foundation
@testable import FastLIFe

final class MockHealthKitNudgeManager: HealthKitNudgeManaging, @unchecked Sendable {
    private let queue = DispatchQueue(label: "MockHealthKitNudgeManager.state", attributes: .concurrent)
    private var shouldShowStorage = false
    private var dismissedTypesStorage: [HealthDataType] = []
    private var permanentlyDismissedStorage = false

    var shouldShow: Bool {
        get { queue.sync { shouldShowStorage } }
        set { queue.async(flags: .barrier) { self.shouldShowStorage = newValue } }
    }

    var dismissedTypes: [HealthDataType] {
        queue.sync { dismissedTypesStorage }
    }

    var permanentlyDismissed: Bool {
        queue.sync { permanentlyDismissedStorage }
    }

    func reset() {
        queue.async(flags: .barrier) {
            self.shouldShowStorage = false
            self.dismissedTypesStorage.removeAll()
            self.permanentlyDismissedStorage = false
        }
    }

    func shouldShowNudge(for dataType: HealthDataType) -> Bool {
        shouldShow
    }

    func dismissNudge(for dataType: HealthDataType) {
        queue.async(flags: .barrier) {
            self.dismissedTypesStorage.append(dataType)
        }
    }

    func permanentlyDismissTimerNudge() {
        queue.async(flags: .barrier) {
            self.permanentlyDismissedStorage = true
        }
    }

    func handleAuthorizationGranted(for dataType: HealthDataType) {
        dismissNudge(for: dataType)
    }
}
