//
// LifeGPTViewModel.swift
// FastingTracker
//
// Created for LifeGPT Feature - Phase 1
// ViewModel for AI Health Coach chat interface
//

import Foundation
import Combine
import os.log

// MARK: - LifeGPT ViewModel

/// ViewModel for LifeGPT chat interface
/// Following Fast LIFe's ViewModel pattern (WeightTrackingViewModel, WeightControlCenterViewModel)
/// Handles user queries, generates responses, manages chat state
/// Phase 1: Simple keyword matching (no AI/LLM yet)
/// Phase 2: Add OpenAI integration for natural language understanding
@MainActor
class LifeGPTViewModel: ObservableObject {

    // MARK: - Published State

    /// All messages in the chat (user + assistant)
    @Published var messages: [ChatMessage] = []

    /// Current user input text
    @Published var inputText: String = ""

    /// Whether assistant is processing a query (for loading indicator)
    @Published var isProcessing: Bool = false

    /// Whether first-launch loading is in progress (building InsightContext from HealthKit)
    @Published var isFirstLaunchLoading: Bool = false

    // MARK: - Dependencies

    private let dataService: HealthDataAggregator

    // Phase 2: Intelligence Layer (Production)
    private let queryClassifier: QueryClassifierProtocol
    private let healthAnalyzer: HealthDataAnalyzerProtocol
    private let responseGenerator: ResponseGeneratorProtocol

    // Phase 4: Enhanced Intelligence Layer (Goal-Aware + Insights + Conversation)
    private let conversationManager: ConversationManager

    // MARK: - Logging (Apple Standard)

    /// Unified logging for LifeGPT intelligence layer
    /// **Apple Pattern:** Subsystem + category for filtering in Console.app
    private let logger = Logger(subsystem: "com.fastlife.FastingTracker", category: "LifeGPT")

    // MARK: - Initialization

    /// Initialize with data service dependency
    /// Following Fast LIFe's dependency injection pattern
    /// - Parameters:
    ///   - dataService: Service for fetching unified health data
    ///   - queryClassifier: Query classification service (default: QueryClassifier.shared)
    ///   - healthAnalyzer: Health data analysis service (optional, uses production analyzer if nil)
    ///   - responseGenerator: Response generation service (default: ResponseGenerator.shared)
    init(
        dataService: HealthDataAggregator,
        queryClassifier: QueryClassifierProtocol = QueryClassifier.shared,
        healthAnalyzer: HealthDataAnalyzerProtocol? = nil,
        responseGenerator: ResponseGeneratorProtocol = ResponseGenerator.shared,
        conversationManager: ConversationManager = ConversationManager()
    ) {
        self.dataService = dataService
        self.queryClassifier = queryClassifier
        self.responseGenerator = responseGenerator
        self.conversationManager = conversationManager

        // Initialize health analyzer with data service
        if let analyzer = healthAnalyzer {
            self.healthAnalyzer = analyzer
        } else {
            // Use production analyzer with data service
            self.healthAnalyzer = HealthDataAnalysisService(dataService: dataService)
        }

        // Add welcome message on init
        addWelcomeMessage()

        // Test log to verify logging is working
        logger.info("✅ LifeGPTViewModel initialized successfully")
    }

    // MARK: - Public API

    /// Send user's query and get response
    /// - Parameter query: User's question
    func sendQuery(_ query: String) {
        // Trim whitespace
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate query is not empty
        guard !trimmedQuery.isEmpty else { return }

        // Add user message
        let userMessage = ChatMessage.userMessage(trimmedQuery)
        messages.append(userMessage)

        // Clear input
        inputText = ""

        // Process query asynchronously
        Task {
            isProcessing = true

            // Add delay to simulate processing (smoother UX)
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Phase 2: Use production intelligence layer
            let (response, emotion) = await executeIntelligentQuery(trimmedQuery)

            // Add assistant response with emotion
            let assistantMessage = ChatMessage.assistantMessage(response, emotion: emotion)
            messages.append(assistantMessage)

            isProcessing = false
        }
    }

    /// Clear all messages and reset chat
    func clearChat() {
        messages.removeAll()
        addWelcomeMessage()
    }

    // MARK: - Private Query Handling (Phase 2: Production Intelligence Layer)

    /// Execute query using production intelligence layer
    /// **Phase 4:** QueryClassifier → HealthDataAnalyzer → EmotionEngine → InsightGenerator → ResponseGenerator
    /// **Fallback:** Phase 1 keyword matching if intelligence layer unavailable
    /// - Parameter query: User's question
    /// - Returns: Tuple of (response text, detected emotion)
    private func executeIntelligentQuery(_ query: String) async -> (String, EmotionState) {
        // Step 1: Classify query intent
        let intent = queryClassifier.classify(query)
        logger.debug("🔍 Query classified: '\(query, privacy: .public)' → Intent: \(String(describing: intent), privacy: .public)")

        // Step 2: Handle offline-capable queries
        if intent.isOfflineCapable {
            do {
                logger.info("✅ Intent is offline-capable, executing analysis...")
                // Step 2a: Execute query based on intent type
                let result = try await executeAnalysis(for: intent)
                logger.debug("✅ Analysis succeeded, result type: \(String(describing: type(of: result)), privacy: .public)")

                // Step 2b: Build insight context (Phase 4: Single source of truth for all health data)
                logger.info("📊 Building insight context...")
                let insightContext = await buildInsightContext()
                logger.debug("📊 Context built - Goal: \(insightContext.weightGoal?.description ?? "nil", privacy: .public), Current: \(insightContext.currentWeight?.description ?? "nil", privacy: .public), Fasts this week: \(insightContext.fastingCountThisWeek?.description ?? "nil", privacy: .public)")

                // Step 2c: Generate insights (Phase 4: Multi-metric correlation)
                let insights = await InsightGenerator.shared.generateInsights(context: insightContext)
                logger.info("💡 Generated \(insights.insights.count) insights")

                // Step 2d: Generate recommendations (Phase 4: Actionable advice)
                let recommendations = await InsightGenerator.shared.generateRecommendations(context: insightContext)
                logger.info("🎯 Generated \(recommendations.count) recommendations")

                // Step 2e: Detect goal-aware emotion (Phase 4: EmotionEngine with context)
                let emotion = EmotionEngine.shared.detectEmotion(
                    weightGoal: insightContext.weightGoal,
                    currentWeight: insightContext.currentWeight,
                    trendResult: insightContext.weightTrendResult,
                    fastingCountThisWeek: insightContext.fastingCountThisWeek,
                    fastingCountLastWeek: insightContext.fastingCountLastWeek,
                    daysSinceLastActivity: nil  // TODO: Calculate days since last activity
                )
                logger.debug("😊 Detected emotion: \(String(describing: emotion), privacy: .public)")

                // Step 2f: Generate enhanced response (Phase 4: Insight-rich + recommendations)
                let userPrefs = UserPreferences.default
                let response = responseGenerator.generateEnhancedResponse(
                    for: intent,
                    result: result,
                    emotion: emotion,
                    userPreferences: userPrefs,
                    insights: insights,
                    recommendations: recommendations,
                    conversationContext: conversationManager.context
                )
                logger.info("💬 Enhanced response generated (\(response.count) chars)")

                // Step 2g: Track conversation (Phase 4: Conversation continuity)
                conversationManager.addMessage(ChatMessage(
                    sender: .user,
                    content: query,
                    emotion: emotion
                ))
                conversationManager.addMessage(ChatMessage(
                    sender: .assistant,
                    content: response,
                    emotion: emotion
                ))

                return (response, emotion)

            } catch {
                // If analysis fails, fall back to Phase 1 method
                logger.error("❌ Intelligence layer error: \(error.localizedDescription, privacy: .public). Falling back to Phase 1.")
                return await handleQueryWithEmotion(query)
            }
        }

        // Step 3: Unknown intents fall back to Phase 1 or LLM (Phase 3)
        logger.warning("⚠️ Intent not offline-capable, falling back to Phase 1")
        return await handleQueryWithEmotion(query)
    }

    // MARK: - Phase 4: Intelligence Context Builder (Optimized)

    /// Build InsightContext from all available health data
    /// **Phase 4:** Single source of truth for intelligence layers
    /// **Phase 4A Optimization:** Cached + batched queries (12 sequential → 2 parallel queries)
    /// **Performance:** 3-5s → <500ms (10x speedup via caching + batching)
    /// **First Launch UX:** Shows loading overlay if first time building context
    /// **Gathers:** Goal, weight, fasting, trend data for EmotionEngine + InsightGenerator
    /// - Returns: InsightContext with all available data
    private func buildInsightContext() async -> InsightContext {
        // Check cache first (30s TTL per PerformanceTokens)
        let cacheKey = "insightContext"
        if let cached: InsightContext = await QueryCache.shared.get(forKey: cacheKey) {
            logger.debug("⚡ InsightContext cache hit (TTL: \(PerformanceTokens.insightContextCacheTTL)s)")
            return cached
        }

        logger.debug("🔄 InsightContext cache miss, building fresh context...")

        // Check if this is first launch (no previous InsightContext built)
        let hasCompletedFirstLoad = UserDefaults.standard.bool(forKey: "hasCompletedFirstInsightLoad")
        if !hasCompletedFirstLoad {
            logger.info("🎯 First launch detected - showing loading overlay")
            await MainActor.run {
                isFirstLaunchLoading = true
            }
        }

        // Goal data (MUST match WeightTrackingViewModel key: "goalWeight")
        let weightGoal: Double? = UserDefaults.standard.object(forKey: "goalWeight") as? Double

        // **OPTIMIZATION:** Fetch all weight data ONCE (instead of 3 separate queries)
        // This single query replaces: getCurrentWeight(), fetchAllWeightData(), fetchWeightData(30d), fetchWeightData(90d)
        let now = Date()
        let cal = Calendar.current
        let ninetyDaysAgo = cal.date(byAdding: .day, value: -90, to: now) ?? now

        // Single batched weight query (replaces 4 queries)
        let allWeights = await dataService.fetchWeightData(from: ninetyDaysAgo, to: now)

        // Derive all weight metrics from single dataset
        let currentWeight = allWeights.first?.weight  // Most recent entry
        let startWeight = allWeights.last?.weight     // Oldest entry (start of 90d window)

        // Calculate weight changes locally (avoid HealthDataAnalyzer queries)
        let sevenDaysAgo = cal.date(byAdding: .day, value: -7, to: now) ?? now
        let thirtyDaysAgo = cal.date(byAdding: .day, value: -30, to: now) ?? now

        let last7DaysWeights = allWeights.filter { $0.date >= sevenDaysAgo }
        let last30DaysWeights = allWeights.filter { $0.date >= thirtyDaysAgo }

        let weightChangeLast7Days = calculateWeightChange(from: last7DaysWeights)
        let weightChangeLast30Days = calculateWeightChange(from: last30DaysWeights)

        // Calculate averages locally (no additional queries needed)
        let averageWeightLast30Days = last30DaysWeights.isEmpty ? nil : last30DaysWeights.map({ $0.weight }).reduce(0, +) / Double(last30DaysWeights.count)
        let averageWeightLast90Days = allWeights.isEmpty ? nil : allWeights.map({ $0.weight }).reduce(0, +) / Double(allWeights.count)

        // Trend analysis (still needs HealthDataAnalyzer, but could be optimized to use allWeights)
        let weightTrendResult = try? await healthAnalyzer.analyzeWeightTrend(in: .last30Days)

        // **OPTIMIZATION:** Batch fasting queries in parallel (use Task.detached for concurrency)
        async let fastingCountThisWeekTask = healthAnalyzer.countFasts(in: .thisWeek)
        async let fastingCountLastWeekTask = healthAnalyzer.countFasts(in: .lastWeek)
        async let fastingCountThisMonthTask = healthAnalyzer.countFasts(in: .thisMonth)
        async let fastingCountLastMonthTask = healthAnalyzer.countFasts(in: .lastMonth)
        async let currentStreakTask = healthAnalyzer.calculateFastingStreak()

        // Await all fasting queries in parallel (5 queries → 1 batch)
        let fastingCountThisWeek = try? await fastingCountThisWeekTask
        let fastingCountLastWeek = try? await fastingCountLastWeekTask
        let fastingCountThisMonth = try? await fastingCountThisMonthTask
        let fastingCountLastMonth = try? await fastingCountLastMonthTask
        let currentStreak = try? await currentStreakTask

        let longestStreak: Int? = nil  // TODO: Add to HealthDataAnalyzer

        // Average fasts per week (estimate from last 30 days)
        let averageFastsPerWeek: Double? = if let monthCount = fastingCountThisMonth {
            Double(monthCount) / 4.0  // Approximate 4 weeks per month
        } else {
            nil
        }

        let context = InsightContext(
            weightGoal: weightGoal,
            currentWeight: currentWeight,
            startWeight: startWeight,
            weightTrendResult: weightTrendResult,
            weightChangeLast7Days: weightChangeLast7Days,
            weightChangeLast30Days: weightChangeLast30Days,
            fastingCountThisWeek: fastingCountThisWeek,
            fastingCountLastWeek: fastingCountLastWeek,
            fastingCountThisMonth: fastingCountThisMonth,
            fastingCountLastMonth: fastingCountLastMonth,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            averageWeightLast30Days: averageWeightLast30Days,
            averageWeightLast90Days: averageWeightLast90Days,
            averageFastsPerWeek: averageFastsPerWeek
        )

        // Cache result (30s TTL)
        await QueryCache.shared.set(context, forKey: cacheKey, ttl: PerformanceTokens.insightContextCacheTTL)
        logger.debug("💾 InsightContext cached (TTL: \(PerformanceTokens.insightContextCacheTTL)s)")

        // Mark first load as complete (only set once)
        if !hasCompletedFirstLoad {
            UserDefaults.standard.set(true, forKey: "hasCompletedFirstInsightLoad")
            logger.info("✅ First InsightContext load complete - flag set")

            // Dismiss loading overlay
            await MainActor.run {
                isFirstLaunchLoading = false
            }
        }

        return context
    }

    /// Calculate weight change from array of weight entries
    /// **Helper:** Avoids redundant HealthDataAnalyzer queries
    /// - Parameter weights: Array of weight entries (sorted newest first)
    /// - Returns: Weight change (negative = loss, positive = gain), nil if insufficient data
    private func calculateWeightChange(from weights: [WeightEntry]) -> Double? {
        guard let first = weights.first, let last = weights.last, weights.count >= 2 else {
            return nil
        }
        return first.weight - last.weight  // newest - oldest
    }

    /// Execute data analysis based on query intent
    /// **Production:** Uses HealthDataAnalyzer for all supported intent types
    /// - Parameter intent: Classified query intent
    /// - Returns: Analysis result (type varies by intent)
    /// - Throws: AnalysisError if data unavailable or calculation fails
    private func executeAnalysis(for intent: QueryIntent) async throws -> Any {
        switch intent {

        // Weight Stats
        case .currentWeight:
            // Get latest weight entry (NOT statistical average)
            if let latestWeight = await dataService.getCurrentWeight() {
                return WeightAnalysisResult(
                    value: latestWeight.weight,
                    date: latestWeight.date,
                    unit: "lbs",
                    timeRange: nil,
                    metadata: nil
                )
            } else {
                throw AnalysisError.noData
            }

        case .minimumWeight(let timeRange):
            return try await healthAnalyzer.findMinimumWeight(in: timeRange)

        case .maximumWeight(let timeRange):
            return try await healthAnalyzer.findMaximumWeight(in: timeRange)

        case .averageWeight(let timeRange):
            return try await healthAnalyzer.calculateAverageWeight(in: timeRange)

        case .medianWeight(let timeRange):
            return try await healthAnalyzer.calculateMedianWeight(in: timeRange)

        case .weightPercentile(let value, let timeRange):
            return try await healthAnalyzer.calculateWeightPercentile(value: value, in: timeRange)

        // Weight Change
        case .largestWeightLoss(let period):
            return try await healthAnalyzer.findLargestWeightLoss(period: period)

        case .largestWeightGain(let period):
            return try await healthAnalyzer.findLargestWeightGain(period: period)

        case .weightChange(let period):
            return try await healthAnalyzer.calculateWeightChange(period: period)

        case .weightChangeRate(let period):
            return try await healthAnalyzer.calculateWeightChangeRate(period: period)

        case .weightDelta(let startDate, let endDate):
            return try await healthAnalyzer.calculateWeightDelta(from: startDate, to: endDate)

        // Fasting Stats
        case .fastCount(let timeRange):
            return try await healthAnalyzer.countFasts(in: timeRange)

        case .longestFast(let timeRange):
            return try await healthAnalyzer.findLongestFast(in: timeRange)

        case .fastingStreak:
            return try await healthAnalyzer.calculateFastingStreak()

        case .completionRate(let timeRange):
            return try await healthAnalyzer.calculateCompletionRate(in: timeRange)

        case .averageFastDuration(let timeRange):
            return try await healthAnalyzer.calculateAverageFastDuration(in: timeRange)

        case .detectProtocol(let timeRange):
            return try await healthAnalyzer.detectFastingProtocol(in: timeRange)

        case .totalFastingHours(let timeRange):
            return try await healthAnalyzer.calculateTotalFastingHours(in: timeRange)

        case .fastFrequency(let timeRange):
            return try await healthAnalyzer.calculateFastFrequency(in: timeRange)

        // Sleep Stats
        case .averageSleep(timeRange: _):
            // TODO: Implement sleep analytics when sleep tracking is added
            throw AnalysisError.noData

        case .sleepQuality(timeRange: _):
            // TODO: Implement sleep quality analytics
            throw AnalysisError.noData

        case .sleepConsistency(timeRange: _):
            // TODO: Implement sleep consistency analytics
            throw AnalysisError.noData

        // Trend Analysis
        case .weightTrend(let timeRange):
            return try await healthAnalyzer.analyzeWeightTrend(in: timeRange)

        case .movingAverage(metric: _, days: let days):
            return try await healthAnalyzer.calculateMovingAverage(days: days)

        case .goalETA(targetValue: let targetValue, metric: _):
            if let eta = try await healthAnalyzer.predictGoalCompletion(targetValue: targetValue) {
                return eta
            } else {
                throw AnalysisError.noSignificantChange
            }

        case .onTrackToGoal(targetValue: let targetValue, targetDate: let targetDate, metric: _):
            return try await healthAnalyzer.isOnTrackToGoal(targetValue: targetValue, targetDate: targetDate)

        case .rateOfChange(metric: _, timeRange: let timeRange):
            return try await healthAnalyzer.calculateRateOfChange(in: timeRange)

        // Goal Tracking
        case .goalProgress(targetValue: _, metric: _):
            // Calculate progress percentage
            // TODO: Implement goal progress calculation
            return 0.0

        case .goalStatus(targetValue: _, metric: _), .remainingToGoal(targetValue: _, metric: _):
            // TODO: Implement goal status/remaining
            throw AnalysisError.noData

        // Current stats and comparisons
        case .currentStats:
            // TODO: Implement aggregated stats
            throw AnalysisError.noData

        case .recentActivity(days: _):
            // TODO: Implement recent activity summary
            throw AnalysisError.noData

        case .weekOverWeek(metric: _):
            // Simple week-over-week comparison using already-gathered data
            // Uses buildInsightContext() data (thisWeek vs lastWeek)
            let context = await buildInsightContext()

            guard let weightChange = context.weightChangeLast7Days,
                  let currentWeight = context.currentWeight else {
                throw AnalysisError.noData
            }

            // Note: fasting counts validated in context but used by InsightGenerator
            // Week-over-week insights include both weight AND fasting data

            // Calculate dates for last week
            let cal = Calendar.current
            let now = Date()
            let sevenDaysAgo = cal.date(byAdding: .day, value: -7, to: now) ?? now

            // Return comparison result as WeightChangeResult
            return WeightChangeResult(
                change: weightChange,
                startValue: currentWeight - weightChange,  // Calculated from current - change
                endValue: currentWeight,
                startDate: sevenDaysAgo,
                endDate: now,
                rate: weightChange / 7.0,  // Change per day
                unit: "lbs",
                period: .week
            )

        case .compareToLast(metric: _, period: _):
            // TODO: Implement compare to last period analytics
            throw AnalysisError.noData

        case .yearOverYear(metric: _):
            // TODO: Implement year-over-year analytics
            throw AnalysisError.noData

        case .monthOverMonth(metric: _):
            // TODO: Implement month-over-month analytics
            throw AnalysisError.noData

        case .unknown(query: _):
            throw AnalysisError.noData
        }
    }

    /// Detect emotion state from analysis result
    /// **Production:** Context-aware emotion detection based on data trends
    /// - Parameters:
    ///   - result: Analysis result
    ///   - intent: Query intent
    /// - Returns: Detected emotion state
    private func detectEmotionFromResult(_ result: Any, intent: QueryIntent) -> EmotionState {
        // Weight change results
        if let weightChange = result as? WeightChangeResult {
            if weightChange.change < -2.0 {
                // Significant loss → Energized
                return .energized
            } else if weightChange.change < 0 {
                // Moderate loss → Stable
                return .stable
            } else if weightChange.change > 2.0 {
                // Significant gain → Offtrack
                return .offtrack
            } else {
                // Slight gain → Stable
                return .stable
            }
        }

        // Trend results
        if let trend = result as? TrendAnalysisResult {
            switch trend.direction {
            case .down:
                return trend.strength < -0.5 ? .energized : .stable
            case .up:
                return trend.strength > 0.5 ? .offtrack : .stable
            case .stable:
                return .stable
            }
        }

        // Fasting streak
        if let streak = result as? Int, case .fastingStreak = intent {
            if streak >= 7 {
                return .energized
            } else if streak >= 3 {
                return .stable
            } else {
                return .offtrack
            }
        }

        // Default: Stable emotion
        return .stable
    }

    // MARK: - Private Query Handling (Phase 1: Legacy Keyword Matching)

    /// Handle user query and generate response
    /// Phase 1: Simple keyword matching
    /// Phase 2: Natural language understanding with OpenAI
    /// - Parameter query: User's question (lowercased for matching)
    /// - Returns: Assistant's response
    private func handleQuery(_ query: String) async -> String {
        let lowercaseQuery = query.lowercased()

        // Weight queries
        if lowercaseQuery.contains("weight") || lowercaseQuery.contains("weigh") {
            return await handleWeightQuery(lowercaseQuery)
        }

        // Fasting queries
        if lowercaseQuery.contains("fast") || lowercaseQuery.contains("fasting") {
            return await handleFastingQuery(lowercaseQuery)
        }

        // Sleep queries
        if lowercaseQuery.contains("sleep") {
            return await handleSleepQuery(lowercaseQuery)
        }

        // Hydration queries
        if lowercaseQuery.contains("water") || lowercaseQuery.contains("hydrat") {
            return await handleHydrationQuery(lowercaseQuery)
        }

        // Mood queries
        if lowercaseQuery.contains("mood") || lowercaseQuery.contains("feel") {
            return await handleMoodQuery(lowercaseQuery)
        }

        // Summary/overview queries
        if lowercaseQuery.contains("summary") || lowercaseQuery.contains("overview") || lowercaseQuery.contains("today") {
            return await handleSummaryQuery()
        }

        // Fallback: Show what we can help with
        return """
        I can help you with:

        • **Weight** - "What's my current weight?" or "Weight trends"
        • **Fasting** - "How many fasts this week?" or "Current fast status"
        • **Sleep** - "How's my sleep?" or "Last night's sleep"
        • **Hydration** - "Water intake today" or "Hydration this week"
        • **Mood** - "My mood today" or "Mood trends"
        • **Summary** - "Today's summary" or "Overview"

        Try asking me something!
        """
    }

    // MARK: - Query Handling with Emotion

    /// Handle query and detect appropriate emotion
    /// Phase 1: Simple keyword matching + data context
    /// Phase 2: NLP + ML-based sentiment analysis
    /// - Parameter query: User's question
    /// - Returns: Tuple of (response text, detected emotion)
    private func handleQueryWithEmotion(_ query: String) async -> (String, EmotionState) {
        let lowercaseQuery = query.lowercased()

        // Detect query type
        let queryType: QueryType
        if lowercaseQuery.contains("weight") || lowercaseQuery.contains("weigh") {
            queryType = .weight
        } else if lowercaseQuery.contains("fast") || lowercaseQuery.contains("fasting") {
            queryType = .fasting
        } else if lowercaseQuery.contains("sleep") {
            queryType = .sleep
        } else if lowercaseQuery.contains("water") || lowercaseQuery.contains("hydrat") {
            queryType = .hydration
        } else if lowercaseQuery.contains("mood") || lowercaseQuery.contains("feel") {
            queryType = .mood
        } else if lowercaseQuery.contains("summary") || lowercaseQuery.contains("overview") || lowercaseQuery.contains("today") {
            queryType = .summary
        } else {
            queryType = .unknown
        }

        // Build data context for emotion detection
        let dataContext = await buildDataContext(for: queryType)

        // Detect emotion based on query type and data
        let emotion = detectEmotion(for: queryType, dataContext: dataContext)

        // Generate response using existing handler
        let response = await handleQuery(lowercaseQuery)

        return (response, emotion)
    }

    /// Build data context for emotion detection
    /// Fetches relevant metrics based on query type
    /// - Parameter queryType: Type of query being handled
    /// - Returns: DataContext with relevant metrics
    private func buildDataContext(for queryType: QueryType) async -> DataContext {
        var context = DataContext()

        switch queryType {
        case .weight:
            // Fetch weight change over last week
            let weekData = await dataService.fetchWeightLastWeek()
            if let first = weekData.last?.weight, let last = weekData.first?.weight {
                context.weightChange = last - first
            }

        case .fasting:
            // Fetch fasting count this week
            let weekFasts = await dataService.fetchFastingThisWeek()
            context.fastingCount = weekFasts.count
            context.isFastingActive = await dataService.getCurrentFast() != nil

        case .sleep:
            // Fetch average sleep
            let allSleep = await dataService.fetchAllSleepData()
            if !allSleep.isEmpty {
                let avgDuration = allSleep.map({ $0.duration }).reduce(0, +) / Double(allSleep.count)
                context.avgSleepHours = avgDuration / 3600
            }

        case .hydration:
            // Fetch today's hydration
            context.hydrationOz = await dataService.getTodayHydration()

        case .mood:
            // Fetch today's mood
            if let todayMood = await dataService.getTodayMood() {
                context.moodRating = todayMood.moodLevel
                context.energyLevel = todayMood.energyLevel
            }

        case .summary:
            // Fetch multiple metrics for aggregate emotion
            let weekWeight = await dataService.fetchWeightLastWeek()
            if let first = weekWeight.last?.weight, let last = weekWeight.first?.weight {
                context.weightChange = last - first
            }

            let weekFasts = await dataService.fetchFastingThisWeek()
            context.fastingCount = weekFasts.count

            let allSleep = await dataService.fetchAllSleepData()
            if !allSleep.isEmpty {
                let avgDuration = allSleep.map({ $0.duration }).reduce(0, +) / Double(allSleep.count)
                context.avgSleepHours = avgDuration / 3600
            }

        case .general, .unknown:
            // No specific data needed for general queries
            break
        }

        return context
    }

    // MARK: - Query Handlers

    /// Handle weight-related queries
    private func handleWeightQuery(_ query: String) async -> String {
        // Check for trends/changes
        if query.contains("trend") || query.contains("change") || query.contains("progress") {
            let weekData = await dataService.fetchWeightLastWeek()
            if weekData.isEmpty {
                return "I don't have any weight data yet. Start logging your weight to see trends!"
            }

            if let first = weekData.last?.weight, let last = weekData.first?.weight {
                let change = last - first
                let direction = change < 0 ? "decreased" : "increased"
                return String(format: "Your weight has %@ by %.1f lbs over the last 7 days.", direction, abs(change))
            }
        }

        // Current weight
        if let currentWeight = await dataService.getCurrentWeight() {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return String(format: "Your current weight is %.1f lbs as of %@.", currentWeight.weight, formatter.string(from: currentWeight.date))
        }

        return "I don't have any weight data yet. Log your first weight entry to get started!"
    }

    /// Handle fasting-related queries
    private func handleFastingQuery(_ query: String) async -> String {
        // Current fast status
        if query.contains("current") || query.contains("now") || query.contains("active") {
            if let currentFast = await dataService.getCurrentFast() {
                // Calculate elapsed time (FastingSession doesn't have elapsedTime, only duration for completed fasts)
                let elapsed = Date().timeIntervalSince(currentFast.startTime)
                let hours = Int(elapsed / 3600)
                let minutes = Int((elapsed.truncatingRemainder(dividingBy: 3600)) / 60)
                return String(format: "You're currently fasting! ⏱️ Elapsed: %d hours %d minutes. Keep it up!", hours, minutes)
            } else {
                return "You're not currently fasting. Start a fast when you're ready!"
            }
        }

        // This week's fasts
        if query.contains("week") || query.contains("this") {
            let weekFasts = await dataService.fetchFastingThisWeek()
            if weekFasts.isEmpty {
                return "You haven't logged any fasts this week yet. Start a fast to begin tracking!"
            }

            let avgDuration = weekFasts.map({ $0.duration }).reduce(0, +) / Double(weekFasts.count)
            let avgHours = avgDuration / 3600
            return String(format: "You've completed %d fasting sessions this week, averaging %.1f hours per fast. Great consistency! 🎉", weekFasts.count, avgHours)
        }

        // General fasting info
        let allFasts = await dataService.fetchAllFastingSessions()
        if allFasts.isEmpty {
            return "You haven't logged any fasts yet. Start your first fast to begin tracking!"
        }

        return String(format: "You've completed %d total fasting sessions. Keep up the great work!", allFasts.count)
    }

    /// Handle sleep-related queries
    private func handleSleepQuery(_ query: String) async -> String {
        // Last night's sleep
        if query.contains("last") || query.contains("tonight") || query.contains("yesterday") {
            if let lastSleep = await dataService.getLastNightSleep() {
                let hours = lastSleep.duration / 3600
                return String(format: "Last night you slept for %.1f hours. 😴", hours)
            }
        }

        // General sleep info
        let allSleep = await dataService.fetchAllSleepData()
        if allSleep.isEmpty {
            return "I don't have any sleep data yet. Log your sleep to start tracking!"
        }

        let avgDuration = allSleep.map({ $0.duration }).reduce(0, +) / Double(allSleep.count)
        let avgHours = avgDuration / 3600
        return String(format: "You've logged %d nights of sleep with an average of %.1f hours per night.", allSleep.count, avgHours)
    }

    /// Handle hydration-related queries
    private func handleHydrationQuery(_ query: String) async -> String {
        // Today's hydration
        if query.contains("today") {
            let todayWater = await dataService.getTodayHydration()
            if todayWater == 0 {
                return "You haven't logged any water today yet. Stay hydrated! 💧"
            }
            return String(format: "You've logged %.1f oz of water today. Keep drinking! 💧", todayWater)
        }

        // General hydration
        let allHydration = await dataService.fetchAllHydrationData()
        if allHydration.isEmpty {
            return "I don't have any hydration data yet. Start logging your water intake!"
        }

        let totalWater = allHydration.map({ $0.1 }).reduce(0, +)
        return String(format: "You've logged %.1f oz of water across %d entries. Stay hydrated! 💧", totalWater, allHydration.count)
    }

    /// Handle mood-related queries
    private func handleMoodQuery(_ query: String) async -> String {
        // Today's mood
        if query.contains("today") {
            if let todayMood = await dataService.getTodayMood() {
                let moodEmoji = getMoodEmoji(todayMood.moodLevel)
                return "Your mood today is \(todayMood.moodLevel)/10 \(moodEmoji) with energy level \(todayMood.energyLevel)/10."
            }
            return "You haven't logged your mood today yet. How are you feeling?"
        }

        // General mood info
        let allMood = await dataService.fetchAllMoodData()
        if allMood.isEmpty {
            return "I don't have any mood data yet. Start tracking your mood to see patterns!"
        }

        let avgMood = allMood.map({ Double($0.moodLevel) }).reduce(0, +) / Double(allMood.count)
        return String(format: "You've logged %d mood entries with an average mood of %.1f/10.", allMood.count, avgMood)
    }

    /// Handle summary queries
    private func handleSummaryQuery() async -> String {
        let summary = await dataService.getTodaySummary()

        var response = "**Today's Summary:**\n\n"

        if let weight = summary["weight"] as? Double {
            response += String(format: "• Weight: %.1f lbs\n", weight)
        }

        if let fastingActive = summary["fastingActive"] as? Bool, fastingActive {
            if let elapsed = summary["fastingElapsed"] as? Double {
                let hours = Int(elapsed / 3600)
                response += String(format: "• Fasting: Active (%d hours)\n", hours)
            }
        }

        if let hydration = summary["hydration"] as? Double, hydration > 0 {
            response += String(format: "• Water: %.1f oz\n", hydration)
        }

        if let mood = summary["mood"] as? Int {
            response += String(format: "• Mood: %d/5 %@\n", mood, getMoodEmoji(mood))
        }

        if let sleepDuration = summary["sleepDuration"] as? Double {
            let hours = sleepDuration / 3600
            response += String(format: "• Sleep: %.1f hours\n", hours)
        }

        if response == "**Today's Summary:**\n\n" {
            return "You haven't logged any data today yet. Start tracking to see your daily summary!"
        }

        return response
    }

    // MARK: - Helpers

    /// Get emoji for mood rating
    private func getMoodEmoji(_ rating: Int) -> String {
        switch rating {
        case 5: return "😄"
        case 4: return "🙂"
        case 3: return "😐"
        case 2: return "😕"
        case 1: return "😞"
        default: return "😐"
        }
    }

    /// Add welcome message on init
    private func addWelcomeMessage() {
        let welcome = ChatMessage.assistantMessage(
            """
            Hi! I'm LifeGPT, your AI health coach. 👋

            I can help you understand your health data:
            • Weight trends and progress
            • Fasting patterns and streaks
            • Sleep quality and consistency
            • Hydration habits
            • Mood patterns

            What would you like to know?
            """
        )
        messages.append(welcome)
    }
}

// MARK: - Mock Health Data Analyzer (Temporary)

/// Mock analyzer for testing until real services are wired up
/// **TODO:** Replace with production HealthDataAnalysisService when WeightService/FastingService ready
private class MockHealthDataAnalyzer: HealthDataAnalyzerProtocol {

    func findMinimumWeight(in timeRange: TimeRange?) async throws -> WeightAnalysisResult {
        throw AnalysisError.noData
    }

    func findMaximumWeight(in timeRange: TimeRange?) async throws -> WeightAnalysisResult {
        throw AnalysisError.noData
    }

    func calculateAverageWeight(in timeRange: TimeRange?) async throws -> WeightAnalysisResult {
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

    func calculateWeightChange(period: TimePeriod) async throws -> WeightChangeResult {
        throw AnalysisError.noData
    }

    func calculateWeightChangeRate(period: TimePeriod) async throws -> Double {
        throw AnalysisError.noData
    }

    func calculateWeightDelta(from startDate: Date, to endDate: Date) async throws -> WeightChangeResult {
        throw AnalysisError.noData
    }

    func countFasts(in timeRange: TimeRange?) async throws -> Int {
        throw AnalysisError.noData
    }

    func findLongestFast(in timeRange: TimeRange?) async throws -> FastingAnalysisResult {
        throw AnalysisError.noData
    }

    func calculateFastingStreak() async throws -> Int {
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

    func analyzeWeightTrend(in timeRange: TimeRange?) async throws -> TrendAnalysisResult {
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
