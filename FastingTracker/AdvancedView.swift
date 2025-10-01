import SwiftUI

struct AdvancedView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Advanced Features")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)

                    // Weight Tracking Feature
                    NavigationLink(destination: WeightTrackingView()) {
                        AdvancedFeatureCard(
                            title: "Weight Tracking",
                            description: "Track your weight, BMI, and body fat percentage",
                            icon: "scalemass.fill",
                            color: .blue,
                            isAvailable: true
                        )
                    }
                    .padding(.horizontal)

                    // Coming Soon Features
                    AdvancedFeatureCard(
                        title: "Mood & Energy Tracker",
                        description: "Track your mood and energy levels during fasting",
                        icon: "face.smiling.fill",
                        color: .orange,
                        isAvailable: false
                    )
                    .padding(.horizontal)

                    AdvancedFeatureCard(
                        title: "Hydration Tracker",
                        description: "Monitor your water intake throughout the day",
                        icon: "drop.fill",
                        color: .cyan,
                        isAvailable: false
                    )
                    .padding(.horizontal)

                    AdvancedFeatureCard(
                        title: "Data Export & Backup",
                        description: "Export your fasting data to CSV or backup to iCloud",
                        icon: "square.and.arrow.up.fill",
                        color: .green,
                        isAvailable: false
                    )
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AdvancedFeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isAvailable: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(isAvailable ? color : .gray)
                .frame(width: 60, height: 60)
                .background(isAvailable ? color.opacity(0.15) : Color.gray.opacity(0.15))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isAvailable ? .primary : .secondary)

                    if !isAvailable {
                        Text("Coming Soon")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(6)
                    }
                }

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if isAvailable {
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .opacity(isAvailable ? 1.0 : 0.7)
    }
}

#Preview {
    AdvancedView()
}
