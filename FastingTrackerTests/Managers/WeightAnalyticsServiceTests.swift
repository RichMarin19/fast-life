import XCTest
@testable import FastLIFe

final class WeightAnalyticsServiceTests: XCTestCase {

    private var service: WeightAnalyticsServicing!
    private var now: Date!

    override func setUp() {
        super.setUp()
        service = WeightAnalyticsService()
        now = Date(timeIntervalSince1970: 1_700_000_000)
    }

    override func tearDown() {
        service = nil
        now = nil
        super.tearDown()
    }

    func test_weightTrend_requiresSevenEntries() throws {
        let entries = (0..<6).map {
            WeightEntry(date: now.addingTimeInterval(-Double($0) * 86_400), weight: 200 - Double($0))
        }

        XCTAssertNil(service.weightTrend(for: entries), "Trend requires at least 7 entries")

        let sevenEntries = (0..<7).map {
            WeightEntry(date: now.addingTimeInterval(-Double($0) * 86_400), weight: 200 - Double($0))
        }

        let trend = try XCTUnwrap(service.weightTrend(for: sevenEntries))
        XCTAssertEqual(trend, 6.0, accuracy: 0.0001)
    }

    func test_averageWeight_returnsMean() throws {
        let entries = [
            WeightEntry(date: now, weight: 200),
            WeightEntry(date: now.addingTimeInterval(-86_400), weight: 198),
            WeightEntry(date: now.addingTimeInterval(-172_800), weight: 202)
        ]

        let average = try XCTUnwrap(service.averageWeight(for: entries))
        XCTAssertEqual(average, 200.0, accuracy: 0.0001)
    }

    func test_totalWeightChange_requiresTwoEntriesUnlessOverride() throws {
        XCTAssertNil(service.totalWeightChange(startWeight: 200, currentWeight: 190, entryCount: 1, hasStartWeightOverride: false))

        let result = try XCTUnwrap(service.totalWeightChange(startWeight: 200, currentWeight: 190, entryCount: 1, hasStartWeightOverride: true))
        XCTAssertEqual(result, -10.0, accuracy: 0.0001)
    }

    func test_progressToGoal_clampsOutOfRange() throws {
        XCTAssertNil(service.progressToGoal(startWeight: 180, currentWeight: 175, goalWeight: 0))
        XCTAssertNil(service.progressToGoal(startWeight: nil, currentWeight: 175, goalWeight: 160))

        let progress = try XCTUnwrap(service.progressToGoal(startWeight: 200, currentWeight: 190, goalWeight: 160))
        XCTAssertEqual(progress, 0.25, accuracy: 0.0001)

        let zeroProgress = try XCTUnwrap(service.progressToGoal(startWeight: 200, currentWeight: 205, goalWeight: 160))
        XCTAssertEqual(zeroProgress, 0.0, accuracy: 0.0001)
    }

    func test_milestoneStats_returnsExpectedSnapshot() throws {
        let progress = try XCTUnwrap(service.progressToGoal(startWeight: 200, currentWeight: 180, goalWeight: 160))
        let stats = try XCTUnwrap(service.milestoneStats(
            startWeight: 200,
            currentWeight: 180,
            goalWeight: 160,
            totalMilestones: 10,
            progress: progress,
            entryCount: 5,
            hasStartWeightOverride: false
        ))

        XCTAssertEqual(stats.goalProgress, 0.5, accuracy: 0.0001)
        XCTAssertEqual(stats.currentIndex, 5)
        XCTAssertEqual(stats.completedCount, 5)
        XCTAssertEqual(stats.currentMilestoneProgress, 0.0, accuracy: 0.0001)
        XCTAssertEqual(stats.remainingWeight, 20.0, accuracy: 0.0001)
    }

    func test_weightChange_returnsAverageDifferenceWithinWindow() throws {
        let entries = [
            WeightEntry(date: now, weight: 195.0),
            WeightEntry(date: now.addingTimeInterval(-3_600), weight: 196.0),
            WeightEntry(date: now.addingTimeInterval(-86_400), weight: 200.0),
            WeightEntry(date: now.addingTimeInterval(-90_000), weight: 201.0)
        ]

        let change = try XCTUnwrap(
            service.weightChange(
                for: entries,
                latestEntry: entries.first,
                since: now.addingTimeInterval(-86_400),
                hasStartWeightOverride: false
            )
        )

        XCTAssertEqual(change, -5.5, accuracy: 0.0001)
    }
}
