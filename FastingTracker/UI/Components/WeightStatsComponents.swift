import SwiftUI

// MARK: - Weight Statistics Components

struct WeightStatsView: View {
    @ObservedObject var weightManager: WeightManager
    @ObservedObject var measurementObserver: MeasurementSystemObserver = MeasurementSystemObserver.shared

    var body: some View {
        let _ = measurementObserver.system
        let unitAbbreviation = weightManager.currentUnitAbbreviation
        let averageText: (value: String, accessibility: String) = weightManager.averageWeight.map { averageWeight in
            let formattedAverage = weightManager.formattedDisplayWeight(averageWeight)
            return (formattedAverage, "\(formattedAverage) \(unitAbbreviation)")
        } ?? ("—", "Not available")
        let sevenDayChange = weightManager.weightChange(since: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
        let thirtyDayChange = weightManager.weightChange(since: Calendar.current.date(byAdding: .day, value: -30, to: Date())!)
        let sevenDaySummary = summary(for: sevenDayChange, periodLabel: "7-day", unitAbbreviation: unitAbbreviation)
        let thirtyDaySummary = summary(for: thirtyDayChange, periodLabel: "30-day", unitAbbreviation: unitAbbreviation)
        let averageSummary = averageText.value == "—" ? "Average weight not available" : "Average weight \(averageText.accessibility)"
        let entriesSummary = "\(weightManager.weightEntries.count) total entries recorded"
        let accessibilitySummary = [sevenDaySummary, thirtyDaySummary, averageSummary, entriesSummary].joined(separator: ". ")

        VStack(spacing: DSSpacing.cardElementSpacing) {
            // REMOVED: "Statistics" header - DSCard now provides title in header
            // Following Universal Standardization Architecture pattern

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSSpacing.cardElementSpacing) {
                WeightChangeStatCard(
                    title: "7-Day Change",
                    weightChange: sevenDayChange,
                    unitAbbreviation: unitAbbreviation,
                    weightManager: weightManager
                )

                WeightChangeStatCard(
                    title: "30-Day Change",
                    weightChange: thirtyDayChange,
                    unitAbbreviation: unitAbbreviation,
                    weightManager: weightManager
                )

                StatCard(
                    title: "Average Weight",
                    value: averageText.value,
                    icon: "chart.bar",
                    color: Theme.ColorToken.accentInfo,
                    accessibilityValue: averageText.accessibility
                )

                StatCard(
                    title: "Total Entries",
                    value: "\(weightManager.weightEntries.count)",
                    icon: "number",
                    color: Theme.ColorToken.stateSuccess,
                    accessibilityValue: "\(weightManager.weightEntries.count) entries recorded"
                )
            }
        }
        // REMOVED: Card styling (padding, background, cornerRadius, shadow)
        // DSCard universal container now provides all standardized styling
        // Following Universal Standardization Architecture pattern
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Swipe right to explore each statistic individually.")
    }

    private func summary(for change: Double?, periodLabel: String, unitAbbreviation: String) -> String {
        guard let change = change else {
            return "\(periodLabel.capitalized) change not available"
        }
        let direction = change >= 0 ? "gained" : "lost"
        let formatted = weightManager.formattedDisplayWeight(abs(change))
        return "\(periodLabel.capitalized) change \(direction) \(formatted) \(unitAbbreviation)"
    }
}

// MARK: - Supporting Components

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var accessibilityValue: String? = nil

    var body: some View {
        VStack(spacing: DSSpacing.cardSmallSpacing) {
            Image(systemName: icon)
                .font(DSTypography.displayS)
                .foregroundColor(color)
                .accessibilityHidden(true)

            Text(value)
                .font(DSTypography.statValueMedium)
                .foregroundColor(Theme.ColorToken.textPrimary)

            Text(title)
                .font(DSTypography.listCaption)
                .foregroundColor(Theme.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)")
        .accessibilityValue(accessibilityValue ?? value)
        // REMOVED: .padding(), .background(), .cornerRadius() - these block parent drag gestures
        // DSCard wrapper provides all necessary styling and gesture handling
        // Per Apple docs: nested interactive views prevent gesture propagation
    }
}

struct WeightChangeStatCard: View {
    let title: String
    let weightChange: Double?
    let unitAbbreviation: String
    let weightManager: WeightManager

    var body: some View {
        let formattedChange = weightChange.flatMap { change -> (String, Bool) in
            let formatted = weightManager.formattedDisplayWeight(abs(change))
            return ("\(formatted) \(unitAbbreviation)", change >= 0)
        }

        VStack(spacing: DSSpacing.cardSmallSpacing) {
            if let change = weightChange {
                let isGain = change >= 0
                // Arrow icon based on gain/loss
                Image(systemName: isGain ? "arrow.up.right" : "arrow.down.right")
                    .font(DSTypography.displayS)
                    .foregroundColor(isGain ? Theme.ColorToken.stateError : Theme.ColorToken.stateSuccess)
                    .accessibilityHidden(true)

                // Weight change value with arrow
                if let (valueText, isGainDisplay) = formattedChange {
                    HStack(spacing: DSSpacing.cardExtraSmallSpacing) {
                        Text(valueText)
                            .font(DSTypography.statValueMedium)
                            .foregroundColor(isGainDisplay ? Theme.ColorToken.stateError : Theme.ColorToken.stateSuccess)
                        Image(systemName: isGainDisplay ? "arrow.up" : "arrow.down")
                            .font(DSTypography.statValueMedium)
                            .foregroundColor(isGainDisplay ? Theme.ColorToken.stateError : Theme.ColorToken.stateSuccess)
                            .accessibilityHidden(true)
                    }
                }
            } else {
                Image(systemName: "calendar")
                    .font(DSTypography.displayS)
                    .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.6))
                    .accessibilityHidden(true)

                Text("N/A")
                    .font(DSTypography.statValueMedium)
                    .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.6))
            }

            Text(title)
                .font(DSTypography.listCaption)
                .foregroundColor(Theme.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)")
        .accessibilityValue(changeAccessibilityValue)
        // REMOVED: .padding(), .background(), .cornerRadius() - these block parent drag gestures
        // DSCard wrapper provides all necessary styling and gesture handling
        // Per Apple docs: nested interactive views prevent gesture propagation
    }

    private var changeAccessibilityValue: String {
        guard let change = weightChange else { return "Not available" }
        let formatted = weightManager.formattedDisplayWeight(abs(change))
        let direction = change >= 0 ? "gained" : "lost"
        return "\(direction) \(formatted) \(unitAbbreviation)"
    }
}
