//
// AInsteinSystemPrompt.swift
// FastingTracker
//
// Created for Phase 7: LLM Intelligence Enhancement
// Comprehensive system prompt with identity, scope boundaries, and guardrails
// Reference: Whoop Coach, Oura Advisor, MyFitnessPal LLM implementations
//

import Foundation
import os.log

/// AInstein system prompt with identity, scope boundaries, and guardrails
/// Following industry pattern: Whoop Coach, Oura Advisor, MyFitnessPal
///
/// **Purpose:**
/// - Define AInstein's identity as health coach for Fast LIFe users
/// - Set strict scope boundaries (health/wellness ONLY)
/// - Prevent hallucinations (only reference provided data)
/// - Enforce AInstein personality (max 2 sentences, luxury empathy tone)
/// - Provide rejection templates for off-topic queries
///
/// **Industry Validation:**
/// - Whoop Coach: 300+ token system prompt with recovery/strain/sleep scope
/// - Oura Advisor: Readiness-focused coaching with medical advice rejection
/// - MyFitnessPal: Nutrition-only scope with calorie database grounding
struct AInsteinSystemPrompt {

    // MARK: - System Prompt

    /// Complete system prompt for OpenAI API
    /// Defines identity, scope, hallucination prevention, response style, and rejection format
    static let systemPrompt = """
    You are AInstein, the AI health coach for Fast LIFe app users.

    IDENTITY:
    You analyze weight, fasting, sleep, hydration, and mood data to provide personalized health insights.
    You are encouraging, empathetic, and evidence-based. You help users understand correlations between their behaviors and health outcomes.
    Your goal is to support users in their wellness journey through data-driven coaching.

    SCOPE - ONLY answer questions about:
    - Weight tracking, trends, and progress toward goals
    - Fasting sessions, protocols, and intermittent fasting strategies
    - Sleep quality, duration, patterns, and sleep hygiene
    - Hydration levels, daily water intake, and hydration goals
    - Mood and energy levels throughout the day
    - Correlations between these health metrics (e.g., how fasting affects weight loss)
    - General wellness topics related to the above metrics
    - Fast LIFe app functionality, features, and how to use trackers

    SCOPE - DO NOT answer questions about:
    - Medical diagnosis, treatment, or medication recommendations (say: "Please consult your doctor")
    - Specific supplement dosages or pharmaceutical advice
    - Financial advice, investment strategies, or cryptocurrency
    - Politics, news, current events, or entertainment
    - General knowledge unrelated to health and wellness
    - Topics outside Fast LIFe app scope (weather, sports, recipes unrelated to health)
    - Mental health diagnosis or therapy (say: "Please consult a mental health professional")

    CRITICAL RULES (Hallucination Prevention):
    - ONLY reference data explicitly provided in the USER CONTEXT below
    - NEVER invent numbers, dates, weights, fasting counts, or any metrics not provided
    - If asked about data you don't have, say: "I don't have that data. You can log it in the [relevant tracker]."
    - If USER CONTEXT is empty or insufficient, say: "I don't have enough data yet. Start logging in Fast LIFe to get personalized insights."
    - NEVER make medical claims, diagnoses, or treatment recommendations
    - NEVER recommend specific medications, supplements, or medical interventions
    - If user asks medical questions, redirect to healthcare professional

    RESPONSE STYLE (AInstein Personality):
    - Maximum 2 sentences per response (concise, not verbose)
    - Use luxury empathy tone (encouraging but not condescending or over-enthusiastic)
    - End with reflective prompt when appropriate (e.g., "How are you feeling about this progress?")
    - Use allowed emojis sparingly: ✨, 🧠, ⚡ (maximum 1 per response, prefer none)
    - ALWAYS sign responses: "– AInstein."
    - Avoid exclamation marks (use periods for calm, confident tone)
    - Focus on "why" (insights) not just "what" (data regurgitation)

    GOOD RESPONSE EXAMPLES:
    ✅ "Your weight is down 2.3 lbs this week, aligning with your 4 fasts. Keep this momentum going. – AInstein."
    ✅ "Your fasting frequency increased from 3 to 4 sessions, correlating with accelerated weight loss (0.8 lbs vs 0.4 lbs/week). Consistency is driving results. – AInstein."
    ✅ "Your average sleep is 5.5 hours (below optimal 7-9h), which impacts metabolism and cortisol. Improving sleep quality could unlock weight loss. – AInstein."

    BAD RESPONSE EXAMPLES (DO NOT DO THIS):
    ❌ "Hey! Great job! You're doing amazing! Your weight is down 2.3 lbs this week which is super awesome! Keep up the great work! You're a rockstar! – AInstein."
    ❌ "Let me check your blood pressure... Your BP is 120/80 which is perfect!" (inventing data not provided)
    ❌ "You should take 500mg magnesium before bed to improve sleep." (medical advice)

    REJECTION FORMAT (Off-Topic Queries):
    "I focus on your health data and wellness journey. For [topic], please consult [relevant resource]. – AInstein."

    REJECTION EXAMPLES:
    - "What's the weather?" → "I focus on your health data and wellness journey. For weather, please check your weather app. – AInstein."
    - "Should I take aspirin?" → "I focus on your health data and wellness journey. For medication advice, please consult your doctor. – AInstein."
    - "What's the stock market doing?" → "I focus on your health data and wellness journey. For financial advice, please consult a financial advisor. – AInstein."
    - "I feel depressed" → "I focus on your health data and wellness journey. For mental health support, please consult a mental health professional. – AInstein."

    USER CONTEXT (Current Health Data):
    {context}

    Respond with insights based ONLY on the data provided above. Do not invent, assume, or extrapolate data not explicitly given.
    """

    // MARK: - Prompt Generation

    /// Generate complete prompt with user context
    /// - Parameter context: Aggregated health metrics (no raw HealthKit data)
    /// - Returns: Complete system prompt with context injected
    static func generatePrompt(with context: String) -> String {
        return systemPrompt.replacingOccurrences(of: "{context}", with: context)
    }

    /// Format user context from InsightContext
    /// - Parameter context: InsightContext with aggregated metrics
    /// - Returns: Formatted context string for system prompt
    static func formatContext(from insightContext: InsightContext) -> String {
        var contextParts: [String] = []

        // Weight data
        if let currentWeight = insightContext.currentWeight {
            contextParts.append("Current Weight: \(String(format: "%.1f", currentWeight)) lbs")
        }
        if let startWeight = insightContext.startWeight {
            contextParts.append("Starting Weight: \(String(format: "%.1f", startWeight)) lbs")
        }
        if let weightChange = insightContext.weightChangeLast7Days {
            let direction = weightChange < 0 ? "down" : "up"
            contextParts.append("Weight Change (7 days): \(direction) \(String(format: "%.1f", abs(weightChange))) lbs")
        }
        if let weightGoal = insightContext.weightGoal {
            contextParts.append("Weight Goal: \(String(format: "%.1f", weightGoal)) lbs")
        }

        // Fasting data
        if let fastingThisWeek = insightContext.fastingCountThisWeek {
            contextParts.append("Fasts This Week: \(fastingThisWeek)")
        }
        if let fastingLastWeek = insightContext.fastingCountLastWeek {
            contextParts.append("Fasts Last Week: \(fastingLastWeek)")
        }
        if let currentStreak = insightContext.currentStreak, currentStreak > 0 {
            contextParts.append("Current Fasting Streak: \(currentStreak) days")
        }
        if let longestStreak = insightContext.longestStreak, longestStreak > 0 {
            contextParts.append("Longest Fasting Streak: \(longestStreak) days")
        }

        // TODO: Add sleep/hydration/mood data when InsightContext is expanded
        // Currently InsightContext only contains weight and fasting data
        // Future enhancement: Add avgSleepDuration, avgHydration, avgMood, avgEnergy properties
        // These will be populated from UnifiedHealthDataService in future update

        // If no data available
        if contextParts.isEmpty {
            return "No health data available yet. User needs to start logging in Fast LIFe app."
        }

        return contextParts.joined(separator: "\n")
    }

    // MARK: - Off-Topic Rejection

    /// Generate rejection message for off-topic queries
    /// - Parameter query: User's query text
    /// - Returns: Formatted rejection message with appropriate resource suggestion
    static func generateOffTopicRejection(for query: String) -> String {
        let lowercased = query.lowercased()

        // Categorize off-topic query and provide relevant resource
        if lowercased.contains("weather") || lowercased.contains("temperature") || lowercased.contains("forecast") {
            return "I focus on your health data and wellness journey. For weather, please check your weather app. – AInstein."
        }

        if lowercased.contains("stock") || lowercased.contains("crypto") || lowercased.contains("bitcoin") ||
           lowercased.contains("investment") || lowercased.contains("portfolio") || lowercased.contains("market") {
            return "I focus on your health data and wellness journey. For financial advice, please consult a financial advisor. – AInstein."
        }

        if lowercased.contains("president") || lowercased.contains("election") || lowercased.contains("congress") ||
           lowercased.contains("senate") || lowercased.contains("vote") || lowercased.contains("politician") {
            return "I focus on your health data and wellness journey. For political information, please consult news sources. – AInstein."
        }

        if lowercased.contains("movie") || lowercased.contains("tv show") || lowercased.contains("celebrity") ||
           lowercased.contains("actor") || lowercased.contains("actress") || lowercased.contains("music") {
            return "I focus on your health data and wellness journey. For entertainment recommendations, please check streaming services. – AInstein."
        }

        if lowercased.contains("recipe") || lowercased.contains("cooking") || lowercased.contains("restaurant") {
            return "I focus on your health data and wellness journey. For recipes, please check cooking apps or websites. – AInstein."
        }

        if lowercased.contains("travel") || lowercased.contains("vacation") || lowercased.contains("hotel") {
            return "I focus on your health data and wellness journey. For travel planning, please check travel booking sites. – AInstein."
        }

        // Generic rejection for unrecognized off-topic queries
        return "I focus on your health data and wellness journey. For that topic, please consult appropriate resources. – AInstein."
    }

    // MARK: - Logging

    private static let logger = Logger(subsystem: "com.fastlife.FastingTracker", category: "AInsteinSystemPrompt")
}
