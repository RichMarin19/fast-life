#!/usr/bin/env python3
"""
Update Xcode project.pbxproj file paths after reorganizing files.
This script updates file references to match the new folder structure.
"""

import re

# Define all file moves: (filename, new_path)
FILE_MOVES = [
    # Views (24 files) → UI/Views/
    ("AddWeightView.swift", "UI/Views/AddWeightView.swift"),
    ("AdvancedView.swift", "UI/Views/AdvancedView.swift"),
    ("AnalyticsView.swift", "UI/Views/AnalyticsView.swift"),
    ("CoachView.swift", "UI/Views/CoachView.swift"),
    ("DebugLogView.swift", "UI/Views/DebugLogView.swift"),
    ("FastingSettingsView.swift", "UI/Views/FastingSettingsView.swift"),
    ("FastingStageDetailView.swift", "UI/Views/FastingStageDetailView.swift"),
    ("HealthDataSelectionView.swift", "UI/Views/HealthDataSelectionView.swift"),
    ("HealthKitNudgeView.swift", "UI/Views/HealthKitNudgeView.swift"),
    ("HistoryView.swift", "UI/Views/HistoryView.swift"),
    ("HubView.swift", "UI/Views/HubView.swift"),
    ("HydrationCalendarView.swift", "UI/Views/HydrationCalendarView.swift"),
    ("HydrationChartView.swift", "UI/Views/HydrationChartView.swift"),
    ("HydrationHistoryView.swift", "UI/Views/HydrationHistoryView.swift"),
    ("HydrationTrackingView.swift", "UI/Views/HydrationTrackingView.swift"),
    ("MoodTrackingView.swift", "UI/Views/MoodTrackingView.swift"),
    ("NotificationSettingsView.swift", "UI/Views/NotificationSettingsView.swift"),
    ("OpenAISettingsView.swift", "UI/Views/OpenAISettingsView.swift"),
    ("SleepTrackingView.swift", "UI/Views/SleepTrackingView.swift"),
    ("TrackerScreenShell.swift", "UI/Views/TrackerScreenShell.swift"),
    ("WeightChartView.swift", "UI/Views/WeightChartView.swift"),
    ("WeightControlCenterView.swift", "UI/Views/WeightControlCenterView.swift"),
    ("WeightSettingsView.swift", "UI/Views/WeightSettingsView.swift"),
    ("WeightTrackingView.swift", "UI/Views/WeightTrackingView.swift"),

    # Components (9 files) → UI/Components/
    ("AInsteinPresenceModifier.swift", "UI/Components/AInsteinPresenceModifier.swift"),
    ("AInsteinPresenceView.swift", "UI/Components/AInsteinPresenceView.swift"),
    ("CurrentWeightCard.swift", "UI/Components/CurrentWeightCard.swift"),
    ("FLCard.swift", "UI/Components/FLCard.swift"),
    ("HubComponents.swift", "UI/Components/HubComponents.swift"),
    ("MilestoneRingCard.swift", "UI/Components/MilestoneRingCard.swift"),
    ("StateBadge.swift", "UI/Components/StateBadge.swift"),
    ("WeightNotificationMessages.swift", "UI/Components/WeightNotificationMessages.swift"),
    ("WeightSetupComponents.swift", "UI/Components/WeightSetupComponents.swift"),

    # Models (6 files) → Models/
    ("FastingSession.swift", "Models/FastingSession.swift"),
    ("FastingStage.swift", "Models/FastingStage.swift"),
    ("HealthDataType.swift", "Models/HealthDataType.swift"),
    ("MoodEntry.swift", "Models/MoodEntry.swift"),
    ("SleepEntry.swift", "Models/SleepEntry.swift"),
    ("WeightEntry.swift", "Models/WeightEntry.swift"),

    # Managers (5 files) → Core/Managers/
    ("ConversationManager.swift", "Core/Managers/ConversationManager.swift"),
    ("CrashReportManager.swift", "Core/Managers/CrashReportManager.swift"),
    ("DataExportManager.swift", "Core/Managers/DataExportManager.swift"),
    ("ProgressStoryCardManager.swift", "Core/Managers/ProgressStoryCardManager.swift"),
    ("TrackerCardManager.swift", "Core/Managers/TrackerCardManager.swift"),

    # Services (3 files) → Core/Services/
    ("HealthDataAnalyzer.swift", "Core/Services/HealthDataAnalyzer.swift"),
    ("HealthKitService.swift", "Core/Services/HealthKitService.swift"),
    ("OpenAIService.swift", "Core/Services/OpenAIService.swift"),

    # Utilities (4 files) → Core/Utilities/
    ("AppLogger.swift", "Core/Utilities/AppLogger.swift"),
    ("CSVImporter.swift", "Core/Utilities/CSVImporter.swift"),
    ("Logging.swift", "Core/Utilities/Logging.swift"),
    ("NetworkMonitor.swift", "Core/Utilities/NetworkMonitor.swift"),

    # Configuration (4 files)
    ("Theme.swift", "Core/DesignSystem/Theme.swift"),
    ("AppSettings.swift", "Core/Configuration/AppSettings.swift"),
    ("HealthDataPreferences.swift", "Core/Configuration/HealthDataPreferences.swift"),
    ("PerformanceTokens.swift", "Core/Configuration/PerformanceTokens.swift"),

    # Test files (6 files)
    ("DSTBoundaryTestHelper.swift", "Testing/Helpers/DSTBoundaryTestHelper.swift"),
    ("HealthKitNudgeTestHelper.swift", "Testing/Helpers/HealthKitNudgeTestHelper.swift"),
    ("NotificationPermissionsUITestHelper.swift", "Testing/Helpers/NotificationPermissionsUITestHelper.swift"),
    ("RuleConfigMigrationTestHelper.swift", "Testing/Helpers/RuleConfigMigrationTestHelper.swift"),
    ("ThrottlePrecedenceTestHelper.swift", "Testing/Helpers/ThrottlePrecedenceTestHelper.swift"),
    ("TrackerCardManagerTestView.swift", "Testing/Views/TrackerCardManagerTestView.swift"),
]

def update_project_file():
    """Update project.pbxproj with new file paths."""
    project_path = "FastingTracker.xcodeproj/project.pbxproj"

    with open(project_path, 'r') as f:
        content = f.read()

    original_content = content
    updates_made = 0

    for filename, new_path in FILE_MOVES:
        # Pattern: path = filename;
        pattern = f'path = {filename};'
        replacement = f'path = {new_path};'

        if pattern in content:
            new_content = content.replace(pattern, replacement)
            count = content.count(pattern)
            updates_made += count
            print(f"✅ Updated {count} reference(s): {filename} → {new_path}")
            content = new_content
        else:
            # Debug: Show if file not found
            print(f"⏭  Skipped (not found in project): {filename}")

    if updates_made > 0:
        with open(project_path, 'w') as f:
            f.write(content)
        print(f"\n✅ Total updates: {updates_made} file references updated")
        return True
    else:
        print("⚠️  No updates needed or pattern not found")
        return False

if __name__ == "__main__":
    success = update_project_file()
    exit(0 if success else 1)
