//
// EmotionState.swift
// FastingTracker
//
// Created for LifeGPT Feature - Phase 1 Hour 3
// ES-5 Emotion System for adaptive UI theming
// Reference: FastLIFe_LIFeGPT_UI_Behavioral_Spec_Hour3.md
//

import SwiftUI

// MARK: - Emotion State (ES-5 System)

/// Five-state emotion system for adaptive UI theming
/// Maps user's current state to appropriate visual theme, copy, and motion
///
/// **Industry Pattern:**
/// - Behavioral design (BJ Fogg - Tiny Habits)
/// - Emotion-aware interfaces (Apple Health insights, Calm app)
/// - Sentiment-driven UX (Google Material Design emotional states)
///
/// **Usage:**
/// ```swift
/// let theme = Theme.emotion(.energized)
/// Text("You're on a roll!")
///     .foregroundStyle(theme.textPrimary)
///     .background(LinearGradient(colors: theme.gradient, ...))
/// ```
enum EmotionState: String, Codable, CaseIterable {
    /// **Energized (↑)** - Improving trend, positive momentum
    /// - **When Used:** Weight loss progress, fasting streaks, improving sleep
    /// - **Emotion:** Upbeat, future-oriented, celebratory
    /// - **Copy Tone:** "Momentum looks great!", "You're on fire!"
    /// - **Motion:** Springy micro-celebrations, upward parallax
    case energized

    /// **Stable (→)** - Maintenance mode, no significant change
    /// - **When Used:** Weight maintenance, consistent habits, steady state
    /// - **Emotion:** Calm, rhythmic, mastery
    /// - **Copy Tone:** "Keep the rhythm", "Consistency is powerful"
    /// - **Motion:** Calm easeInOut, breathing animation
    case stable

    /// **Stressed (⚠︎)** - Volatility, overwhelm, inconsistency
    /// - **When Used:** Weight fluctuations, irregular sleep, missed workouts
    /// - **Emotion:** Grounding, supportive, non-judgmental
    /// - **Copy Tone:** "One thing at a time", "Short walks lower stress fast"
    /// - **Motion:** Gentle breathing animation, soft pulse
    case stressed

    /// **Tired (⌁)** - Low energy, poor sleep, need for recovery
    /// - **When Used:** Low sleep duration, low activity, fatigue signals
    /// - **Emotion:** Restorative, gentle, understanding
    /// - **Copy Tone:** "Gentle start", "Sunlight break or micro-nap?"
    /// - **Motion:** Slow fade, low amplitude movement
    case tired

    /// **Off-track (↓)** - Regression, >72h idle, negative trend
    /// - **When Used:** Weight gain (when losing goal), long idle periods
    /// - **Emotion:** Reframe, hope beacon, small wins focus
    /// - **Copy Tone:** "Zero guilt", "One small choice now"
    /// - **Motion:** Minimal motion, subtle hope indicator
    case offtrack

    /// Display symbol for UI
    var symbol: String {
        switch self {
        case .energized: return "↑"
        case .stable: return "→"
        case .stressed: return "⚠︎"
        case .tired: return "⌁"
        case .offtrack: return "↓"
        }
    }

    /// Display name for debugging/analytics
    var displayName: String {
        switch self {
        case .energized: return "Energized"
        case .stable: return "Stable"
        case .stressed: return "Stressed"
        case .tired: return "Tired"
        case .offtrack: return "Off-track"
        }
    }
}

// MARK: - Emotion Theme

/// Visual theme for a given emotion state
/// Contains all design tokens needed to render emotion-aware UI
///
/// **Components:**
/// - `gradient`: Background gradient colors (apply at 6-12% opacity)
/// - `textPrimary`: High-contrast text color
/// - `textSecondary`: Supporting text color
/// - `icon`: Icon tint color (state-specific)
/// - `motionStyle`: Animation style for this emotion
///
/// **Design System Integration:**
/// All colors reference Theme.ColorToken (existing mood gradients)
struct EmotionTheme {
    /// Background gradient colors (2-color array for LinearGradient)
    /// Apply at 6-12% opacity over surface color
    let gradient: [Color]

    /// Primary text color (high contrast)
    /// WCAG AA: ≥4.5:1 contrast ratio
    let textPrimary: Color

    /// Secondary text color (supporting)
    /// WCAG AA: ≥4.5:1 contrast ratio
    let textSecondary: Color

    /// Icon tint color (state-specific)
    /// Used for state indicators, leading icons, accents
    let icon: Color

    /// Motion/animation style for this emotion
    /// Maps to DSMotion system (defined below)
    let motionStyle: MotionStyle
}

// MARK: - Motion Style

/// Animation style for emotion states
/// Maps to existing DSMotion patterns (or defines new ones)
enum MotionStyle: String, Codable {
    /// Bubble reveal - Upward micro-parallax with springy celebration
    /// Used for: Energized, Stable
    /// Effect: 1.03 → 1.0 scale, upward slide, haptic feedback
    case bubbleReveal

    /// Feedback subtle - Gentle breathing animation
    /// Used for: Stressed, Tired
    /// Effect: Slow fade, low amplitude pulse, calming
    case feedbackSubtle

    /// None - Minimal motion (Reduce Motion fallback)
    /// Used for: Off-track, Reduce Motion setting
    /// Effect: Fade-only transitions
    case none

    /// Animation duration in seconds
    var duration: Double {
        switch self {
        case .bubbleReveal: return 0.22 // Standard spring animation
        case .feedbackSubtle: return 0.4 // Slower, calming
        case .none: return 0.12 // Quick fade
        }
    }

    /// Spring animation response value
    var springResponse: Double {
        switch self {
        case .bubbleReveal: return 0.35 // Bouncy
        case .feedbackSubtle: return 0.6 // Gentle
        case .none: return 0.0 // No spring
        }
    }

    /// Spring animation damping fraction
    var springDamping: Double {
        switch self {
        case .bubbleReveal: return 0.7 // Slight overshoot
        case .feedbackSubtle: return 0.9 // Minimal overshoot
        case .none: return 1.0 // No overshoot
        }
    }
}

// MARK: - Theme Extension (Emotion Mapping)

extension Theme {
    /// Map emotion state to visual theme
    /// **Single Source of Truth** for ES-5 theming
    ///
    /// **Design Token Mapping:**
    /// - Energized → Theme.ColorToken.moodImproving* (teal/blue gradient)
    /// - Stable → Theme.ColorToken.moodStable* (gold gradient)
    /// - Stressed → Theme.ColorToken.moodRegressing* (coral/peach gradient) - repurposed as "care" colors
    /// - Tired → New restore colors (soft blue-gray) - using moodStable with different motion
    /// - Off-track → Theme.ColorToken.moodRegressing* (coral/peach gradient)
    ///
    /// - Parameter state: Emotion state to map
    /// - Returns: EmotionTheme with colors, motion, and design tokens
    static func emotion(_ state: EmotionState) -> EmotionTheme {
        switch state {
        case .energized:
            return EmotionTheme(
                gradient: [ColorToken.moodImprovingStart, ColorToken.moodImprovingEnd],
                textPrimary: ColorToken.textPrimary,
                textSecondary: ColorToken.textSecondary,
                icon: ColorToken.moodImprovingEnd,
                motionStyle: .bubbleReveal
            )

        case .stable:
            return EmotionTheme(
                gradient: [ColorToken.moodStableStart, ColorToken.moodStableEnd],
                textPrimary: ColorToken.textPrimary,
                textSecondary: ColorToken.textSecondary,
                icon: ColorToken.moodStableEnd,
                motionStyle: .bubbleReveal
            )

        case .stressed:
            return EmotionTheme(
                gradient: [ColorToken.moodRegressingStart, ColorToken.moodRegressingEnd],
                textPrimary: ColorToken.textPrimary,
                textSecondary: ColorToken.textSecondary,
                icon: ColorToken.accentCoral,
                motionStyle: .feedbackSubtle
            )

        case .tired:
            // Reuse stable colors but with different motion (calming)
            // TODO Phase 2: Add dedicated restore colors (soft blue-gray)
            return EmotionTheme(
                gradient: [ColorToken.moodStableStart.opacity(0.7), ColorToken.moodStableEnd.opacity(0.7)],
                textPrimary: ColorToken.textPrimary,
                textSecondary: ColorToken.textSecondary,
                icon: ColorToken.moodStableStart,
                motionStyle: .feedbackSubtle
            )

        case .offtrack:
            return EmotionTheme(
                gradient: [ColorToken.moodRegressingStart, ColorToken.moodRegressingEnd],
                textPrimary: ColorToken.textPrimary,
                textSecondary: ColorToken.textSecondary,
                icon: ColorToken.accentCoral,
                motionStyle: .none
            )
        }
    }
}

// MARK: - View Extension (Motion Helpers)

extension View {
    /// Apply emotion-aware motion to view
    /// Respects system Reduce Motion setting
    ///
    /// - Parameters:
    ///   - motionStyle: Motion style from EmotionTheme
    ///   - isReduceMotionEnabled: Whether Reduce Motion is enabled (default: system setting)
    /// - Returns: View with applied animation
    func emotionMotion(_ motionStyle: MotionStyle, isReduceMotionEnabled: Bool = false) -> some View {
        Group {
            if isReduceMotionEnabled || motionStyle == .none {
                // Reduce Motion: Fade-only
                self.transition(.opacity)
                    .animation(.easeInOut(duration: 0.12), value: UUID())
            } else {
                switch motionStyle {
                case .bubbleReveal:
                    // Springy reveal animation
                    self.transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: motionStyle.springResponse, dampingFraction: motionStyle.springDamping), value: UUID())

                case .feedbackSubtle:
                    // Gentle fade animation
                    self.transition(.opacity)
                        .animation(.easeInOut(duration: motionStyle.duration), value: UUID())

                case .none:
                    // Minimal motion
                    self.transition(.opacity)
                        .animation(.easeInOut(duration: motionStyle.duration), value: UUID())
                }
            }
        }
    }
}

// MARK: - Sample Data (Preview/Testing)

#if DEBUG
extension EmotionState {
    /// Sample emotion states for testing all themes
    static let samples: [(EmotionState, String)] = [
        (.energized, "Weight down 3 lbs this week! 🎉"),
        (.stable, "Maintaining your rhythm. Keep it up!"),
        (.stressed, "Take it one step at a time. You've got this."),
        (.tired, "Rest is part of progress. Be gentle with yourself."),
        (.offtrack, "No guilt. Just one small choice today.")
    ]
}
#endif
