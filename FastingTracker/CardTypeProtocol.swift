import Foundation

// MARK: - Card Type Protocol

/// Protocol for all card type enums (TrackerCardType, ProgressStoryCardType, etc.)
/// Enables generic CardManager to work with any card type
/// Industry Pattern: Protocol-oriented design (Apple Swift WWDC 2015)
/// Reference: https://developer.apple.com/videos/play/wwdc2015/408/
///
/// ARCHITECTURE DECISION (ADR-001):
/// This protocol enables a single unified CardManager to replace:
/// - TrackerCardManager (for main tracker cards)
/// - ProgressStoryCardManager (for Progress Story cards)
///
/// Benefits:
/// - ✅ DRY (Don't Repeat Yourself) - No duplicate manager logic
/// - ✅ SSOT (Single Source of Truth) - One implementation
/// - ✅ Industry Standard - Apple/Google/Stripe use this pattern
/// - ✅ Future-Proof - Works for all 5 trackers (Weight, Fasting, Hydration, Sleep, Mood)
///
/// Usage:
/// ```
/// // Define card type enum
/// enum MyCardType: String, CaseIterable, CardTypeProtocol {
///     case card1 = "card1"
///     case card2 = "card2"
///
///     var displayName: String {
///         switch self {
///         case .card1: return "Card 1"
///         case .card2: return "Card 2"
///         }
///     }
/// }
///
/// // Create manager instance
/// let manager = CardManager<MyCardType>(preferencesKey: "myCardPreferences_v1")
///
/// // Use manager
/// manager.isCardVisible(.card1)  // → true/false
/// manager.hideCard(.card1)
/// manager.reorderCards(from: 0, to: 2)
/// ```
protocol CardTypeProtocol: Hashable, CaseIterable, RawRepresentable where RawValue == String {
    /// Display name for card (shown in DSCardHeader)
    /// Must be human-readable (e.g., "Current Weight", "7-Day Trend")
    var displayName: String { get }
}
