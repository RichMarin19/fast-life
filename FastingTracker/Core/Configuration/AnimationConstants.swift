import Foundation

/// Animation Duration Constants
/// Centralizes all animation timing values for consistent UI motion across the app
/// Following Apple Human Interface Guidelines for animation timing
///
/// Reference: Phase 8.9 Weight Tracker Refactoring (Issues #9-13)
/// Apple HIG: https://developer.apple.com/design/human-interface-guidelines/motion
/// Updated: October 28, 2025

// MARK: - Animation Constants

enum AnimationConstants {

    // MARK: - Standard Durations

    /// Standard animation durations following Apple HIG recommendations
    /// These are the most commonly used animation timings throughout the app
    enum Duration {
        /// Quick transitions (0.25 seconds)
        /// Used for: Simple state changes, button presses, toggles
        /// Examples: Card appearance, view transitions, small UI updates
        /// Rationale: Fast enough to feel responsive, slow enough to be perceptible
        static let quick: Double = 0.25

        /// Standard transitions (0.35 seconds)
        /// Used for: Default animations, view presentations, modal displays
        /// Examples: Sheet presentations, navigation pushes, card flips
        /// Rationale: Apple's recommended duration for most animations
        static let standard: Double = 0.35

        /// Slow transitions (0.4 seconds)
        /// Used for: Dramatic state changes, important UI updates
        /// Examples: Major view changes, data-heavy updates, emphasis animations
        /// Rationale: Gives users time to perceive and understand significant changes
        static let slow: Double = 0.4

        /// Ring animations (1.2 seconds)
        /// Used for: Progress rings, circular progress indicators
        /// Examples: Weight progress ring, milestone rings, achievement animations
        /// Rationale: Longer duration emphasizes progress and creates satisfying visual feedback
        static let ring: Double = 1.2

        /// Breathe animation cycle (5.0 seconds)
        /// Used for: Subtle pulsing effects, attention-drawing elements
        /// Examples: Breathe circle, ambient animations, idle state pulses
        /// Rationale: Slow, calming rhythm that doesn't distract from content
        static let breathe: Double = 5.0
    }

    // MARK: - Spring Animations

    /// Spring animation parameters for natural, physics-based motion
    /// Following Apple's recommendations for spring animations
    enum Spring {
        /// Quick spring response (0.3)
        /// Used for: Snappy interactions, button feedback
        static let quickResponse: Double = 0.3

        /// Standard spring response (0.5)
        /// Used for: Most spring animations, default choice
        static let standardResponse: Double = 0.5

        /// Bouncy spring response (0.6)
        /// Used for: Playful interactions, celebration animations
        static let bouncyResponse: Double = 0.6

        /// Slow spring response (0.8)
        /// Used for: Gentle, smooth animations
        static let slowResponse: Double = 0.8

        // Damping Fractions

        /// Light damping (0.6) - More bounce
        /// Used for: Energetic, playful animations
        static let lightDamping: Double = 0.6

        /// Standard damping (0.7) - Balanced bounce
        /// Used for: Most spring animations, default choice
        static let standardDamping: Double = 0.7

        /// Heavy damping (0.8) - Less bounce
        /// Used for: Professional, subdued animations
        static let heavyDamping: Double = 0.8

        /// Critical damping (1.0) - No bounce
        /// Used for: Smooth, non-bouncy spring animations
        static let criticalDamping: Double = 1.0
    }

    // MARK: - Delays

    /// Delay constants for sequential or staggered animations
    enum Delay {
        /// Micro delay (0.05 seconds)
        /// Used for: Staggered list animations, cascading effects
        static let micro: Double = 0.05

        /// Short delay (0.1 seconds)
        /// Used for: Sequential animations, slight offsets
        static let short: Double = 0.1

        /// Medium delay (0.2 seconds)
        /// Used for: Noticeable sequential effects
        static let medium: Double = 0.2

        /// Long delay (0.5 seconds)
        /// Used for: Deliberate pauses between animation steps
        static let long: Double = 0.5
    }

    // MARK: - Easing Curves

    /// Animation easing curve timing functions
    /// These match SwiftUI's Animation types for consistency
    enum Easing {
        // Note: SwiftUI uses Animation enum, but we document common timing functions here

        /// Linear timing - constant speed throughout
        /// Used for: Mechanical movements, loading indicators
        /// Mathematical: y = x
        static let linear: String = "linear"

        /// Ease in - starts slow, accelerates
        /// Used for: Elements entering the screen
        /// Mathematical: y = x²
        static let easeIn: String = "easeIn"

        /// Ease out - starts fast, decelerates
        /// Used for: Elements leaving the screen, settling animations
        /// Mathematical: y = 1 - (1-x)²
        static let easeOut: String = "easeOut"

        /// Ease in-out - starts slow, fast middle, ends slow
        /// Used for: Most general animations, smooth transitions
        /// Mathematical: Combination of ease-in and ease-out
        static let easeInOut: String = "easeInOut"
    }

    // MARK: - Weight Tracker Specific

    /// Animation durations specific to Weight Tracker features
    enum WeightTracker {
        /// Progress card update animation (0.35 seconds)
        /// Used for: Weight progress card data updates
        static let progressUpdate: Double = Duration.standard

        /// Chart data transition (0.4 seconds)
        /// Used for: Chart data point updates, time range changes
        static let chartTransition: Double = Duration.slow

        /// Goal line animation (0.3 seconds)
        /// Used for: Goal line appearance/movement
        static let goalLine: Double = 0.3

        /// Weight entry submission (0.25 seconds)
        /// Used for: Weight entry form submission feedback
        static let entrySubmission: Double = Duration.quick

        /// Trend arrow animation (0.2 seconds)
        /// Used for: Trend arrow direction changes
        static let trendArrow: Double = 0.2

        /// History list appearance (0.3 seconds with 0.05s stagger)
        /// Used for: Weight history list items appearing
        static let historyListItem: Double = 0.3
        static let historyListStagger: Double = Delay.micro
    }

    // MARK: - Haptic Feedback Timing

    /// Delay values that pair well with haptic feedback
    /// Ensures animation and haptic feedback feel synchronized
    enum Haptic {
        /// Haptic + quick animation pairing
        static let quick: Double = 0.25

        /// Haptic + standard animation pairing
        static let standard: Double = 0.35

        /// Delay before haptic for success animations
        /// Allows visual animation to begin before haptic emphasis
        static let successDelay: Double = 0.1

        /// Delay before haptic for error animations
        /// Immediate haptic for errors (no delay)
        static let errorDelay: Double = 0.0
    }
}
