import SwiftUI

/// Top Status Bar component for Heart Rate display
/// Following luxury Hub spec: ≤ 56pt high, visible but not prominent
/// Reference: FastLIFe_Hub_Redesign_LuxuryIcons.md Section 2
struct TopStatusBar: View {
    @StateObject private var heartRateViewModel = HeartRateViewModel()
    @State private var isPulsing = false
    @State private var showingPermissionSheet = false

    // MARK: - Luxury Design Tokens (From Spec)
    private let maxHeight: CGFloat = 88
    private let backgroundColor = Color(hex: "#0D1B2A") // background.dark from spec
    private let textPrimary = Color(hex: "#FFFFFF")     // text.primary
    private let textSecondary = Color(hex: "#D0D4DA")   // text.secondary
    private let accentPrimary = Color(hex: "#1ABC9C")   // accent.primary

    // MARK: - Heart Rate Animation (Industry Standard BPM-Matched Pulse)
    // Following Fitbit/Garmin pattern: Animation duration = 60 seconds ÷ BPM
    private var heartRatePulseAnimation: Animation {
        if heartRateViewModel.isLoading {
            // Loading state: Slower, gentle pulse while fetching data
            return .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
        }

        guard let currentHR = heartRateViewModel.currentHeartRate, currentHR > 0 else {
            // No data: Resting heart rate animation (60 BPM = 1 second per beat)
            return .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        }

        // Calculate realistic cardiac timing: 60 seconds ÷ BPM
        let beatsPerSecond = currentHR / 60.0
        let durationPerBeat = 1.0 / beatsPerSecond

        // Realistic cardiac cycle: Quick systole + longer diastole
        // Using easeOut for authentic heart contraction pattern
        return .easeOut(duration: durationPerBeat * 0.7)
               .repeatForever(autoreverses: true)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Heart Rate Status Content
            HStack(spacing: 16) {
                if heartRateViewModel.isAuthorized {
                    // Current Heart Rate with pulse animation
                    heartRateSection

                    Spacer()

                    // Daily Average Heart Rate
                    dailyAverageSection
                } else {
                    // No permission - show different message based on state
                    if heartRateViewModel.isLoading {
                        loadingSection
                    } else {
                        noPermissionSection
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: maxHeight)
            .padding(.horizontal, 20)
            .background(
                // Subtle gradient background
                LinearGradient(
                    colors: [
                        backgroundColor.opacity(0.6),
                        backgroundColor.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Subtle bottom separator
            Rectangle()
                .fill(textSecondary.opacity(0.15))
                .frame(height: 0.5)
        }
        .sheet(isPresented: $showingPermissionSheet) {
            heartRatePermissionSheet
        }
        .onAppear {
            // Refresh heart rate data when view appears
            heartRateViewModel.refresh()
        }
        .onChange(of: heartRateViewModel.isAuthorized) { _, isAuthorized in
            // Following Apple reactive UI patterns - refresh data when authorization changes
            if isAuthorized {
                heartRateViewModel.refresh()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Check authorization when app becomes active (handles Settings app changes)
            heartRateViewModel.refresh()
        }
    }

    // MARK: - Heart Rate Section (Current with Pulse Animation)

    @ViewBuilder
    private var heartRateSection: some View {
        HStack(spacing: 8) {
            // Heart icon with realistic BPM-matched pulse animation
            Image(systemName: "heart.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(accentPrimary)
                .scaleEffect(isPulsing ? 1.15 : 1.0)
                .animation(
                    heartRatePulseAnimation,
                    value: isPulsing
                )

            // Current HR display
            VStack(alignment: .leading, spacing: 2) {
                if heartRateViewModel.isLoading {
                    // Loading state
                    HStack(spacing: 4) {
                        Text("—")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(textPrimary)

                        Text("bpm")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(textSecondary)
                    }
                } else if let currentHR = heartRateViewModel.currentHeartRate {
                    // Current heart rate value
                    HStack(spacing: 4) {
                        Text("\(Int(currentHR))")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(textPrimary)

                        Text("bpm")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(textSecondary)
                    }
                } else {
                    // No data available
                    HStack(spacing: 4) {
                        Text("—")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(textSecondary)

                        Text("bpm")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(textSecondary)
                    }
                }
            }
        }
        .onAppear {
            // Start pulse animation when heart rate is active
            if heartRateViewModel.currentHeartRate != nil {
                isPulsing = true
            }
        }
        .onChange(of: heartRateViewModel.currentHeartRate) { _, newValue in
            // Restart animation with new heart rate for perfect synchronization
            isPulsing = false
            withAnimation(.easeInOut(duration: 0.1)) {
                isPulsing = newValue != nil
            }
        }
    }

    // MARK: - Daily Average Section

    @ViewBuilder
    private var dailyAverageSection: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Avg Today")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(textSecondary)

            if let avgHR = heartRateViewModel.dailyAverageHeartRate {
                HStack(spacing: 2) {
                    Text("\(Int(avgHR))")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(textPrimary.opacity(0.8))

                    Text("bpm")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(textSecondary)
                }
            } else {
                Text("—")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(textSecondary)
            }
        }
    }

    // MARK: - Loading Section

    @ViewBuilder
    private var loadingSection: some View {
        HStack {
            Spacer()

            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(textSecondary)

                Text("Checking Health access...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - No Permission Section

    @ViewBuilder
    private var noPermissionSection: some View {
        HStack {
            Spacer()

            Button(action: {
                // Use expert's actor-based authorization pattern
                heartRateViewModel.requestAuthorization()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(accentPrimary)

                    Text("Connect Health")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(accentPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(accentPrimary.opacity(0.15))
                        .overlay(
                            Capsule()
                                .strokeBorder(accentPrimary.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    // MARK: - Heart Rate Permission Sheet

    @ViewBuilder
    private var heartRatePermissionSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(accentPrimary)

                    VStack(spacing: 8) {
                        Text("Enable Heart Rate")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("Track your heart rate to see current and daily average in the Hub status bar")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                Spacer()

                // Enable button
                Button(action: {
                    heartRateViewModel.requestAuthorization()
                    showingPermissionSheet = false
                }) {
                    Text("Enable Heart Rate Access")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(accentPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)

                // Cancel button
                Button(action: {
                    showingPermissionSheet = false
                }) {
                    Text("Not Now")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Color extension is defined in HubView.swift (single source of truth)

#Preview {
    TopStatusBar()
        .background(Color.black)
}