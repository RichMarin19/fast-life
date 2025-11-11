import Foundation
@testable import FastLIFe

final class MockHealthKitNudgeManager: HealthKitNudgeManaging {
    var shouldShow = false
    var dismissedTypes: [HealthDataType] = []
    var permanentlyDismissed = false

    func shouldShowNudge(for dataType: HealthDataType) -> Bool {
        shouldShow
    }

    func dismissNudge(for dataType: HealthDataType) {
        dismissedTypes.append(dataType)
    }

    func permanentlyDismissTimerNudge() {
        permanentlyDismissed = true
    }

    func handleAuthorizationGranted(for dataType: HealthDataType) {
        dismissedTypes.append(dataType)
    }
}
