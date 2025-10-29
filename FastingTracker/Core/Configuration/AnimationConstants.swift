//
// AnimationConstants.swift
// FastLIFe
//
// Created for UI/UX Animation Standardization
// Single source of truth for animation durations, spring parameters, and timing curves
// Reference: SESSION-PREFERENCES.md - Always use tokens for centralized constants
//

import Foundation

/// Animation constants for consistent UI/UX feel across the app
/// **Single Source of Truth:** All animation-related constants centralized here
/// **Industry Pattern:** Apple HIG animation guidelines, iOS standard spring parameters
enum AnimationConstants {

    // MARK: - Animation Durations

    enum Duration {
        /// Standard animation duration for most UI transitions
        /// **Apple Pattern:** 0.3s standard for modal presentations, sheet transitions
        /// **iOS Standard:** Default UIView.animate duration
        static let standard: Double = 0.3  // 0.3 seconds

        /// Quick animation for small UI changes
        /// **Purpose:** Button presses, toggle switches, small scale changes
        /// **iOS Standard:** Haptic feedback timing alignment
        static let quick: Double = 0.15  // 0.15 seconds

        /// Slow animation for large content changes
        /// **Purpose:** Page transitions, large view changes
        /// **Apple Pattern:** Navigation controller push/pop duration
        static let slow: Double = 0.5  // 0.5 seconds
    }

    // MARK: - Spring Animation Parameters

    enum Spring {
        /// Quick response for snappy animations
        /// **Purpose:** Badge bounce, button scale effects
        /// **Apple Pattern:** iOS spring animations feel responsive and natural
        static let quickResponse: Double = 0.3  // 0.3 seconds

        /// Standard response for smooth animations
        /// **Purpose:** Sheet presentations, view transitions
        /// **iOS Standard:** Default spring response
        static let standardResponse: Double = 0.5  // 0.5 seconds

        /// Slow response for gentle animations
        /// **Purpose:** Large content slides, drawer animations
        static let slowResponse: Double = 0.7  // 0.7 seconds

        /// Light damping for bouncy feel
        /// **Purpose:** Playful animations, badge effects
        /// **Range:** 0.0 (oscillates) to 1.0 (critically damped)
        static let lightDamping: Double = 0.6  // Bouncy

        /// Standard damping for balanced feel
        /// **Purpose:** Most UI animations
        /// **iOS Standard:** Balanced between bounce and smoothness
        static let standardDamping: Double = 0.8  // Smooth with slight bounce

        /// Heavy damping for no bounce
        /// **Purpose:** Professional, serious UI elements
        /// **Apple Pattern:** Settings app, system preferences
        static let heavyDamping: Double = 1.0  // No bounce (critically damped)
    }
}
