import SwiftUI

/// Apple Health sync configuration card within the Weight Control Center.
struct WeightControlCenterSyncCard: View {
    @ObservedObject var viewModel: WeightControlCenterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardPadding) {
            Toggle(isOn: $viewModel.localSyncEnabled) {
                VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
                    Text("Sync with Apple Health")
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("Auto-import your weight from Apple Health.")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                    Text("No manual entry.")
                        .font(DSTypography.cardCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                    Text(viewModel.hasHealthKitPermission ? "Ready to sync" : "Not synced")
                        .font(DSTypography.listCaption)
                        .foregroundColor(viewModel.hasHealthKitPermission ? Theme.ColorToken.accentPrimary : Theme.ColorToken.textSecondaryOnDark)
                }
            }
            .tint(Theme.ColorToken.accentPrimary)
            .disabled(!viewModel.canEnableSync)
            .onChange(of: viewModel.localSyncEnabled) { _, newValue in
                viewModel.userSyncPreference = newValue
                if viewModel.canEnableSync {
                    viewModel.weightManager.setSyncPreference(newValue)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.updatePermissionStatus()
                    viewModel.updateToggleState()
                }
            }

            if viewModel.localSyncEnabled {
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)
            }

                Button(action: {
                    viewModel.syncWithHealthKit()
                }) {
                    HStack(spacing: DSSpacing.cardSmallSpacing) {
                        if viewModel.isSyncing {
                            ProgressView()
                                .tint(Theme.ColorToken.textPrimaryOnDark)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(DSTypography.cardTitle)
                        }
                        Text(viewModel.isSyncing ? "Syncing..." : "Sync Now")
                            .font(DSTypography.cardTitle)
                    }
                    .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    .frame(maxWidth: .infinity)
                    .padding(DSSpacing.cardElementSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.ColorToken.accentPrimary)
                    )
                }
                .disabled(viewModel.isSyncing || !viewModel.hasHealthKitPermission)
                .opacity((viewModel.isSyncing || !viewModel.hasHealthKitPermission) ? 0.5 : 1.0)

                Divider()
                    .background(Theme.ColorToken.dividerOnDark)

            if !viewModel.hasHealthKitPermission {
                statusRow(icon: "exclamationmark.triangle.fill", color: Theme.ColorToken.stateWarning, message: viewModel.permissionStatusMessage)
            } else if !viewModel.lastSyncStatus.isEmpty {
                statusRow(icon: "checkmark.circle.fill", color: Theme.ColorToken.accentPrimary, message: viewModel.lastSyncStatus)
            }

            if viewModel.hasHealthKitPermission && viewModel.localSyncEnabled {
                HStack(spacing: DSSpacing.cardSmallSpacing) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(Theme.ColorToken.accentInfo)
                        .font(DSTypography.listCaption)
                    Text("Your data is secure & up-to-date")
                        .font(DSTypography.statLabel)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }
                .padding(DSSpacing.cardSmallSpacing)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.ColorToken.accentInfo.opacity(0.15))
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func statusRow(icon: String, color: Color, message: String) -> some View {
        HStack(spacing: DSSpacing.cardSmallSpacing) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(message)
                .font(DSTypography.cardCaption)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
        }
    }
}
