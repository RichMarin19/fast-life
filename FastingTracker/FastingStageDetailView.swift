import SwiftUI

/// Educational popover showing details about a fasting stage
/// Per Apple HIG: Use contextual help to educate users
/// Reference: https://developer.apple.com/design/human-interface-guidelines/help
struct FastingStageDetailView: View {
    let stage: FastingStage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with icon and title
                    HStack(spacing: 16) {
                        Text(stage.icon)
                            .font(.system(size: 60))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(stage.title)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(stage.hourRange + " hours")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's Happening")
                            .font(.headline)
                            .foregroundColor(.blue)

                        ForEach(stage.description, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .fontWeight(.bold)
                                Text(point)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(12)

                    // Did You Know section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Did You Know?")
                                .font(.headline)
                        }

                        Text(stage.didYouKnow)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Fasting Stage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
