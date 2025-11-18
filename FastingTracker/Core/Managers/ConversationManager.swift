//
// ConversationManager.swift
// FastingTracker
//
// Created for Phase 3C: Conversational Context Manager
// Industry Pattern: ChatGPT context, Alexa follow-up mode, Siri Shortcuts
// Reference: docs/planning/PHASE-3-INTELLIGENCE-UPGRADE.md
//

import Foundation
import Combine

// MARK: - Conversation Manager Protocol

/// Protocol for managing conversational context
/// **Single Source of Truth** for dialogue state management
protocol ConversationManagerProtocol: ObservableObject {
    /// Add message to conversation history
    func addMessage(_ message: ChatMessage)

    /// Get recent conversation history (last N messages)
    func getRecentHistory(limit: Int) -> [ChatMessage]

    /// Detect if topic switched from last query
    func detectTopicSwitch(newQuery: String) -> Bool

    /// Generate contextual follow-up suggestions
    func generateFollowUpSuggestions() -> [String]

    /// Clear conversation history
    func clearHistory()
}

// MARK: - Conversation Topic

/// Conversation topic (for topic switch detection)
enum ConversationTopic: String, Codable {
    case weight             // Weight-related queries
    case fasting            // Fasting-related queries
    case goal               // Goal progress queries
    case comparison         // Week/month comparisons
    case general            // General/summary queries
    case unknown            // Unclassified

    /// Detect topic from query string
    /// Simple keyword matching (can enhance later)
    static func detect(from query: String) -> ConversationTopic {
        let normalized = query.lowercased()

        // Weight keywords
        if normalized.contains("weight") || normalized.contains("lbs") || normalized.contains("kg") ||
           normalized.contains("pounds") || normalized.contains("kilograms") {
            return .weight
        }

        // Fasting keywords
        if normalized.contains("fast") || normalized.contains("streak") || normalized.contains("protocol") {
            return .fasting
        }

        // Goal keywords
        if normalized.contains("goal") || normalized.contains("target") || normalized.contains("progress") ||
           normalized.contains("on track") || normalized.contains("eta") {
            return .goal
        }

        // Comparison keywords
        if normalized.contains("week") || normalized.contains("month") || normalized.contains("compare") ||
           normalized.contains("vs") || normalized.contains("last") {
            return .comparison
        }

        // General keywords
        if normalized.contains("summary") || normalized.contains("stats") || normalized.contains("how am i") ||
           normalized.contains("overview") {
            return .general
        }

        return .unknown
    }
}

// MARK: - Conversation Context

/// Current conversation context (state of dialogue)
struct ConversationContext: Codable {
    /// Current topic
    var currentTopic: ConversationTopic

    /// Previous topic (for switch detection)
    var previousTopic: ConversationTopic?

    /// Last query text
    var lastQuery: String?

    /// Last answer text
    var lastAnswer: String?

    /// Timestamp of last interaction
    var lastInteractionTime: Date?

    init(
        currentTopic: ConversationTopic = .unknown,
        previousTopic: ConversationTopic? = nil,
        lastQuery: String? = nil,
        lastAnswer: String? = nil,
        lastInteractionTime: Date? = nil
    ) {
        self.currentTopic = currentTopic
        self.previousTopic = previousTopic
        self.lastQuery = lastQuery
        self.lastAnswer = lastAnswer
        self.lastInteractionTime = lastInteractionTime
    }
}

// MARK: - Conversation Manager Implementation

/// Production-grade conversational context manager
/// **Architecture:** Rolling window context (last 5 messages)
/// **Industry Patterns:**
/// - ChatGPT: Context window with token limits
/// - Alexa: Follow-up mode (30-second window)
/// - Siri: Short-term context (last query only)
class ConversationManager: ObservableObject, ConversationManagerProtocol {

    // MARK: - Constants

    /// Maximum conversation history size (memory management)
    /// Industry standard: 5-10 messages for mobile apps
    private static let maxHistorySize = 5

    /// Topic switch threshold (seconds)
    /// If >5 minutes since last interaction, always consider it a new topic
    private static let topicSwitchThreshold: TimeInterval = 300  // 5 minutes

    // MARK: - Published State

    /// Conversation history (last N messages)
    /// @Published for SwiftUI reactivity
    @Published private(set) var history: [ChatMessage] = []

    /// Current conversation context
    /// @Published for SwiftUI reactivity
    @Published private(set) var context: ConversationContext = ConversationContext()

    // MARK: - Initialization

    init() {
        // Initialize with empty history
        self.history = []
        self.context = ConversationContext()
    }

    // MARK: - Public Methods

    /// Add message to conversation history
    /// Maintains rolling window (last N messages)
    func addMessage(_ message: ChatMessage) {
        // Add to history
        history.append(message)

        // Maintain max history size (rolling window)
        if history.count > Self.maxHistorySize {
            history.removeFirst()
        }

        // Update context if it's a user message (query)
        if message.sender == .user {
            let topic = ConversationTopic.detect(from: message.content)
            context.previousTopic = context.currentTopic
            context.currentTopic = topic
            context.lastQuery = message.content
            context.lastInteractionTime = message.timestamp
        }

        // Update context if it's an assistant message (answer)
        if message.sender == .assistant {
            context.lastAnswer = message.content
        }
    }

    /// Get recent conversation history
    func getRecentHistory(limit: Int) -> [ChatMessage] {
        let count = min(limit, history.count)
        return Array(history.suffix(count))
    }

    /// Detect if topic switched from last query
    /// **Logic:**
    /// - If >5 minutes since last interaction → new topic
    /// - If topic category changed → topic switch
    /// - Otherwise → same topic
    func detectTopicSwitch(newQuery: String) -> Bool {
        // Detect topic of new query
        let newTopic = ConversationTopic.detect(from: newQuery)

        // Check time threshold
        if let lastTime = context.lastInteractionTime {
            let timeSinceLastInteraction = Date().timeIntervalSince(lastTime)
            if timeSinceLastInteraction > Self.topicSwitchThreshold {
                return true  // Too much time passed, new topic
            }
        }

        // Check topic switch
        if newTopic != context.currentTopic && context.currentTopic != .unknown {
            return true  // Topic category changed
        }

        return false  // Same topic
    }

    /// Generate follow-up suggestions based on current context
    /// **Industry Pattern:** ChatGPT suggested prompts
    func generateFollowUpSuggestions() -> [String] {
        var suggestions: [String] = []

        // Generate suggestions based on current topic
        switch context.currentTopic {
        case .weight:
            suggestions = [
                "What's my weight trend?",
                "Am I on track to my goal?",
                "How does this compare to last week?"
            ]

        case .fasting:
            suggestions = [
                "What's my fasting streak?",
                "How many fasts did I complete this month?",
                "What's my longest fast?"
            ]

        case .goal:
            suggestions = [
                "When will I reach my goal?",
                "What's my progress rate?",
                "What can I do to improve?"
            ]

        case .comparison:
            suggestions = [
                "What else changed this week?",
                "How does fasting affect my progress?",
                "Show me the last 30 days"
            ]

        case .general:
            suggestions = [
                "What's my lowest weight?",
                "How many fasts this month?",
                "Am I trending up or down?"
            ]

        case .unknown:
            suggestions = [
                "What's my current weight?",
                "How am I doing overall?",
                "What should I focus on?"
            ]
        }

        return suggestions
    }

    /// Clear conversation history
    /// Call when user starts new chat or resets conversation
    func clearHistory() {
        history.removeAll()
        context = ConversationContext()
    }

    // MARK: - Context Helpers

    /// Get last user query (if exists)
    var lastUserQuery: String? {
        context.lastQuery
    }

    /// Get last assistant answer (if exists)
    var lastAssistantAnswer: String? {
        context.lastAnswer
    }

    /// Check if conversation has history
    var hasHistory: Bool {
        !history.isEmpty
    }

    /// Get current topic
    var currentTopic: ConversationTopic {
        context.currentTopic
    }

    /// Get conversation age (time since last interaction)
    var conversationAge: TimeInterval? {
        guard let lastTime = context.lastInteractionTime else { return nil }
        return Date().timeIntervalSince(lastTime)
    }
}

// MARK: - Conversation Manager Extensions

extension ConversationManager {

    /// Generate contextual reference to previous answer
    /// **Industry Pattern:** ChatGPT "As I mentioned earlier..."
    /// - Returns: Contextual reference phrase (or nil if no context)
    func generateContextualReference() -> String? {
        // Check if context has a last query (intentionally unused for now, reserved for future enhancement)
        guard context.lastQuery != nil else { return nil }

        // Simple topic-based references
        switch context.currentTopic {
        case .weight:
            return "Based on your weight data"
        case .fasting:
            return "Looking at your fasting history"
        case .goal:
            return "Considering your goal progress"
        case .comparison:
            return "Comparing to previous periods"
        case .general:
            return "From your overall stats"
        case .unknown:
            return nil
        }
    }

    /// Check if enough time passed to greet user again
    /// **Logic:** If >24 hours, use greeting. Otherwise, skip.
    var shouldGreetUser: Bool {
        guard let age = conversationAge else { return true }
        return age > 86400  // 24 hours
    }
}

// MARK: - Sample Data (Testing/Previews)

#if DEBUG
extension ConversationManager {
    static var preview: ConversationManager {
        let manager = ConversationManager()

        // Add sample conversation
        manager.addMessage(ChatMessage(
            id: UUID(),
            sender: .user,
            content: "What's my lowest weight?",
            timestamp: Date().addingTimeInterval(-300)
        ))

        manager.addMessage(ChatMessage(
            id: UUID(),
            sender: .assistant,
            content: "Your lowest weight was 175.2 lbs on Jan 15, 2025.",
            timestamp: Date().addingTimeInterval(-290),
            emotion: .stable
        ))

        manager.addMessage(ChatMessage(
            id: UUID(),
            sender: .user,
            content: "How many fasts did I do this month?",
            timestamp: Date().addingTimeInterval(-60)
        ))

        manager.addMessage(ChatMessage(
            id: UUID(),
            sender: .assistant,
            content: "You completed 18 fasts this month. Great consistency!",
            timestamp: Date().addingTimeInterval(-50),
            emotion: .energized
        ))

        return manager
    }
}
#endif
