//
// CoachInviteCard.swift
// FastingTracker
//
// Created for LifeGPT Feature - Phase 1 Hour 3
// Hub entry card for LifeGPT AI Health Coach
// Reference: FastLIFe_LIFeGPT_UI_Behavioral_Spec_Hour3.md (Section 3)
//

import SwiftUI

// MARK: - Coach Invite Card

/// Hub entry card for LifeGPT chat interface
/// **Spec:** Section 3 - Hub Coach Card (Entry to Chat)
///
/// **Features:**
/// - Fixed at top of Hub (above trackers)
/// - 72-88pt height (expands), 40-44pt chip (collapsed)
/// - Left icon brain.head.profile (state-tinted)
/// - Rotating prompt per day-part + state
/// - ES-5 gradient background (12-18% opacity over surface)
/// - Shimmer animation on first daily open (600ms micro-reward)
/// - Tap opens LIFeGPTChatView with seeded prompt
///
/// **Industry Pattern:**
/// - Apple Fitness+ (coaching cards)
/// - Duolingo (daily goal reminders)
/// - Calm (daily mindfulness prompts)
struct CoachInviteCard: View {
    var emotion: EmotionState
    var onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var hasShimmered = false

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DSSpacing.cardElementSpacing) {
                // Leading icon (state-tinted)
                leadingIcon

                // Content (title + prompt)
                VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
                    title
                    prompt
                }

                Spacer()

                // Trailing chevron
                trailingChevron
            }
            .padding(.horizontal, DSSpacing.cardPadding)
            .padding(.vertical, DSSpacing.cardPadding)
            .background(cardBackground)
            .cornerRadius(DSCornerRadius.card)
            .shadow(color: Theme.ColorToken.shadowCard.opacity(0.12), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(CoachCardButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens AI health coach chat")
        .onAppear {
            // Shimmer effect on first daily appearance
            if !hasShimmered && shouldShowShimmer {
                performShimmer()
            }
        }
    }

    // MARK: - Components

    /// Leading brain icon (state-tinted)
    @ViewBuilder
    private var leadingIcon: some View {
        Image(systemName: "brain.head.profile")
            .font(.system(size: 36, weight: .light))
            .foregroundStyle(Theme.emotion(emotion).icon)
            .accessibilityHidden(true)
    }

    /// Card title
    @ViewBuilder
    private var title: some View {
        Text("Ask Your Coach")
            .font(DSTypography.cardTitle)
            .foregroundStyle(titleColor)
    }

    /// Rotating prompt (ES-5 × day-part)
    @ViewBuilder
    private var prompt: some View {
        Text(promptText)
            .font(DSTypography.cardSubtitle)
            .foregroundStyle(promptColor)
            .lineLimit(1)
    }

    /// Trailing chevron
    @ViewBuilder
    private var trailingChevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.emotion(emotion).icon.opacity(0.6))
            .accessibilityHidden(true)
    }

    // MARK: - Background

    /// Card background with ES-5 gradient
    @ViewBuilder
    private var cardBackground: some View {
        ZStack {
            // Base surface color
            (colorScheme == .dark ?
                Theme.ColorToken.cardOnDark :
                Theme.ColorToken.card)

            // ES-5 gradient overlay (12-18% opacity)
            LinearGradient(
                colors: Theme.emotion(emotion).gradient.map { $0.opacity(gradientOpacity) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Gradient opacity based on color scheme
    private var gradientOpacity: Double {
        colorScheme == .dark ? 0.18 : 0.12
    }

    // MARK: - Colors

    /// Title text color
    private var titleColor: Color {
        colorScheme == .dark ?
            Theme.ColorToken.textPrimaryOnDark :
            Theme.ColorToken.textPrimary
    }

    /// Prompt text color
    private var promptColor: Color {
        colorScheme == .dark ?
            Theme.ColorToken.textSecondaryOnDark :
            Theme.ColorToken.textSecondary
    }

    // MARK: - Content

    /// Prompt text from behavioral copy system
    private var promptText: String {
        let dayPart = BehavioralCopy.currentDayPart()
        return BehavioralCopy.shared.getPrompt(emotion: emotion, dayPart: dayPart)
    }

    /// VoiceOver accessibility label
    private var accessibilityLabel: String {
        "Ask Your Coach. \(promptText)"
    }

    // MARK: - Shimmer Animation

    /// Whether to show shimmer (first daily open)
    /// TODO Phase 2: Track in UserDefaults
    private var shouldShowShimmer: Bool {
        // For Phase 1, show shimmer on first app launch
        // Phase 2: Track last shimmer date in UserDefaults
        return !hasShimmered
    }

    /// Perform shimmer animation (600ms micro-reward)
    private func performShimmer() {
        withAnimation(.easeInOut(duration: 0.6)) {
            hasShimmered = true
        }
        // TODO: Add actual shimmer effect (gradient sweep)
        // For Phase 1, just tracking state
    }
}

// MARK: - Button Style

/// Custom button style for coach card
/// Provides subtle scale feedback on press
struct CoachCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Design System Integration
// Using global DSSpacing from Core/DesignSystem/DSSpacing.swift

// MARK: - Compact Variant (Collapsed Chip)

/// Compact chip variant for scrolled state
/// **Spec:** 40-44pt height, minimal content
///
/// **Phase 2 Enhancement:**
/// - Collapse to chip on Hub scroll
/// - Expand back to full card on scroll up
/// - Smooth transition animation
struct CoachInviteChip: View {
    var emotion: EmotionState
    var onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: DSSpacing.cardSmallSpacing) {
                // Icon (smaller)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.emotion(emotion).icon)

                // Title only (no prompt in chip)
                Text("Coach")
                    .font(DSTypography.cardSubtitle)
                    .foregroundStyle(textColor)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.emotion(emotion).icon.opacity(0.6))
            }
            .padding(.horizontal, DSSpacing.cardElementSpacing)
            .padding(.vertical, 10)
            .background(chipBackground)
            .cornerRadius(DSCornerRadius.button)
            .shadow(color: Theme.ColorToken.shadowCard.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(CoachCardButtonStyle())
        .accessibilityLabel("Ask Coach")
    }

    private var chipBackground: some View {
        ZStack {
            (colorScheme == .dark ?
                Theme.ColorToken.cardOnDark :
                Theme.ColorToken.card)

            LinearGradient(
                colors: Theme.emotion(emotion).gradient.map { $0.opacity(0.12) },
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private var textColor: Color {
        colorScheme == .dark ?
            Theme.ColorToken.textPrimaryOnDark :
            Theme.ColorToken.textPrimary
    }
}

// MARK: - Preview Provider

#if DEBUG
struct CoachInviteCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Full card variants
            CoachInviteCard(emotion: .energized, onTap: {})
            CoachInviteCard(emotion: .stable, onTap: {})
            CoachInviteCard(emotion: .stressed, onTap: {})

            // Chip variant
            CoachInviteChip(emotion: .energized, onTap: {})
        }
        .padding()
        .background(Theme.ColorToken.bgDeepStart)
        .preferredColorScheme(.dark)
    }
}
#endif
