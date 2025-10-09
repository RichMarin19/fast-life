import SwiftUI

/// FLCard - Reusable card component following Fast LIFe design system
/// Implements Apple HIG card patterns with professional styling
/// Reference: https://developer.apple.com/design/human-interface-guidelines/layout
struct FLCard<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let shadowOpacity: Double
    let shadowRadius: CGFloat
    let shadowOffset: CGSize
    let padding: EdgeInsets

    enum Style {
        case primary, success, warning, compact, stats

        var configuration: (backgroundColor: Color, shadowOpacity: Double, shadowRadius: CGFloat, padding: EdgeInsets) {
            switch self {
            case .primary:
                return (.white, 0.1, 15, EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            case .success:
                return (Color("FLSuccess").opacity(0.05), 0.05, 10, EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            case .warning:
                return (Color("FLWarning").opacity(0.05), 0.05, 10, EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            case .compact:
                return (.white, 0.05, 10, EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            case .stats:
                return (Color(UIColor.secondarySystemGroupedBackground), 0.03, 5, EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            }
        }
    }

    /// Initialize FLCard with customizable styling
    /// - Parameters:
    ///   - backgroundColor: Card background color (default: white)
    ///   - cornerRadius: Corner radius following Apple 2025 standards (default: 12pt)
    ///   - shadowOpacity: Shadow opacity for depth (default: 0.05)
    ///   - shadowRadius: Shadow blur radius (default: 10)
    ///   - shadowOffset: Shadow offset for natural depth (default: y: 5)
    ///   - padding: Internal padding (default: 16pt)
    ///   - content: Card content view
    init(
        backgroundColor: Color = .white,
        cornerRadius: CGFloat = 12,
        shadowOpacity: Double = 0.05,
        shadowRadius: CGFloat = 10,
        shadowOffset: CGSize = CGSize(width: 0, height: 5),
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowOpacity = shadowOpacity
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.padding = padding
    }

    /// Apple-style convenience initializer with predefined styles
    /// - Parameters:
    ///   - style: Predefined card style (primary, success, warning, compact, stats)
    ///   - content: Card content view
    init(
        style: Style,
        @ViewBuilder content: () -> Content
    ) {
        let config = style.configuration
        self.content = content()
        self.backgroundColor = config.backgroundColor
        self.cornerRadius = 12
        self.shadowOpacity = config.shadowOpacity
        self.shadowRadius = config.shadowRadius
        self.shadowOffset = CGSize(width: 0, height: 5)
        self.padding = config.padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: .black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: shadowOffset.width,
                y: shadowOffset.height
            )
    }
}

// MARK: - Specialized Card Types


// MARK: - Card Content Helpers

/// Standard metric display component for cards
struct FLMetricView: View {
    let value: String
    let unit: String
    let label: String
    let valueColor: Color
    let unitColor: Color

    init(
        value: String,
        unit: String = "",
        label: String,
        valueColor: Color = Color("FLPrimary"),
        unitColor: Color = Color("FLSuccess")
    ) {
        self.value = value
        self.unit = unit
        self.label = label
        self.valueColor = valueColor
        self.unitColor = unitColor
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(valueColor)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.title2)
                        .foregroundColor(unitColor)
                }
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Primary card example
        FLCard(style: .primary) {
            FLMetricView(
                value: "182.4",
                unit: "lbs",
                label: "Current Weight"
            )
        }

        // Success card example
        FLCard(style: .success) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color("FLSuccess"))
                    .font(.title)
                Text("Goal achieved!")
                    .font(.headline)
                    .foregroundColor(Color("FLSuccess"))
            }
        }

        // Stats card example
        FLCard(style: .stats) {
            HStack {
                FLMetricView(value: "7", label: "Days")
                Spacer()
                FLMetricView(value: "2.1", unit: "lbs", label: "Lost")
            }
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}