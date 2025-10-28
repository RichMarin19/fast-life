//
// AInsteinPresenceModifier.swift
// FastingTracker
//
// Created for Phase 5C: Multi-Screen Integration
// Industry Pattern: Whoop/Oura/Levels have persistent UI on ALL screens
// Reference: docs/planning/PHASE-5-AINSTEIN-UI-TRANSFORMATION.md
//

import SwiftUI

// MARK: - AInstein Presence View Modifier

/// View modifier that adds AInstein floating presence to any screen
/// **Usage:** `.withAInsteinPresence(dataService:)`
/// **Industry Pattern:** Whoop/Oura/Levels show ambient AI on all screens
struct AInsteinPresenceModifier: ViewModifier {

    // MARK: - Dependencies

    let dataService: UnifiedHealthDataService

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .center) {
                // MARK: - AInstein Floating Overlay (Phase 5B)
                // Ambient presence system - floating overlay on all screens
                // Replaces CoachInviteCard as single entry point for LifeGPT
                AInsteinPresenceView(dataService: dataService)
            }
    }
}

// MARK: - View Extension

extension View {
    /// Add AInstein floating presence to any screen
    /// - Parameter dataService: UnifiedHealthDataService with all manager dependencies
    /// - Returns: View with AInstein overlay
    func withAInsteinPresence(dataService: UnifiedHealthDataService) -> some View {
        modifier(AInsteinPresenceModifier(dataService: dataService))
    }
}
