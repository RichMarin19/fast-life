import SwiftUI

/// Sync options modal for fasting HealthKit integration
/// Matching onboarding pattern with historical vs future sync choice
/// Following Apple HIG and industry standards (MyFitnessPal, Lose It)
struct FastingSyncOptionsView: View {
    let onSyncAll: () -> Void
    let onSyncFuture: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {  // Increased from 30 to 40 - prevents overlapping
                Spacer()
                    .frame(height: 30)  // Increased from 20 to 30 - more top padding

                // Header
                VStack(spacing: 20) {  // Increased from 16 to 20 - more header spacing
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)

                    Text("Sync Fasting Data")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Choose how you'd like to sync your fasting sessions with Apple Health")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Sync Options
                VStack(spacing: 20) {  // Increased from 15 to 20 - prevents button overlapping
                    Button(action: onSyncAll) {
                        VStack(spacing: 8) {
                            Text("Sync All Data")
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text("Import all fasting sessions from your history")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                    Button(action: onSyncFuture) {
                        VStack(spacing: 8) {
                            Text("Sync Future Data Only")
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text("Only sync new fasting sessions going forward")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .background(Color.cyan)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 30)

                Spacer()
            }
            .navigationTitle("HealthKit Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}