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

    /// Logger for debugging (Apple standard)
    private let logger = Logger(subsystem: "com.fastlife.FastingTracker", category: "LifeGPT")

    // MARK: - Initialization

    /// Initialize with data service dependency
    /// Following Fast LIFe's dependency injection pattern
    /// - Parameter dataService: Service for fetching unified health data
    init(dataService: HealthDataAggregator) {
        self.dataService = dataService

        // Add welcome message on init
        addWelcomeMessage()
    }

    /// Pre-load HealthKit data on first launch to prevent freeze during first query
    /// **First Launch UX:** Shows loading overlay while building InsightContext
    /// **Industry Pattern:** Whoop, Oura, Levels all pre-fetch data on app open
    func preloadHealthData() async {
        // Check if this is first launch
        let hasCompletedFirstLoad = UserDefaults.standard.bool(forKey: "hasCompletedFirstInsightLoad")

        guard !hasCompletedFirstLoad else {
            return // Already loaded, skip
        }

        // Show loading overlay
        isFirstLaunchLoading = true

        // CRITICAL: Give SwiftUI time to render the overlay before blocking with HealthKit queries
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay

        // Pre-fetch common health data (simulates .summary query to warm cache)
        _ = await buildDataContext(for: .summary)

        // Mark as complete
        UserDefaults.standard.set(true, forKey: "hasCompletedFirstInsightLoad")

        // Dismiss loading overlay
        isFirstLaunchLoading = false
    }

    // MARK: - Public API

    /// Send user's query and get response
    /// **Phase 6:** Now uses hybrid routing (rule-based → LLM)
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

            // Phase 6: Execute hybrid query (rule-based → LLM)
            let (response, emotion) = await executeHybridQuery(trimmedQuery)

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

    // MARK: - Private Query Handling

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

    // MARK: - Intelligence Context Building (Phase 4B)

    /// Build comprehensive insight context from all available health data
    /// **Industry Pattern:** Whoop, Oura, Levels batch-fetch all data upfront
    /// **Performance:** Cached for 30s via PerformanceTokens.insightContextCacheTTL
    /// **Phase 4B:** Single source of truth for intelligence layers
    /// - Returns: InsightContext with goal, trends, correlations, streaks
    private func buildInsightContext() async -> InsightContext {
        // Check cache first (30s TTL)
        let cacheKey = "insightContext"
        if let cached: InsightContext = await QueryCache.shared.get(forKey: cacheKey) {
            logger.debug("⚡ InsightContext cache hit (TTL: \(PerformanceTokens.insightContextCacheTTL)s)")
            return cached
        }

        logger.debug("🔄 InsightContext cache miss, building fresh context...")

        // Goal data (from AppSettings - TODO: Add weight goal to AppSettings)
        // For now, using placeholder - will integrate with AppSettings in polish phase
        let weightGoal: Double? = nil  // TODO: Get from AppSettings.shared.weightGoal

        // Current weight
        let currentWeight = await dataService.getCurrentWeight()

        // Start weight (first entry ever)
        let allWeightData = await dataService.fetchAllWeightData()
        let startWeight = allWeightData.first

        // Week-over-week weight comparison (CRITICAL for insights)
        let thisWeekWeight = await dataService.fetchWeightLastWeek()
        let lastWeekStart = Date().addingTimeInterval(-14 * 86400)  // 2 weeks ago
        let lastWeekEnd = Date().addingTimeInterval(-7 * 86400)      // 1 week ago
        let lastWeekWeight = await dataService.fetchWeightData(from: lastWeekStart, to: lastWeekEnd)

        // Calculate week-over-week weight change
        let thisWeekAvg = thisWeekWeight.isEmpty ? 0 : thisWeekWeight.map({ $0.weight }).reduce(0, +) / Double(thisWeekWeight.count)
        let lastWeekAvg = lastWeekWeight.isEmpty ? 0 : lastWeekWeight.map({ $0.weight }).reduce(0, +) / Double(lastWeekWeight.count)
        let weightChangeWeek = thisWeekWeight.isEmpty || lastWeekWeight.isEmpty ? nil : (thisWeekAvg - lastWeekAvg)

        // Fasting correlation data (CRITICAL for multi-metric insights)
        let fastingThisWeek = await dataService.fetchFastingThisWeek()
        let fastingLastWeek = await dataService.fetchFastingSessions(from: lastWeekStart, to: lastWeekEnd)

        // Fasting streaks (motivational context)
        let currentStreak = calculateCurrentStreak(fastingThisWeek)
        let longestStreak = calculateLongestStreak(allWeightData.count)  // Placeholder for now

        // Build comprehensive context
        let context = InsightContext(
            weightGoal: weightGoal,
            currentWeight: currentWeight?.weight,
            startWeight: startWeight?.weight,
            weightChangeLast7Days: weightChangeWeek,  // CRITICAL FIX: Use correct parameter name
            fastingCountThisWeek: fastingThisWeek.count,
            fastingCountLastWeek: fastingLastWeek.count,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )

        // Cache for 30s (avoid redundant queries)
        await QueryCache.shared.set(context, forKey: cacheKey, ttl: PerformanceTokens.insightContextCacheTTL)
        logger.debug("💾 InsightContext cached (TTL: \(PerformanceTokens.insightContextCacheTTL)s)")

        return context
    }

    /// Calculate current fasting streak (consecutive fasts this week)
    /// **Industry Pattern:** Duolingo, Peloton streak gamification
    /// - Parameter fastingSessions: This week's fasting sessions
    /// - Returns: Current streak count
    private func calculateCurrentStreak(_ fastingSessions: [FastingSession]) -> Int {
        // Simple implementation: count completed fasts this week
        // Future enhancement: Track consecutive days
        return fastingSessions.count
    }

    /// Calculate longest fasting streak ever
    /// **Industry Pattern:** Snapchat, Duolingo longest streak
    /// - Parameter totalEntries: Total weight entries (placeholder)
    /// - Returns: Longest streak count
    private func calculateLongestStreak(_ totalEntries: Int) -> Int {
        // Placeholder: Return 0 for now
        // Future enhancement: Query historical fasting data for true longest streak
        return 0
    }

    // MARK: - Intelligent Query Execution (Phase 4B)

    /// Execute full intelligence pipeline for query
    /// **Phase 4B:** Wires up ALL intelligence layers
    /// **Industry Pattern:** Whoop Recovery Algorithm, Oura Readiness Pipeline
    /// **Flow:** Context → Insights → Recommendations → Emotion → Response → Conversation Tracking
    /// - Parameter query: User's natural language question
    /// - Returns: Tuple of (enhanced response, goal-aware emotion)
    private func executeIntelligentQuery(_ query: String) async -> (String, EmotionState) {
        logger.info("🚀 Executing intelligent query pipeline for: \(query, privacy: .public)")

        // Step 1: Build comprehensive insight context (cached 30s)
        let context = await buildInsightContext()
        logger.debug("✅ InsightContext built (goal: \(context.weightGoal?.description ?? "none", privacy: .public))")

        // Step 2: Classify query intent
        let intent = QueryClassifier.shared.classify(query)
        logger.debug("✅ Query classified as: \(String(describing: intent), privacy: .public)")

        // Step 3: Generate insights (multi-metric correlations)
        let insights = await InsightGenerator.shared.generateInsights(context: context)
        logger.debug("✅ Generated \(insights.insights.count) insights")

        // Step 4: Generate recommendations (actionable advice)
        let recommendations = await InsightGenerator.shared.generateRecommendations(context: context)
        logger.debug("✅ Generated \(recommendations.count) recommendations")

        // Step 5: Detect goal-aware emotion
        let emotionContext = EmotionContext(
            weightGoal: context.weightGoal,
            currentWeight: context.currentWeight,
            weightTrend: context.weightChangeLast7Days,
            fastingCountThisWeek: context.fastingCountThisWeek,
            fastingCountLastWeek: context.fastingCountLastWeek
        )
        let emotion = EmotionEngine.shared.detectEmotion(context: emotionContext)
        logger.debug("✅ Emotion detected: \(emotion.rawValue, privacy: .public)")

        // Step 6: Convert InsightContext to intent-specific result object
        // CRITICAL FIX: ResponseGenerator expects WeightAnalysisResult, not InsightContext
        let result = await convertContextToResult(context: context, intent: intent)
        logger.debug("✅ Result object prepared for intent: \(String(describing: intent), privacy: .public)")

        // Step 7: Generate enhanced response (Phase 3D template system)
        let response = ResponseGenerator.shared.generateEnhancedResponse(
            for: intent,
            result: result,  // Pass properly typed result (WeightAnalysisResult, etc.)
            emotion: emotion,
            userPreferences: .default,
            insights: insights,
            recommendations: recommendations,
            conversationContext: nil  // TODO: Wire ConversationManager in Hour 3C
        )
        logger.info("✅ Enhanced response generated (\(response.count) chars)")

        // Step 8: Track conversation (for multi-turn dialogue)
        // TODO: Add conversation tracking with ConversationManager
        logger.debug("⏭️ Conversation tracking (TODO: Phase 4B Hour 3)")

        return (response, emotion)
    }

    // MARK: - Hybrid Query Routing (Phase 6: LLM Integration)

    /// Execute query with hybrid routing (rule-based → LLM)
    /// **Phase 7 Architecture:** LLM-primary intelligence with rule-based safety net
    /// **Industry Pattern:** Whoop Coach, Oura Advisor (trust LLM with system prompt guardrails)
    /// - Parameter query: User's natural language question
    /// - Returns: Tuple of (response, emotion)
    private func executeHybridQuery(_ query: String) async -> (String, EmotionState) {

        logger.info("🔀 PHASE 7 HYBRID ROUTING START - Query: \(query, privacy: .public)")

        // Step 1: Classify query intent
        let intent = QueryClassifier.shared.classify(query)
        logger.info("📊 QueryClassifier returned - Intent: \(String(describing: intent), privacy: .public), Confidence: \(intent.confidence, privacy: .public)")

        // Step 2: EXTREMELY high confidence (>0.95) → use rule-based system (fast, free, offline)
        // Phase 7: Lowered threshold from 0.8 → 0.95 (ONLY exact matches like "What's my weight?")
        // Anything below 0.95 = complex/nuanced query → route to LLM for intelligent analysis
        if intent.confidence > 0.95 {
            logger.info("✅ ROUTING TO RULE-BASED - Confidence \(intent.confidence, privacy: .public) > 0.95 threshold")
            return await executeIntelligentQuery(query) // Existing Phase 4B pipeline
        }

        logger.info("🧠 Confidence \(intent.confidence, privacy: .public) ≤ 0.95 - Should route to LLM")

        // Step 3: Low confidence or complex query → check network connectivity
        let isConnected = NetworkMonitor.shared.isConnected
        logger.info("📡 Network status: \(isConnected ? "CONNECTED" : "OFFLINE", privacy: .public)")

        guard isConnected else {
            logger.warning("⚠️ NO INTERNET - Falling back to rule-based despite low confidence")
            return await executeOfflineFallback(query)
        }

        // Step 4: Route to LLM for complex/nuanced/conversational queries
        // Phase 7: LLM handles 70%+ of queries with system prompt guardrails
        logger.info("🚀 ROUTING TO LLM - Confidence: \(intent.confidence, privacy: .public), Network: CONNECTED")
        return await executeLLMQuery(query)
    }

    /// Execute LLM query (complex/nuanced queries only)
    /// **Phase 7:** Now uses AInsteinSystemPrompt with comprehensive guardrails
    /// **Cost:** ~$0.01-0.03 per query (GPT-4o-mini)
    /// **Performance:** ~1-2s response time
    /// - Parameter query: User's question
    /// - Returns: Tuple of (LLM response with AInstein personality, emotion)
    private func executeLLMQuery(_ query: String) async -> (String, EmotionState) {

        logger.info("🤖 ===== EXECUTING LLM QUERY START =====")
        logger.info("🤖 Query: \(query, privacy: .public)")

        do {
            // Build health context from existing intelligence system
            logger.info("🤖 Step 1: Building InsightContext...")
            let insightContext = await buildInsightContext()
            logger.info("🤖 Step 1 COMPLETE: InsightContext built")

            // Phase 7: Format context using AInsteinSystemPrompt
            logger.info("🤖 Step 2: Formatting context with AInsteinSystemPrompt...")
            let formattedContext = AInsteinSystemPrompt.formatContext(from: insightContext)
            logger.info("🤖 Step 2 COMPLETE: Context formatted (\(formattedContext.count) chars)")
            logger.debug("📊 Formatted context: \(formattedContext, privacy: .public)")

            // Phase 7: Generate complete system prompt with guardrails
            logger.info("🤖 Step 3: Generating Phase 7 system prompt...")
            let systemPrompt = AInsteinSystemPrompt.generatePrompt(with: formattedContext)
            logger.info("🤖 Step 3 COMPLETE: System prompt generated (\(systemPrompt.count) chars)")

            // Call OpenAI API with Phase 7 system prompt
            logger.info("🤖 Step 4: Calling OpenAI API...")
            let llmContext = convertToLLMContext(insightContext)
            let response = try await OpenAIService.shared.generateResponse(
                query: query,
                context: llmContext,
                conversationHistory: messages.suffix(5).map { $0 }, // Last 5 messages for context
                customSystemPrompt: systemPrompt // Phase 7: Use AInsteinSystemPrompt with guardrails
            )
            logger.info("🤖 Step 4 COMPLETE: OpenAI returned response (\(response.count) chars)")
            logger.debug("📝 Raw OpenAI response: \(response, privacy: .public)")

            // Phase 7: Validate response for hallucinations and tone enforcement
            logger.info("🤖 Step 5: Validating response with ResponseValidator...")
            let validatedResponse = ResponseValidator.validate(response, against: insightContext)
            logger.info("🤖 Step 5 COMPLETE: Response validated (\(validatedResponse.count) chars)")

            // Apply AInstein personality filter (max 2 sentences, luxury empathy, signature)
            logger.info("🤖 Step 6: Applying AInstein personality filter...")
            let filteredResponse = AInsteinPersonality.shared.transform(validatedResponse)
            logger.info("🤖 Step 6 COMPLETE: Personality filter applied (\(filteredResponse.count) chars)")
            logger.debug("📝 Final filtered response: \(filteredResponse, privacy: .public)")

            // Detect emotion from response sentiment (simple heuristic for now)
            let emotion = detectEmotionFromLLMResponse(filteredResponse)

            logger.info("✅ ===== LLM QUERY COMPLETE - Emotion: \(emotion.rawValue, privacy: .public) =====")

            return (filteredResponse, emotion)

        } catch {
            logger.error("❌ ===== LLM QUERY FAILED: \(error.localizedDescription, privacy: .public) =====")
            logger.error("❌ Error type: \(String(describing: type(of: error)), privacy: .public)")

            // Fallback to rule-based on LLM error
            logger.info("⚠️ Falling back to rule-based system due to LLM error")
            return await executeIntelligentQuery(query)
        }
    }

    /// Offline fallback (no internet connection)
    /// **UX:** Provide rule-based response + notice about offline status
    /// - Parameter query: User's question
    /// - Returns: Tuple of (rule-based response + notice, emotion)
    private func executeOfflineFallback(_ query: String) async -> (String, EmotionState) {

        logger.info("📴 Executing offline fallback")

        // Execute rule-based intelligence system
        let (response, emotion) = await executeIntelligentQuery(query)

        // Append offline notice
        let offlineNotice = "\n\n(You're offline. Connect to internet for more detailed AI insights.)"

        return (response + offlineNotice, emotion)
    }

    /// Convert InsightContext → HealthContextForLLM (privacy-protected aggregated metrics)
    /// **Privacy:** Send aggregated metrics only, never raw HealthKit samples
    /// - Parameter context: Full insight context from intelligence system
    /// - Returns: Privacy-protected LLM context
    private func convertToLLMContext(_ context: InsightContext) -> HealthContextForLLM {
        return HealthContextForLLM(
            currentWeight: context.currentWeight ?? 0.0,
            weightTrend: determineWeightTrend(context.weightChangeLast7Days),  // FIX: Use correct property name
            weightGoal: context.weightGoal,
            fastingFrequency: context.fastingCountThisWeek ?? 0,
            sleepQuality: "unknown", // TODO: Wire up sleep quality from context
            hydrationStatus: "unknown", // TODO: Wire up hydration from context
            moodStatus: "unknown", // TODO: Wire up mood from context
            lastFastDate: nil, // TODO: Wire up last fast date
            weightChange30Days: context.weightChangeLast7Days ?? 0.0,  // FIX: Use correct property name
            daysToGoal: nil // TODO: Calculate days to goal
        )
    }

    /// Determine weight trend from weight change value
    /// - Parameter weightChange: Weight change over period (negative = loss, positive = gain)
    /// - Returns: Trend string ("up", "down", "stable")
    private func determineWeightTrend(_ weightChange: Double?) -> String {
        guard let change = weightChange else { return "stable" }

        if change < -0.5 { return "down" }
        if change > 0.5 { return "up" }
        return "stable"
    }

    /// Detect emotion from LLM response sentiment (simple heuristic)
    /// **Future:** Use sentiment analysis model
    /// - Parameter response: LLM-generated response
    /// - Returns: Detected emotion state
    private func detectEmotionFromLLMResponse(_ response: String) -> EmotionState {
        let lowercased = response.lowercased()

        // Positive sentiment indicators → ES-5: energized
        if lowercased.contains("great") || lowercased.contains("excellent") || lowercased.contains("amazing") {
            return .energized
        }

        // Progress sentiment indicators → ES-5: energized
        if lowercased.contains("progress") || lowercased.contains("improving") || lowercased.contains("on track") {
            return .energized
        }

        // Encouraging sentiment indicators → ES-5: energized
        if lowercased.contains("keep it up") || lowercased.contains("maintain") || lowercased.contains("consistent") {
            return .energized
        }

        // Default: stable (neutral in ES-5)
        return .stable
    }

    /// Convert InsightContext to intent-specific result object
    /// **CRITICAL:** ResponseGenerator expects strongly-typed result objects (WeightAnalysisResult, etc.)
    /// - Parameters:
    ///   - context: Comprehensive insight context with all health data
    ///   - intent: Classified query intent
    /// - Returns: Properly typed result object for the intent
    private func convertContextToResult(context: InsightContext, intent: QueryIntent) async -> Any {
        switch intent {
        case .currentWeight:
            // CRITICAL FIX: Fetch current weight entry (with date) from dataService
            // This ensures we get BOTH value AND date for proper formatting
            if let currentWeightEntry = await dataService.getCurrentWeight() {
                logger.debug("✅ getCurrentWeight() returned weight: \(currentWeightEntry.weight) lbs, date: \(currentWeightEntry.date, privacy: .public)")
                return WeightAnalysisResult(
                    value: currentWeightEntry.weight,
                    date: currentWeightEntry.date,
                    unit: "lbs",  // TODO: Get from UserPreferences
                    timeRange: nil,
                    metadata: nil
                )
            } else {
                // This should NOT happen if user has weight data
                logger.error("❌ getCurrentWeight() returned nil - user may have no weight data")
                // Fallback: Return 0 weight with today's date
                return WeightAnalysisResult(
                    value: 0,
                    date: Date(),
                    unit: "lbs",
                    timeRange: nil,
                    metadata: nil
                )
            }

        case .averageWeight, .minimumWeight, .maximumWeight:
            // Use context weight data (simple fallback)
            return WeightAnalysisResult(
                value: context.currentWeight ?? 0,
                date: Date(),
                unit: "lbs",
                timeRange: nil,
                metadata: nil
            )

        case .weightChange(let period):
            // Use week-over-week change from context
            let change = context.weightChangeLast7Days ?? 0  // FIX: Use correct property name
            let currentWeight = context.currentWeight ?? 0
            let startWeight = currentWeight - change
            let now = Date()
            let weekAgo = now.addingTimeInterval(-7 * 86400)

            return WeightChangeResult(
                change: change,
                startValue: startWeight,
                endValue: currentWeight,
                startDate: weekAgo,
                endDate: now,
                rate: change / 7.0,  // Change per day
                unit: "lbs",
                period: period
            )

        case .fastCount(let timeRange):
            // Use fasting count from context
            let count = timeRange == .thisWeek ? (context.fastingCountThisWeek ?? 0) : 0
            return count

        case .fastingStreak:
            // Use current streak from context
            return context.currentStreak ?? 0

        case .weekOverWeek, .monthOverMonth, .yearOverYear:
            // CRITICAL FIX: Comparison queries need full InsightContext for week-over-week templates
            // These intents require access to fastingCountThisWeek, fastingCountLastWeek, weightChangeLast7Days
            // ResponseGenerator.generateWeekOverWeekResponse() expects InsightContext, NOT WeightChangeResult
            logger.debug("🔍 Returning InsightContext for comparison intent: \(String(describing: intent), privacy: .public)")
            return context

        default:
            // Fallback: Return context itself for other intents
            return context
        }
    }

    // MARK: - Query Handling with Emotion (Phase 1 - Deprecated)

    /// Handle query and detect appropriate emotion
    /// **DEPRECATED:** Use executeIntelligentQuery() instead (Phase 4B)
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
