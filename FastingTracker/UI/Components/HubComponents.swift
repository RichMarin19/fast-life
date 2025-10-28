//
//  HubComponents.swift
//  FastingTracker
//
//  Created: October 23, 2025
//  Purpose: Extracted HubView components for better organization and maintainability
//  Reference: HUBVIEW-ANALYSIS.md - Phase 2 Performance Recovery
//  Strategy: Component extraction following Apple MVVM patterns
//

import SwiftUI

// MARK: - TrackerDropDelegate
// Drag & drop reordering logic for tracker cards
// Reference: https://developer.apple.com/documentation/swiftui/dropdelegate
struct TrackerDropDelegate: DropDelegate {
    let tracker: TrackerType
    @Binding var trackerOrder: [TrackerType]
    @Binding var draggedTracker: TrackerType?

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTracker = draggedTracker else { return false }

        if let fromIndex = trackerOrder.firstIndex(of: draggedTracker),
           let toIndex = trackerOrder.firstIndex(of: tracker) {

            withAnimation(.spring()) {
                trackerOrder.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }
        }

        self.draggedTracker = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        // Optional: Add visual feedback during drag
    }

    func dropExited(info: DropInfo) {
        // Optional: Remove visual feedback
    }
}

// MARK: - FastingProgressRing (Extracted from ContentView for consistency)
struct FastingProgressRing: View {
    let progress: Double
    let isActive: Bool
    let fastingGoalHours: Double
    let size: CGFloat

    // Gradient colors for progress ring - transitions through stages (matching ContentView)
    private var progressGradientColors: [Color] {
        [
            Color(red: 0.2, green: 0.6, blue: 0.9),   // 0%: Blue (start)
            Color(red: 0.2, green: 0.7, blue: 0.8),   // 25%: Teal
            Color(red: 0.2, green: 0.8, blue: 0.7),   // 50%: Cyan
            Color(red: 0.3, green: 0.8, blue: 0.5),   // 75%: Green-teal
            Color(red: 0.4, green: 0.9, blue: 0.4),   // 90%: Vibrant green
            Color(red: 0.3, green: 0.85, blue: 0.3)   // 100%: Celebration green
        ]
    }

    var body: some View {
        ZStack {
            // Timer Circle (exact same as ContentView, scaled)
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6) // Universal thickness
                    .frame(width: size, height: size)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isActive ?
                            AngularGradient(
                                gradient: Gradient(colors: progressGradientColors),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ) : AngularGradient(
                                gradient: Gradient(colors: [Color.gray, Color.gray]),
                                center: .center
                            ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Progress Percentage (centered)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }

            // Educational stage icons positioned around the circle (ON TOP of progress ring)
            ForEach(FastingStage.relevantStages(for: fastingGoalHours)) { stage in
                let midpointHour = Double(stage.startHour + stage.endHour) / 2.0
                let angle = (midpointHour / 24.0) * 360.0 - 90.0 // -90 to start at top

                // PERFECT overlap radius matching all other cards
                let dynamicRadius = size * 0.45  // Universal overlap formula

                let x = dynamicRadius * cos(angle * .pi / 180)
                let y = dynamicRadius * sin(angle * .pi / 180)

                Text(stage.icon)
                    .font(.system(size: size * 0.18)) // Restored icon size for visibility
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: size * 0.22, height: size * 0.22) // Restored background size
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .offset(x: x, y: y)
            }
        }
    }
}

// MARK: - WeightProgressRing (Following North Star Design System)
struct WeightProgressRing: View {
    let progress: Double // 0.0 to 1.0 (percentage toward goal)
    let size: CGFloat

    // Progress gradient colors (EXACT same as FastingProgressRing North Star)
    private var weightProgressGradientColors: [Color] {
        [
            Color(red: 0.2, green: 0.6, blue: 0.9),   // 0%: Blue (start)
            Color(red: 0.2, green: 0.7, blue: 0.8),   // 25%: Teal
            Color(red: 0.2, green: 0.8, blue: 0.7),   // 50%: Cyan
            Color(red: 0.3, green: 0.8, blue: 0.5),   // 75%: Green-teal
            Color(red: 0.4, green: 0.9, blue: 0.4),   // 90%: Vibrant green
            Color(red: 0.3, green: 0.85, blue: 0.3)   // 100%: Celebration green
        ]
    }

    var body: some View {
        ZStack {
            // Progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                    .frame(width: size, height: size)

                // Progress ring with gradient (matching Mood & Energy thickness exactly)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: weightProgressGradientColors),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Center text
                VStack(spacing: 2) {
                    Text("Progress")
                        .font(.system(size: size * 0.12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            // Behavioral icons positioned around ring (ON TOP - matching Mood & Energy pattern)
            behavioralIcons
        }
    }

    // Behavioral Icons Around Ring (Following North Star FastingProgressRing Design)
    @ViewBuilder
    private var behavioralIcons: some View {
        // PERFECT overlap radius matching Mood & Energy card (the pattern you loved!)
        let dynamicRadius = size * 0.45 // Same beautiful overlap calculation

        // Full-color behavioral icons (matching FastingProgressRing North Star pattern)
        let behaviors: [(icon: String, angle: Double)] = [
            ("💤", 0),      // Sleep (top)
            ("💧", 60),     // Hydration
            ("⚡", 120),    // Energy
            ("🧠", 180),    // Mindset (bottom)
            ("🍽️", 240),   // Nutrition
            ("❤️", 300)     // Mood
        ]

        ForEach(Array(behaviors.enumerated()), id: \.offset) { _, behavior in
            let angle = behavior.angle - 90.0 // -90 to start at top like FastingProgressRing
            let x = dynamicRadius * cos(angle * .pi / 180)
            let y = dynamicRadius * sin(angle * .pi / 180)

            Text(behavior.icon)
                .font(.system(size: size * 0.18)) // Matching FastingProgressRing icon size
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.22, height: size * 0.22) // Matching FastingProgressRing background size
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .offset(x: x, y: y)
        }
    }
}

// MARK: - SleepRegularityRing (Following Vision Document Sleep Design)
struct SleepRegularityRing: View {
    let regularity: Double // 0.0 to 1.0 (sleep regularity percentage)
    let size: CGFloat

    // Universal gradient colors (matching Mood & Energy + Weight pattern exactly)
    private var sleepRegularityGradientColors: [Color] {
        // STANDARD: Blue-to-green gradient for all Main Focus cards
        return [
            Color(hex: "#3498DB"), // Blue for reflective periods
            Color(hex: "#1ABC9C"), // Teal for balanced states
            Color(hex: "#27AE60")  // Green for stable periods
        ]
    }

    var body: some View {
        ZStack {
            // Sleep regularity progress ring
            ZStack {
                // Background ring (matching universal standard)
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                    .frame(width: size, height: size)

                // Sleep regularity ring with gradient (matching universal thickness)
                Circle()
                    .trim(from: 0, to: regularity)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: sleepRegularityGradientColors),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: regularity)

                // Center text
                VStack(spacing: 2) {
                    Text("Regularity")
                        .font(.system(size: size * 0.12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(Int(regularity * 100))%")
                        .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            // Sleep behavioral icons (ON TOP - matching overlap pattern)
            sleepBehavioralIcons
        }
    }

    // Sleep Behavioral Icons Around Ring (Following Vision Document)
    @ViewBuilder
    private var sleepBehavioralIcons: some View {
        // PERFECT overlap radius matching Mood & Energy + Weight pattern
        let dynamicRadius = size * 0.45  // Universal overlap formula

        // Sleep behavioral icons (6 icons for visual symmetry like Weight)
        let sleepBehaviors: [(icon: String, angle: Double)] = [
            ("💧", 0),      // Hydration (top) - affects nighttime thirst
            ("⚡", 60),     // Energy - next day energy level
            ("🧠", 120),    // Mindset - reflection/journaling
            ("🍽️", 180),   // Fasting (bottom) - fasting end time before bed
            ("❤️", 240),    // Mood - morning positivity check-in
            ("🌙", 300)     // Sleep quality - new 6th icon for symmetry
        ]

        ForEach(Array(sleepBehaviors.enumerated()), id: \.offset) { _, behavior in
            let angle = behavior.angle - 90.0 // -90 to start at top like North Star
            let x = dynamicRadius * cos(angle * .pi / 180)
            let y = dynamicRadius * sin(angle * .pi / 180)

            Text(behavior.icon)
                .font(.system(size: size * 0.18)) // Matching North Star icon size
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.22, height: size * 0.22) // Matching North Star background size
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .offset(x: x, y: y)
        }
    }
}

// MARK: - HydrationProgressRing (Following North Star Design System)
struct HydrationProgressRing: View {
    let progress: Double // 0.0 to 1.0 (percentage of daily goal)
    let size: CGFloat

    // Progress gradient colors (EXACT same as FastingProgressRing North Star)
    private var hydrationProgressGradientColors: [Color] {
        [
            Color(red: 0.2, green: 0.6, blue: 0.9),   // 0%: Blue (start)
            Color(red: 0.2, green: 0.7, blue: 0.8),   // 25%: Teal
            Color(red: 0.2, green: 0.8, blue: 0.7),   // 50%: Cyan
            Color(red: 0.3, green: 0.8, blue: 0.5),   // 75%: Green-teal
            Color(red: 0.4, green: 0.9, blue: 0.4),   // 90%: Vibrant green
            Color(red: 0.3, green: 0.85, blue: 0.3)   // 100%: Celebration green
        ]
    }

    var body: some View {
        ZStack {
            // Hydration progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                    .frame(width: size, height: size)

                // Progress ring with gradient
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: hydrationProgressGradientColors),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Center text
                VStack(spacing: 2) {
                    Text("Intake")
                        .font(.system(size: size * 0.12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            // Hydration behavioral icons (ON TOP - matching overlap pattern)
            hydrationBehavioralIcons
        }
    }

    // Hydration Behavioral Icons Around Ring (Following Vision Document)
    @ViewBuilder
    private var hydrationBehavioralIcons: some View {
        // PERFECT overlap radius matching universal pattern
        let dynamicRadius = size * 0.45  // Universal overlap formula

        // Hydration behavioral icons (6 icons for visual balance)
        let hydrationBehaviors: [(icon: String, angle: Double)] = [
            ("💧", 0),      // Hydration (top) - primary focus
            ("⚡", 60),     // Energy - hydration affects energy levels
            ("🧠", 120),    // Mental clarity - hydration affects cognition
            ("❤️", 180),    // Heart health (bottom) - hydration affects circulation
            ("🏃‍♂️", 240),    // Exercise - hydration for performance
            ("☀️", 300)     // Daily habit - consistent hydration
        ]

        ForEach(Array(hydrationBehaviors.enumerated()), id: \.offset) { _, behavior in
            let angle = behavior.angle - 90.0 // Start at top like North Star
            let x = dynamicRadius * cos(angle * .pi / 180)
            let y = dynamicRadius * sin(angle * .pi / 180)

            Text(behavior.icon)
                .font(.system(size: size * 0.18)) // Matching North Star icon size
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.22, height: size * 0.22) // Matching North Star background size
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .offset(x: x, y: y)
        }
    }
}
