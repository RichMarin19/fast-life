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

/// Validates LLM responses for hallucination prevention and tone enforcement
/// Following industry pattern: Whoop Coach validation, Oura Advisor guardrails
///
/// **Purpose:**
/// - Detect hallucinations (LLM inventing numbers not in context)
/// - Enforce AInstein personality (max 2 sentences, luxury empathy tone)
/// - Filter emojis (only ✨, 🧠, ⚡ allowed, max 1)
/// - Ensure signature ("– AInstein." at end)
///
/// **Industry Validation:**
/// - Whoop Coach: Validates metrics against provided data
/// - Oura Advisor: Flags responses with invented sleep scores
/// - MyFitnessPal: Cross-checks calorie counts with database
struct ResponseValidator {

    // MARK: - Public API

    /// Validate LLM response against provided context
    /// - Parameters:
    ///   - response: Raw LLM response
    ///   - context: InsightContext used to generate response
    /// - Returns: Validated response (truncated, signature added, emojis filtered)
    static func validate(_ response: String, against context: InsightContext) -> String {
        var validated = response

        // 1. Detect hallucinations (invented numbers)
        if containsHallucination(validated, context: context) {
            logger.warning("⚠️ Hallucination detected in LLM response, returning fallback")
            return "I don't have enough reliable data for that question yet. Keep logging to get insights. – AInstein."
        }

        // 2. Enforce max 2 sentences
        validated = enforceMaxSentences(validated, maxSentences: 2)

        // 3. Filter emojis (only ✨, 🧠, ⚡ allowed, max 1)
        validated = filterEmojis(validated)

        // 4. Ensure signature
        validated = ensureSignature(validated)

        return validated
    }

    // MARK: - Hallucination Detection

    /// Check if response contains numbers not present in context (hallucination)
    /// **Tolerance:** ±0.5 for rounding differences
    /// - Parameters:
    ///   - response: LLM-generated response
    ///   - context: InsightContext with health data
    /// - Returns: True if hallucination detected, false otherwise
    private static func containsHallucination(_ response: String, context: InsightContext) -> Bool {
        // Extract all numbers from response
        let responseNumbers = extractNumbers(from: response)

        // Extract all numbers from context
        let contextNumbers = extractNumbersFromContext(context)

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
                logger.debug("🚨 Hallucination detected: \(responseNum) not in context")
                return true
            }
        }

        return false
    }

    /// Extract all numbers from string (weight values, counts, percentages)
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

    /// Extract all numbers from InsightContext
    /// - Parameter context: Health data context
    /// - Returns: Array of all numeric values in context
    private static func extractNumbersFromContext(_ context: InsightContext) -> [Double] {
        var numbers: [Double] = []

        // Weight data
        if let weight = context.currentWeight { numbers.append(weight) }
        if let startWeight = context.startWeight { numbers.append(startWeight) }
        if let weightChange = context.weightChangeLast7Days { numbers.append(abs(weightChange)) }
        if let goal = context.weightGoal { numbers.append(goal) }

        // Fasting data
        if let fastingThisWeek = context.fastingCountThisWeek { numbers.append(Double(fastingThisWeek)) }
        if let fastingLastWeek = context.fastingCountLastWeek { numbers.append(Double(fastingLastWeek)) }
        if let streak = context.currentStreak { numbers.append(Double(streak)) }
        if let longestStreak = context.longestStreak { numbers.append(Double(longestStreak)) }

        // TODO: Add sleep/hydration/mood data extraction when InsightContext is expanded
        // Currently InsightContext only contains weight and fasting data
        // Future enhancement: Add avgSleepDuration, avgHydration, avgMood, avgEnergy properties

        return numbers
    }

    // MARK: - Sentence Enforcement

    /// Enforce maximum sentence count
    /// **AInstein Rule:** Max 2 sentences per response
    /// - Parameters:
    ///   - text: Response text
    ///   - maxSentences: Maximum allowed sentences (default: 2)
    /// - Returns: Truncated text with max sentences
    private static func enforceMaxSentences(_ text: String, maxSentences: Int) -> String {
        // Split by sentence-ending punctuation (.!?)
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if sentences.count <= maxSentences {
            return text
        }

        // Take first maxSentences and rejoin
        let truncated = sentences.prefix(maxSentences).joined(separator: ". ")
        return truncated + "."
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
