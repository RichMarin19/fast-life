import SwiftUI

/// Specialized nudge for fasting with smart persistence
/// Offers both temporary dismiss (show again in 5 visits) and permanent dismiss
/// Following industry standards: Strava, MyFitnessPal persistence patterns
struct FastingHealthKitNudgeView: View {
    let onConnect: () -> Void
    let onDismiss: () -> Void
    let onPermanentDismiss: () -> Void

    @State private var showingDismissOptions = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "heart.fill")
                    .font(.title3)
                    .foregroundColor(.red)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sync with Apple Health")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("Export your fasting progress automatically")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Action buttons
                HStack(spacing: 8) {
                    Button("Connect") {
                        onConnect()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color("FLPrimary"))
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Button(action: {
                        showingDismissOptions = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 24, height: 24)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .confirmationDialog("Dismiss Options", isPresented: $showingDismissOptions, titleVisibility: .visible) {
            Button("Remind me later") {
                onDismiss()
            }
            Button("Don't show again", role: .destructive) {
                onPermanentDismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You can choose to be reminded again in a few visits, or stop seeing this reminder completely.")
        }
    }
}