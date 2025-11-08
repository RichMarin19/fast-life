import SwiftUI

enum WeightProgressStoryMilestoneLocalization {
    static func localized(_ key: String, comment: StaticString = "") -> String {
        NSLocalizedString(key, bundle: .main, comment: String(describing: comment))
    }

    static func unitAbbreviation(for locale: Locale = .current) -> String {
        isMetric(locale: locale)
            ? localized("progress_story_unit_kg", comment: "Kilogram unit abbreviation")
            : localized("progress_story_unit_lbs", comment: "Pound unit abbreviation")
    }

    static func formattedWeight(_ pounds: Double, locale: Locale = .current) -> String {
        let value = isMetric(locale: locale)
            ? Measurement(value: pounds, unit: UnitMass.pounds).converted(to: .kilograms).value
            : pounds

        formatter.locale = locale
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = value.truncatingRemainder(dividingBy: 1).isZero ? 0 : 1
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    static func accessibilityLabel(
        tag: String,
        formattedValue: String?,
        unitAbbreviation: String,
        periodLabel: String
    ) -> String {
        if let value = formattedValue {
            let template = localized("progress_story_milestone_accessibility", comment: "Milestone accessibility label")
            return String(format: template, tag, value, unitAbbreviation, periodLabel)
        } else {
            let template = localized("progress_story_milestone_accessibility_no_data", comment: "Milestone accessibility no data label")
            return String(format: template, tag, periodLabel)
        }
    }

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private static func isMetric(locale: Locale) -> Bool {
        if #available(iOS 16.0, *) {
            return locale.measurementSystem == .metric
        } else {
            return locale.usesMetricSystem
        }
    }
}

struct CircularTrendRingCard: View {
    let periodLabel: String  // "7 DAYS" or "30 DAYS"
    let delta: Double?       // Signed value (negative = loss)
    let surfaceStyle: WeightProgressStorySurfaceStyle
    let locale: Locale
    let onHide: () -> Void   // Hide card callback
    private let unitAbbreviation: String
    private let formatWeight: (Double) -> String

    @State private var animateRing = false  // Ring sweep animation
    @State private var showWinHalo = false  // v1.2b: Win halo animation (D.1)
    @Environment(\.accessibilityReduceMotion) var reduceMotion  // Respect Reduce Motion

    init(periodLabel: String,
         delta: Double?,
         surfaceStyle: WeightProgressStorySurfaceStyle,
         locale: Locale = .current,
         onHide: @escaping () -> Void) {
        self.periodLabel = periodLabel
        self.delta = delta
        self.surfaceStyle = surfaceStyle
        self.locale = locale
        self.onHide = onHide
        self.unitAbbreviation = WeightProgressStoryMilestoneLocalization.unitAbbreviation(for: locale)
        self.formatWeight = { value in
            WeightProgressStoryMilestoneLocalization.formattedWeight(value, locale: locale)
        }
    }

    private var state: WeightProgressStoryTrendState {
        guard let delta = delta else { return .flat }
        if delta < -0.2 { return .improving }
        if delta > 0.2 { return .regressing }
        return .flat
    }

    private var palette: WeightProgressStoryTrendPalette {
        WeightProgressStoryTrendPalette(state: state)
    }

    /// Gradient colors based on trend state per spec §3
    /// Loss → Teal → Blue
    /// Gain → Coral → Rose
    /// Stable → Gold → Amber
    private var ringGradient: LinearGradient {
        palette.gradient
    }

    private var formattedDelta: String? {
        delta.map { formatWeight(abs($0)) }
    }

    private var tag: String {
        guard let delta = delta else {
            return WeightProgressStoryMilestoneLocalization.localized("progress_story_metric_no_data", comment: "Milestone no data tag")
        }
        if delta < -0.2 {
            return WeightProgressStoryMilestoneLocalization.localized("progress_story_metric_tag_lost", comment: "Milestone lost tag")
        }
        if delta > 0.2 {
            return WeightProgressStoryMilestoneLocalization.localized("progress_story_metric_tag_gained", comment: "Milestone gained tag")
        }
        return WeightProgressStoryMilestoneLocalization.localized("progress_story_metric_tag_flat", comment: "Milestone flat tag")
    }

    /// Microcopy per spec §6
    /// v1.2: Added exclamation points for motivational emphasis
    private var microcopy: String {
        switch state {
        case .improving:
            return WeightProgressStoryMilestoneLocalization.localized("progress_story_milestone_microcopy_improving")
        case .regressing:
            return WeightProgressStoryMilestoneLocalization.localized("progress_story_milestone_microcopy_regressing")
        case .flat:
            return WeightProgressStoryMilestoneLocalization.localized("progress_story_milestone_microcopy_flat")
        }
    }

    /// Ring progress (0.0 - 1.0) - simplified for v1
    /// TODO: Calculate actual progress based on goal distance
    private var ringProgress: Double {
        guard let delta = delta else { return 0.0 }
        // Simple mapping: 0-5 lbs = 0.0-1.0 ring fill
        let maxChange: Double = 5.0
        let normalizedProgress = min(abs(delta) / maxChange, 1.0)
        return normalizedProgress
    }

    /// Accent color for ring glow based on trend state
    /// Per v1.1 spec §4: Ambient glow uses accent color at 35% opacity
    private var accentColor: Color {
        switch state {
        case .improving:  // Weight loss → Success green
            return Theme.ColorToken.stateSuccess
        case .regressing:  // Weight gain → Coral (non-judgmental)
            return Theme.ColorToken.accentCoral
        case .flat:  // Stable → Gold
            return Theme.ColorToken.accentGold
        }
    }

    /// Emotion indicator icon (v1.1 spec §7)
    /// Returns SF Symbol name for trend state
    private func emotionIcon(for state: WeightProgressStoryTrendState) -> String {
        switch state {
        case .improving:  return "checkmark.seal"           // Trend down
        case .regressing: return "arrow.up.right.circle"    // Trend up
        case .flat:       return "pause.circle"             // Holding steady
        }
    }

    /// Emotion indicator label (v1.1 spec §7)
    /// Returns text label for trend state
    private func emotionLabel(for state: WeightProgressStoryTrendState) -> String {
        switch state {
        case .improving:
            return WeightProgressStoryMilestoneLocalization.localized("progress_story_milestone_emotion_improving")
        case .regressing:
            return WeightProgressStoryMilestoneLocalization.localized("progress_story_milestone_emotion_regressing")
        case .flat:
            return WeightProgressStoryMilestoneLocalization.localized("progress_story_milestone_emotion_flat")
        }
    }

    var body: some View {
        WeightProgressStorySurfaceCard(style: surfaceStyle, onHide: onHide) {
            VStack(spacing: DSSpacing.cardSectionSpacing) {
                // CIRCULAR PROGRESS RING
                // v1.2: Centered horizontally (user requirement: all center icons/imagery centered by default)
                ZStack {
                    // WIN HALO (v1.2b) - Expanding + fading celebration when trend = improving
                    // Per v1.2 spec D.1: One-time animation on appear, skip on Reduce Motion
                    if state == .improving && !reduceMotion {
                        Circle()
                            .stroke(accentColor.opacity(0.15), lineWidth: 8)
                            .frame(width: 180, height: 180)
                            .scaleEffect(showWinHalo ? 1.12 : 1.0)
                            .opacity(showWinHalo ? 0.0 : 1.0)
                            .animation(.easeOut(duration: 0.9), value: showWinHalo)
                    }

                    // v1.2d: Replaced duplicated ring code with DSProgressRing component
                    // Industry Pattern: Apple Watch Activity Rings
                    // Extracted to eliminate ~60-80 lines of duplication across CircularTrendRingCard + MilestoneRingCard
                    DSProgressRing(
                        progress: ringProgress,
                        size: 160,
                        strokeWidth: 12,
                        progressGradient: ringGradient,
                        trackColor: Color.white.opacity(0.2),
                        glowColor: accentColor,
                        glowIntensity: 0.40,
                        enableGlow: true,
                        enableHalo: true,
                        animationDuration: 1.2,
                        animateProgress: $animateRing
                    )

                    // Center content - Weight change value
                    VStack(spacing: DSSpacing.cardExtraSmallSpacing) {
                        HStack(alignment: .firstTextBaseline, spacing: DSSpacing.cardExtraSmallSpacing) {
                            Text(formattedDelta ?? "--")
                                .font(DSTypography.statValueLarge)
                                .foregroundColor(Theme.ColorToken.textPrimary)

                            Text(verbatim: unitAbbreviation)
                                .font(DSTypography.cardSubtitle)
                                .foregroundColor(Theme.ColorToken.textSecondary)
                        }

                        // Emotion Indicator (v1.2) - Icon + Label
                        // Per v1.2 spec C.3: Enhanced sizes for better legibility
                        // Icon: 20pt, Label: 14pt semibold
                        if delta != nil {
                            HStack(spacing: DSSpacing.cardExtraSmallSpacing) {
                                Image(systemName: emotionIcon(for: state))
                                    .font(DSTypography.displayS)
                                    .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.8))

                                Text(emotionLabel(for: state))
                                    .font(DSTypography.cardSubtitle)
                                    .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.8))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, DSSpacing.cardSmallSpacing)

                // TAG + PERIOD LABEL
                HStack(spacing: DSSpacing.cardSmallSpacing) {
                    Text(tag)
                        .font(DSTypography.pillLabel)
                        .foregroundColor(Theme.ColorToken.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                        )

                    Text(periodLabel)
                        .font(DSTypography.labelSecondary)
                        .foregroundColor(Theme.ColorToken.textSecondary)
                }

                // MICROCOPY (motivational message)
                Text(microcopy)
                    .font(DSTypography.iconButton)
                    .foregroundColor(Theme.ColorToken.textPrimary.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, DSSpacing.cardElementSpacing)
            }
            .padding(.vertical, DSSpacing.cardSmallSpacing)
        }
        .onAppear {
            // Trigger ring animation on appear
            animateRing = true

            // v1.2b: Trigger win halo animation (D.1) - only when improving + Reduce Motion OFF
            if state == .improving && !reduceMotion {
                showWinHalo = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        WeightProgressStoryMilestoneLocalization.accessibilityLabel(
            tag: tag,
            formattedValue: formattedDelta,
            unitAbbreviation: unitAbbreviation,
            periodLabel: periodLabel
        )
    }
}

/// LEGACY: Trend Card Full-Width - Simple flat number display
/// Replaced by CircularTrendRingCard but kept for reference
/// Per Stacked v1.2 spec: Light surface card with WeightProgressStorySurfaceCard wrapper

struct TrendCardFull: View {
    let periodLabel: String  // "7 DAYS" or "30 DAYS"
    let delta: Double?       // Signed value (negative = loss)
    let surfaceStyle: WeightProgressStorySurfaceStyle
    let locale: Locale
    let onHide: () -> Void   // Hide card callback
    private let unitAbbreviation: String
    private let formatWeight: (Double) -> String

    init(periodLabel: String,
         delta: Double?,
         surfaceStyle: WeightProgressStorySurfaceStyle,
         locale: Locale = .current,
         onHide: @escaping () -> Void) {
        self.periodLabel = periodLabel
        self.delta = delta
        self.surfaceStyle = surfaceStyle
        self.locale = locale
        self.onHide = onHide
        self.unitAbbreviation = WeightProgressStoryMilestoneLocalization.unitAbbreviation(for: locale)
        self.formatWeight = { value in
            WeightProgressStoryMilestoneLocalization.formattedWeight(value, locale: locale)
        }
    }

    private var state: WeightProgressStoryTrendState {
        guard let delta = delta else { return .flat }
        if delta < -0.2 { return .improving }
        if delta > 0.2 { return .regressing }
        return .flat
    }

    private var accent: Color {
        switch state {
        case .improving: return Theme.ColorToken.stateSuccess
        case .regressing: return Theme.ColorToken.stateError
        case .flat: return Theme.ColorToken.textSecondary.opacity(0.8)
        }
    }

    private var tag: String {
        guard let delta = delta else {
            return WeightProgressStoryMilestoneLocalization.localized("progress_story_metric_no_data", comment: "Milestone no data tag")
        }
        if delta < -0.2 {
            return WeightProgressStoryMilestoneLocalization.localized("progress_story_metric_tag_lost", comment: "Milestone lost tag")
        }
        if delta > 0.2 {
            return WeightProgressStoryMilestoneLocalization.localized("progress_story_metric_tag_gained", comment: "Milestone gained tag")
        }
        return WeightProgressStoryMilestoneLocalization.localized("progress_story_metric_tag_flat", comment: "Milestone flat tag")
    }

    private var formattedDelta: String? {
        delta.map { formatWeight(abs($0)) }
    }

    var body: some View {
        WeightProgressStorySurfaceCard(style: surfaceStyle, onHide: onHide) {
            VStack(alignment: .leading, spacing: DSSpacing.cardElementSpacing) {
                // Top accent bar (3pt height)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(accent)
                    .frame(height: 3)
                    .opacity(0.9)

                // Primary number + unit
                HStack(alignment: .lastTextBaseline, spacing: DSSpacing.cardSmallSpacing) {
                    Text(formattedDelta ?? "--")
                        .font(DSTypography.displayHero)
                        .foregroundColor(Theme.ColorToken.textPrimary)

                    Text(verbatim: unitAbbreviation)
                        .font(DSTypography.listTitle)
                        .foregroundColor(Theme.ColorToken.textSecondary)

                    Spacer()
                }

                // Tag + Period label
                HStack(spacing: DSSpacing.cardSmallSpacing) {
                    Text(tag)
                        .font(DSTypography.statLabel)
                        .padding(.horizontal, DSSpacing.cardSmallSpacing)
                        .padding(.vertical, DSSpacing.cardExtraSmallSpacing)
                        .background(accent.opacity(0.18))
                        .clipShape(Capsule())
                        .foregroundColor(accent)

                    Text(periodLabel)
                        .font(DSTypography.listCaption)
                        .foregroundColor(Theme.ColorToken.textSecondary)

                    Spacer()

                    // Chevron disclosure
                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.ColorToken.textSecondary.opacity(0.8))
                        .font(DSTypography.listCaption)
                }
            }
        }
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            WeightProgressStoryMilestoneLocalization.accessibilityLabel(
                tag: tag,
                formattedValue: formattedDelta,
                unitAbbreviation: unitAbbreviation,
                periodLabel: periodLabel
            )
        )
    }
}

/// Recap Row - Three metrics in single row (Net Δ | Streak | Entries)
/// Per Stacked v1.2 spec: Mint surface with eye.slash dismiss on RIGHT (matching DSCard pattern)
/// Updated: Eye-slash moved from LEFT to RIGHT to match DSCardHeader
/// v1.2b: Added streak badge system (D.2) - badge dot + haptic when new best streak achieved
/// v1.2e: Refactored to use DSBanner component for uniform container sizing

struct TrendCard: View {
    let title: String
    let trend: (amount: Double, isLoss: Bool)?
    let locale: Locale
    private let unitAbbreviation: String
    private let formatWeight: (Double) -> String

    init(title: String, trend: (amount: Double, isLoss: Bool)?, locale: Locale = .current) {
        self.title = title
        self.trend = trend
        self.locale = locale
        self.unitAbbreviation = WeightProgressStoryMilestoneLocalization.unitAbbreviation(for: locale)
        self.formatWeight = { value in
            WeightProgressStoryMilestoneLocalization.formattedWeight(value, locale: locale)
        }
    }

    var body: some View {
        VStack(spacing: DSSpacing.cardSmallSpacing) {
            if let trend = trend {
                // Top: Celebration emoji (EXCITING!)
                Text(trendEmoji(for: trend))
                    .font(DSTypography.displayHero)
                    .padding(.top, DSSpacing.cardSmallSpacing)

                // Middle: HUGE number + lbs (IMPACTFUL!)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(formatWeight(abs(trend.amount)))
                        .font(DSTypography.displayXXL)
                        .foregroundColor(.white)
                    Text(verbatim: unitAbbreviation)
                        .font(DSTypography.statValueSmall)
                        .foregroundColor(.white.opacity(0.9))
                }

                // Status pill (like weight lost pill!)
                Text(trend.isLoss ? LocalizedStringKey("progress_story_metric_tag_lost") : LocalizedStringKey("progress_story_metric_tag_gained"))
                    .font(DSTypography.pillLabel)
                    .foregroundColor(.white)
                    .padding(.horizontal, DSSpacing.cardElementSpacing)
                    .padding(.vertical, DSSpacing.cardExtraSmallSpacing)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                    )

                // Period label (clear but subtle)
                Text(title)
                    .font(DSTypography.periodLabel)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, DSSpacing.cardExtraSmallSpacing)
            } else {
                // No data state
                Text("📊")
                    .font(DSTypography.displayHero)
                    .padding(.top, DSSpacing.cardSmallSpacing)

                Text("--")
                    .font(DSTypography.displayXXL)
                    .foregroundColor(.white.opacity(0.6))

                Text("progress_story_metric_no_data")
                    .font(DSTypography.pillLabel)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, DSSpacing.cardElementSpacing)
                    .padding(.vertical, DSSpacing.cardExtraSmallSpacing)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )

                Text(title)
                    .font(DSTypography.periodLabel)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, DSSpacing.cardExtraSmallSpacing)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DSSpacing.cardSectionSpacing)
        .padding(.horizontal, DSSpacing.cardPadding)  // Internal padding for content breathing room
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardGradient)
        )
        .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
    }

    /// Luxury gradient background per Theme.ColorToken design system
    /// Loss: Emerald green gradient (success)
    /// Gain: Orange/red gradient (caution/warning)
    /// Per UI/UX spec: Deep navy background, gold highlights, green for success
    private var cardGradient: LinearGradient {
        guard let trend = trend else {
            // No data: Gray gradient
            return LinearGradient(
                colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if trend.isLoss {
            // Loss: Emerald gradient per luxury UI spec
            // Using accentPrimary (emerald #1ABC9C) for success states
            return LinearGradient(
                colors: [Theme.ColorToken.accentPrimary, Theme.ColorToken.accentPrimary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Gain: Warning/Error gradient per luxury UI spec
            // Using stateWarning (amber) for gentle caution
            return LinearGradient(
                colors: [Theme.ColorToken.stateWarning, Theme.ColorToken.stateWarning.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Shadow color matches card gradient per luxury UI spec
    private var shadowColor: Color {
        guard let trend = trend else {
            return Color.gray.opacity(0.3)
        }

        if trend.isLoss {
            // Loss: Emerald shadow for success
            return Theme.ColorToken.accentPrimary.opacity(0.3)
        } else {
            // Gain: Amber shadow for caution
            return Theme.ColorToken.stateWarning.opacity(0.3)
        }
    }

    /// Dynamic emoji based on trend - CELEBRATION!
    private func trendEmoji(for trend: (amount: Double, isLoss: Bool)) -> String {
        if trend.isLoss {
            // Celebration emojis for weight loss!
            switch trend.amount {
            case 0..<1:
                return "👍"  // Small progress
            case 1..<2:
                return "💪"  // Good progress
            case 2..<3:
                return "⭐️"  // Great progress
            case 3..<5:
                return "🔥"  // Excellent progress
            case 5..<10:
                return "🏆"  // Amazing progress
            default:
                return "🚀"  // Incredible progress!
            }
        } else {
            // Gentle supportive emojis for weight gain
            switch trend.amount {
            case 0..<1:
                return "💧"  // Just water weight
            case 1..<2:
                return "🤝"  // Small fluctuation
            case 2..<5:
                return "💙"  // Keep going
            default:
                return "🫂"  // Still on the journey
            }
        }
    }
}

// MARK: - Drag-and-Drop Delegate (Phase v1.4b Layer 4)

/// ProgressStoryCardDropDelegate - Handles drop events for reordering Progress Story cards
/// Per Phase v1.4b: Apple Health Edit button pattern with SwiftUI official drag-and-drop API
/// Triggers CardManager.reorderCards(from:to:) when user drops a card on another card
