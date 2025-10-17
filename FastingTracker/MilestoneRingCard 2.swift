import SwiftUI

struct MilestoneRingCard: View {
    let progress: Double
    let milestoneIndex: Int
    let centerValue: String
    let dateText: String
    let leftStat: String
    let midStat: String
    let rightStat: String
    let totalMilestones: Int
    let completedMilestones: Int

    private var clampedProgress: Double { min(max(progress, 0.0), 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 90, height: 90)

                    Circle()
                        .trim(from: 0, to: clampedProgress)
                        .stroke(AngularGradient(gradient: Gradient(colors: [Color("FLPrimary"), Color("FLPrimary").opacity(0.6), Color("FLPrimary")]), center: .center), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 90, height: 90)
                        .animation(.easeInOut(duration: 0.6), value: clampedProgress)

                    VStack(spacing: 2) {
                        Text(centerValue)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        if !dateText.isEmpty {
                            Text(dateText)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Milestone")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(milestoneIndex)/\(totalMilestones)")
                            .font(.subheadline.weight(.semibold))
                    }

                    ProgressView(value: clampedProgress)
                        .tint(Color("FLPrimary"))
                        .frame(maxWidth: .infinity)

                    HStack {
                        Label("\(completedMilestones) done", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(clampedProgress * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(leftStat)
                        .font(.footnote.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .center, spacing: 4) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(midStat)
                        .font(.footnote.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("To Goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(rightStat)
                        .font(.footnote.weight(.semibold))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06))
        )
    }
}

#Preview {
    MilestoneRingCard(
        progress: 0.65,
        milestoneIndex: 6,
        centerValue: "182.4",
        dateText: "Oct 14",
        leftStat: "196.0 lb",
        midStat: "-13.6 lb",
        rightStat: "2.4 to go",
        totalMilestones: 10,
        completedMilestones: 6
    )
    .padding()
}
