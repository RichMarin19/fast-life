import SwiftUI

/// Empty state shown when no weight data exists yet.
/// Provides manual entry and HealthKit sync actions using design-system tokens.
struct EmptyWeightStateView: View {
    @Binding var showingAddWeight: Bool
    let healthKitManager: HealthKitManagerProtocol
    let weightManager: WeightManager

    var body: some View {
        VStack(spacing: DSSpacing.cardSectionSpacing) {
            Image(systemName: "scalemass")
                .font(DSTypography.displayXXL)
                .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.6))

            Text("No Weight Data Yet")
                .font(DSTypography.displayM)
                .foregroundColor(Theme.ColorToken.textSecondary)

            Text("Add your first weight entry or sync with Apple Health")
                .font(DSTypography.cardBody)
                .foregroundColor(Theme.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: DSSpacing.cardElementSpacing) {
                Button(action: { showingAddWeight = true }) {
                    Label("Add Weight Manually", systemImage: "plus.circle.fill")
                        .font(DSTypography.buttonPrimary)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.ColorToken.accentPrimary)
                        .cornerRadius(DSCornerRadius.button)
                }
                .accessibilityLabel("Add weight entry manually")

                Button(action: syncWithHealthKit) {
                    Label("Sync with Apple Health", systemImage: "heart.fill")
                        .font(DSTypography.buttonPrimary)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.ColorToken.stateSuccess)
                        .cornerRadius(DSCornerRadius.button)
                }
                .accessibilityLabel("Sync weight data with Apple Health")
            }
            .padding(.horizontal, DSSpacing.cardPadding * 2.5)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 60)
    }

    private func syncWithHealthKit() {
        AppLogger.info("EmptyState: Sync button tapped - requesting weight authorization", category: AppLogger.healthKit)
        weightManager.setSyncPreference(true)
        AppLogger.info("EmptyState: Enabled sync preference", category: AppLogger.healthKit)

        healthKitManager.requestWeightAuthorization { success, _ in
            guard success else {
                AppLogger.info("EmptyState: Weight authorization denied", category: AppLogger.healthKit)
                return
            }

            AppLogger.info("EmptyState: Weight authorization granted - starting sync", category: AppLogger.healthKit)

            DispatchQueue.main.async {
                let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
                weightManager.syncFromHealthKitWithReset(startDate: startDate) { addedCount, error in
                    if let error = error {
                        AppLogger.error("EmptyState: Sync failed", category: AppLogger.healthKit, error: error)
                    } else {
                        AppLogger.info("EmptyState: Sync completed - added \(addedCount) entries", category: AppLogger.healthKit)
                    }
                }
            }
        }
    }
}
