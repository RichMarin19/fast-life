//
// QueryClassifierTests.swift
// FastingTrackerTests
//
// Created for LifeGPT Phase 2 Hour 1 - Query Classification Tests
// Production standard: 95%+ recognition rate, <50ms P50 latency
// Reference: LIFEGPT-INTELLIGENCE-LAYER-SPEC.md Section 2
//

import XCTest
@testable import FastLIFe

final class QueryClassifierTests: XCTestCase {

    var classifier: QueryClassifier!

    override func setUp() {
        super.setUp()
        classifier = QueryClassifier.shared
    }

    // MARK: - Pattern Count Tests

    func testTotalPatternCount_MeetsProductionStandard() {
        // Production standard: 50+ patterns
        XCTAssertGreaterThanOrEqual(
            classifier.totalPatternCount,
            50,
            "Must have at least 50 patterns for production"
        )
    }

    func testPatternCategories_Has8Categories() {
        XCTAssertEqual(classifier.patternCategories.count, 8)
    }

    // MARK: - Weight Stats Tests (11 patterns each)

    func testMinimumWeight_AllVariations() {
        let queries = [
            "What's the least I ever weighed?",
            "Lowest weight?",
            "Minimum weight",
            "Lightest I've been",
            "What's my smallest weight?"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .minimumWeight = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as minimumWeight, got \(intent)")
            }
        }
    }

    func testMaximumWeight_AllVariations() {
        let queries = [
            "What's the most I ever weighed?",
            "Highest weight?",
            "Maximum weight",
            "Heaviest I've been",
            "What's my peak weight?"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .maximumWeight = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as maximumWeight, got \(intent)")
            }
        }
    }

    func testAverageWeight_AllVariations() {
        let queries = [
            "What's my average weight?",
            "Mean weight",
            "Typical weight",
            "Average I weigh"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .averageWeight = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as averageWeight, got \(intent)")
            }
        }
    }

    func testMedianWeight_AllVariations() {
        let queries = [
            "What's my median weight?",
            "Middle weight",
            "Mid weight value"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .medianWeight = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as medianWeight, got \(intent)")
            }
        }
    }

    // MARK: - Weight Change Tests (12 patterns each)

    func testLargestWeightLoss_AllVariations() {
        let queries = [
            "What's the most weight I lost in a month?",
            "Biggest weight loss",
            "Largest weight drop",
            "Most I lost",
            "Greatest weight loss this year",
            "Best weight loss in a week"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .largestWeightLoss = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as largestWeightLoss, got \(intent)")
            }
        }
    }

    func testLargestWeightGain_AllVariations() {
        let queries = [
            "What's the most weight I gained in a month?",
            "Biggest weight gain",
            "Largest weight increase",
            "Most I gained this week",
            "Worst weight gain"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .largestWeightGain = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as largestWeightGain, got \(intent)")
            }
        }
    }

    func testWeightChange_AllVariations() {
        let queries = [
            "How much weight did I lose this month?",
            "How much weight did I gain?",
            "Weight change this year",
            "Weight difference"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .weightChange = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as weightChange, got \(intent)")
            }
        }
    }

    func testWeightChangeRate_AllVariations() {
        let queries = [
            "How fast am I losing weight?",
            "Weight loss rate",
            "Rate of weight loss",
            "How quickly am I losing?"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .weightChangeRate = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as weightChangeRate, got \(intent)")
            }
        }
    }

    // MARK: - Fasting Stats Tests (10+ patterns each)

    func testFastCount_AllVariations() {
        let queries = [
            "How many fasts this week?",
            "Number of fasts this month",
            "Count of fasts",
            "How many times did I fast?",
            "Total fasts"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .fastCount = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as fastCount, got \(intent)")
            }
        }
    }

    func testLongestFast_AllVariations() {
        let queries = [
            "What's my longest fast?",
            "Best fast duration",
            "Longest I've fasted",
            "Personal best fast",
            "Longest fast ever"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .longestFast = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as longestFast, got \(intent)")
            }
        }
    }

    func testFastingStreak_AllVariations() {
        let queries = [
            "What's my streak?",
            "Current streak",
            "How many days in a row?",
            "Consecutive days",
            "Fasting streak"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .fastingStreak = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as fastingStreak, got \(intent)")
            }
        }
    }

    func testCompletionRate_AllVariations() {
        let queries = [
            "What's my completion rate?",
            "Success rate",
            "Success percentage",
            "How often do I complete fasts?"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .completionRate = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as completionRate, got \(intent)")
            }
        }
    }

    func testAverageFastDuration_AllVariations() {
        let queries = [
            "What's my average fast?",
            "Mean fast duration",
            "Typical fast length",
            "Average fasting time"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .averageFastDuration = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as averageFastDuration, got \(intent)")
            }
        }
    }

    func testProtocolDetection_AllVariations() {
        let queries = [
            "What protocol am I following?",
            "Am I doing 16:8?",
            "What's my fasting schedule?",
            "Fasting protocol",
            "OMAD"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .detectProtocol = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as detectProtocol, got \(intent)")
            }
        }
    }

    func testTotalFastingHours_AllVariations() {
        let queries = [
            "Total hours fasted this month",
            "How long have I fasted?",
            "Total fasting time",
            "Cumulative fasting hours"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .totalFastingHours = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as totalFastingHours, got \(intent)")
            }
        }
    }

    // MARK: - Trend Tests (10 patterns each)

    func testWeightTrend_AllVariations() {
        let queries = [
            "Am I trending up?",
            "Weight trend",
            "Trending down?",
            "Weight direction",
            "What's the trend?"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .weightTrend = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as weightTrend, got \(intent)")
            }
        }
    }

    func testGoalETA_AllVariations() {
        let queries = [
            "When will I reach 170?",
            "ETA to goal",
            "When will I hit my goal?",
            "Goal completion date"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .goalETA = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as goalETA, got \(intent)")
            }
        }
    }

    func testOnTrackToGoal_AllVariations() {
        let queries = [
            "Am I on track?",
            "Will I hit my goal?",
            "On pace to goal?",
            "On target?"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .onTrackToGoal = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as onTrackToGoal, got \(intent)")
            }
        }
    }

    func testGoalProgress_AllVariations() {
        let queries = [
            "Progress to goal",
            "How much progress?",
            "Percentage to goal",
            "Percent complete"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .goalProgress = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as goalProgress, got \(intent)")
            }
        }
    }

    // MARK: - General Queries Tests

    func testCurrentStats_AllVariations() {
        let queries = [
            "Today's summary",
            "My stats",
            "How am I doing?",
            "Current stats",
            "Summary"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            if case .currentStats = intent {
                // Success
            } else {
                XCTFail("Failed to classify '\(query)' as currentStats, got \(intent)")
            }
        }
    }

    func testComparisons_AllVariations() {
        let queries = [
            "This week vs last week",
            "Compare this month to last",
            "This year vs last year",
            "WoW comparison"
        ]

        for query in queries {
            let intent = classifier.classify(query)
            switch intent {
            case .weekOverWeek, .monthOverMonth, .yearOverYear:
                // Success
                break
            default:
                XCTFail("Failed to classify '\(query)' as comparison, got \(intent)")
            }
        }
    }

    // MARK: - Time Range Extraction Tests

    func testTimeRangeExtraction_ThisWeek() {
        let intent = classifier.classify("What's my average weight this week?")
        if case .averageWeight(let timeRange) = intent {
            XCTAssertEqual(timeRange, .thisWeek)
        } else {
            XCTFail("Failed to extract 'this week' time range")
        }
    }

    func testTimeRangeExtraction_LastMonth() {
        let intent = classifier.classify("How many fasts last month?")
        if case .fastCount(let timeRange) = intent {
            XCTAssertEqual(timeRange, .lastMonth)
        } else {
            XCTFail("Failed to extract 'last month' time range")
        }
    }

    func testTimeRangeExtraction_AllTime() {
        let intent = classifier.classify("What's the least I ever weighed?")
        if case .minimumWeight(let timeRange) = intent {
            // "ever" should map to .allTime, but if nil, that's acceptable
            // as the default should be all-time for min/max queries
            XCTAssertTrue(timeRange == .allTime || timeRange == nil)
        } else {
            XCTFail("Failed to classify query with 'ever'")
        }
    }

    // MARK: - Period Extraction Tests

    func testPeriodExtraction_Month() {
        let intent = classifier.classify("What's the most weight I lost in a month?")
        if case .largestWeightLoss(let period) = intent {
            XCTAssertEqual(period, .month)
        } else {
            XCTFail("Failed to extract 'month' period")
        }
    }

    func testPeriodExtraction_Week() {
        let intent = classifier.classify("Biggest weight gain in a week")
        if case .largestWeightGain(let period) = intent {
            XCTAssertEqual(period, .week)
        } else {
            XCTFail("Failed to extract 'week' period")
        }
    }

    // MARK: - Number Extraction Tests

    func testNumberExtraction_GoalETA() {
        let intent = classifier.classify("When will I reach 170?")
        if case .goalETA(let targetValue, _) = intent {
            XCTAssertEqual(targetValue, 170.0)
        } else {
            XCTFail("Failed to extract number 170 from query")
        }
    }

    func testNumberExtraction_GoalProgress() {
        let intent = classifier.classify("Progress to 165?")
        if case .goalProgress(let targetValue, _) = intent {
            XCTAssertEqual(targetValue, 165.0)
        } else {
            XCTFail("Failed to extract number 165 from query")
        }
    }

    // MARK: - Unknown Intent Tests

    func testUnknownIntent_ComplexQuery() {
        let intent = classifier.classify("What's the meaning of life?")
        if case .unknown(let query) = intent {
            XCTAssertEqual(query, "What's the meaning of life?")
        } else {
            XCTFail("Should classify unrelated query as unknown")
        }
    }

    func testUnknownIntent_ConversationalQuery() {
        let intent = classifier.classify("How are you feeling today?")
        if case .unknown = intent {
            // Success
        } else {
            XCTFail("Should classify conversational query as unknown")
        }
    }

    // MARK: - Performance Tests

    func testLatency_MeetsProductionStandard() {
        // Production standard: <50ms P50
        let query = "What's the most weight I lost in a month?"
        let latency = classifier.measureLatency(for: query, iterations: 100)

        XCTAssertLessThan(
            latency,
            50.0,
            "Classification latency must be <50ms (got \(latency)ms)"
        )
    }

    func testLatency_ComplexQuery() {
        // Even complex queries should be <100ms
        let query = "When will I reach 170 lbs at this rate?"
        let latency = classifier.measureLatency(for: query, iterations: 100)

        XCTAssertLessThan(
            latency,
            100.0,
            "Complex query latency must be <100ms (got \(latency)ms)"
        )
    }

    // MARK: - Recognition Rate Test (Production: 95%+)

    func testRecognitionRate_MeetsProductionStandard() {
        let testQueries: [(query: String, expected: QueryIntent)] = [
            // Weight stats (5 queries)
            ("What's the least I ever weighed?", .minimumWeight(timeRange: nil)),
            ("Highest weight?", .maximumWeight(timeRange: nil)),
            ("Average weight", .averageWeight(timeRange: nil)),
            ("Median weight", .medianWeight(timeRange: nil)),

            // Weight change (5 queries)
            ("Most weight lost in a month", .largestWeightLoss(period: .month)),
            ("Biggest weight gain", .largestWeightGain(period: .month)),
            ("Weight change", .weightChange(period: .month)),
            ("How fast am I losing?", .weightChangeRate(period: .month)),

            // Fasting stats (7 queries)
            ("How many fasts this week?", .fastCount(timeRange: .thisWeek)),
            ("Longest fast", .longestFast(timeRange: nil)),
            ("What's my streak?", .fastingStreak),
            ("Completion rate", .completionRate(timeRange: .thisMonth)),
            ("Average fast", .averageFastDuration(timeRange: .thisMonth)),
            ("What protocol am I doing?", .detectProtocol(timeRange: .last30Days)),
            ("Total hours fasted", .totalFastingHours(timeRange: .thisMonth)),

            // Trends (4 queries)
            ("Weight trend", .weightTrend(timeRange: .last30Days)),
            ("ETA to goal", .goalETA(targetValue: 170.0, metric: .weight)),
            ("Am I on track?", .onTrackToGoal(targetValue: 170.0, targetDate: Date().addingTimeInterval(30*24*60*60), metric: .weight)),
            ("Progress to goal", .goalProgress(targetValue: 170.0, metric: .weight)),

            // General (2 queries)
            ("Today's summary", .currentStats),
            ("This week vs last week", .weekOverWeek(metric: .weight))
        ]

        let recognitionRate = classifier.recognitionRate(for: testQueries)

        XCTAssertGreaterThanOrEqual(
            recognitionRate,
            0.95,
            "Recognition rate must be ≥95% (got \(Int(recognitionRate * 100))%)"
        )
    }

    // MARK: - Edge Cases

    func testCaseInsensitive() {
        let lowercase = classifier.classify("what's my average weight?")
        let uppercase = classifier.classify("WHAT'S MY AVERAGE WEIGHT?")
        let mixed = classifier.classify("WhAt'S mY aVeRaGe WeIgHt?")

        XCTAssertEqual(lowercase, uppercase)
        XCTAssertEqual(lowercase, mixed)
    }

    func testWhitespaceHandling() {
        let normal = classifier.classify("what's my average weight?")
        let extraSpaces = classifier.classify("  what's   my   average   weight?  ")

        XCTAssertEqual(normal, extraSpaces)
    }

    func testEmptyQuery() {
        let intent = classifier.classify("")
        if case .unknown = intent {
            // Success
        } else {
            XCTFail("Empty query should classify as unknown")
        }
    }

    // MARK: - Intent Properties Tests

    func testOfflineCapability_MinimumWeight() {
        let intent = QueryIntent.minimumWeight(timeRange: .allTime)
        XCTAssertTrue(intent.isOfflineCapable)
    }

    func testOfflineCapability_Unknown() {
        let intent = QueryIntent.unknown(query: "test")
        XCTAssertFalse(intent.isOfflineCapable)
    }

    func testComplexity_SimpleQuery() {
        let intent = QueryIntent.currentStats
        XCTAssertEqual(intent.complexity, .simple)
    }

    func testComplexity_ModerateQuery() {
        let intent = QueryIntent.weightTrend(timeRange: .last30Days)
        XCTAssertEqual(intent.complexity, .moderate)
    }

    func testComplexity_ComplexQuery() {
        let intent = QueryIntent.goalETA(targetValue: 170, metric: .weight)
        XCTAssertEqual(intent.complexity, .complex)
    }
}
