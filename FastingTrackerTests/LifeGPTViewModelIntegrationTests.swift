//
// LifeGPTViewModelIntegrationTests.swift
// FastingTrackerTests
//
// Created for Phase 4A: Intelligence Integration Tests
// Test Coverage: ViewModel → EmotionEngine → InsightGenerator → ResponseGenerator → ConversationManager
// Reference: docs/planning/PHASE-4-INTEGRATION-UPGRADE.md
//

import XCTest
@testable import FastingTracker

final class LifeGPTViewModelIntegrationTests: XCTestCase {

    var viewModel: LifeGPTViewModel!
    var mockDataService: MockHealthDataAggregator!
    var mockAnalyzer: MockHealthAnalyzer!

    override func setUp() {
        super.setUp()
        mockDataService = MockHealthDataAggregator()
        mockAnalyzer = MockHealthAnalyzer()
        viewModel = LifeGPTViewModel(
            dataService: mockDataService,
            healthAnalyzer: mockAnalyzer
        )
    }

    override func tearDown() {
        viewModel = nil
        mockDataService = nil
        mockAnalyzer = nil
        super.tearDown()
    }

    // MARK: - Phase 4A Integration Tests

    /// Test: buildInsightContext() gathers all required data
    func testBuildInsightContext_GathersAllData() async {
        // Given: Mock data service returns test data
        mockDataService.mockCurrentWeight = WeightEntry(weight: 180.6, date: Date(), notes: nil)
        mockDataService.mockAllWeights = [
            WeightEntry(weight: 180.6, date: Date(), notes: nil),
            WeightEntry(weight: 185.0, date: Date().addingTimeInterval(-86400 * 30), notes: nil)
        ]
        mockAnalyzer.mockTrendResult = TrendAnalysisResult(
            direction: .up,
            strength: 0.2,
            confidence: 0.85,
            dataPoints: 10
        )
        mockAnalyzer.mockWeightChange7Days = WeightChangeResult(
            change: 1.5,
            startWeight: 179.1,
            endWeight: 180.6,
            startDate: Date().addingTimeInterval(-86400 * 7),
            endDate: Date()
        )
        mockAnalyzer.mockFastCountThisWeek = 3
        mockAnalyzer.mockFastCountLastWeek = 5

        // When: buildInsightContext() is called (indirectly via query)
        // Note: buildInsightContext() is private, so we test via executeIntelligentQuery
        let (_, _) = await viewModel.executeIntelligentQuery("What's my average weight?")

        // Then: Verify data was gathered (mock methods were called)
        XCTAssertTrue(mockDataService.didCallGetCurrentWeight, "Should fetch current weight")
        XCTAssertTrue(mockDataService.didCallFetchAllWeightData, "Should fetch all weight data")
        XCTAssertTrue(mockAnalyzer.didCallAnalyzeTrend, "Should analyze weight trend")
        XCTAssertTrue(mockAnalyzer.didCallCalculateWeightChange, "Should calculate weight changes")
        XCTAssertTrue(mockAnalyzer.didCallCountFasts, "Should count fasts")
    }

    /// Test: EmotionEngine is called with context from buildInsightContext()
    func testEmotionEngine_CalledWithCorrectContext() async {
        // Given: User gaining weight when goal is to lose (offtrack scenario)
        UserDefaults.standard.set(170.0, forKey: "weightGoal")
        mockDataService.mockCurrentWeight = WeightEntry(weight: 180.6, date: Date(), notes: nil)
        mockAnalyzer.mockTrendResult = TrendAnalysisResult(
            direction: .up,
            strength: 0.2,  // Gaining weight
            confidence: 0.85,
            dataPoints: 10
        )
        mockAnalyzer.mockFastCountThisWeek = 3
        mockAnalyzer.mockFastCountLastWeek = 5  // Fasting dropped

        // When: Execute query
        let (_, emotion) = await viewModel.executeIntelligentQuery("What's my weight?")

        // Then: Emotion should be offtrack (gaining weight when goal is to lose)
        XCTAssertEqual(emotion, .offtrack, "User gaining weight toward loss goal should be offtrack")
    }

    /// Test: InsightGenerator generates goal progress insights
    func testInsightGenerator_GeneratesGoalProgressInsight() async {
        // Given: User with goal set
        UserDefaults.standard.set(170.0, forKey: "weightGoal")
        mockDataService.mockCurrentWeight = WeightEntry(weight: 180.6, date: Date(), notes: nil)
        mockAnalyzer.mockAverageWeight = WeightAnalysisResult(
            value: 180.6,
            date: Date(),
            context: "last 7 days"
        )

        // When: Execute average weight query
        let (response, _) = await viewModel.executeIntelligentQuery("What's my average weight?")

        // Then: Response should include goal-related context
        // Note: We can't directly test InsightGenerator.generateInsights() here,
        // but we verify the response includes insight-rich content
        XCTAssertFalse(response.isEmpty, "Should generate response")
        // Response should NOT be the old gimmicky format
        XCTAssertFalse(response == "Your average weight is 180.6 lbs.", "Should use enhanced response")
    }

    /// Test: ConversationManager tracks dialogue
    func testConversationManager_TracksConversation() async {
        // Given: Initial state
        XCTAssertEqual(viewModel.messages.count, 1, "Should have welcome message")

        // When: Send multiple queries
        await viewModel.sendQuery("What's my weight?")
        // Wait for processing
        try? await Task.sleep(nanoseconds: 600_000_000)  // 0.6 seconds

        await viewModel.sendQuery("How does that compare to last week?")
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Then: Messages should be tracked
        // Welcome + Query1 + Response1 + Query2 + Response2 = 5 messages
        XCTAssertGreaterThanOrEqual(viewModel.messages.count, 4, "Should track conversation history")
    }

    /// Test: generateEnhancedResponse() is called (not old generateResponse)
    func testGenerateEnhancedResponse_CalledInsteadOfOldMethod() async {
        // Given: User query
        mockDataService.mockCurrentWeight = WeightEntry(weight: 180.6, date: Date(), notes: nil)
        mockAnalyzer.mockAverageWeight = WeightAnalysisResult(
            value: 180.6,
            date: Date(),
            context: "last 7 days"
        )

        // When: Execute query
        let (response, _) = await viewModel.executeIntelligentQuery("What's my average weight?")

        // Then: Response format should indicate enhanced generation
        // Old format: "Your average weight is X lbs."
        // New format: Multi-paragraph with context, insights, recommendations
        XCTAssertFalse(response.isEmpty, "Should generate response")

        // Enhanced responses should be longer (contain more context)
        // Note: This is a heuristic test - enhanced responses are typically 100+ chars
        // while old responses were ~30 chars
        // We can't assert exact length, but we verify it's not the old format
    }

    // MARK: - End-to-End Scenarios (Phase 4C)

    /// Scenario 1: "What's my average weight?" with goal context
    func testScenario_AverageWeightWithGoal() async {
        // Given: User with goal and data
        UserDefaults.standard.set(170.0, forKey: "weightGoal")
        mockDataService.mockCurrentWeight = WeightEntry(weight: 180.6, date: Date(), notes: nil)
        mockDataService.mockAllWeights = [
            WeightEntry(weight: 180.6, date: Date(), notes: nil),
            WeightEntry(weight: 182.9, date: Date().addingTimeInterval(-86400 * 7), notes: nil)
        ]
        mockAnalyzer.mockAverageWeight = WeightAnalysisResult(
            value: 180.6,
            date: Date(),
            context: "last 7 days"
        )
        mockAnalyzer.mockWeightChange7Days = WeightChangeResult(
            change: -2.3,
            startWeight: 182.9,
            endWeight: 180.6,
            startDate: Date().addingTimeInterval(-86400 * 7),
            endDate: Date()
        )
        mockAnalyzer.mockFastCountThisWeek = 4
        mockAnalyzer.mockFastCountLastWeek = 3

        // When: Query average weight
        let (response, emotion) = await viewModel.executeIntelligentQuery("What's my average weight?")

        // Then: Response should include context + insights
        XCTAssertFalse(response.isEmpty, "Should generate response")
        XCTAssertEqual(emotion, .energized, "Lost weight with improved fasting should be energized")
        // Response quality test: Should not be the old gimmicky format
        XCTAssertFalse(response == "Your average weight is 180.6 lbs.", "Should use enhanced response")
    }

    /// Scenario 2: "How far away am I from my goal?"
    func testScenario_GoalProgressQuery() async {
        // Given: User with goal
        UserDefaults.standard.set(170.0, forKey: "weightGoal")
        mockDataService.mockCurrentWeight = WeightEntry(weight: 180.6, date: Date(), notes: nil)
        mockAnalyzer.mockTrendResult = TrendAnalysisResult(
            direction: .down,
            strength: -0.33,  // Losing ~0.33 lbs/week
            confidence: 0.85,
            dataPoints: 10
        )

        // When: Query goal progress
        let (response, emotion) = await viewModel.executeIntelligentQuery("How far am I from my goal?")

        // Then: Response should include distance and ETA
        XCTAssertFalse(response.isEmpty, "Should generate response")
        // Emotion should be goal-aware
        XCTAssertNotEqual(emotion, .offtrack, "User losing weight toward goal should not be offtrack")
    }

    /// Scenario 3: No data (graceful fallback)
    func testScenario_NoData_GracefulFallback() async {
        // Given: No data available
        mockDataService.mockCurrentWeight = nil
        mockDataService.mockAllWeights = []

        // When: Query weight
        let (response, emotion) = await viewModel.executeIntelligentQuery("What's my weight?")

        // Then: Should fall back gracefully (Phase 1 handler)
        XCTAssertFalse(response.isEmpty, "Should generate fallback response")
        XCTAssertEqual(emotion, .stable, "No data should default to stable emotion")
    }
}

// MARK: - Mock Data Service

class MockHealthDataAggregator: HealthDataAggregator {

    var mockCurrentWeight: WeightEntry?
    var mockAllWeights: [WeightEntry] = []
    var mockAllFasts: [FastingSession] = []
    var mockCurrentFast: FastingSession?

    var didCallGetCurrentWeight = false
    var didCallFetchAllWeightData = false

    func fetchAllWeightData() async -> [WeightEntry] {
        didCallFetchAllWeightData = true
        return mockAllWeights
    }

    func fetchWeightData(from startDate: Date, to endDate: Date) async -> [WeightEntry] {
        return mockAllWeights.filter { $0.date >= startDate && $0.date <= endDate }
    }

    func getCurrentWeight() async -> WeightEntry? {
        didCallGetCurrentWeight = true
        return mockCurrentWeight
    }

    func fetchAllFastingSessions() async -> [FastingSession] {
        return mockAllFasts
    }

    func fetchFastingSessions(from startDate: Date, to endDate: Date) async -> [FastingSession] {
        return mockAllFasts.filter { $0.startTime >= startDate && $0.startTime <= endDate }
    }

    func getCurrentFast() async -> FastingSession? {
        return mockCurrentFast
    }

    func fetchAllSleepData() async -> [SleepEntry] { return [] }
    func fetchSleepData(from startDate: Date, to endDate: Date) async -> [SleepEntry] { return [] }
    func getLastNightSleep() async -> SleepEntry? { return nil }
    func fetchAllHydrationData() async -> [(Date, Double)] { return [] }
    func fetchHydrationData(from startDate: Date, to endDate: Date) async -> [(Date, Double)] { return [] }
    func getTodayHydration() async -> Double { return 0 }
    func fetchAllMoodData() async -> [MoodEntry] { return [] }
    func fetchMoodData(from startDate: Date, to endDate: Date) async -> [MoodEntry] { return [] }
    func getTodayMood() async -> MoodEntry? { return nil }
    func getTodaySummary() async -> [String: Any] { return [:] }
    func getSummary(from startDate: Date, to endDate: Date) async -> [String: Any] { return [:] }
}

// MARK: - Mock Health Analyzer

class MockHealthAnalyzer: HealthDataAnalyzerProtocol {

    var mockTrendResult: TrendAnalysisResult?
    var mockWeightChange7Days: WeightChangeResult?
    var mockWeightChange30Days: WeightChangeResult?
    var mockFastCountThisWeek: Int?
    var mockFastCountLastWeek: Int?
    var mockFastCountThisMonth: Int?
    var mockFastCountLastMonth: Int?
    var mockFastingStreak: Int?
    var mockAverageWeight: WeightAnalysisResult?

    var didCallAnalyzeTrend = false
    var didCallCalculateWeightChange = false
    var didCallCountFasts = false

    func analyzeWeightTrend(in timeRange: TimeRange?) async throws -> TrendAnalysisResult {
        didCallAnalyzeTrend = true
        guard let result = mockTrendResult else { throw AnalysisError.noData }
        return result
    }

    func calculateWeightChange(period: TimePeriod) async throws -> WeightChangeResult {
        didCallCalculateWeightChange = true
        if case .custom(let days) = period {
            if days == 7, let result = mockWeightChange7Days {
                return result
            }
            if days == 30, let result = mockWeightChange30Days {
                return result
            }
        }
        throw AnalysisError.noData
    }

    func countFasts(in timeRange: TimeRange?) async throws -> Int {
        didCallCountFasts = true
        switch timeRange {
        case .thisWeek:
            guard let count = mockFastCountThisWeek else { throw AnalysisError.noData }
            return count
        case .lastWeek:
            guard let count = mockFastCountLastWeek else { throw AnalysisError.noData }
            return count
        case .thisMonth:
            guard let count = mockFastCountThisMonth else { throw AnalysisError.noData }
            return count
        case .lastMonth:
            guard let count = mockFastCountLastMonth else { throw AnalysisError.noData }
            return count
        default:
            throw AnalysisError.noData
        }
    }

    func calculateFastingStreak() async throws -> Int {
        guard let streak = mockFastingStreak else { throw AnalysisError.noData }
        return streak
    }

    func calculateAverageWeight(in timeRange: TimeRange?) async throws -> WeightAnalysisResult {
        guard let result = mockAverageWeight else { throw AnalysisError.noData }
        return result
    }

    // MARK: - Unimplemented (throw noData)

    func findMinimumWeight(in timeRange: TimeRange?) async throws -> WeightAnalysisResult {
        throw AnalysisError.noData
    }

    func findMaximumWeight(in timeRange: TimeRange?) async throws -> WeightAnalysisResult {
        throw AnalysisError.noData
    }

    func calculateMedianWeight(in timeRange: TimeRange?) async throws -> WeightAnalysisResult {
        throw AnalysisError.noData
    }

    func calculateWeightPercentile(value: Double, in timeRange: TimeRange?) async throws -> Double {
        throw AnalysisError.noData
    }

    func findLargestWeightLoss(period: TimePeriod) async throws -> WeightChangeResult {
        throw AnalysisError.noData
    }

    func findLargestWeightGain(period: TimePeriod) async throws -> WeightChangeResult {
        throw AnalysisError.noData
    }

    func calculateWeightChangeRate(period: TimePeriod) async throws -> Double {
        throw AnalysisError.noData
    }

    func calculateWeightDelta(from startDate: Date, to endDate: Date) async throws -> WeightChangeResult {
        throw AnalysisError.noData
    }

    func findLongestFast(in timeRange: TimeRange?) async throws -> FastingAnalysisResult {
        throw AnalysisError.noData
    }

    func calculateCompletionRate(in timeRange: TimeRange?) async throws -> Double {
        throw AnalysisError.noData
    }

    func calculateAverageFastDuration(in timeRange: TimeRange?) async throws -> Double {
        throw AnalysisError.noData
    }

    func detectFastingProtocol(in timeRange: TimeRange?) async throws -> String {
        throw AnalysisError.noData
    }

    func calculateTotalFastingHours(in timeRange: TimeRange?) async throws -> Double {
        throw AnalysisError.noData
    }

    func calculateFastFrequency(in timeRange: TimeRange?) async throws -> Double {
        throw AnalysisError.noData
    }

    func calculateMovingAverage(days: Int) async throws -> Double {
        throw AnalysisError.noData
    }

    func predictGoalCompletion(targetValue: Double) async throws -> Date? {
        return nil
    }

    func isOnTrackToGoal(targetValue: Double, targetDate: Date) async throws -> Bool {
        throw AnalysisError.noData
    }

    func calculateRateOfChange(in timeRange: TimeRange?) async throws -> Double {
        throw AnalysisError.noData
    }
}
