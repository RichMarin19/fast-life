#!/bin/bash

PROJECT_FILE="FastingTracker.xcodeproj/project.pbxproj"

echo "========================================="
echo "UPDATING XCODE PROJECT REFERENCES"
echo "========================================="
echo ""
echo "Strategy: Update project.pbxproj to point to subdirectory versions"
echo "Safety: Root files remain in place (not deleted yet)"
echo ""

# Design System files (9 files)
echo "Updating Design System files..."
sed -i '' 's|path = DSBanner\.swift;|path = Core/DesignSystem/DSBanner.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = DSCard\.swift;|path = Core/DesignSystem/DSCard.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = DSCardHeader\.swift;|path = Core/DesignSystem/DSCardHeader.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = DSCoachBar\.swift;|path = Core/DesignSystem/DSCoachBar.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = DSColors\.swift;|path = Core/DesignSystem/DSColors.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = DSCornerRadius\.swift;|path = Core/DesignSystem/DSCornerRadius.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = DSProgressRing\.swift;|path = Core/DesignSystem/DSProgressRing.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = DSSpacing\.swift;|path = Core/DesignSystem/DSSpacing.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = DSTypography\.swift;|path = Core/DesignSystem/DSTypography.swift;|g' "$PROJECT_FILE"

# Services (3 files)
echo "Updating Services files..."
sed -i '' 's|path = BehavioralCopy\.swift;|path = Core/Services/BehavioralCopy.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = HealthDataAggregator\.swift;|path = Core/Services/HealthDataAggregator.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = UnifiedHealthDataService\.swift;|path = Core/Services/UnifiedHealthDataService.swift;|g' "$PROJECT_FILE"

# Managers (2 files)
echo "Updating Managers files..."
sed -i '' 's|path = WeightNotificationManager\.swift;|path = Core/Managers/WeightNotificationManager.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = WeightNotificationPlanner\.swift;|path = Core/Managers/WeightNotificationPlanner.swift;|g' "$PROJECT_FILE"

# Models (4 files)
echo "Updating Models files..."
sed -i '' 's|path = ChatMessage\.swift;|path = Models/ChatMessage.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = EmotionState\.swift;|path = Models/EmotionState.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = HealthInsight\.swift;|path = Models/HealthInsight.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = TrackerCard\.swift;|path = Core/Models/TrackerCard.swift;|g' "$PROJECT_FILE"

# ViewModels (1 file)
echo "Updating ViewModels files..."
sed -i '' 's|path = LifeGPTViewModel\+EmotionDetection\.swift;|path = Core/ViewModels/LifeGPTViewModel+EmotionDetection.swift;|g' "$PROJECT_FILE"

# UI Components (2 files - NOTE: WeightSetupComponents is at root and that's correct, skip it)
echo "Updating UI Components files..."
sed -i '' 's|path = WeightHistoryComponents\.swift;|path = UI/Components/WeightHistoryComponents.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = WeightStatsComponents\.swift;|path = UI/Components/WeightStatsComponents.swift;|g' "$PROJECT_FILE"

# UI/LifeGPT (4 files)
echo "Updating UI/LifeGPT files..."
sed -i '' 's|path = CoachInviteCard\.swift;|path = UI/LifeGPT/CoachInviteCard.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = LIFeGPTChatView\.swift;|path = UI/LifeGPT/LIFeGPTChatView.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = LifeGPTComponents\.swift;|path = UI/LifeGPT/LifeGPTComponents.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = LifeGPTLoadingOverlay\.swift;|path = UI/LifeGPT/LifeGPTLoadingOverlay.swift;|g' "$PROJECT_FILE"

# Core/Views (1 file)
echo "Updating Core/Views files..."
sed -i '' 's|path = UniversalCardContainer\.swift;|path = Core/Views/UniversalCardContainer.swift;|g' "$PROJECT_FILE"

# Core/DesignSystem (2 more files)
echo "Updating Core/DesignSystem files..."
sed -i '' 's|path = CardManager\.swift;|path = Core/DesignSystem/CardManager.swift;|g' "$PROJECT_FILE"
sed -i '' 's|path = CardTypeProtocol\.swift;|path = Core/DesignSystem/CardTypeProtocol.swift;|g' "$PROJECT_FILE"

echo ""
echo "========================================="
echo "✅ COMPLETE: Updated project references"
echo "========================================="
echo ""
echo "Total files updated: 27 references"
echo "Note: Root files still exist (not deleted yet)"
echo ""
echo "Next step: Verify build succeeds BEFORE deleting root files"
