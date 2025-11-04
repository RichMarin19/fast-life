import SwiftUI
import UIKit

/// ViewModel for Badge Interactions in Weight Control Center
/// Handles badge highlighting, scrolling, and animations
/// Extracted from WeightControlCenterViewModel as part of Phase 8.9 Phase 2
/// Reference: HANDOFF.md - Weight Tracker Refactoring
@MainActor
class BadgesViewModel: ObservableObject {
    // MARK: - Published State

    /// Current index in the highlighted items cycle
    @Published var currentHighlightedItemIndex: Int = 0

    /// ID of the currently highlighted item (for gold border)
    @Published var highlightedItemID: String?

    /// Scroll view proxy for programmatic scrolling
    @Published var scrollViewProxy: ScrollViewProxy?

    /// Badge scale for bounce animation (1.0 = normal, 1.15 = bounced)
    @Published var badgeScale: CGFloat = 1.0

    // MARK: - Badge Interaction

    /// Cycle to next opted-out item when badge is tapped
    /// Industry pattern: Instagram stories badge, Spotify playlist scroll
    /// - Parameter optedOutItems: All opted-out items in visual top-to-bottom order
    func cycleToNextOptedOutItem(_ optedOutItems: [ContentItem]) {
        guard !optedOutItems.isEmpty else { return }

        // Get the target item to scroll to (use CURRENT index before incrementing)
        let targetItem = optedOutItems[currentHighlightedItemIndex]

        // Increment index BEFORE UI operations (so tests can verify immediately)
        currentHighlightedItemIndex = (currentHighlightedItemIndex + 1) % optedOutItems.count

        // Layer 3: Set highlighted item ID for gold border (works with or without scrolling)
        highlightedItemID = targetItem.id

        // Layer 4: Smooth scroll to target item with animation (only if proxy exists)
        if let proxy = scrollViewProxy {
            withAnimation(.easeInOut(duration: AnimationConstants.Duration.standard)) {
                proxy.scrollTo(targetItem.id, anchor: .center)
            }
        }

        // Auto-reset highlight after 1 second
        scheduleHighlightReset()

        // Layer 5: Haptic feedback - Light tap for premium feel
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Layer 6: Badge bounce animation (1.0 → 1.15 → 1.0)
        withAnimation(.spring(response: AnimationConstants.Spring.quickResponse, dampingFraction: AnimationConstants.Spring.lightDamping)) {
            badgeScale = 1.15
        }
        scheduleBounceReset()
    }

    private func scheduleHighlightReset() {
        highlightedResetTask?.cancel()
        highlightedResetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard let self else { return }
            await MainActor.run {
                withAnimation {
                    self.highlightedItemID = nil
                }
            }
        }
    }

    private func scheduleBounceReset() {
        badgeResetTask?.cancel()
        badgeResetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard let self else { return }
            await MainActor.run {
                withAnimation(.spring(response: AnimationConstants.Spring.quickResponse, dampingFraction: AnimationConstants.Spring.lightDamping)) {
                    self.badgeScale = 1.0
                }
            }
        }
    }

    private var highlightedResetTask: Task<Void, Never>?
    private var badgeResetTask: Task<Void, Never>?
}
