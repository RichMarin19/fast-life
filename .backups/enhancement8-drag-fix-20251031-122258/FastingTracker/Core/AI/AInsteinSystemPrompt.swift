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
    - Be concise and actionable (typically 1-3 sentences, but use your judgment for complex calculations)
    - Use luxury empathy tone (encouraging but not condescending or over-enthusiastic)
    - Use SIMPLE language that average users can understand (avoid jargon)
    - For complex information (calculations, projections), use clear structure:
      * Lead with the key insight
      * Present calculations with context (not just raw numbers)
      * Translate technical terms into plain English
    - End with reflective prompt when appropriate (e.g., "How are you feeling about this progress?")
    - Use allowed emojis sparingly: ✨, 🧠, ⚡ (maximum 1 per response, prefer none)
    - ALWAYS sign responses: "– AInstein."
    - Avoid exclamation marks (use periods for calm, confident tone)
    - Focus on "why" (insights) not just "what" (data regurgitation)

    FORMATTING GUIDELINES FOR CLARITY:
    - Use line breaks to separate distinct thoughts (helps readability)
    - Present calculations with explanation: "Based on your average rate of X, it will take approximately Y days"
    - Translate time into relatable terms: "194 days (about 6.5 months)" instead of just "194 days"
    - Use comparison for context: "You're losing 0.3 lbs/week (slower than your goal of 1 lb/week)"

    GOOD RESPONSE EXAMPLES:
    ✅ "Your weight is down 2.3 lbs this week, aligning with your 4 fasts. Keep this momentum going. – AInstein."

    ✅ "You've lost 1.7 lbs this week—solid progress.

    At your current rate of 0.3 lbs/week, reaching 170 lbs will take about 6-7 months. Staying consistent with fasting and improving sleep could help you hit your goal faster. How are you feeling about this timeline? – AInstein."

    ✅ "Your fasting frequency jumped from 3 to 4 sessions this week, and your weight loss accelerated (0.8 lbs vs 0.4 lbs/week). This pattern shows consistency is working. – AInstein."

    BAD RESPONSE EXAMPLES (DO NOT DO THIS):
    ❌ "Hey! Great job! You're doing amazing! Your weight is down 2.3 lbs this week which is super awesome! Keep up the great work! You're a rockstar! – AInstein."
    ❌ "Let me check your blood pressure... Your BP is 120/80 which is perfect!" (inventing data not provided)
    ❌ "You should take 500mg magnesium before bed to improve sleep." (medical advice)
    ❌ "If you maintain a similar rate, it will take approximately 194 days to reach your goal weight of 170 lbs." (too technical, no context)

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

    /// Format comprehensive user context from RichHealthContext
    /// **Phase 8.1:** New formatter with 10x more data to fix "not enough data" bug
    /// - Parameter context: RichHealthContext with comprehensive health metrics
    /// - Returns: Formatted context string for system prompt
    static func formatContext(from richContext: RichHealthContext) -> String {
        var sections: [String] = []

        // MARK: Current Status (Today/Now)
        var currentSection: [String] = []
        if let weight = richContext.currentWeight {
            currentSection.append("Weight: \(String(format: "%.1f", weight)) lbs")
        }
        if let status = richContext.currentFastingStatus {
            currentSection.append("Fasting Status: \(status)")
        }
        if let sleep = richContext.lastNightSleep {
            currentSection.append("Last Night Sleep: \(String(format: "%.1f", sleep)) hours")
        }
        if let hydration = richContext.todayHydration {
            currentSection.append("Today's Hydration: \(String(format: "%.0f", hydration)) oz")
        }
        if let mood = richContext.todayMood {
            currentSection.append("Today's Mood: \(mood)/5")
        }
        if !currentSection.isEmpty {
            sections.append("CURRENT STATUS:\n" + currentSection.map { "  " + $0 }.joined(separator: "\n"))
        }

        // MARK: 7-Day Trends
        var week7Section: [String] = []
        if let weightChange = richContext.weightChange7d {
            let direction = weightChange < 0 ? "down" : "up"
            week7Section.append("Weight Change: \(direction) \(String(format: "%.1f", abs(weightChange))) lbs")
        }
        if let fasts = richContext.fastingCount7d {
            week7Section.append("Fasts Completed: \(fasts)")
        }
        if let sleep = richContext.avgSleep7d {
            week7Section.append("Avg Sleep: \(String(format: "%.1f", sleep)) hours/night")
        }
        if let hydration = richContext.avgHydration7d {
            week7Section.append("Avg Hydration: \(String(format: "%.0f", hydration)) oz/day")
        }
        if let mood = richContext.avgMood7d {
            week7Section.append("Avg Mood: \(String(format: "%.1f", mood))/5")
        }
        if let energy = richContext.avgEnergy7d {
            week7Section.append("Avg Energy: \(String(format: "%.1f", energy))/5")
        }
        if !week7Section.isEmpty {
            sections.append("7-DAY TRENDS (This Week):\n" + week7Section.map { "  " + $0 }.joined(separator: "\n"))
        }

        // MARK: 30-Day Trends
        var month30Section: [String] = []
        if let weightChange = richContext.weightChange30d {
            let direction = weightChange < 0 ? "down" : "up"
            month30Section.append("Weight Change: \(direction) \(String(format: "%.1f", abs(weightChange))) lbs")
        }
        if let fasts = richContext.fastingCount30d {
            month30Section.append("Fasts Completed: \(fasts)")
        }
        if let avgDuration = richContext.avgFastDuration30d {
            month30Section.append("Avg Fast Duration: \(String(format: "%.1f", avgDuration)) hours")
        }
        if let sleep = richContext.avgSleep30d {
            month30Section.append("Avg Sleep: \(String(format: "%.1f", sleep)) hours/night")
        }
        if let hydration = richContext.avgHydration30d {
            month30Section.append("Avg Hydration: \(String(format: "%.0f", hydration)) oz/day")
        }
        if let mood = richContext.avgMood30d {
            month30Section.append("Avg Mood: \(String(format: "%.1f", mood))/5")
        }
        if !month30Section.isEmpty {
            sections.append("30-DAY TRENDS (This Month):\n" + month30Section.map { "  " + $0 }.joined(separator: "\n"))
        }

        // MARK: 90-Day Trends
        var quarter90Section: [String] = []
        if let weightChange = richContext.weightChange90d {
            let direction = weightChange < 0 ? "down" : "up"
            quarter90Section.append("Weight Change: \(direction) \(String(format: "%.1f", abs(weightChange))) lbs")
        }
        if let fasts = richContext.fastingCount90d {
            quarter90Section.append("Fasts Completed: \(fasts)")
        }
        if let avgDuration = richContext.avgFastDuration90d {
            quarter90Section.append("Avg Fast Duration: \(String(format: "%.1f", avgDuration)) hours")
        }
        if let avgLossRate = richContext.avgWeightLossRate90d {
            quarter90Section.append("Avg Weight Loss Rate: \(String(format: "%.1f", avgLossRate)) lbs/week")
        }
        if !quarter90Section.isEmpty {
            sections.append("90-DAY TRENDS (Last 3 Months):\n" + quarter90Section.map { "  " + $0 }.joined(separator: "\n"))
        }

        // MARK: Goals & Progress
        var goalsSection: [String] = []
        if let goal = richContext.weightGoal {
            goalsSection.append("Weight Goal: \(String(format: "%.1f", goal)) lbs")
        }
        if let start = richContext.startWeight {
            goalsSection.append("Starting Weight: \(String(format: "%.1f", start)) lbs")
        }
        if let lost = richContext.totalWeightLost {
            goalsSection.append("Total Lost: \(String(format: "%.1f", lost)) lbs")
        }
        if let days = richContext.daysInJourney {
            goalsSection.append("Days in Journey: \(days)")
        }
        if let progress = richContext.progressPercent {
            goalsSection.append("Progress: \(Int(progress * 100))% to goal")
        }
        if let eta = richContext.estimatedDaysToGoal {
            goalsSection.append("Estimated Days to Goal: \(eta)")
        }
        if let status = richContext.onTrackStatus {
            goalsSection.append("Status: \(status)")
        }
        if !goalsSection.isEmpty {
            sections.append("GOALS & PROGRESS:\n" + goalsSection.map { "  " + $0 }.joined(separator: "\n"))
        }

        // MARK: Streaks & Milestones
        var streaksSection: [String] = []
        if let streak = richContext.currentFastingStreak, streak > 0 {
            streaksSection.append("Current Streak: \(streak) days")
        }
        if let longest = richContext.longestFastingStreak, longest > 0 {
            streaksSection.append("Longest Streak: \(longest) days")
        }
        if let total = richContext.totalFastsCompleted {
            streaksSection.append("Total Fasts Completed: \(total)")
        }
        if let milestones = richContext.milestones, !milestones.isEmpty {
            streaksSection.append("Milestones: \(milestones.joined(separator: ", "))")
        }
        if !streaksSection.isEmpty {
            sections.append("STREAKS & MILESTONES:\n" + streaksSection.map { "  " + $0 }.joined(separator: "\n"))
        }

        // MARK: Correlations (Key Insights)
        var correlationsSection: [String] = []
        if let highFasts = richContext.weeksWith5PlusFasts_AvgWeightLoss,
           let lowFasts = richContext.weeksWith3OrLessFasts_AvgWeightLoss {
            correlationsSection.append("Weeks with 5+ fasts: avg \(String(format: "%.1f", highFasts)) lbs lost")
            correlationsSection.append("Weeks with ≤3 fasts: avg \(String(format: "%.1f", lowFasts)) lbs lost")
        }
        if let wellRested = richContext.avgWeightLoss_WellRested,
           let poorly = richContext.avgWeightLoss_PoorlySleep {
            correlationsSection.append("Well-rested weeks (7+ hrs): avg \(String(format: "%.1f", wellRested)) lbs lost")
            correlationsSection.append("Poorly-slept weeks (<7 hrs): avg \(String(format: "%.1f", poorly)) lbs lost")
        }
        if let highHydration = richContext.avgWeightLoss_HighHydration,
           let lowHydration = richContext.avgWeightLoss_LowHydration {
            correlationsSection.append("High hydration weeks (80+ oz): avg \(String(format: "%.1f", highHydration)) lbs lost")
            correlationsSection.append("Low hydration weeks (<80 oz): avg \(String(format: "%.1f", lowHydration)) lbs lost")
        }
        if !correlationsSection.isEmpty {
            sections.append("CORRELATIONS (Pre-Calculated):\n" + correlationsSection.map { "  " + $0 }.joined(separator: "\n"))
        }

        // MARK: Historical Patterns
        var patternsSection: [String] = []
        if let bestDate = richContext.bestWeek_Date,
           let bestFasts = richContext.bestWeek_FastingCount,
           let bestLoss = richContext.bestWeek_WeightLoss {
            patternsSection.append("Best Week: \(bestDate) (\(bestFasts) fasts, \(String(format: "%.1f", bestLoss)) lbs lost)")
        }
        if let worstDate = richContext.worstWeek_Date,
           let worstFasts = richContext.worstWeek_FastingCount,
           let worstChange = richContext.worstWeek_WeightChange {
            let direction = worstChange < 0 ? "lost" : "gained"
            patternsSection.append("Worst Week: \(worstDate) (\(worstFasts) fasts, \(String(format: "%.1f", abs(worstChange))) lbs \(direction))")
        }
        if let avgRate = richContext.avgWeightLossRate {
            patternsSection.append("Avg Weight Loss Rate: \(String(format: "%.1f", avgRate)) lbs/week (all-time)")
        }
        if let commonDuration = richContext.mostCommonFastDuration {
            patternsSection.append("Most Common Fast Duration: \(commonDuration)")
        }
        if let productiveDay = richContext.mostProductiveDayOfWeek {
            patternsSection.append("Most Productive Day: \(productiveDay)")
        }
        if !patternsSection.isEmpty {
            sections.append("HISTORICAL PATTERNS:\n" + patternsSection.map { "  " + $0 }.joined(separator: "\n"))
        }

        // MARK: Data Completeness
        var dataSection: [String] = []
        if let weightEntries = richContext.totalWeightEntries {
            dataSection.append("Weight Entries: \(weightEntries)")
        }
        if let sleepEntries = richContext.totalSleepEntries {
            dataSection.append("Sleep Entries: \(sleepEntries)")
        }
        if let hydrationEntries = richContext.totalHydrationEntries {
            dataSection.append("Hydration Entries: \(hydrationEntries)")
        }
        if let moodEntries = richContext.totalMoodEntries {
            dataSection.append("Mood Entries: \(moodEntries)")
        }
        if !dataSection.isEmpty {
            sections.append("DATA COMPLETENESS:\n" + dataSection.map { "  " + $0 }.joined(separator: "\n"))
        }

        // If no data available
        if sections.isEmpty {
            return "No health data available yet. User needs to start logging in Fast LIFe app."
        }

        return sections.joined(separator: "\n\n")
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
