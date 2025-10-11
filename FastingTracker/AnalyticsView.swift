import SwiftUI

/// Analytics Hub - Cross-Tracker Insights (Coming Soon)
/// Per Apple HIG: Provide clear communication about upcoming features
/// Reference: https://developer.apple.com/design/human-interface-guidelines/feedback
struct AnalyticsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    Spacer()
                        .frame(height: 40)

                    // Icon
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 80))
                        .foregroundColor(Color("FLSecondary"))

                    // Title
                    Text("Analytics Hub")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    // Subtitle
                    Text("Cross-Tracker Insights")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    // Coming Soon Badge
                    Text("COMING SOON")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color("FLSecondary"))
                        )

                    // Description
                    VStack(spacing: 20) {
                        FeaturePreviewCard(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Cross-Tracker Correlations",
                            description: "See how fasting impacts your weight, sleep quality, mood, and energy levels in one unified dashboard."
                        )

                        FeaturePreviewCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Trend Analysis",
                            description: "Discover patterns between your fasting schedule and other health metrics over time."
                        )

                        FeaturePreviewCard(
                            icon: "lightbulb.fill",
                            title: "Smart Insights",
                            description: "Get personalized insights like \"Your weight drops 0.5 lbs on fast days\" and \"Better sleep leads to longer fasts.\""
                        )

                        FeaturePreviewCard(
                            icon: "calendar.badge.clock",
                            title: "Comprehensive Timeline",
                            description: "View all your health metrics on a single timeline to see the complete picture of your wellness journey."
                        )
                    }
                    .padding(.horizontal)

                    // Bottom Message
                    VStack(spacing: 12) {
                        Text("This feature is in development")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("In the meantime, explore your individual tracker analytics in each feature section.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)

                    Spacer()
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Analytics")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Feature Preview Card

struct FeaturePreviewCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: self.icon)
                .font(.title2)
                .foregroundColor(Color("FLSecondary"))
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text(self.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(self.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

#Preview {
    AnalyticsView()
}
