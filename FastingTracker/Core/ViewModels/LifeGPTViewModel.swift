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

            // Phase 4B: Execute intelligent query pipeline (replaces deprecated handleQueryWithEmotion)
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
            weightChangeWeek: weightChangeWeek,
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
            weightChangeWeek: context.weightChangeWeek,
            fastingCountThisWeek: context.fastingCountThisWeek,
            fastingCountLastWeek: context.fastingCountLastWeek
        )
        let emotion = EmotionEngine.shared.detectEmotion(context: emotionContext)
        logger.debug("✅ Emotion detected: \(emotion.rawValue, privacy: .public)")

        // Step 6: Generate enhanced response (Phase 3D template system)
        let response = ResponseGenerator.shared.generateEnhancedResponse(
            for: intent,
            result: context,  // Pass context as result (contains all health data)
            emotion: emotion,
            userPreferences: .default,
            insights: insights,
            recommendations: recommendations,
            conversationContext: nil  // TODO: Wire ConversationManager in Hour 3C
        )
        logger.info("✅ Enhanced response generated (\(response.count) chars)")

        // Step 7: Track conversation (for multi-turn dialogue)
        // TODO: Add conversation tracking with ConversationManager
        logger.debug("⏭️ Conversation tracking (TODO: Phase 4B Hour 3)")

        return (response, emotion)
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
