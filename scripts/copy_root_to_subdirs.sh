#!/bin/bash

echo "==========================================="
echo "COPYING ROOT FILES TO SUBDIRECTORIES"
echo "==========================================="
echo ""
echo "Strategy: Overwrite old subdirectory versions with current root code"
echo ""

# Design System files (9 files)
echo "Copying Design System files..."
cp FastingTracker/DSBanner.swift FastingTracker/Core/DesignSystem/DSBanner.swift
cp FastingTracker/DSCard.swift FastingTracker/Core/DesignSystem/DSCard.swift
cp FastingTracker/DSCardHeader.swift FastingTracker/Core/DesignSystem/DSCardHeader.swift
cp FastingTracker/DSCoachBar.swift FastingTracker/Core/DesignSystem/DSCoachBar.swift
cp FastingTracker/DSColors.swift FastingTracker/Core/DesignSystem/DSColors.swift
cp FastingTracker/DSCornerRadius.swift FastingTracker/Core/DesignSystem/DSCornerRadius.swift
cp FastingTracker/DSProgressRing.swift FastingTracker/Core/DesignSystem/DSProgressRing.swift
cp FastingTracker/DSSpacing.swift FastingTracker/Core/DesignSystem/DSSpacing.swift
cp FastingTracker/DSTypography.swift FastingTracker/Core/DesignSystem/DSTypography.swift

# Services (3 files)
echo "Copying Services files..."
cp FastingTracker/BehavioralCopy.swift FastingTracker/Core/Services/BehavioralCopy.swift
cp FastingTracker/HealthDataAggregator.swift FastingTracker/Core/Services/HealthDataAggregator.swift
cp FastingTracker/UnifiedHealthDataService.swift FastingTracker/Core/Services/UnifiedHealthDataService.swift

# Managers (2 files)
echo "Copying Managers files..."
cp FastingTracker/WeightNotificationManager.swift FastingTracker/Core/Managers/WeightNotificationManager.swift
cp FastingTracker/WeightNotificationPlanner.swift FastingTracker/Core/Managers/WeightNotificationPlanner.swift

# Models (4 files)
echo "Copying Models files..."
cp FastingTracker/ChatMessage.swift FastingTracker/Models/ChatMessage.swift
cp FastingTracker/EmotionState.swift FastingTracker/Models/EmotionState.swift
cp FastingTracker/HealthInsight.swift FastingTracker/Models/HealthInsight.swift
cp FastingTracker/TrackerCard.swift FastingTracker/Core/Models/TrackerCard.swift

# ViewModels (1 file)
echo "Copying ViewModels files..."
cp "FastingTracker/LifeGPTViewModel+EmotionDetection.swift" "FastingTracker/Core/ViewModels/LifeGPTViewModel+EmotionDetection.swift"

# UI Components (2 files - skip WeightSetupComponents, already correct)
echo "Copying UI Components files..."
cp FastingTracker/WeightHistoryComponents.swift FastingTracker/UI/Components/WeightHistoryComponents.swift
cp FastingTracker/WeightStatsComponents.swift FastingTracker/UI/Components/WeightStatsComponents.swift

# UI/LifeGPT (4 files)
echo "Copying UI/LifeGPT files..."
cp FastingTracker/CoachInviteCard.swift FastingTracker/UI/LifeGPT/CoachInviteCard.swift
cp FastingTracker/LIFeGPTChatView.swift FastingTracker/UI/LifeGPT/LIFeGPTChatView.swift
cp FastingTracker/LifeGPTComponents.swift FastingTracker/UI/LifeGPT/LifeGPTComponents.swift
cp FastingTracker/LifeGPTLoadingOverlay.swift FastingTracker/UI/LifeGPT/LifeGPTLoadingOverlay.swift

# Core/Views (1 file)
echo "Copying Core/Views files..."
cp FastingTracker/UniversalCardContainer.swift FastingTracker/Core/Views/UniversalCardContainer.swift

# Core/DesignSystem (2 more files)
echo "Copying Core/DesignSystem files..."
cp FastingTracker/CardManager.swift FastingTracker/Core/DesignSystem/CardManager.swift
cp FastingTracker/CardTypeProtocol.swift FastingTracker/Core/DesignSystem/CardTypeProtocol.swift

echo ""
echo "==========================================="
echo "✅ COMPLETE: Copied 27 files to subdirectories"
echo "==========================================="
echo ""
echo "Note: Root files still exist (not deleted yet)"
