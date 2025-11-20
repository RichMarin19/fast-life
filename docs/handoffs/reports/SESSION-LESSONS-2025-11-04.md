# Session Lessons – November 4, 2025

## Weight Tracker Control Center
- Individual restore buttons must drive shared opt-out state (`ContentOptOutManager`) in addition to the card manager; otherwise UI looks restored but preference remains hidden.
- Always reuse the badge bounce helper when mutating opt-out state so the visual affordance stays in sync with new counts.

## Accessibility & Localization
- VoiceOver summaries need to include both the metric and supporting microcopy; testing with rotor shortcuts catches missing labels that static audits miss.
- Chart interactions must expose equivalent VoiceOver actions (Zoom In/Out/Reset). Gestures alone are insufficient for assistive tech parity.

## Gesture & Animation Testing
- SwiftUI animation tests require hopping back to the main actor (`await MainActor.run {}`) after `Task.sleep` to let the state update before assertions.
- Zoom/pan tests depend on chart data. Seed entries before asserting domain clamping, otherwise helper methods return early.

## Xcode Project Hygiene
- Hidden/restore flows should be verified inside both Weight Trends and Control Center; progress-story IDs live in `ProgressStoryCardType` and need a single source of truth.
- When reusing file references (e.g., `WeightProgressStoryTrendPalette.swift`), ensure project groups don’t duplicate members—Xcode will warn loudly during builds.
