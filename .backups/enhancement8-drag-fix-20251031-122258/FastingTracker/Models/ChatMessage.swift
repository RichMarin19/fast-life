//
// ChatMessage.swift
// FastingTracker
//
// Created for LifeGPT Feature - Phase 1
// Simple message model for chat interface
//

import Foundation

// MARK: - Chat Message Model

/// Represents a single message in the LifeGPT chat
/// Following Swift best practices: Struct for value types, Cod able for persistence
struct ChatMessage: Identifiable, Codable, Equatable {

    // MARK: - Properties

    /// Unique identifier for the message
    let id: UUID

    /// Sender of the message (user or assistant)
    let sender: MessageSender

    /// Content of the message
    let content: String

    /// Timestamp when message was sent
    let timestamp: Date

    /// Optional metadata (for future use: query type, data sources, etc.)
    var metadata: [String: String]?

    /// Emotion state for assistant messages (nil for user messages)
    /// Used for emotion-aware theming in UI
    var emotion: EmotionState?

    // MARK: - Initialization

    /// Initialize a new chat message
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - sender: Who sent the message
    ///   - content: Message text
    ///   - timestamp: When message was sent (defaults to now)
    ///   - metadata: Optional metadata dictionary
    ///   - emotion: Emotion state for theming (assistant messages only)
    init(
        id: UUID = UUID(),
        sender: MessageSender,
        content: String,
        timestamp: Date = Date(),
        metadata: [String: String]? = nil,
        emotion: EmotionState? = nil
    ) {
        self.id = id
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
        self.metadata = metadata
        self.emotion = emotion
    }

    // MARK: - Convenience Initializers

    /// Create a user message
    /// - Parameter content: Message text
    /// - Returns: ChatMessage from user
    static func userMessage(_ content: String) -> ChatMessage {
        ChatMessage(sender: .user, content: content)
    }

    /// Create an assistant message
    /// - Parameters:
    ///   - content: Message text
    ///   - emotion: Emotion state for theming (default: .stable)
    /// - Returns: ChatMessage from assistant with emotion
    static func assistantMessage(_ content: String, emotion: EmotionState = .stable) -> ChatMessage {
        ChatMessage(sender: .assistant, content: content, emotion: emotion)
    }

    // MARK: - Computed Properties

    /// Whether this message is from the user
    var isFromUser: Bool {
        sender == .user
    }

    /// Whether this message is from the assistant
    var isFromAssistant: Bool {
        sender == .assistant
    }

    /// Formatted timestamp string for display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Message Sender

/// Who sent the message
enum MessageSender: String, Codable, Equatable {
    /// Message from the user
    case user

    /// Message from the AI assistant
    case assistant

    /// Display name for the sender
    var displayName: String {
        switch self {
        case .user:
            return "You"
        case .assistant:
            return "LifeGPT"
        }
    }
}

// MARK: - Sample Data (Preview/Testing)

extension ChatMessage {
    /// Sample messages for SwiftUI previews and testing
    static let samples: [ChatMessage] = [
        .userMessage("What's my current weight?"),
        .assistantMessage("Your current weight is 185.2 lbs as of October 23, 2025."),
        .userMessage("How many fasts did I complete this week?"),
        .assistantMessage("You completed 5 fasting sessions this week! Great job staying consistent."),
        .userMessage("Show me my sleep trends"),
        .assistantMessage("Here's your sleep summary:\n• Average: 7.2 hours per night\n• Best: 8.5 hours\n• Consistency: 85%")
    ]

    /// Sample conversation for testing
    static let sampleConversation: [ChatMessage] = [
        .assistantMessage("Hi! I'm LifeGPT, your AI health coach. I can help you understand your weight, fasting, sleep, hydration, and mood data. What would you like to know?"),
        .userMessage("What's my weight trend?"),
        .assistantMessage("Your weight has decreased by 3.2 lbs over the last 30 days. You're trending in the right direction! Keep up the great work."),
        .userMessage("What about my fasting?"),
        .assistantMessage("You've completed 18 fasting sessions this month, averaging 16.5 hours per fast. Your longest streak was 7 days in a row!")
    ]
}
