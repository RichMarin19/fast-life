//
// LifeGPTViewModel.swift
// FastingTracker
//
// Phase 8.2: Simplified LLM-First Architecture
// Industry Standard: WHOOP Coach, Oura Advisor, Levels Insights
//

import Foundation
import Combine
import os.log

// MARK: - LifeGPT ViewModel

/// ViewModel for LifeGPT chat interface
/// **Phase 8.2:** Simplified LLM-first architecture (50 lines of query logic)
/// **Architecture:** Query → RichHealthContext → OpenAI + Guardrails → Validate → Return
@MainActor
class LifeGPTViewModel: ObservableObject {

    // MARK: - Published State

    /// All messages in the chat (user + assistant)
    @Published var messages: [ChatMessage] = []

    /// Current user input text
    @Published var inputText: String = ""

    /// Whether assistant is processing a query (for loading indicator)
    @Published var isProcessing: Bool = false

    /// Whether first-launch loading is in progress
    @Published var isFirstLaunchLoading: Bool = false

    // MARK: - Dependencies

    private let dataService: HealthDataAggregator
    private let logger = Logger(subsystem: "com.fastlife.FastingTracker", category: "LifeGPT")

    // MARK: - Initialization

    init(dataService: HealthDataAggregator) {
        self.dataService = dataService
        addWelcomeMessage()
    }

    /// Pre-load HealthKit data on first launch
    func preloadHealthData() async {
        let hasCompletedFirstLoad = UserDefaults.standard.bool(forKey: "hasCompletedFirstInsightLoad")
        guard !hasCompletedFirstLoad else { return }

        isFirstLaunchLoading = true
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay

        // Pre-fetch data to warm cache
        _ = await buildRichHealthContext()

        UserDefaults.standard.set(true, forKey: "hasCompletedFirstInsightLoad")
        isFirstLaunchLoading = false
    }

    // MARK: - Public API

    /// Send user's query and get response
    /// **Phase 8.2:** Simplified LLM-first architecture
    func sendQuery(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        // Add user message
        messages.append(ChatMessage.userMessage(trimmedQuery))
        inputText = ""

        // Process query asynchronously
        Task {
            isProcessing = true
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s for smooth UX

            let (response, emotion) = await executeQuery(trimmedQuery)

            messages.append(ChatMessage.assistantMessage(response, emotion: emotion))
            isProcessing = false
        }
    }

    /// Clear all messages and reset chat
    func clearChat() {
        messages.removeAll()
        addWelcomeMessage()
    }

    // MARK: - Query Execution (Phase 8.2: Industry Standard)

    /// Execute query using LLM-first architecture
    /// **Architecture:** Query → RichHealthContext → OpenAI + Guardrails → Validate → Return
    /// **Matches:** WHOOP Coach, Oura Advisor, Levels Insights
    private func executeQuery(_ query: String) async -> (String, EmotionState) {
        logger.info("🚀 PHASE 8.2 LLM-FIRST - Query: \(query, privacy: .public)")

        // Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            logger.warning("📴 Offline - providing basic response")
            if let currentWeight = await dataService.getCurrentWeight() {
                return ("I need internet to analyze patterns. Your current weight is \(String(format: "%.1f", currentWeight.weight)) lbs", .stable)
            } else {
                return ("I need internet to analyze your health patterns.", .stable)
            }
        }

        do {
            // Build rich health context (cached 30s)
            logger.info("📊 Building RichHealthContext...")
            let richContext = await buildRichHealthContext()
            logger.info("✅ RichHealthContext built (\(richContext.totalWeightEntries ?? 0) weight entries)")

            // Format context
            let formattedContext = AInsteinSystemPrompt.formatContext(from: richContext)
            logger.info("📝 Context formatted (\(formattedContext.count) chars)")

            // DIAGNOSTIC: Log full formatted context for debugging
            logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logger.debug("📋 FORMATTED CONTEXT SENT TO LLM:")
            logger.debug("\(formattedContext, privacy: .public)")
            logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            // Generate system prompt with guardrails
            let systemPrompt = AInsteinSystemPrompt.generatePrompt(with: formattedContext)
            logger.info("🛡️ System prompt generated (\(systemPrompt.count) chars)")

            // Send to LLM
            logger.info("🤖 Calling OpenAI API...")
            logger.debug("🔹 User Query: \(query, privacy: .public)")
            let llmContext = convertRichContextToLLMContext(richContext)
            let response = try await OpenAIService.shared.generateResponse(
                query: query,
                context: llmContext,
                conversationHistory: messages.suffix(5).map { $0 },
                customSystemPrompt: systemPrompt
            )
            logger.info("✅ OpenAI response received (\(response.count) chars)")

            // DIAGNOSTIC: Log raw LLM response before validation
            logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logger.debug("🤖 RAW LLM RESPONSE (before validation):")
            logger.debug("\(response, privacy: .public)")
            logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            // Validate response (emoji filtering + signature enforcement)
            let validatedResponse = ResponseValidator.validateWithRichContext(response, against: richContext)
            logger.info("✅ Response validated (\(validatedResponse.count) chars)")

            // DIAGNOSTIC: Log validated response if different from raw
            if validatedResponse != response {
                logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                logger.debug("✨ VALIDATED RESPONSE (after validation):")
                logger.debug("\(validatedResponse, privacy: .public)")
                logger.debug("🔧 Validator changed: \(response.count - validatedResponse.count) chars")
                logger.debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            }

            // Detect emotion from response
            let emotion = detectEmotionFromLLMResponse(validatedResponse)
            logger.info("✅ Query complete - Emotion: \(emotion.rawValue, privacy: .public)")

            return (validatedResponse, emotion)

        } catch {
            // CRITICAL: Log full error details for diagnosis
            logger.error("❌ LLM query failed: \(error.localizedDescription, privacy: .public)")
            logger.error("❌ Error type: \(String(describing: type(of: error)), privacy: .public)")
            logger.error("❌ Full error: \(String(describing: error), privacy: .public)")

            // Log stack trace if available
            if let nsError = error as NSError? {
                logger.error("❌ NSError domain: \(nsError.domain, privacy: .public)")
                logger.error("❌ NSError code: \(nsError.code, privacy: .public)")
                logger.error("❌ NSError userInfo: \(nsError.userInfo, privacy: .public)")
            }

            // Fallback: Simple response with current weight
            if let currentWeight = await dataService.getCurrentWeight() {
                return ("I'm having trouble connecting. Your current weight is \(String(format: "%.1f", currentWeight.weight)) lbs", .stable)
            } else {
                return ("I'm having trouble connecting. Please try again.", .stable)
            }
        }
    }

    // MARK: - Context Building

    /// Build comprehensive RichHealthContext for AInstein LLM intelligence
    /// **Performance:** Cached for 30s to avoid redundant queries
    private func buildRichHealthContext() async -> RichHealthContext {
        // Check cache first (30s TTL)
        let cacheKey = "richHealthContext"
        if let cached: RichHealthContext = await QueryCache.shared.get(forKey: cacheKey) {
            logger.debug("⚡ RichHealthContext cache hit")
            return cached
        }

        logger.debug("🔄 RichHealthContext cache miss, building fresh context...")

        // Build comprehensive context from UnifiedHealthDataService
        let context = await dataService.buildRichHealthContext()
        logger.info("📦 RichHealthContext built with \(context.totalWeightEntries ?? 0) weight entries")

        // Cache for 30s
        await QueryCache.shared.set(context, forKey: cacheKey, ttl: PerformanceTokens.insightContextCacheTTL)
        logger.debug("💾 RichHealthContext cached")

        return context
    }

    // MARK: - Helper Methods

    /// Convert RichHealthContext → HealthContextForLLM (backward compatibility)
    private func convertRichContextToLLMContext(_ richContext: RichHealthContext) -> HealthContextForLLM {
        return HealthContextForLLM(
            currentWeight: richContext.currentWeight ?? 0.0,
            weightTrend: determineWeightTrendFromChange(richContext.weightChange7d),
            weightGoal: richContext.weightGoal,
            fastingFrequency: richContext.fastingCount7d ?? 0,
            sleepQuality: determineSleepQuality(richContext.avgSleep7d),
            hydrationStatus: determineHydrationStatus(richContext.avgHydration7d),
            moodStatus: determineMoodStatus(richContext.avgMood7d),
            lastFastDate: nil,
            weightChange30Days: richContext.weightChange30d ?? 0.0,
            daysToGoal: richContext.estimatedDaysToGoal
        )
    }

    /// Determine sleep quality from average sleep hours
    private func determineSleepQuality(_ avgSleepHours: Double?) -> String {
        guard let hours = avgSleepHours else { return "unknown" }
        if hours >= 7.5 { return "excellent" }
        if hours >= 6.5 { return "good" }
        if hours >= 5.5 { return "fair" }
        return "poor"
    }

    /// Determine hydration status from average daily oz
    private func determineHydrationStatus(_ avgHydrationOz: Double?) -> String {
        guard let oz = avgHydrationOz else { return "unknown" }
        if oz >= 64 { return "well-hydrated" }
        if oz >= 48 { return "adequate" }
        if oz >= 32 { return "low" }
        return "very low"
    }

    /// Determine mood status from average mood rating
    private func determineMoodStatus(_ avgMood: Double?) -> String {
        guard let mood = avgMood else { return "unknown" }
        if mood >= 4 { return "positive" }
        if mood >= 3 { return "neutral" }
        return "low"
    }

    /// Determine weight trend from weight change value
    private func determineWeightTrendFromChange(_ weightChange: Double?) -> String {
        guard let change = weightChange else { return "stable" }
        if change < -0.5 { return "down" }
        if change > 0.5 { return "up" }
        return "stable"
    }

    /// Detect emotion from LLM response sentiment (simple heuristic)
    private func detectEmotionFromLLMResponse(_ response: String) -> EmotionState {
        let lowercased = response.lowercased()

        // Positive sentiment indicators
        if lowercased.contains("great") || lowercased.contains("excellent") || lowercased.contains("amazing") {
            return .energized
        }

        // Progress sentiment indicators
        if lowercased.contains("progress") || lowercased.contains("improving") || lowercased.contains("on track") {
            return .energized
        }

        // Encouraging sentiment indicators
        if lowercased.contains("keep it up") || lowercased.contains("maintain") || lowercased.contains("consistent") {
            return .energized
        }

        // Default: stable (neutral)
        return .stable
    }

    /// Add welcome message on init
    private func addWelcomeMessage() {
        let welcome = ChatMessage.assistantMessage(
            """
            Hi! I'm AInstein, your AI health coach. 👋

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
