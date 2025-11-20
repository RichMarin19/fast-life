//
// ResponseValidator.swift
// FastingTracker
//
// Created for Phase 7: LLM Intelligence Enhancement
// Validates LLM responses for hallucination prevention and tone enforcement
// Reference: Whoop Coach validation, Oura Advisor guardrails
//

import Foundation
import os.log

/// Validates LLM responses for tone enforcement (minimal, trust-based)
/// Following industry pattern: Whoop Coach validation, Oura Advisor guardrails
///
/// **Purpose (Phase 8.2+):**
/// - Filter emojis (only ✨, 🧠, ⚡ allowed, max 1)
/// - Ensure signature ("– AInstein." at end)
/// - Trust LLM intelligence for conciseness, accuracy, and tone
///
/// **Industry Reality:**
/// - WHOOP, Oura, Levels do NOT enforce sentence limits - they trust the LLM
/// - System prompts + rich context = accurate, concise responses naturally
/// - Over-engineering validation fights against LLM strengths
struct ResponseValidator {

    // MARK: - Public API

    /// Validate LLM response against RichHealthContext (Phase 8.2+)
    /// **Industry Standard:** WHOOP, Oura, Levels trust LLM intelligence - no artificial truncation
    /// **Philosophy:** GPT-4o-mini is smart enough to follow system prompt instructions naturally
    /// - Parameters:
    ///   - response: Raw LLM response
    ///   - richContext: RichHealthContext used to generate response (unused, kept for future)
    /// - Returns: Validated response (signature added, emojis filtered)
    static func validateWithRichContext(_ response: String, against richContext: RichHealthContext) -> String {
        var validated = response

        // 1. Filter emojis (only ✨, 🧠, ⚡ allowed, max 1)
        validated = filterEmojis(validated)

        // 2. Ensure signature
        validated = ensureSignature(validated)

        return validated
    }

    // MARK: - Deprecated: Hallucination Detection (Phase 8.2)
    // Industry standard: Trust LLM accuracy with rich context + system prompts
    // These methods are kept for reference but not used in validation

    /// [DEPRECATED] Extract all numbers from string (weight values, counts, percentages)
    /// - Parameter text: Text to extract numbers from
    /// - Returns: Array of Double values found in text
    private static func extractNumbers(from text: String) -> [Double] {
        // Pattern: Matches integers and decimals (e.g., 178.7, 4, 5.5)
        let pattern = "\\d+\\.?\\d*"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return Double(text[range])
        }
    }

    /// [DEPRECATED] Check if response contains numbers not present in RichHealthContext (Phase 8.1)
    /// **Phase 8.2:** Removed from validation - false positives on calculated values (0.4 lbs/week)
    /// **Industry Standard:** WHOOP/Oura/Levels trust LLM math with rich context
    /// - Parameters:
    ///   - response: LLM-generated response
    ///   - context: RichHealthContext with comprehensive health data
    /// - Returns: True if hallucination detected, false otherwise
    private static func containsHallucinationInRichContext(_ response: String, context: RichHealthContext) -> Bool {
        // Extract all numbers from response
        let responseNumbers = extractNumbers(from: response)

        // Extract all numbers from RichHealthContext (70+ metrics)
        let contextNumbers = extractNumbersFromRichContext(context)

        // Check if response contains numbers NOT in context (tolerance: ±0.5 for rounding)
        for responseNum in responseNumbers {
            var foundMatch = false
            for contextNum in contextNumbers {
                if abs(responseNum - contextNum) <= 0.5 {
                    foundMatch = true
                    break
                }
            }
            if !foundMatch {
                logger.debug("🚨 Hallucination detected: \(responseNum) not in RichHealthContext")
                return true
            }
        }

        return false
    }

    /// [DEPRECATED] Extract all numbers from RichHealthContext (Phase 8.1)
    /// **Phase 8.2:** No longer used - trust LLM to calculate derived values
    /// - Parameter context: Comprehensive health data context
    /// - Returns: Array of all numeric values in context
    private static func extractNumbersFromRichContext(_ context: RichHealthContext) -> [Double] {
        var numbers: [Double] = []

        // Current State
        if let weight = context.currentWeight { numbers.append(weight) }
        if let hydration = context.todayHydration { numbers.append(hydration) }
        if let mood = context.todayMood { numbers.append(Double(mood)) }
        if let sleep = context.lastNightSleep { numbers.append(sleep) }

        // 7-Day Trends
        if let change = context.weightChange7d { numbers.append(abs(change)) }
        if let count = context.fastingCount7d { numbers.append(Double(count)) }
        if let sleep = context.avgSleep7d { numbers.append(sleep) }
        if let hydration = context.avgHydration7d { numbers.append(hydration) }
        if let mood = context.avgMood7d { numbers.append(mood) }
        if let energy = context.avgEnergy7d { numbers.append(energy) }

        // 30-Day Trends
        if let change = context.weightChange30d { numbers.append(abs(change)) }
        if let count = context.fastingCount30d { numbers.append(Double(count)) }
        if let duration = context.avgFastDuration30d { numbers.append(duration) }
        if let sleep = context.avgSleep30d { numbers.append(sleep) }
        if let hydration = context.avgHydration30d { numbers.append(hydration) }
        if let mood = context.avgMood30d { numbers.append(mood) }
        if let energy = context.avgEnergy30d { numbers.append(energy) }

        // 90-Day Trends
        if let change = context.weightChange90d { numbers.append(abs(change)) }
        if let count = context.fastingCount90d { numbers.append(Double(count)) }
        if let duration = context.avgFastDuration90d { numbers.append(duration) }
        if let sleep = context.avgSleep90d { numbers.append(sleep) }
        if let rate = context.avgWeightLossRate90d { numbers.append(abs(rate)) }

        // Goals & Progress
        if let goal = context.weightGoal { numbers.append(goal) }
        if let start = context.startWeight { numbers.append(start) }
        if let lost = context.totalWeightLost { numbers.append(abs(lost)) }
        if let days = context.daysInJourney { numbers.append(Double(days)) }
        if let percent = context.progressPercent { numbers.append(percent) }
        if let daysToGoal = context.estimatedDaysToGoal { numbers.append(Double(daysToGoal)) }

        // Streaks & Milestones
        if let streak = context.currentFastingStreak { numbers.append(Double(streak)) }
        if let longest = context.longestFastingStreak { numbers.append(Double(longest)) }
        if let total = context.totalFastsCompleted { numbers.append(Double(total)) }

        // Correlations
        if let high = context.weeksWith5PlusFasts_AvgWeightLoss { numbers.append(abs(high)) }
        if let low = context.weeksWith3OrLessFasts_AvgWeightLoss { numbers.append(abs(low)) }
        if let wellRested = context.avgWeightLoss_WellRested { numbers.append(abs(wellRested)) }
        if let poorly = context.avgWeightLoss_PoorlySleep { numbers.append(abs(poorly)) }
        if let highHydration = context.avgWeightLoss_HighHydration { numbers.append(abs(highHydration)) }
        if let lowHydration = context.avgWeightLoss_LowHydration { numbers.append(abs(lowHydration)) }

        // Key Patterns
        if let count = context.bestWeek_FastingCount { numbers.append(Double(count)) }
        if let loss = context.bestWeek_WeightLoss { numbers.append(abs(loss)) }
        if let count = context.worstWeek_FastingCount { numbers.append(Double(count)) }
        if let change = context.worstWeek_WeightChange { numbers.append(abs(change)) }
        if let rate = context.avgWeightLossRate { numbers.append(abs(rate)) }

        // Data Completeness
        if let count = context.totalWeightEntries { numbers.append(Double(count)) }
        if let count = context.totalSleepEntries { numbers.append(Double(count)) }
        if let count = context.totalHydrationEntries { numbers.append(Double(count)) }
        if let count = context.totalMoodEntries { numbers.append(Double(count)) }

        return numbers
    }


    // MARK: - Deprecated: Sentence Enforcement (Phase 8.2+)
    // Industry Reality: WHOOP, Oura, Levels do NOT enforce sentence limits
    // Philosophy: "We have the power of an LLM connected to us" - trust its intelligence
    // These methods are kept for reference but not used in validation

    /// [DEPRECATED] Enforce maximum sentence count
    /// **Phase 8.2+ Decision:** REMOVED from validation - trust LLM to follow system prompt naturally
    /// **Issue:** Artificially truncating LLM responses fights against its intelligence
    /// **Fix Applied (before deprecation):** Properly handles decimal numbers (0.3, 178.4) without breaking
    /// - Parameters:
    ///   - text: Response text
    ///   - maxSentences: Maximum allowed sentences (default: 2)
    /// - Returns: Truncated text with max sentences
    private static func enforceMaxSentences(_ text: String, maxSentences: Int) -> String {
        // Pattern: Match sentence-ending punctuation (.!?) followed by:
        // - Whitespace + uppercase letter (start of new sentence)
        // - OR end of string
        // But NOT periods in decimal numbers (e.g., 0.3, 178.4)
        let pattern = "(?<![0-9])[.!?](?=\\s+[A-Z]|\\s*$)"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            // Fallback: return original text if regex fails
            return text
        }

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        // If we have maxSentences or fewer sentences, return original
        if matches.count <= maxSentences {
            return text
        }

        // Find the position after the Nth sentence-ending punctuation
        guard let nthMatch = matches.dropFirst(maxSentences - 1).first,
              let range = Range(nthMatch.range, in: text) else {
            return text
        }

        // Truncate at the Nth sentence boundary
        let truncated = String(text[..<range.upperBound]).trimmingCharacters(in: .whitespaces)
        return truncated
    }

    // MARK: - Emoji Filtering

    /// Filter emojis (only ✨, 🧠, ⚡ allowed, max 1)
    /// **AInstein Rule:** Minimal emoji use, max 1 per response
    /// - Parameter text: Response text
    /// - Returns: Text with filtered emojis
    private static func filterEmojis(_ text: String) -> String {
        let allowedEmojis: Set<Character> = ["✨", "🧠", "⚡"]
        var emojiCount = 0

        return String(text.compactMap { char in
            if allowedEmojis.contains(char) {
                if emojiCount < 1 {
                    emojiCount += 1
                    return char // Keep first allowed emoji
                } else {
                    return nil // Remove extra allowed emojis
                }
            } else if char.unicodeScalars.first?.properties.isEmoji == true {
                // Check if it's a digit (digits are emoji-capable but should NOT be removed)
                if let scalar = char.unicodeScalars.first, scalar.value >= 48 && scalar.value <= 57 {
                    return char // Preserve ASCII digits (0-9)
                }
                return nil // Remove disallowed emojis
            } else {
                return char // Keep non-emoji characters
            }
        })
    }

    // MARK: - Signature Enforcement

    /// Ensure response ends with "– AInstein."
    /// **AInstein Rule:** All responses must be signed
    /// - Parameter text: Response text
    /// - Returns: Text with signature appended if missing
    private static func ensureSignature(_ text: String) -> String {
        let signature = "– AInstein."

        // Check if already has signature
        if text.hasSuffix(signature) {
            return text
        }

        // Remove any existing incomplete signature
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasSuffix("AInstein") || cleaned.hasSuffix("AInstein.") || cleaned.hasSuffix("- AInstein") {
            // Remove incomplete signature variants
            if let range = cleaned.range(of: "AInstein", options: .backwards) {
                cleaned = String(cleaned[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Append proper signature
        return cleaned + " " + signature
    }

    // MARK: - Logging

    private static let logger = Logger(subsystem: "com.fastlife.FastingTracker", category: "ResponseValidator")
}
