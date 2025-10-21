import SwiftUI

// MARK: - DSCard Surface Parameter Tests
// Phase v1.3c: Quick visual tests to verify surface parameter works correctly
// Industry Pattern: Apple SwiftUI Preview testing (official SwiftUI documentation)

/// Test 1: Verify surface parameter displays light background (ice/ivory/mint)
/// Expected: Card has light blue/ice background instead of white
#Preview("Test 1: Surface Parameter - Ice Background") {
    ZStack {
        // Dark background to see light card clearly
        Color(red: 10/255, green: 18/255, blue: 36/255)
            .ignoresSafeArea()

        DSCard(
            cardType: .milestone,
            title: "Test: Ice Surface",
            surface: Theme.ColorToken.surfaceIce,  // 🧪 TEST: Light ice background
            onDismiss: { print("Dismiss tapped") }
        ) {
            VStack(spacing: 12) {
                Text("✅ SUCCESS")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.green)

                Text("If you see a light ice/blue background")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.ColorToken.textPrimary)

                Text("surface parameter is working!")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.ColorToken.textPrimary)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, DSSpacing.screenEdgePadding)
    }
}

/// Test 2: Verify default behavior unchanged (white background when surface = nil)
/// Expected: Card has white background (same as before enhancement)
#Preview("Test 2: Default Behavior - White Background") {
    ZStack {
        // Dark background to see white card clearly
        Color(red: 10/255, green: 18/255, blue: 36/255)
            .ignoresSafeArea()

        DSCard(
            cardType: .currentWeight,
            title: "Test: Default (No Surface)",
            // 🧪 TEST: No surface parameter = should be white
            onDismiss: { print("Dismiss tapped") }
        ) {
            VStack(spacing: 12) {
                Text("✅ SUCCESS")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.green)

                Text("If you see a WHITE background")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.ColorToken.textPrimary)

                Text("default behavior is preserved!")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.ColorToken.textPrimary)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, DSSpacing.screenEdgePadding)
    }
}

/// Bonus Test: All 3 surface colors side-by-side
/// Visual comparison test to verify all light surfaces work
#Preview("Bonus: All Surface Colors") {
    ZStack {
        Color(red: 10/255, green: 18/255, blue: 36/255)
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 20) {
                // Ice
                DSCard(
                    cardType: .milestone,
                    title: "Ice Surface",
                    surface: Theme.ColorToken.surfaceIce,
                    onDismiss: { print("Ice dismissed") }
                ) {
                    Text("Light Ice/Blue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textPrimary)
                }

                // Ivory
                DSCard(
                    cardType: .milestone,
                    title: "Ivory Surface",
                    surface: Theme.ColorToken.surfaceIvory,
                    onDismiss: { print("Ivory dismissed") }
                ) {
                    Text("Light Ivory/Cream")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textPrimary)
                }

                // Mint
                DSCard(
                    cardType: .milestone,
                    title: "Mint Surface",
                    surface: Theme.ColorToken.surfaceMint,
                    onDismiss: { print("Mint dismissed") }
                ) {
                    Text("Light Mint/Green")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textPrimary)
                }

                // Default (White)
                DSCard(
                    cardType: .currentWeight,
                    title: "Default (White)",
                    onDismiss: { print("Default dismissed") }
                ) {
                    Text("White Background")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.ColorToken.textPrimary)
                }
            }
            .padding(.horizontal, DSSpacing.screenEdgePadding)
            .padding(.vertical, 20)
        }
    }
}
