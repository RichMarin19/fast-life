import SwiftUI

struct HistoryRowView: View {
    let session: FastingSession

    // Pre-calculate these values once
    private let formattedDateValue: String
    private let formattedDurationValue: String
    private let formattedEatingWindowValue: String?

    init(session: FastingSession) {
        self.session = session

        // Calculate formatted strings in init to avoid repeated calculations
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        self.formattedDateValue = dateFormatter.string(from: session.startTime)

        let durationSeconds = session.duration
        let hours = Int(durationSeconds) / 3600
        let minutes = Int(durationSeconds) / 60 % 60
        self.formattedDurationValue = "\(hours)h \(minutes)m"

        // Format eating window if available
        if let eatingWindow = session.eatingWindowDuration {
            let ewHours = Int(eatingWindow) / 3600
            let ewMinutes = Int(eatingWindow) / 60 % 60
            self.formattedEatingWindowValue = "\(ewHours)h \(ewMinutes)m"
        } else {
            self.formattedEatingWindowValue = nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formattedDateValue)
                    .font(.headline)

                Spacer()

                if session.metGoal {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("FLSuccess"))
                        Text("Goal Met")
                            .font(.subheadline)
                            .foregroundColor(Color("FLSuccess"))
                    }
                } else {
                    Text("Incomplete")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("Fast: \(formattedDurationValue)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Show eating window if available
            if let eatingWindow = formattedEatingWindowValue {
                HStack(spacing: 4) {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.orange)
                    Text("Ate for: \(eatingWindow)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}