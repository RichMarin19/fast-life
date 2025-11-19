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
    @Environment(\.weightDependencies) private var dependencies

    var body: some View {
        WeightTrendsExperienceView(dependencies: dependencies)
    }
}

@MainActor
private struct WeightTrendsExperienceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WeightTrendsViewModel
    private let weightManager: WeightManager
    private let optOutManager: ContentOptOutManaging
    private let cardManager: ProgressStoryCardManaging

    @State private var isAnimating = false  // Animation state for staggered fade-in
    @Environment(\.accessibilityReduceMotion) var reduceMotion  // v1.1: Respect Reduce Motion
    private let backgroundDriftAmplitude: CGFloat = 34
    private let backgroundDriftPeriod: Double = 8.0
    private let backgroundDriftInterval: TimeInterval = 1.0 / 30.0

    // Phase v1.4b: Drag-to-Reorder State (following existing pattern - no Edit button)
    @State private var draggedCard: ProgressStoryCardType?  // Currently dragged card

    // 🔧 FIX #12: Stable text state - locked at view appearance, never changes during drag
    // Apple Health Pattern: Use @State for content that shouldn't change during interactions
    init(dependencies: WeightDependencies) {
        self.weightManager = dependencies.weightManager
        self.optOutManager = dependencies.optOutManager
        self.cardManager = dependencies.progressStoryCardManager
        _viewModel = StateObject(
            wrappedValue: dependencies.makeWeightTrendsViewModel()
        )
    }

    // MARK: - Adaptive Mood Overlay (v1.1)

    /// Returns adaptive mood gradient overlay based on trend state
    /// Per v1.1 spec §2: Subtle 12-18% opacity overlays on navy base
    /// Colors reflect emotional state without being alarmist
    private func tealMotionOverlay() -> LinearGradient {
        LinearGradient(
            colors: [
                Theme.ColorToken.accentPrimary.opacity(0.22),   // Emerald
                Theme.ColorToken.accentInfo.opacity(0.14)       // Teal
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func backgroundOffset(for date: Date) -> CGFloat {
        guard reduceMotion == false else { return 0 }
        let time = date.timeIntervalSinceReferenceDate / backgroundDriftPeriod
        let normalized = sin(time)
        return CGFloat(normalized) * backgroundDriftAmplitude
    }

    var body: some View {
        NavigationStack {
            // v1.1 Adaptive Background: Navy base + teal motion overlay
            // Per FastLIFe_LIFeJourney_UIUX_v1.1_AdaptiveBehavioralDesign.md §3
            ZStack {
                TimelineView(.periodic(from: .now, by: backgroundDriftInterval)) { timeline in
                    let driftOffset = backgroundOffset(for: timeline.date)

                    ZStack {
                        // Layer 1: Deep 3-stop navy gradient (base canvas)
                        LinearGradient(
                            colors: [
                                Theme.ColorToken.bgDeepStart,
                                Theme.ColorToken.bgDeepMid,
                                Theme.ColorToken.bgDeepEnd
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .padding(.vertical, -backgroundDriftAmplitude)
                        .offset(y: driftOffset)

                        // Layer 2: Emerald/teal translucent overlay with subtle motion
                        tealMotionOverlay()
                            .padding(.vertical, -backgroundDriftAmplitude)
                            .offset(y: driftOffset)
                    }
                    .ignoresSafeArea()
                }

                ScrollView {
                    VStack(spacing: DSSpacing.cardSectionSpacing) {
                        // HEADER: Title + Subtitle
                        // Per FastLIFe_Your_LIFe_Journey_UIUX_v1.0.md §2
                        VStack(spacing: DSSpacing.cardExtraSmallSpacing) {
                            // TITLE: Your LIFe Journey (luxury gradient)
                            // Font: SF Pro Rounded 34pt (matching app standard, not spec's 28pt)
                            // Gradient: Theme.ColorToken.accentInfo → accentPrimary (blue→emerald)
                            Text("progress_story_title")
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
                            Text("progress_story_subtitle")
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
                        if viewModel.isCoachBarVisible {
                            CoachBar(text: viewModel.coachBarText, onHide: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    // Hide via ProgressStoryCardManager (shows in "Your Progress Journey" section)
                                    viewModel.hideCoachBar()
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

                        ProgressStoryCardStack(
                            visibleCards: viewModel.visibleCards,
                            context: viewModel.cardContext,
                            isAnimating: isAnimating,
                            draggedCard: $draggedCard,
                            reflectionTap: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            },
                            onHideCard: { cardType in
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    viewModel.hideCard(cardType)
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            },
                            onReorder: { draggedCard, destinationCard in
                                viewModel.reorderCard(draggedCard, before: destinationCard)
                            }
                        )

                        // 6. FOOTER CELEBRATION (optional - motivational message)
                        // Per FastLIFe_Your_LIFe_Journey_UIUX_v1.0.md §2
                        // Animated text: "You're showing up. That's what builds your LIFe!"
                        // Subtle, encouraging, human tone
                        // Standard: Dark background = light text, proper punctuation
                        if viewModel.shouldShowFooter {
                            Text("progress_story_footer")
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 🔧 FIX #12: Initialize reflection prompt once on appear (never changes during drag)
                // Apple Health Pattern: Lock content at view appearance for stable UI during interactions
                viewModel.refresh()

                // Trigger staggered fade-in animation on view appear
                withAnimation {
                    isAnimating = true
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

                        // Layer 2: Smooth fade-out animation (0.25s)
                        viewModel.optOutProgressStory {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.slash")
                                .font(DSTypography.cardSubtitle)
                            Text("progress_story_opt_out_cta")
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
