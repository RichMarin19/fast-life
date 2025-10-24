import SwiftUI

// MARK: - Weight History Components

struct WeightHistoryListView: View {
    @ObservedObject var weightManager: WeightManager

    var body: some View {
        VStack(spacing: DSSpacing.cardElementSpacing) {
            // REMOVED: "Weight History" header - DSCard now provides title in header
            // Following Universal Standardization Architecture pattern

            ForEach(Array(weightManager.weightEntries.prefix(10))) { entry in
                WeightHistoryRow(entry: entry, weightManager: weightManager)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            weightManager.deleteWeightEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .accessibilityLabel("Delete this weight entry")
                    }
                Divider()
                    .background(Theme.ColorToken.dividerOnDark)
            }
        }
        // REMOVED: Card styling (padding, background, cornerRadius, shadow)
        // DSCard universal container now provides all standardized styling
        // Following Universal Standardization Architecture pattern
    }
}

struct WeightHistoryRow: View {
    let entry: WeightEntry
    let weightManager: WeightManager
    @State private var showingDeleteAlert = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DSSpacing.cardExtraSmallSpacing) {
                HStack(spacing: DSSpacing.cardExtraSmallSpacing) {
                    Text(entry.date, style: .date)
                        .font(DSTypography.cardTitle)
                        .foregroundColor(Theme.ColorToken.textPrimaryOnDark)
                    Text("•")
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                    Text(entry.date, style: .time)
                        .font(DSTypography.cardBody)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                }

                HStack(spacing: DSSpacing.cardSmallSpacing) {
                    Text(entry.source.rawValue)
                        .font(DSTypography.listCaption)
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

                    if let bmi = entry.bmi {
                        Text("BMI: \(bmi, specifier: "%.1f")")
                            .font(DSTypography.listCaption)
                            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                    }

                    if let bodyFat = entry.bodyFat {
                        Text("BF: \(bodyFat, specifier: "%.1f")%")
                            .font(DSTypography.listCaption)
                            .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                    }
                }
            }

            Spacer()

            Text("\(weightManager.displayWeight(for: entry), specifier: "%.1f") \("lbs")")
                .font(DSTypography.statValueMedium)
                .fontWeight(.semibold)
                .foregroundColor(Theme.ColorToken.accentPrimary)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive, action: { showingDeleteAlert = true }) {
                Label("Delete", systemImage: "trash")
            }
            .accessibilityLabel("Delete weight entry")
        }
        .alert("Delete Weight Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
                .accessibilityLabel("Cancel weight entry deletion")

            Button("Delete", role: .destructive) {
                weightManager.deleteWeightEntry(entry)
            }
            .accessibilityLabel("Confirm weight entry deletion")
        } message: {
            Text("Are you sure you want to delete this weight entry?")
        }
    }
}
