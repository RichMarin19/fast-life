import SwiftUI

/// Educational popover showing details about a fasting stage
/// Per Apple HIG: Use contextual help to educate users
/// Reference: https://developer.apple.com/design/human-interface-guidelines/help
struct FastingStageDetailView: View {
    let stage: FastingStage
    @Environment(\.dismiss) private var dismiss
    @State private var doNotShowAgain: Bool

    init(stage: FastingStage) {
        self.stage = stage
        // Initialize checkbox state from UserDefaults
        let stageKey = "disabledStage_\(stage.startHour)h"
        _doNotShowAgain = State(initialValue: UserDefaults.standard.bool(forKey: stageKey))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with icon and title
                    HStack(spacing: 16) {
                        Text(self.stage.icon)
                            .font(.system(size: 60))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(self.stage.title)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(self.stage.hourRange + " hours")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)

                    // What's Happening
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What's Happening")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)

                        ForEach(self.stage.description, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.body)
                                    .fontWeight(.bold)
                                Text(point)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(10)

                    // Physical Signs
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundColor(.red)
                            Text("Physical Signs")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }

                        ForEach(self.stage.physicalSigns, id: \.self) { sign in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.body)
                                    .fontWeight(.bold)
                                Text(sign)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(10)

                    // Recommendations
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.green)
                            Text("Recommendations")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }

                        ForEach(self.stage.recommendations, id: \.self) { rec in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.body)
                                    .fontWeight(.bold)
                                Text(rec)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.08))
                    .cornerRadius(10)

                    // Did You Know section
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Did You Know?")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }

                        Text(self.stage.didYouKnow)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(10)

                    // Do Not Show Again checkbox
                    // Per Apple HIG: Give users control over notification preferences
                    // Reference: https://developer.apple.com/design/human-interface-guidelines/notifications
                    Toggle(isOn: Binding(
                        get: { self.doNotShowAgain },
                        set: { newValue in
                            self.doNotShowAgain = newValue
                            let stageKey = "disabledStage_\(stage.startHour)h"
                            UserDefaults.standard.set(newValue, forKey: stageKey)
                            print(
                                "Stage \(self.stage.startHour)h notifications \(newValue ? "disabled" : "enabled") from detail view"
                            )
                        }
                    )) {
                        HStack(spacing: 8) {
                            Image(systemName: "bell.slash.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Do Not Show Again")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Stop receiving notifications for this stage")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
                    .padding(12)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Fasting Stage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        self.dismiss()
                    }
                }
            }
        }
    }
}
