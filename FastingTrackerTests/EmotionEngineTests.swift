//
// EmotionEngineTests.swift
// FastingTrackerTests
//
// Created for Phase 3A: Goal-Aware Emotion Detection Tests
// Test Coverage: 20+ scenarios across all ES-5 states
// Reference: docs/planning/PHASE-3-INTELLIGENCE-UPGRADE.md
//

import XCTest
@testable import FastingTracker

final class EmotionEngineTests: XCTestCase {

    var engine: EmotionEngine!

    override func setUp() {
        super.setUp()
        engine = EmotionEngine.shared
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Priority 1: Inactivity Detection

    func testInactivity_4DaysIdle_ReturnsOfftrack() {
        // Given: User hasn't logged data in 4 days
        let context = EmotionContext(
            weightGoal: 170.0,
            currentWeight: 180.0,
            daysSinceLastActivity: 4
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .offtrack, "User idle >3 days should be offtrack")
    }

    func testInactivity_2DaysIdle_DoesNotReturnOfftrack() {
        // Given: User logged data 2 days ago
        let context = EmotionContext(
            weightGoal: 170.0,
            currentWeight: 180.0,
            weightTrend: -0.5,  // Losing weight
            progressRate: 3.5,
            requiredRate: 0.83,
            daysSinceLastActivity: 2
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertNotEqual(emotion, .offtrack, "User active within 3 days should not be offtrack from inactivity")
        XCTAssertEqual(emotion, .energized, "Should detect based on progress rate instead")
    }

    // MARK: - Priority 2: Goal Direction vs Trend Alignment

    func testGoalAlignment_LosingWeightButGoalToLose_ReturnsPositive() {
        // Given: User wants to lose weight (current > goal) and weight is decreasing
        let context = EmotionContext(
            weightGoal: 170.0,
            currentWeight: 180.0,
            weightTrend: -0.5,  // Losing 0.5 lbs/week
            progressRate: 3.5,  // Making progress
            requiredRate: 0.83  // Need 0.83 lbs/week
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .energized, "User losing weight toward goal should be energized")
    }

    func testGoalAlignment_GainingWeightButGoalToLose_ReturnsOfftrack() {
        // Given: User wants to lose weight (current > goal) but weight is increasing
        let context = EmotionContext(
            weightGoal: 170.0,
            currentWeight: 180.0,
            weightTrend: 0.3  // Gaining 0.3 lbs/week (wrong direction!)
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .offtrack, "User gaining weight when goal is to lose should be offtrack")
    }

    func testGoalAlignment_GainingWeightAndGoalToGain_ReturnsPositive() {
        // Given: User wants to gain weight (current < goal) and weight is increasing
        let context = EmotionContext(
            weightGoal: 180.0,
            currentWeight: 170.0,
            weightTrend: 0.5,  // Gaining 0.5 lbs/week
            progressRate: 3.5,
            requiredRate: 0.83
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .energized, "User gaining weight toward goal should be energized")
    }

    func testGoalAlignment_LosingWeightButGoalToGain_ReturnsOfftrack() {
        // Given: User wants to gain weight (current < goal) but weight is decreasing
        let context = EmotionContext(
            weightGoal: 180.0,
            currentWeight: 170.0,
            weightTrend: -0.3  // Losing weight (wrong direction!)
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .offtrack, "User losing weight when goal is to gain should be offtrack")
    }

    // MARK: - Priority 3: Progress Rate Analysis

    func testProgressRate_Exceeding120Percent_ReturnsEnergized() {
        // Given: User progressing at 120%+ of required rate
        let context = EmotionContext(
            weightGoal: 170.0,
            currentWeight: 180.0,
            progressRate: 1.2,  // 1.2 lbs/week
            requiredRate: 0.83  // Need 0.83 lbs/week → ratio = 1.45 (145%)
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .energized, "Progress >120% of required should be energized")
    }

    func testProgressRate_Between80And120Percent_ReturnsStable() {
        // Given: User progressing at 80-120% of required rate
        let context = EmotionContext(
            weightGoal: 170.0,
            currentWeight: 180.0,
            progressRate: 0.9,  // 0.9 lbs/week
            requiredRate: 0.83  // Need 0.83 lbs/week → ratio = 1.08 (108%)
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .stable, "Progress 80-120% of required should be stable")
    }

    func testProgressRate_Between50And80Percent_ReturnsStressed() {
        // Given: User progressing at 50-80% of required rate
        let context = EmotionContext(
            weightGoal: 170.0,
            currentWeight: 180.0,
            progressRate: 0.6,  // 0.6 lbs/week
            requiredRate: 0.83  // Need 0.83 lbs/week → ratio = 0.72 (72%)
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .stressed, "Progress 50-80% of required should be stressed")
    }

    func testProgressRate_Below50Percent_ReturnsTired() {
        // Given: User progressing at <50% of required rate
        let context = EmotionContext(
            weightGoal: 170.0,
            currentWeight: 180.0,
            progressRate: 0.3,  // 0.3 lbs/week
            requiredRate: 0.83  // Need 0.83 lbs/week → ratio = 0.36 (36%)
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .tired, "Progress <50% of required should be tired")
    }

    // MARK: - Priority 4: Fasting Consistency

    func testFastingConsistency_Improved20Percent_ReturnsEnergized() {
        // Given: User improved fasting by >20%
        let context = EmotionContext(
            fastingCountThisWeek: 6,
            fastingCountLastWeek: 5  // 120% consistency ratio
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .energized, "Fasting improved >20% should be energized")
    }

    func testFastingConsistency_Within20Percent_ReturnsStable() {
        // Given: User maintained fasting within ±20%
        let context = EmotionContext(
            fastingCountThisWeek: 5,
            fastingCountLastWeek: 5  // 100% consistency ratio
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .stable, "Fasting within ±20% should be stable")
    }

    func testFastingConsistency_Dropped20To50Percent_ReturnsStressed() {
        // Given: User dropped fasting by 20-50%
        let context = EmotionContext(
            fastingCountThisWeek: 3,
            fastingCountLastWeek: 5  // 60% consistency ratio
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .stressed, "Fasting dropped 20-50% should be stressed")
    }

    func testFastingConsistency_DroppedOver50Percent_ReturnsOfftrack() {
        // Given: User dropped fasting by >50%
        let context = EmotionContext(
            fastingCountThisWeek: 2,
            fastingCountLastWeek: 5  // 40% consistency ratio
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .offtrack, "Fasting dropped >50% should be offtrack")
    }

    // MARK: - Priority 5: Weight Change Heuristics

    func testWeightChange_Lost2PlusLbs_ReturnsEnergized() {
        // Given: User lost >2 lbs in 7 days (no goal data)
        let context = EmotionContext(
            weightChangeLast7Days: -2.5  // Lost 2.5 lbs
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .energized, "Lost >2 lbs should be energized")
    }

    func testWeightChange_Maintained_ReturnsStable() {
        // Given: User maintained weight (±1 lb)
        let context = EmotionContext(
            weightChangeLast7Days: 0.5  // Gained 0.5 lbs
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .stable, "Maintained ±1 lb should be stable")
    }

    func testWeightChange_Gained1To3Lbs_ReturnsStressed() {
        // Given: User gained 1-3 lbs in 7 days
        let context = EmotionContext(
            weightChangeLast7Days: 2.0  // Gained 2 lbs
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .stressed, "Gained 1-3 lbs should be stressed")
    }

    func testWeightChange_Gained3PlusLbs_ReturnsOfftrack() {
        // Given: User gained >3 lbs in 7 days
        let context = EmotionContext(
            weightChangeLast7Days: 4.0  // Gained 4 lbs
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .offtrack, "Gained >3 lbs should be offtrack")
    }

    // MARK: - Fallback Scenario

    func testFallback_NoData_ReturnsStable() {
        // Given: No data provided (all nil)
        let context = EmotionContext()

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .stable, "No data should default to stable")
    }

    // MARK: - Real-World Scenarios

    func testRealWorld_UserFromScreenshot_ReturnsOfftrack() {
        // Given: User from screenshot (180.6 lbs, goal 170 lbs, trending increasing)
        let context = EmotionContext(
            weightGoal: 170.0,
            currentWeight: 180.6,
            weightTrend: 0.2,  // Gaining 0.2 lbs/week (wrong direction!)
            fastingCountThisWeek: 3,
            fastingCountLastWeek: 5  // Fasting dropped 40%
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .offtrack, "User gaining weight when goal is to lose should be offtrack")
    }

    func testRealWorld_UserOnTrackToGoal_ReturnsEnergized() {
        // Given: User making great progress
        let context = EmotionContext(
            weightGoal: 170.0,
            currentWeight: 175.0,
            weightTrend: -0.8,  // Losing 0.8 lbs/week
            fastingCountThisWeek: 5,
            fastingCountLastWeek: 4,  // Improved consistency
            progressRate: 5.6,  // 0.8 lbs/week * 7 days
            requiredRate: 0.42  // 5 lbs / 12 weeks → ratio = 13.3 (1330%!)
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .energized, "User exceeding goal pace should be energized")
    }

    func testRealWorld_UserStrugglingWithFasting_ReturnsTired() {
        // Given: User struggling to maintain pace
        let context = EmotionContext(
            weightGoal: 160.0,
            currentWeight: 180.0,
            progressRate: 0.3,  // Very slow progress
            requiredRate: 1.67,  // Need 1.67 lbs/week → ratio = 0.18 (18%)
            fastingCountThisWeek: 2,
            fastingCountLastWeek: 5  // Fasting dropped significantly
        )

        // When
        let emotion = engine.detectEmotion(context: context)

        // Then
        XCTAssertEqual(emotion, .tired, "User at <50% progress rate should be tired")
    }
}
