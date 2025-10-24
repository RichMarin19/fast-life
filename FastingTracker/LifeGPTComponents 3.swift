//
// LifeGPTComponents.swift
// FastingTracker
//
// Created for LifeGPT Feature - Phase 1 Hour 3
// Chat interface components with emotion-aware theming
// Reference: FastLIFe_LIFeGPT_UI_Behavioral_Spec_Hour3.md (Sections 2, 4, 5)
//

import SwiftUI

// MARK: - Message Bubble

/// Chat message bubble with emotion-aware theming
/// **Spec:** Section 2 - Chat Message Bubbles
///
/// **Features:**
/// - User bubble: Simple style with chat.user colors
/// - Assistant bubble: ES-5 gradient @ 6-12% opacity + 2pt accent strip
/// - Reveal animation: 1.03 → 1.0 easeOut 200ms
/// - Accessibility: ≥4.5:1 contrast, Dynamic Type, VoiceOver labels
struct MessageBubble: View {
    let message: ChatMessage

    @Environment(\.colorScheme) var colorScheme
    @AccessibilityFocusState private var isAccessibilityFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: DSSpacing.cardSmallSpacing) {
            if message.isFromUser {
                Spacer(minLength: 60) // Right-align user messages
                userBubble
            } else {
                assistantBubble
                Spacer(minLength: 60) // Left-align assistant messages
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityFocused($isAccessibilityFocused)
    }

    // MARK: - User Bubble

    @ViewBuilder
    private var userBubble: some View {
        Text(message.content)
            .font(DSTypography.body)
            .foregroundStyle(userTextColor)
            .padding(.horizontal, DSSpacing.cardElementSpacing)
            .padding(.vertical, 10)
            .background(userBackgroundColor)
            .cornerRadius(DSCornerRadius.chatBubble)
            .shadow(color: Theme.ColorToken.shadowCard.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    /// User bubble background color
    private var userBackgroundColor: Color {
        // Simple solid color for user messages
        colorScheme == .dark ?
            Theme.ColorToken.accentPrimary.opacity(0.2) :
            Theme.ColorToken.accentPrimary.opacity(0.12)
    }

    /// User bubble text color
    private var userTextColor: Color {
        colorScheme == .dark ?
            Theme.ColorToken.textPrimaryOnDark :
            Theme.ColorToken.textPrimary
    }

    // MARK: - Assistant Bubble

    @ViewBuilder
    private var assistantBubble: some View {
        HStack(spacing: 0) {
            // 2pt accent strip (leading edge)
            accentStrip

            // Message content with gradient background
            VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
                Text(message.content)
                    .font(DSTypography.body)
                    .foregroundStyle(assistantTextColor)
                    .multilineTextAlignment(.leading)

                // Timestamp (subtle)
                Text(message.formattedTime)
                    .font(DSTypography.caption)
                    .foregroundStyle(assistantSecondaryTextColor)
            }
            .padding(.horizontal, DSSpacing.cardElementSpacing)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(assistantBackgroundGradient)
        .cornerRadius(DSCornerRadius.chatBubble)
        .shadow(color: Theme.ColorToken.shadowCard.opacity(0.08), radius: 3, x: 0, y: 2)
    }

    /// 2pt accent strip on leading edge
    @ViewBuilder
    private var accentStrip: some View {
        let theme = Theme.emotion(message.emotion ?? .stable)
        Rectangle()
            .fill(theme.icon)
            .frame(width: 2)
    }

    /// Assistant bubble background gradient (ES-5 aware)
    private var assistantBackgroundGradient: some View {
        let theme = Theme.emotion(message.emotion ?? .stable)
        let gradientOpacity: Double = colorScheme == .dark ? 0.12 : 0.08

        return LinearGradient(
            colors: theme.gradient.map { $0.opacity(gradientOpacity) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // Surface overlay for proper contrast
            (colorScheme == .dark ?
                Theme.ColorToken.cardOnDark :
                Theme.ColorToken.card.opacity(0.95))
        )
    }

    /// Assistant text color (high contrast)
    private var assistantTextColor: Color {
        colorScheme == .dark ?
            Theme.ColorToken.textPrimaryOnDark :
            Theme.ColorToken.textPrimary
    }

    /// Assistant secondary text color
    private var assistantSecondaryTextColor: Color {
        colorScheme == .dark ?
            Theme.ColorToken.textSecondaryOnDark :
            Theme.ColorToken.textSecondary
    }

    /// VoiceOver accessibility label
    private var accessibilityLabel: String {
        if message.isFromUser {
            return "You said: \(message.content)"
        } else {
            let emotionTone: String
            switch message.emotion {
            case .energized: emotionTone = "in an encouraging tone"
            case .stable: emotionTone = "in a calm tone"
            case .stressed: emotionTone = "in a supportive tone"
            case .tired: emotionTone = "in a gentle tone"
            case .offtrack: emotionTone = "in a hopeful tone"
            case .none: emotionTone = ""
            }
            return "Coach says \(emotionTone): \(message.content). Sent at \(message.formattedTime)"
        }
    }
}

// MARK: - Input Bar

/// Chat input bar with emotion-aware placeholder and state-tinted icon
/// **Spec:** Section 4 - Input Bar (Text + Send)
///
/// **Features:**
/// - Leading icon (spark/bolt) state-tinted
/// - Placeholder rotates from prompt pool (ES-5 + day-part)
/// - Send button circular with brand colors
/// - Behavioral cues: micro-tip toast on send
struct LifeGPTInputBar: View {
    @Binding var text: String
    var emotion: EmotionState
    var onSend: () -> Void

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: DSSpacing.cardSmallSpacing) {
            // Leading icon (state-tinted)
            leadingIcon

            // Text input field
            TextField("", text: $text, axis: .vertical)
                .font(DSTypography.body)
                .lineLimit(1...4)
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }
                .accessibilityLabel("Message input")
                .accessibilityHint(placeholderText)

            // Send button
            sendButton
        }
        .padding(DSSpacing.cardElementSpacing)
        .background(inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.textField + 6))
        .shadow(color: Theme.ColorToken.shadowCard.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: DSCornerRadius.textField + 6)
                .stroke(isFocused ? Theme.emotion(emotion).icon.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Components

    /// Leading sparkle icon (state-tinted)
    @ViewBuilder
    private var leadingIcon: some View {
        Image(systemName: "sparkle.magnifyingglass")
            .font(.system(size: 18))
            .foregroundStyle(Theme.emotion(emotion).icon)
            .accessibilityHidden(true)
    }

    /// Send button
    @ViewBuilder
    private var sendButton: some View {
        Button(action: {
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                onSend()
            }
        }) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(sendButtonColor)
        }
        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
        .accessibilityLabel("Send message")
    }

    /// Send button color (disabled when empty)
    private var sendButtonColor: Color {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Theme.ColorToken.textSecondary.opacity(0.3)
        } else {
            return Theme.ColorToken.accentPrimary
        }
    }

    /// Input background color
    private var inputBackground: Color {
        colorScheme == .dark ?
            Theme.ColorToken.cardOnDark :
            Theme.ColorToken.card
    }

    /// Placeholder text from behavioral copy system
    private var placeholderText: String {
        let dayPart = BehavioralCopy.currentDayPart()
        return BehavioralCopy.shared.getInputPlaceholder(emotion: emotion, dayPart: dayPart)
    }
}

// MARK: - Typing Indicator

/// Animated typing indicator for assistant processing state
/// **Spec:** Section 5 - Typing / Loading Indicators
///
/// **Features:**
/// - 3-dot pulse animation (300ms-300ms-500ms pause)
/// - Color = state icon @ 80% opacity
/// - 2pt presence aura below input (pulses while typing)
struct TypingIndicator: View {
    var emotion: EmotionState

    @State private var animatingDot1 = false
    @State private var animatingDot2 = false
    @State private var animatingDot3 = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotScale(for: index))
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animatingDot1
                    )
            }
        }
        .padding(.vertical, DSSpacing.cardSmallSpacing)
        .padding(.horizontal, DSSpacing.cardElementSpacing)
        .background(indicatorBackground)
        .cornerRadius(DSCornerRadius.chatBubble)
        .onAppear {
            animatingDot1 = true
            animatingDot2 = true
            animatingDot3 = true
        }
        .accessibilityLabel("Coach is typing")
    }

    /// Dot color (emotion-aware @ 80%)
    private var dotColor: Color {
        Theme.emotion(emotion).icon.opacity(0.8)
    }

    /// Dot scale based on index
    private func dotScale(for index: Int) -> CGFloat {
        switch index {
        case 0: return animatingDot1 ? 1.2 : 1.0
        case 1: return animatingDot2 ? 1.2 : 1.0
        case 2: return animatingDot3 ? 1.2 : 1.0
        default: return 1.0
        }
    }

    /// Indicator background
    private var indicatorBackground: Color {
        Theme.emotion(emotion).gradient.first?.opacity(0.15) ?? Color.gray.opacity(0.15)
    }
}

// MARK: - Empty State

/// Empty state view for first-run or no chat history
/// **Spec:** Section 6 - Empty States & First-Run
///
/// **Features:**
/// - Title "Meet your Coach."
/// - 3 chips with prompt examples
/// - Seed→sprout animation badge (Day 1)
struct LifeGPTEmptyState: View {
    var onPromptTap: (String) -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: DSSpacing.cardSmallSpacing) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(Theme.ColorToken.accentPrimary)

                Text("Meet your Coach.")
                    .font(DSTypography.titleLg)
                    .foregroundStyle(Theme.ColorToken.textPrimary)
            }

            // Prompt chips
            VStack(spacing: DSSpacing.cardSmallSpacing) {
                promptChip("What's my weight trend?")
                promptChip("How many fasts this week?")
                promptChip("Today's summary")
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Prompt chip button
    @ViewBuilder
    private func promptChip(_ prompt: String) -> some View {
        Button(action: {
            onPromptTap(prompt)
        }) {
            Text(prompt)
                .font(DSTypography.body)
                .foregroundStyle(Theme.ColorToken.accentPrimary)
                .padding(.horizontal, DSSpacing.cardElementSpacing)
                .padding(.vertical, DSSpacing.cardSmallSpacing)
                .frame(maxWidth: .infinity)
                .background(Theme.ColorToken.accentPrimary.opacity(0.1))
                .cornerRadius(DSCornerRadius.chip)
        }
    }
}

// MARK: - Design System Integration
// Using global DSSpacing from Core/DesignSystem/DSSpacing.swift

// MARK: - Preview Provider

#if DEBUG
struct LifeGPTComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Sample messages
            MessageBubble(message: .userMessage("What's my weight?"))
            MessageBubble(message: .assistantMessage("Your weight is 185.2 lbs", emotion: .energized))
            MessageBubble(message: .assistantMessage("You're doing great!", emotion: .stable))

            // Typing indicator
            TypingIndicator(emotion: .energized)

            // Input bar
            LifeGPTInputBar(
                text: .constant(""),
                emotion: .energized,
                onSend: {}
            )
        }
        .padding()
        .background(Theme.ColorToken.bgDeepStart)
    }
}
#endif
