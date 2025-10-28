//
// AInsteinPresenceView.swift
// FastingTracker
//
// Created for Phase 5B: Floating Overlay Implementation
// Industry Pattern: Whoop ambient presence, Oura readiness ring, Levels glucose score
// Reference: docs/planning/PHASE-5-AINSTEIN-UI-TRANSFORMATION.md
//

import SwiftUI
import os.log

// MARK: - AInstein Presence State

/// State machine for AInstein floating overlay
enum AInsteinPresenceState {
    case welcome        // Center introduction card (every Hub open until dismissed)
    case idle          // Bottom-right floating icon (30% opacity)
    case thinking      // Analyzing data (pulse animation)
    case insightReady  // Has message (glow animation)
    case active        // User tapped, chat overlay open
}

// MARK: - AInstein Position

/// Position options for AInstein floating icon
/// Industry Pattern: iOS Assistive Touch, WhatsApp chat heads, Messenger bubbles
enum AInsteinPosition: String, CaseIterable, Identifiable {
    case topLeft = "top_left"
    case topRight = "top_right"
    case bottomLeft = "bottom_left"
    case bottomRight = "bottom_right"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        }
    }

    /// SwiftUI alignment for positioning
    var alignment: Alignment {
        switch self {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }

    /// SF Symbol icon for position picker
    var icon: String {
        switch self {
        case .topLeft: return "arrow.up.left"
        case .topRight: return "arrow.up.right"
        case .bottomLeft: return "arrow.down.left"
        case .bottomRight: return "arrow.down.right"
        }
    }
}

// MARK: - AInstein Presence View

/// Floating overlay component for AInstein ambient presence
/// **Architecture:** State-driven UI with animation transitions
/// **Behavioral Science:** Familiar cue loop, anticipation bias, variable reward
struct AInsteinPresenceView: View {

    // MARK: - Dependencies

    let dataService: UnifiedHealthDataService

    @AppStorage("hasSeenAInsteinWelcome") private var hasSeenWelcome: Bool = false
    @AppStorage("ainsteinPosition") private var selectedPositionRaw: String = AInsteinPosition.bottomRight.rawValue

    @State private var currentState: AInsteinPresenceState = .welcome
    @State private var showChatOverlay: Bool = false
    @State private var showPositionPicker: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    /// Current selected position (computed from AppStorage)
    private var selectedPosition: AInsteinPosition {
        AInsteinPosition(rawValue: selectedPositionRaw) ?? .bottomRight
    }

    // MARK: - Logger

    private let logger = Logger(subsystem: "com.fastlife.FastingTracker", category: "AInsteinPresence")

    // MARK: - Design Tokens

    /// Icon size for floating state (48-56pt per spec)
    private let iconSize: CGFloat = 52

    /// Welcome card size (center introduction)
    private let welcomeCardWidth: CGFloat = 280
    private let welcomeCardHeight: CGFloat = 320

    /// Position offset (margin from screen edge)
    private let positionOffset: CGFloat = 20

    /// Animation duration (spring animation)
    private let animationDuration: Double = 0.8

    // MARK: - Body

    var body: some View {
        ZStack {
            // Welcome state: Center introduction card
            if currentState == .welcome && !hasSeenWelcome {
                welcomeCard
                    .transition(.scale.combined(with: .opacity))
            }

            // Idle/Thinking/Insight Ready states: Floating icon
            if currentState != .welcome || hasSeenWelcome {
                floatingIcon
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Active state: Chat overlay (full screen)
            if showChatOverlay {
                chatOverlay
                    .transition(.move(edge: .bottom))
            }

            // Position picker overlay
            if showPositionPicker {
                positionPickerOverlay
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            // Check if we should show welcome card
            if !hasSeenWelcome {
                currentState = .welcome
            } else {
                currentState = .idle
            }
        }
    }

    // MARK: - Welcome Card

    /// Center introduction card (first time Hub opens)
    private var welcomeCard: some View {
        VStack(spacing: 16) {
            // Icon
            Circle()
                .fill(iconGradient)
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                )

            // Title
            Text("Meet AInstein")
                .font(Theme.Font.title(24))
                .foregroundColor(Theme.ColorToken.textPrimary)

            // Description
            Text("Your intelligent companion for fasting and health insights. I'll analyze your patterns and share personalized guidance when it matters.")
                .font(Theme.Font.body(15))
                .foregroundColor(Theme.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // CTA Button
            Button(action: dismissWelcomeCard) {
                Text("Got it")
                    .font(Theme.Font.headline(17))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.ColorToken.accentPrimary)
                    .cornerRadius(DSCornerRadius.button)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: welcomeCardWidth)
        .background(glassBackground)
        .cornerRadius(DSCornerRadius.card)
        .shadow(color: Theme.ColorToken.shadowCard, radius: 20, x: 0, y: 10)
    }

    // MARK: - Floating Icon

    /// Dynamically positioned floating icon (idle/thinking/insight ready states)
    private var floatingIcon: some View {
        ZStack(alignment: selectedPosition.alignment) {
            Color.clear // Full screen container

            Button(action: openChatOverlay) {
                Circle()
                    .fill(glassBackground)
                    .frame(width: iconSize, height: iconSize)
                    .overlay(
                        Circle()
                            .stroke(iconBorderColor, lineWidth: 1.5)
                    )
                    .overlay(
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(iconColor)
                    )
                    .shadow(color: Theme.ColorToken.shadowCard, radius: 10, x: 0, y: 4)
                    .opacity(iconOpacity)
                    .scaleEffect(iconScale)
            }
            .frame(width: Theme.TapTarget.minimum, height: Theme.TapTarget.minimum)
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 0.5) {
                // Long-press to open position picker
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showPositionPicker = true
                }
                logger.info("Position picker opened")
            }
            .padding(positionOffset) // Margin from screen edge
        }
    }

    // MARK: - Chat Overlay

    /// Full-screen chat overlay (active state)
    /// Displays actual LIFeGPTChatView interface
    private var chatOverlay: some View {
        ZStack {
            // Background dimming
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    closeChatOverlay()
                }

            // Chat interface (full LifeGPT)
            VStack {
                Spacer()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("AInstein")
                            .font(Theme.Font.title(20))
                            .foregroundColor(Theme.ColorToken.textPrimary)

                        Spacer()

                        Button(action: closeChatOverlay) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Theme.ColorToken.textSecondary)
                        }
                    }
                    .padding()

                    Divider()

                    // LifeGPT Chat Interface
                    LIFeGPTChatView(dataService: dataService)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: 500)
                .background(Theme.ColorToken.card)
                .cornerRadius(DSCornerRadius.card)
                .shadow(color: Theme.ColorToken.shadowCard, radius: 30, x: 0, y: -10)
                .padding()
            }
        }
    }

    // MARK: - Position Picker Overlay

    /// Position picker menu (long-press activated)
    private var positionPickerOverlay: some View {
        ZStack {
            // Background dimming
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPositionPicker = false
                    }
                }

            // Position picker card
            VStack(spacing: 20) {
                Text("Choose Position")
                    .font(Theme.Font.headline(20))
                    .foregroundColor(Theme.ColorToken.textPrimary)

                // 2x2 grid of position buttons
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        PositionButton(position: .topLeft, isSelected: selectedPosition == .topLeft, action: selectPosition)
                        PositionButton(position: .topRight, isSelected: selectedPosition == .topRight, action: selectPosition)
                    }
                    HStack(spacing: 12) {
                        PositionButton(position: .bottomLeft, isSelected: selectedPosition == .bottomLeft, action: selectPosition)
                        PositionButton(position: .bottomRight, isSelected: selectedPosition == .bottomRight, action: selectPosition)
                    }
                }
            }
            .padding(24)
            .background(Theme.ColorToken.card)
            .cornerRadius(DSCornerRadius.card)
            .shadow(color: Theme.ColorToken.shadowCard, radius: 30, x: 0, y: 10)
        }
    }

    // MARK: - Computed Properties

    /// Glass background for luxury aesthetic
    private var glassBackground: some ShapeStyle {
        // Light mode: White with subtle opacity
        // Dark mode: White with lower opacity (glass-morphism)
        return colorScheme == .dark
            ? Color.white.opacity(0.12)
            : Color.white.opacity(0.95)
    }

    /// Icon gradient based on color scheme
    private var iconGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Theme.ColorToken.accentPrimary, Theme.ColorToken.accentInfo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Theme.ColorToken.accentGold, Theme.ColorToken.accentPrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Icon color based on state and color scheme
    private var iconColor: Color {
        switch currentState {
        case .welcome:
            return colorScheme == .dark ? Theme.ColorToken.accentPrimary : Theme.ColorToken.accentGold
        case .idle:
            return colorScheme == .dark ? Theme.ColorToken.accentPrimary : Theme.ColorToken.accentGold
        case .thinking:
            return Theme.ColorToken.accentInfo
        case .insightReady:
            return Theme.ColorToken.accentGold
        case .active:
            return Theme.ColorToken.accentPrimary
        }
    }

    /// Icon border color
    private var iconBorderColor: Color {
        return colorScheme == .dark
            ? Color.white.opacity(0.2)
            : Color.black.opacity(0.08)
    }

    /// Icon opacity based on state
    private var iconOpacity: Double {
        switch currentState {
        case .welcome:
            return 1.0
        case .idle:
            return 0.3  // Subtle presence (per spec)
        case .thinking:
            return 0.6  // More visible during thinking
        case .insightReady:
            return 1.0  // Full visibility for insight
        case .active:
            return 1.0
        }
    }

    /// Icon scale for pulse animation
    private var iconScale: CGFloat {
        switch currentState {
        case .thinking:
            return 1.1  // Pulse effect
        case .insightReady:
            return 1.05 // Subtle glow
        default:
            return 1.0
        }
    }

    // MARK: - Actions

    /// Dismiss welcome card and animate to bottom-right corner
    private func dismissWelcomeCard() {
        logger.info("Dismissing welcome card")

        withAnimation(.spring(response: animationDuration, dampingFraction: Theme.Animation.springDamping)) {
            hasSeenWelcome = true
            currentState = .idle
        }
    }

    /// Open chat overlay
    private func openChatOverlay() {
        logger.info("Opening chat overlay")

        withAnimation(.spring(response: Theme.Animation.standard, dampingFraction: Theme.Animation.springDamping)) {
            currentState = .active
            showChatOverlay = true
        }
    }

    /// Close chat overlay
    private func closeChatOverlay() {
        logger.info("Closing chat overlay")

        withAnimation(.spring(response: Theme.Animation.standard, dampingFraction: Theme.Animation.springDamping)) {
            showChatOverlay = false
            currentState = .idle
        }
    }

    /// Select position for AInstein icon
    private func selectPosition(_ position: AInsteinPosition) {
        logger.info("Position selected: \(position.rawValue)")

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            selectedPositionRaw = position.rawValue
            showPositionPicker = false
        }
    }

    // MARK: - Public API (for external state changes)

    /// Trigger thinking state (when analyzing data)
    func startThinking() {
        guard currentState == .idle else { return }

        withAnimation(.easeInOut(duration: Theme.Animation.quick).repeatForever(autoreverses: true)) {
            currentState = .thinking
        }
    }

    /// Trigger insight ready state (when insight available)
    func showInsightReady() {
        withAnimation(.easeInOut(duration: Theme.Animation.glow).repeatForever(autoreverses: true)) {
            currentState = .insightReady
        }
    }

    /// Return to idle state
    func returnToIdle() {
        withAnimation(.easeOut(duration: Theme.Animation.quick)) {
            currentState = .idle
        }
    }
}

// MARK: - Position Button Component

/// Individual position button for picker menu
struct PositionButton: View {
    let position: AInsteinPosition
    let isSelected: Bool
    let action: (AInsteinPosition) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: { action(position) }) {
            VStack(spacing: 8) {
                // Icon
                Image(systemName: position.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(iconColor)

                // Label
                Text(position.displayName)
                    .font(Theme.Font.body(12))
                    .foregroundColor(Theme.ColorToken.textSecondary)
            }
            .frame(width: 80, height: 80)
            .background(buttonBackground)
            .cornerRadius(DSCornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: DSCornerRadius.button)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
    }

    private var iconColor: Color {
        isSelected ? Theme.ColorToken.accentPrimary : Theme.ColorToken.textSecondary
    }

    private var buttonBackground: Color {
        if isSelected {
            return colorScheme == .dark
                ? Color.white.opacity(0.15)
                : Theme.ColorToken.accentPrimary.opacity(0.1)
        } else {
            return colorScheme == .dark
                ? Color.white.opacity(0.05)
                : Color.black.opacity(0.03)
        }
    }

    private var borderColor: Color {
        isSelected
            ? Theme.ColorToken.accentPrimary
            : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
    }
}

// MARK: - Preview

#Preview("Welcome State") {
    ZStack {
        Theme.ColorToken.bgDeepStart
            .ignoresSafeArea()

        AInsteinPresenceView(
            dataService: UnifiedHealthDataService(
                weightManager: WeightManager(),
                fastingManager: FastingManager(),
                sleepManager: SleepManager(),
                hydrationManager: HydrationManager(),
                moodManager: MoodManager()
            )
        )
    }
}

#Preview("Idle State") {
    ZStack {
        Theme.ColorToken.bgDeepStart
            .ignoresSafeArea()

        AInsteinPresenceView(
            dataService: UnifiedHealthDataService(
                weightManager: WeightManager(),
                fastingManager: FastingManager(),
                sleepManager: SleepManager(),
                hydrationManager: HydrationManager(),
                moodManager: MoodManager()
            )
        )
        .onAppear {
            UserDefaults.standard.set(true, forKey: "hasSeenAInsteinWelcome")
        }
    }
}
