import SwiftUI

/*
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 📝 PROGRESS STORY PATTERN (Standardized for Reuse)
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 WHEN TO USE:
 Apply this pattern to ANY tracker that needs progress visualization:
 • Hydration Tracker: 7d/30d intake trends
 • Sleep Tracker: 7d/30d sleep quality trends
 • Mood Tracker: 7d/30d stability trends
 • Fasting Tracker: 7d/30d fasting completion trends

 INDUSTRY STANDARD:
 Follows Apple Health, MyFitnessPal, Strava pattern:
 • Stacked narrative (tell a story top-to-bottom)
 • Glass morphism UI (luxury feel on dark gradients)
 • Behavioral copy (adapting to user's trend state)
 • Educational tips (Did You Know banners)

 STANDARD IMPLEMENTATION NOTES:
 1️⃣ Trend calculation methods live in this view (pending future MVVM extraction).
 2️⃣ Components below use design tokens (DSSpacing, DSTypography, Theme).
 3️⃣ Reuse the subviews in `UI/Components/WeightProgressStory/` to assemble tracker-specific narratives.
 */

struct WeightTrendsView: View {
    @ObservedObject var weightManager: WeightManager
    @Environment(\.dismiss) private var dismiss

    // Unified opt-out system: ContentOptOutManager for all cards + global
    @ObservedObject private var optOutManager = ContentOptOutManager.shared

    // Progress Story Card Manager for master toggle visibility control
    @ObservedObject private var progressStoryCardManager = ProgressStoryCards.shared

    // Content IDs for opt-out tracking
    private let contentID_ProgressStory = "progress_story_v1"             // Global (toolbar button)
    private let contentID_CoachBar = "progress_story_coach_bar_v1"        // Coach Bar (v1.2)
    private let contentID_7Day = "progress_story_7day_v1"                 // 7-day card
    private let contentID_30Day = "progress_story_30day_v1"               // 30-day card
    private let contentID_Banner = "progress_story_banner_v1"             // Motivational banner
    private let contentID_ReflectionNudge = "progress_story_reflection_v1" // Reflection Nudge (v1.2b)
    private let contentID_Recap = "progress_story_recap_v1"               // Recap row
    private let contentID_Tip = "progress_story_tip_v1"                   // Did You Know

    // MARK: - Trend State Logic (Layer 1)

    /// Trend state classification per Stacked_v1.1 spec
    enum TrendState {
        case improving  // Δ < -0.2 (loss)
        case regressing // Δ > +0.2 (gain)
        case flat       // |Δ| ≤ 0.2
    }

    /// Calculate signed delta for a period using WeightManager Single Source of Truth
    /// Returns signed value (negative = loss, positive = gain)
    private func calculateDelta(days: Int) -> Double? {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        // SINGLE SOURCE OF TRUTH: Use WeightManager.weightChange(since:)
        // Returns: latestWeight - avgWeightOnOldestDay
        // Negative = weight loss, Positive = weight gain
        return weightManager.weightChange(since: cutoffDate)
    }

    /// Determine trend state from delta
    private func trendState(for delta: Double) -> TrendState {
        if delta < -0.2 { return .improving }
        if delta > 0.2 { return .regressing }
        return .flat
    }

    /// Calculate net delta across 30 days for recap row
    private var netDelta30d: Double {
        return calculateDelta(days: 30) ?? 0
    }

    /// Calculate best streak (placeholder - TODO)
    private var bestStreak: Int {
        return weightManager.weightEntries.count // Placeholder logic
    }

    /// Total entries count
    private var totalEntries: Int {
        return weightManager.weightEntries.count
    }

    /// Coach Bar text based on 7-day trend state (v1.1)
    /// Per v1.1 spec §5: Behavioral micro-copy under subtitle
    /// v1.2: Added exclamation points for motivational emphasis
    private func coachBarText(for state: TrendState) -> String {
        switch state {
        case .improving:
            return "Progress in motion — your consistency shows!"
        case .regressing:
            return "Weight gain is feedback, not failure — hydrate and sleep strong!"
        case .flat:
            return "Balance is mastery in motion — keep showing up!"
        }
    }

    /// Banner text based on 7-day trend state
    /// Per Stacked_v1.1 spec: Dynamic behavioral copy
    /// v1.2: Added exclamation points for motivational emphasis
    private func banner7Text(for state: TrendState) -> String {
        switch state {
        case .improving:
            return "Small wins compound. Keep stacking the days!"
        case .regressing:
            return "Course‑correct today. One choice changes the trend!"
        case .flat:
            return "Consistency is power. Nudge your routine by 1%!"
        }
    }

    /// Banner accent color based on trend state
    private func bannerAccentColor(for state: TrendState) -> Color {
        switch state {
        case .improving:
            return Theme.ColorToken.stateSuccess
        case .regressing:
            return Theme.ColorToken.stateError
        case .flat:
            return Theme.ColorToken.accentInfo
        }
    }

    /// Random "Did You Know" tip for educational banner
    /// Per Stacked_v1.1 spec: Max ~80 chars, no medical claims
    /// FASTING-FRIENDLY: Avoids time-specific meal names (breakfast/lunch/dinner)
    /// Fast LIFe users have flexible eating windows, so use universal language
    private func randomDidYouKnowTip() -> String {
        let tips = [
            "Drinking water before meals can reduce calorie intake.",
            "Sleep loss increases hunger hormones; protect your 7–8 hours.",
            "Protein at your first meal improves satiety for the day.",  // Fasting-friendly!
            "Consistent weigh-ins help track trends, not daily fluctuations.",
            "Strength training preserves muscle during weight loss."
        ]
        return tips.randomElement() ?? tips[0]
    }

    /// Random reflection prompt for ReflectionNudge banner
    /// Per v1.2 spec D.3: Rotates between 3 options to encourage micro-planning
    /// 🔧 FIX #7: Extracted as separate function for pre-computation pattern
    private func randomReflectionPrompt() -> String {
        let prompts = [
            "One small habit to try this week?",
            "What helped most on your best day?",
            "Pick tomorrow's anchor: sleep / steps / water."
        ]
        return prompts.randomElement() ?? prompts[0]
    }

    /// Calculate weight change over a specific number of days using WeightManager Single Source of Truth
    /// Returns (amount: Double, isLoss: Bool) or nil if insufficient data
    private func calculateTrend(days: Int?) -> (amount: Double, isLoss: Bool)? {
        let cutoffDate: Date
        if let days = days {
            cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        } else {
            // All-time trend: use date 10 years ago
            cutoffDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
        }

        // SINGLE SOURCE OF TRUTH: Use WeightManager.weightChange(since:)
        // Returns: latestWeight - avgWeightOnOldestDay
        // Negative = weight loss (isLoss = true), Positive = weight gain (isLoss = false)
        guard let change = weightManager.weightChange(since: cutoffDate) else { return nil }

        return (amount: abs(change), isLoss: change < 0)
    }

    @State private var isAnimating = false  // Animation state for staggered fade-in
    @Environment(\.accessibilityReduceMotion) var reduceMotion  // v1.1: Respect Reduce Motion
    @State private var moodAnimate = false  // v1.1: Mood background micro-drift animation

    // Phase v1.4b: Drag-to-Reorder State (following existing pattern - no Edit button)
    @State private var draggedCard: ProgressStoryCardType?  // Currently dragged card

    // 🔧 FIX #12: Stable text state - locked at view appearance, never changes during drag
    // Apple Health Pattern: Use @State for content that shouldn't change during interactions
    @State private var reflectionPromptText: String = ""  // Initialized in onAppear

    // MARK: - Adaptive Mood Overlay (v1.1)

    /// Returns adaptive mood gradient overlay based on trend state
    /// Per v1.1 spec §2: Subtle 12-18% opacity overlays on navy base
    /// Colors reflect emotional state without being alarmist
    private func adaptiveMoodOverlay(for state: TrendState) -> LinearGradient {
        switch state {
        case .improving:  // Weight loss (teal → blue)
            // Per v1.2 spec C.4: Enhanced opacity for better emotional feedback
            // Improving: top 0.22, bottom 0.16 (was 0.18/0.12)
            return LinearGradient(
                colors: [
                    Theme.ColorToken.moodImprovingStart.opacity(0.22),  // Teal
                    Theme.ColorToken.moodImprovingEnd.opacity(0.16)     // Blue
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .regressing:  // Weight gain (coral → peach)
            // Per v1.2 spec C.4: Enhanced opacity for better emotional feedback
            // Regressing: top 0.22, bottom 0.16 (was 0.18/0.12)
            return LinearGradient(
                colors: [
                    Theme.ColorToken.moodRegressingStart.opacity(0.22),  // Coral
                    Theme.ColorToken.moodRegressingEnd.opacity(0.16)     // Peach
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .flat:  // Stable (gold → light gold)
            // Per v1.2 spec C.4: Enhanced opacity for better emotional feedback
            // Stable: top 0.18, bottom 0.12 (was 0.16/0.10)
            return LinearGradient(
                colors: [
                    Theme.ColorToken.moodStableStart.opacity(0.18),  // Gold
                    Theme.ColorToken.moodStableEnd.opacity(0.12)     // Light gold
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var body: some View {
        NavigationView {
            // v1.1 Adaptive Background: Navy base + Mood overlay based on 7-day trend
            // Per FastLIFe_LIFeJourney_UIUX_v1.1_AdaptiveBehavioralDesign.md §3
            ZStack {
                // Layer 1: Deep 3-stop navy gradient (base canvas)
                LinearGradient(
                    colors: [
                        Theme.ColorToken.bgDeepStart,  // Top: #0C1A2B (calm base)
                        Theme.ColorToken.bgDeepMid,    // Mid: #0F2438 (breathing effect)
                        Theme.ColorToken.bgDeepEnd     // Bot: #123449 (depth)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Layer 2: Adaptive mood gradient overlay (12-18% opacity)
                // Driven by 7-day trend state: improving/regressing/stable
                // Changes color to reflect emotional tone without being alarmist
                adaptiveMoodOverlay(for: trendState(for: calculateDelta(days: 7) ?? 0))
                    .ignoresSafeArea()
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.6), value: calculateDelta(days: 7))
                    .offset(y: reduceMotion ? 0 : (moodAnimate ? -6 : 6))  // Micro drift (breathing effect)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 5).repeatForever(autoreverses: true),
                        value: moodAnimate
                    )

                ScrollView {
                    VStack(spacing: DSSpacing.cardSectionSpacing) {
                        // HEADER: Title + Subtitle
                        // Per FastLIFe_Your_LIFe_Journey_UIUX_v1.0.md §2
                        VStack(spacing: DSSpacing.cardExtraSmallSpacing) {
                            // TITLE: Your LIFe Journey (luxury gradient)
                            // Font: SF Pro Rounded 34pt (matching app standard, not spec's 28pt)
                            // Gradient: Theme.ColorToken.accentInfo → accentPrimary (blue→emerald)
                            Text("Your LIFe Journey")
                                .font(DSTypography.displayLRounded)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Theme.ColorToken.accentInfo,    // Blue (left)
                                            Theme.ColorToken.accentPrimary  // Emerald (right)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(maxWidth: .infinity)

                            // SUBTITLE: Motivational tagline
                            // Font: SF Pro Display 15pt, weight 400, italic (per spec §4)
                            // v1.2: Changed to white for better visibility on gradient background
                            Text("Progress you can feel — one choice at a time.")
                                .font(DSTypography.cardBody)
                                .italic()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)  // Centered
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, DSSpacing.cardSmallSpacing)
                        .padding(.bottom, DSSpacing.cardSmallSpacing)

                        // COACH BAR (v1.2) - State-based micro-copy under subtitle with hide functionality
                        // Per v1.2 spec: Accent background, white text, eye.slash hide button
                        // Registers under "Your Progress Journey" in Control Center
                        // Dual visibility system: ProgressStoryCardManager (master) + ContentOptOutManager (individual)
                        let coachState7d = trendState(for: calculateDelta(days: 7) ?? 0)
                        if progressStoryCardManager.isCardVisible(.coachBar) && !optOutManager.isContentOptedOut(id: contentID_CoachBar) {
                            CoachBar(text: coachBarText(for: coachState7d), onHide: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    // Hide via ProgressStoryCardManager (shows in "Your Progress Journey" section)
                                    progressStoryCardManager.hideCard(.coachBar)
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            })
                            .padding(.bottom, DSSpacing.cardSmallSpacing)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                            .animation(.easeInOut(duration: 0.4).delay(0.05), value: isAnimating)
                        }

                        // STACKED LAYOUT v1.1: Narrative flow top-to-bottom
                        // Phase v1.4b Layer 3 & 4: Drag-and-drop reordering with ForEach

                        // REORDERABLE CARDS (exclude Coach Bar)
                        let visibleCards = progressStoryCardManager.getVisibleCardsInOrder()
                        let reorderableCards = visibleCards.filter { $0 != .coachBar }

                        // Precompute values for banner and tip (outside ForEach to prevent random changes during drag)
                        let sevenDayDelta = calculateDelta(days: 7)
                        let state7d = trendState(for: sevenDayDelta ?? 0)
                        let bannerText = banner7Text(for: state7d)
                        let bannerAccent = bannerAccentColor(for: state7d)
                        let didYouKnowText = randomDidYouKnowTip()  // 🔧 FIX #1: Pre-compute tip text once

                        let contentIDs = ProgressStoryContentIDs(
                            sevenDay: contentID_7Day,
                            thirtyDay: contentID_30Day,
                            banner: contentID_Banner,
                            reflection: contentID_ReflectionNudge,
                            recap: contentID_Recap,
                            didYouKnow: contentID_Tip
                        )

                        let cardContext = ProgressStoryCardContext(
                            sevenDayDelta: sevenDayDelta,
                            thirtyDayDelta: calculateDelta(days: 30),
                            netDelta30d: netDelta30d,
                            bestStreak: bestStreak,
                            totalEntries: totalEntries,
                            bannerText: bannerText,
                            bannerAccent: bannerAccent,
                            didYouKnowText: didYouKnowText,
                            reflectionPrompt: reflectionPromptText
                        )

                        ProgressStoryCardStack(
                            cards: reorderableCards,
                            optOutManager: optOutManager,
                            cardManager: progressStoryCardManager,
                            contentIDs: contentIDs,
                            context: cardContext,
                            isAnimating: isAnimating,
                            draggedCard: $draggedCard,
                            reflectionTap: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        )

                        // 6. FOOTER CELEBRATION (optional - motivational message)
                        // Per FastLIFe_Your_LIFe_Journey_UIUX_v1.0.md §2
                        // Animated text: "You're showing up. That's what builds your LIFe!"
                        // Subtle, encouraging, human tone
                        // Standard: Dark background = light text, proper punctuation
                        if totalEntries >= 1 {
                            Text("You're showing up. That's what builds your LIFe!")
                                .font(DSTypography.cardBody)
                                .foregroundColor(.white.opacity(0.8))
                                .italic()
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .opacity(isAnimating ? 1 : 0)
                                .animation(.easeInOut(duration: 0.6).delay(0.6), value: isAnimating)
                        }
                    }
                    .padding(.horizontal, DSSpacing.screenEdgePadding)  // Universal standard (20pt) - matches all tracker screens
                    .padding(.vertical, DSSpacing.cardPadding)
                }
            }
            .navigationTitle("Weight Trends")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 🔧 FIX #12: Initialize reflection prompt once on appear (never changes during drag)
                // Apple Health Pattern: Lock content at view appearance for stable UI during interactions
                reflectionPromptText = randomReflectionPrompt()

                // Trigger staggered fade-in animation on view appear
                withAnimation {
                    isAnimating = true
                }

                // v1.1: Trigger mood background micro-drift animation (respects Reduce Motion)
                if !reduceMotion {
                    moodAnimate = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // LUXURY OPT-OUT BUTTON (v1.0 - Refined Design)
                    // Per UI/UX Design Note: FastLIFe_UIUX_DontShowAgain_DesignNote.md
                    // Layers: Gradient border + Fade animation + Haptic feedback
                    Button {
                        // Layer 3: Haptic feedback (light tap) = premium responsiveness
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()

                        // Opt out entire Progress Story (global)
                        optOutManager.optOutContent(id: contentID_ProgressStory, category: .progressSummaries, text: "Your Progress Story")

                        // Layer 2: Smooth fade-out animation (0.25s)
                        withAnimation(.easeInOut(duration: 0.25)) {
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.slash")
                                .font(DSTypography.cardSubtitle)
                            Text("Don't show again")
                                .font(DSTypography.cardSubtitle)
                        }
                        .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
                        .padding(.horizontal, DSSpacing.cardElementSpacing)
                        .padding(.vertical, 6)
                        .background(
                            // Layer 1: Subtle gradient border (10-15% opacity) = luxury feel
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Theme.ColorToken.accentPrimary.opacity(0.15),
                                                    Theme.ColorToken.accentPrimary.opacity(0.10)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                        )
                    }
                    .buttonStyle(.plain)  // Removes default button press effect
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Close weight trends view")
                }
            }
        }
    }
}
