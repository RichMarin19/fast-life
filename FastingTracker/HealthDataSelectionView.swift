import SwiftUI

/// Granular health data selection view for users who initially skipped onboarding
/// Following Apple Human Interface Guidelines for selection interfaces
/// Reference: https://developer.apple.com/design/human-interface-guidelines/components/selection-and-input/toggles/
struct HealthDataSelectionView: View {
    @Environment(\.dismiss) var dismiss

    // Selection state for each data type
    @State private var selectedTypes: Set<HealthDataType> = []
    @State private var isProcessing = false

    // Completion handler
    let onComplete: (Set<HealthDataType>) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header section
                VStack(spacing: 16) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                        .padding(.top, 20)

                    Text("Choose Health Data to Sync")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(
                        "Select which health data you'd like to sync with Apple Health. You can change these preferences later in settings."
                    )
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)

                // Selection options
                List {
                    ForEach(HealthDataType.allCases, id: \.self) { dataType in
                        HealthDataRow(
                            dataType: dataType,
                            isSelected: self.selectedTypes.contains(dataType)
                        ) {
                            self.toggleSelection(dataType)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: self.enableSelectedFeatures) {
                        HStack {
                            if self.isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(self.isProcessing ? "Setting up..." : "Enable Selected Features")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(self.selectedTypes.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(self.selectedTypes.isEmpty || self.isProcessing)

                    Button("Maybe Later") {
                        self.onComplete([])
                        self.dismiss()
                    }
                    .foregroundColor(.secondary)
                    .disabled(self.isProcessing)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }

    private func toggleSelection(_ dataType: HealthDataType) {
        if self.selectedTypes.contains(dataType) {
            self.selectedTypes.remove(dataType)
        } else {
            self.selectedTypes.insert(dataType)
        }
    }

    private func enableSelectedFeatures() {
        self.isProcessing = true

        // CRITICAL: Dismiss sheet FIRST, then request authorization
        // Apple's HealthKit dialog can't present while another modal is open
        self.dismiss()

        // Small delay to ensure sheet is fully dismissed before requesting authorization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.onComplete(self.selectedTypes)
        }
    }
}

/// Individual health data type row
/// Following Apple HIG for list item design
private struct HealthDataRow: View {
    let dataType: HealthDataType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: self.onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: self.dataType.iconName)
                    .font(.title2)
                    .foregroundColor(self.dataType.color)
                    .frame(width: 28, height: 28)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.dataType.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(self.dataType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Selection indicator
                Image(systemName: self.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(self.isSelected ? .blue : .gray)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
    struct HealthDataSelectionView_Previews: PreviewProvider {
        static var previews: some View {
            HealthDataSelectionView { selectedTypes in
                print("Selected: \(selectedTypes)")
            }
        }
    }
#endif
