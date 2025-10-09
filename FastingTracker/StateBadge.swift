import SwiftUI

/// StateBadge - Reusable status indicator component
/// Follows Apple HIG patterns for status communication
/// Reference: https://developer.apple.com/design/human-interface-guidelines/feedback
struct StateBadge: View {
    let text: String
    let style: BadgeStyle
    let size: BadgeSize

    enum BadgeStyle {
        case success
        case warning
        case error
        case info
        case neutral

        var colors: (background: Color, foreground: Color) {
            switch self {
            case .success:
                return (Color("FLSuccess"), .white)
            case .warning:
                return (Color("FLWarning"), .white)
            case .error:
                return (.red, .white)
            case .info:
                return (Color("FLPrimary"), .white)
            case .neutral:
                return (Color(UIColor.secondarySystemFill), Color(UIColor.label))
            }
        }
    }

    enum BadgeSize {
        case small
        case medium
        case large

        var font: Font {
            switch self {
            case .small:
                return .caption
            case .medium:
                return .subheadline
            case .large:
                return .headline
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .medium:
                return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .large:
                return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            }
        }
    }

    init(
        _ text: String,
        style: BadgeStyle = .neutral,
        size: BadgeSize = .medium
    ) {
        self.text = text
        self.style = style
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(size.font)
            .fontWeight(.semibold)
            .foregroundColor(style.colors.foreground)
            .padding(size.padding)
            .background(
                Capsule()
                    .fill(style.colors.background)
            )
    }
}

// MARK: - Convenience Initializers

extension StateBadge {
    /// Success badge (green)
    static func success(_ text: String, size: BadgeSize = .medium) -> StateBadge {
        StateBadge(text, style: .success, size: size)
    }

    /// Warning badge (gold)
    static func warning(_ text: String, size: BadgeSize = .medium) -> StateBadge {
        StateBadge(text, style: .warning, size: size)
    }

    /// Error badge (red)
    static func error(_ text: String, size: BadgeSize = .medium) -> StateBadge {
        StateBadge(text, style: .error, size: size)
    }

    /// Info badge (navy blue)
    static func info(_ text: String, size: BadgeSize = .medium) -> StateBadge {
        StateBadge(text, style: .info, size: size)
    }

    /// Neutral badge (system colors)
    static func neutral(_ text: String, size: BadgeSize = .medium) -> StateBadge {
        StateBadge(text, style: .neutral, size: size)
    }
}

// MARK: - Specialized Status Badges

/// SyncStatusView - Shows HealthKit sync status
struct SyncStatusView: View {
    let isEnabled: Bool
    let lastSyncDate: Date?
    let errorMessage: String?

    var body: some View {
        HStack(spacing: 8) {
            if let errorMessage = errorMessage {
                StateBadge.error("Sync Error")
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if isEnabled {
                StateBadge.success("HealthKit Connected")
                if let lastSync = lastSyncDate {
                    Text("Last sync: \(lastSync, formatter: relativeDateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                StateBadge.neutral("Not Connected")
                Text("Tap to connect Apple Health")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var relativeDateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }
}

/// GoalStatusBadge - Shows goal achievement status
struct GoalStatusBadge: View {
    let current: Double
    let goal: Double
    let unit: String

    private var progress: Double {
        goal > 0 ? current / goal : 0
    }

    private var status: (text: String, style: StateBadge.BadgeStyle) {
        if progress >= 1.0 {
            return ("Goal Met! 🎉", .success)
        } else if progress >= 0.8 {
            return ("Almost There!", .warning)
        } else if progress >= 0.5 {
            return ("On Track", .info)
        } else {
            return ("Getting Started", .neutral)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            StateBadge(status.text, style: status.style, size: .small)

            HStack(spacing: 4) {
                Text("\(current, specifier: "%.1f") / \(goal, specifier: "%.0f") \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(status.style.colors.background)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Badge styles
        HStack(spacing: 12) {
            StateBadge.success("Success")
            StateBadge.warning("Warning")
            StateBadge.error("Error")
            StateBadge.info("Info")
            StateBadge.neutral("Neutral")
        }

        // Badge sizes
        HStack(spacing: 12) {
            StateBadge.success("Small", size: .small)
            StateBadge.success("Medium", size: .medium)
            StateBadge.success("Large", size: .large)
        }

        // Sync status examples
        VStack(alignment: .leading, spacing: 12) {
            SyncStatusView(
                isEnabled: true,
                lastSyncDate: Date().addingTimeInterval(-3600),
                errorMessage: nil
            )

            SyncStatusView(
                isEnabled: false,
                lastSyncDate: nil,
                errorMessage: nil
            )

            SyncStatusView(
                isEnabled: true,
                lastSyncDate: nil,
                errorMessage: "Network connection failed"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)

        // Goal status example
        GoalStatusBadge(current: 165.2, goal: 160.0, unit: "lbs")
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}