//
// LIFeGPTChatView.swift
// FastingTracker
//
// Created for LifeGPT Feature - Phase 1 Hour 3
// Main chat interface with emotion-aware theming and animations
// Reference: FastLIFe_LIFeGPT_UI_Behavioral_Spec_Hour3.md (Section 3, 8)
//

import SwiftUI

// MARK: - LifeGPT Chat View

/// Main chat interface for LifeGPT AI Health Coach
/// **Industry Pattern:** iMessage, WhatsApp, Slack (chat UX standards)
///
/// **Features:**
/// - ScrollView with messages (reversed, newest at bottom)
/// - ScrollViewReader for auto-scroll
/// - Keyboard avoidance
/// - Empty state with prompt chips
/// - Emotion-aware theming
/// - Typewriter reveal animations (1.03→1.0 easeOut 200ms)
/// - Sheet presentation with DSMotion.sheet.present
///
/// **Accessibility:**
/// - Dynamic Type support
/// - VoiceOver navigation
/// - Reduce Motion fallbacks
/// - Keyboard shortcuts
struct LIFeGPTChatView: View {
    @StateObject private var viewModel: LifeGPTViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var bottomID

    // Keyboard handling
    @FocusState private var isInputFocused: Bool

    // Reduce Motion accessibility
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Initialization

    /// Initialize chat view with data service dependency
    /// - Parameter dataService: Health data aggregator service
    init(dataService: HealthDataAggregator) {
        _viewModel = StateObject(wrappedValue: LifeGPTViewModel(dataService: dataService))
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()

                // Main content
                VStack(spacing: 0) {
                    // Messages scroll view
                    messagesScrollView

                    // Input bar (fixed at bottom)
                    inputBar
                        .padding(.horizontal, DSSpacing.cardElementSpacing)
                        .padding(.bottom, DSSpacing.cardSmallSpacing)
                }

                // First-launch loading overlay
                if viewModel.isFirstLaunchLoading {
                    LifeGPTLoadingOverlay()
                        .transition(.opacity)
                }
            }
            .navigationTitle("LifeGPT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    clearButton
                }
            }
        }
        .onAppear {
            // Pre-load HealthKit data on first launch (prevents freeze during first query)
            Task {
                await viewModel.preloadHealthData()
            }

            // Focus input after data loads
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }

    // MARK: - Background

    /// Background gradient (deep navy from design system)
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Theme.ColorToken.bgDeepStart,
                Theme.ColorToken.bgDeepMid,
                Theme.ColorToken.bgDeepEnd
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Messages Scroll View

    /// Messages scroll view with auto-scroll and empty state
    @ViewBuilder
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: DSSpacing.cardElementSpacing) {
                    if viewModel.messages.isEmpty {
                        // Empty state
                        emptyState
                    } else {
                        // Message list
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                                .transition(messageTransition)
                        }

                        // Typing indicator (when processing)
                        if viewModel.isProcessing {
                            TypingIndicator(emotion: currentEmotion)
                                .id(bottomID)
                                .transition(.opacity)
                        }
                    }
                }
                .padding(.horizontal, DSSpacing.cardElementSpacing)
                .padding(.top, DSSpacing.cardElementSpacing)
                .padding(.bottom, 24)
            }
            .onChange(of: viewModel.messages.count) { _ in
                // Auto-scroll to bottom on new message
                withAnimation(.easeOut(duration: 0.3)) {
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isProcessing) { isProcessing in
                // Auto-scroll to typing indicator
                if isProcessing {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
        }
    }

    /// Message reveal transition (respects Reduce Motion)
    private var messageTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        } else {
            return .scale(scale: 0.95).combined(with: .opacity)
        }
    }

    // MARK: - Empty State

    /// Empty state view with prompt chips
    @ViewBuilder
    private var emptyState: some View {
        LifeGPTEmptyState { prompt in
            // Handle prompt chip tap
            viewModel.inputText = prompt
            viewModel.sendQuery(prompt)
        }
        .padding(.top, 48)
    }

    // MARK: - Input Bar

    /// Input bar with emotion-aware placeholder
    @ViewBuilder
    private var inputBar: some View {
        LifeGPTInputBar(
            text: $viewModel.inputText,
            emotion: currentEmotion,
            onSend: {
                viewModel.sendQuery(viewModel.inputText)
            }
        )
        .focused($isInputFocused)
    }

    // MARK: - Toolbar Buttons

    /// Close button
    @ViewBuilder
    private var closeButton: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Theme.ColorToken.textSecondaryOnDark)
        }
        .accessibilityLabel("Close chat")
    }

    /// Clear chat button
    @ViewBuilder
    private var clearButton: some View {
        Button(action: {
            withAnimation {
                viewModel.clearChat()
            }
        }) {
            Image(systemName: "arrow.counterclockwise.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Theme.ColorToken.textSecondaryOnDark)
        }
        .accessibilityLabel("Clear chat history")
    }

    // MARK: - Helpers

    /// Current emotion state for theming
    /// Uses last assistant message emotion, defaults to stable
    private var currentEmotion: EmotionState {
        viewModel.messages.last(where: { $0.isFromAssistant })?.emotion ?? .stable
    }
}

// MARK: - Design System Spacing
// Using global DSSpacing from Core/DesignSystem/DSSpacing.swift

// MARK: - Preview Provider

#if DEBUG
struct LIFeGPTChatView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock data service for preview
        let mockService = MockHealthDataService()

        LIFeGPTChatView(dataService: mockService)
            .preferredColorScheme(.dark)
    }
}

/// Mock health data service for previews
class MockHealthDataService: HealthDataAggregator {
    func fetchAllWeightData() async -> [WeightEntry] { [] }
    func fetchWeightData(from startDate: Date, to endDate: Date) async -> [WeightEntry] { [] }
    func getCurrentWeight() async -> WeightEntry? { nil }
    func fetchWeightLastWeek() async -> [WeightEntry] { [] }
    func fetchAllFastingSessions() async -> [FastingSession] { [] }
    func fetchFastingSessions(from startDate: Date, to endDate: Date) async -> [FastingSession] { [] }
    func getCurrentFast() async -> FastingSession? { nil }
    func fetchFastingThisWeek() async -> [FastingSession] { [] }
    func fetchAllSleepData() async -> [SleepEntry] { [] }
    func fetchSleepData(from startDate: Date, to endDate: Date) async -> [SleepEntry] { [] }
    func getLastNightSleep() async -> SleepEntry? { nil }
    func fetchAllHydrationData() async -> [(Date, Double)] { [] }
    func fetchHydrationData(from startDate: Date, to endDate: Date) async -> [(Date, Double)] { [] }
    func getTodayHydration() async -> Double { 0 }
    func fetchAllMoodData() async -> [MoodEntry] { [] }
    func fetchMoodData(from startDate: Date, to endDate: Date) async -> [MoodEntry] { [] }
    func getTodayMood() async -> MoodEntry? { nil }
    func getTodaySummary() async -> [String: Any] { [:] }
    func getSummary(from startDate: Date, to endDate: Date) async -> [String: Any] { [:] }
}
#endif
