import SwiftUI

/// Centralized gradients for Progress Story trend states.
/// Keeps the palette aligned with design tokens so updates cascade automatically.
struct WeightProgressStoryTrendPalette {
    let gradient: LinearGradient

    init(state: WeightProgressStoryTrendState) {
        switch state {
        case .improving:
            gradient = LinearGradient(
                colors: [
                    Theme.ColorToken.moodImprovingStart,
                    Theme.ColorToken.moodImprovingEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .regressing:
            gradient = LinearGradient(
                colors: [
                    Theme.ColorToken.moodRegressingStart,
                    Theme.ColorToken.moodRegressingEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .flat:
            gradient = LinearGradient(
                colors: [
                    Theme.ColorToken.moodStableStart,
                    Theme.ColorToken.moodStableEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
