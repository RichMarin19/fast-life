import XCTest
@testable import FastLIFe

@MainActor
final class WeightTrackerMetricsTests: XCTestCase {

    override func tearDown() {
        #if DEBUG
        CrashReportManager.metricRecorderOverride = nil
        #endif
        super.tearDown()
    }

    func testRecordTrendSnapshotStateEmitsMetricEvent() {
        #if DEBUG
        let expectation = expectation(description: "METRIC log captured")

        CrashReportManager.metricRecorderOverride = { name, metadata in
            guard name == "weight_trend_snapshot_state" else { return }
            XCTAssertEqual(metadata["has7day"], "true")
            XCTAssertEqual(metadata["has30day"], "false")
            XCTAssertEqual(metadata["trend_state"], "improving")
            expectation.fulfill()
        }

        WeightTrackerMetrics.recordTrendSnapshotState(
            hasSevenDayData: true,
            hasThirtyDayData: false,
            trendState: "improving"
        )

        wait(for: [expectation], timeout: 1.0)
        #endif
    }

    func testRecordGoalEventEmitsMetric() {
        #if DEBUG
        let expectation = expectation(description: "Goal metric emitted")

        CrashReportManager.metricRecorderOverride = { name, metadata in
            guard name == "weight_goal_event" else { return }
            XCTAssertEqual(metadata["event"], "goal_weight_saved")
            XCTAssertEqual(metadata["source"], "control_center")
            expectation.fulfill()
        }

        WeightTrackerMetrics.recordGoalEvent(
            .goalWeightSaved,
            metadata: ["source": "control_center"]
        )

        wait(for: [expectation], timeout: 1.0)
        #endif
    }

    func testRecordProgressStoryEventEmitsMetric() {
        #if DEBUG
        let expectation = expectation(description: "Progress story metric emitted")

        CrashReportManager.metricRecorderOverride = { name, metadata in
            guard name == "weight_progress_story_event" else { return }
            XCTAssertEqual(metadata["event"], "progress_card_hidden")
            XCTAssertEqual(metadata["card"], "trend_snapshot")
            expectation.fulfill()
        }

        WeightTrackerMetrics.recordProgressStoryEvent(
            .cardHidden,
            metadata: ["card": "trend_snapshot"]
        )

        wait(for: [expectation], timeout: 1.0)
        #endif
    }
}
