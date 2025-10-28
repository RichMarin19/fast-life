//
// LifeGPTLoadingOverlay.swift
// FastingTracker
//
// Created for LifeGPT Phase 4A - Performance UX Enhancement
// First-launch loading screen while building InsightContext from HealthKit
// Reference: Whoop, Oura, Levels first-sync UX patterns
//

import SwiftUI

/// Loading overlay shown during first launch while building health insights
/// **Industry Pattern:** Whoop "Analyzing your recovery", Oura "Building your baseline"
///
/// **Features:**
/// - Full-screen overlay with blur background
/// - Animated progress indicator
/// - Contextual messaging
/// - ES-5 emotion-aware theming
struct LifeGPTLoadingOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Blur background
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Content card
            VStack(spacing: DSSpacing.cardElementSpacing) {
                // Animated icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.ColorToken.accentEmerald,
                                Theme.ColorToken.accentTeal
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                // Title
                Text("Building Your Health Insights")
                    .font(DSTypography.heading3)
                    .foregroundStyle(Theme.ColorToken.textPrimary)
                    .multilineTextAlignment(.center)

                // Subtitle
                Text("Analyzing your HealthKit data to provide personalized insights...")
                    .font(DSTypography.bodySmall)
                    .foregroundStyle(Theme.ColorToken.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DSSpacing.cardElementSpacing)

                // Progress indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.ColorToken.accentEmerald))
                    .scaleEffect(1.2)
                    .padding(.top, DSSpacing.cardSmallSpacing)

                // Time estimate
                Text("This usually takes 30-60 seconds")
                    .font(DSTypography.caption)
                    .foregroundStyle(Theme.ColorToken.textTertiary)
                    .padding(.top, DSSpacing.cardSmallSpacing)
            }
            .padding(DSSpacing.cardLargeSpacing)
            .background(
                RoundedRectangle(cornerRadius: DSCornerRadius.card)
                    .fill(Theme.ColorToken.bgCard)
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
            )
            .padding(.horizontal, DSSpacing.cardLargeSpacing)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct LifeGPTLoadingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Background (simulating chat view)
            LinearGradient(
                colors: [
                    Theme.ColorToken.bgDeepStart,
                    Theme.ColorToken.bgDeepMid,
                    Theme.ColorToken.bgDeepEnd
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Overlay
            LifeGPTLoadingOverlay()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
