//
// OpenAIService.swift
// FastingTracker
//
// Created for Phase 6: LLM Intelligence Integration
// Industry Pattern: Whoop Coach, Oura Advisor, MyFitnessPal (all use GPT-4 API)
// Reference: docs/handoffs/HANDOFF.md - Phase 6 implementation plan
//

import Foundation
import os.log

/// OpenAI API service for AInstein intelligence
/// **Architecture:** Hybrid approach - rule-based first, LLM for complex queries
/// **Privacy:** Send aggregated metrics only, never raw HealthKit samples
/// **Cost:** GPT-4o-mini ($0.15/1M input, $0.60/1M output) = $1-3/month per user
class OpenAIService {

    // MARK: - Singleton

    static let shared = OpenAIService()
    private init() {}

    // MARK: - Properties

    private let apiKey: String = {
        // Load from Xcode Config (Bundle.main.infoDictionary)
        // **Setup:** Create Config.xcconfig with OPENAI_API_KEY = sk-...
        // **Security:** Config.xcconfig added to .gitignore (never committed)
        // **Phase 7:** Migrate to backend proxy for maximum security
        guard let key = Bundle.main.infoDictionary?["OpenAI_API_Key"] as? String,
              !key.isEmpty,
              key != "$(OPENAI_API_KEY)" else {
            // Fallback: Return empty string (will throw error on first API call)
            // This allows app to compile without Config.xcconfig during development
            return ""
        }
        return key
    }()

    private let model = "gpt-4o-mini" // Cost-optimized choice (90% cheaper than GPT-4)
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let maxTokens = 500 // Response length limit (balance quality vs cost)
    private let temperature = 0.7 // Balance between creativity and consistency

    private let logger = Logger(subsystem: "com.fastlife.FastingTracker", category: "OpenAI")

    // MARK: - Public API

    /// Generate LLM response for complex health query
    /// - Parameters:
    ///   - query: User's question
    ///   - context: Aggregated health data (privacy-protected)
    ///   - conversationHistory: Last 5 messages for context
    /// - Returns: AInstein's intelligent response
    func generateResponse(
        query: String,
        context: HealthContextForLLM,
        conversationHistory: [ChatMessage] = []
    ) async throws -> String {

        logger.info("Generating LLM response for query: \(query, privacy: .public)")

        // Build system prompt (AInstein personality + health coaching role)
        let systemPrompt = buildSystemPrompt()

        // Build user prompt (health context + query)
        let userPrompt = buildUserPrompt(query: query, context: context)

        // Build conversation messages
        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]

        // Add conversation history (last 5 messages for cost optimization)
        for message in conversationHistory.suffix(5) {
            messages.append([
                "role": message.isUser ? "user" : "assistant",
                "content": message.text
            ])
        }

        // Add current query
        messages.append(["role": "user", "content": userPrompt])

        // Make API request
        let response = try await callOpenAIAPI(messages: messages)

        logger.info("LLM response generated (\(response.count) chars)")

        return response
    }

    /// Test API connection (for debugging and settings verification)
    func testConnection() async throws -> String {
        let testContext = HealthContextForLLM(
            currentWeight: 179.7,
            weightTrend: "down",
            weightGoal: 175.0,
            fastingFrequency: 4,
            sleepQuality: "good",
            hydrationStatus: "on track",
            moodStatus: "positive",
            lastFastDate: "Oct 24, 2025",
            weightChange30Days: -2.3,
            daysToGoal: 45
        )

        return try await generateResponse(
            query: "What's my weight?",
            context: testContext
        )
    }

    // MARK: - Private Methods

    /// Build system prompt (AInstein personality + role)
    /// **Design:** Luxury empathy, max 2 sentences, reflective prompts, data-driven
    private func buildSystemPrompt() -> String {
        return """
        You are AInstein, an intelligent health coach for Fast LIFe wellness app.

        Your personality:
        - Luxury empathy (warm but not overly casual)
        - Max 2 sentences per response
        - Reflective prompts (ask questions to deepen user thinking)
        - Data-driven insights (reference specific metrics)

        Your role:
        - Analyze user's health patterns (weight, fasting, sleep, hydration, mood)
        - Provide personalized, actionable recommendations
        - Correlate multi-metric trends (e.g., sleep quality × weight loss)
        - Celebrate wins, provide constructive guidance on setbacks

        Response format:
        1. Direct answer (state fact first)
        2. Context (trend, comparison to goal)
        3. Insight (correlation, pattern)
        4. Recommendation (1 actionable step)

        Never use emojis except: ✨, 🧠, ⚡
        Always end with: "– AInstein."
        """
    }

    /// Build user prompt (health context + query)
    /// **Privacy:** Send aggregated metrics only, never raw HealthKit samples
    private func buildUserPrompt(query: String, context: HealthContextForLLM) -> String {
        return """
        User query: "\(query)"

        Health context (last 30 days):
        - Weight: \(context.currentWeight) lbs (trend: \(context.weightTrend))
        - Weight goal: \(context.weightGoal?.description ?? "not set") lbs
        - Fasting frequency: \(context.fastingFrequency) sessions/week
        - Sleep quality: \(context.sleepQuality)
        - Hydration: \(context.hydrationStatus)
        - Mood: \(context.moodStatus)

        Additional context:
        - Last fasting session: \(context.lastFastDate ?? "N/A")
        - Weight change (30 days): \(context.weightChange30Days) lbs
        - Days to goal: \(context.daysToGoal?.description ?? "N/A")
        """
    }

    /// Call OpenAI API
    /// **Error Handling:** Validates API key, HTTP status, response format
    private func callOpenAIAPI(messages: [[String: String]]) async throws -> String {

        // Validate API key
        guard !apiKey.isEmpty else {
            logger.error("OpenAI API key not configured")
            throw OpenAIError.missingAPIKey
        }

        // Build request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": maxTokens,
            "temperature": temperature
        ]

        // Create URL request
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 10 // 10s timeout

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            logger.error("OpenAI API error: HTTP \(httpResponse.statusCode)")
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }

        return content
    }
}

// MARK: - Health Context Model

/// Privacy-protected health context for LLM queries
/// **Privacy:** Send aggregated metrics only, never raw HealthKit samples
/// **HIPAA Compliance:** No PII, no raw health data, aggregated summaries only
struct HealthContextForLLM {
    let currentWeight: Double
    let weightTrend: String // "up", "down", "stable"
    let weightGoal: Double?
    let fastingFrequency: Int
    let sleepQuality: String // "excellent", "good", "fair", "poor"
    let hydrationStatus: String
    let moodStatus: String
    let lastFastDate: String?
    let weightChange30Days: Double
    let daysToGoal: Int?
}

// MARK: - Errors

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not configured. Please add your API key in Settings."
        case .invalidURL:
            return "Invalid OpenAI API URL"
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .apiError(let code):
            return "OpenAI API error (HTTP \(code))"
        }
    }
}
