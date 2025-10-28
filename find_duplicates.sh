#!/bin/bash

# Duplicate File Finder for FastingTracker
# Finds all duplicate Swift files and reports which locations Xcode is using

PROJECT_ROOT="/Users/richmarin/Desktop/FastingTracker"
PBXPROJ="$PROJECT_ROOT/FastingTracker.xcodeproj/project.pbxproj"

echo "========================================="
echo "DUPLICATE FILE FINDER"
echo "========================================="
echo ""

# Step 1: Find all Swift files with duplicate basenames
echo "Step 1: Finding files with duplicate basenames..."
echo ""

find "$PROJECT_ROOT/FastingTracker" -name "*.swift" -type f | while read -r filepath; do
    basename=$(basename "$filepath")
    echo "$basename|$filepath"
done | sort | uniq -d -f 0 > /tmp/duplicate_basenames.txt

if [ ! -s /tmp/duplicate_basenames.txt ]; then
    echo "No duplicate basenames found."
else
    echo "Found duplicate basenames:"
    cat /tmp/duplicate_basenames.txt
fi

echo ""
echo "========================================="
echo "Step 2: Analyzing each duplicate..."
echo "========================================="
echo ""

# Step 2: For each duplicate, find all locations and check which Xcode is using
find "$PROJECT_ROOT/FastingTracker" -name "*.swift" -type f -print0 | xargs -0 basename -a | sort | uniq -d | while read -r duplicate_name; do
    echo "--------------------------------------"
    echo "File: $duplicate_name"
    echo "--------------------------------------"

    # Find all locations of this file
    locations=$(find "$PROJECT_ROOT/FastingTracker" -name "$duplicate_name" -type f)

    echo "Locations found:"
    echo "$locations" | nl
    echo ""

    # Check which location Xcode is using
    if grep -q "$duplicate_name" "$PBXPROJ"; then
        # Extract the path from project.pbxproj
        xcode_path=$(grep "path.*$duplicate_name" "$PBXPROJ" | head -1 | sed 's/.*path = \(.*\);.*/\1/' | tr -d ' ')
        echo "Xcode is using: $xcode_path"

        # Check if it's at root or in subdirectory
        if [[ "$xcode_path" == *"/"* ]]; then
            echo "Status: In subdirectory (CORRECT)"
        else
            echo "Status: At root (LIKELY WRONG - should be in subdirectory)"
        fi
    else
        echo "WARNING: File not found in project.pbxproj!"
    fi

    echo ""

    # Recommend action
    location_count=$(echo "$locations" | wc -l | tr -d ' ')
    if [ "$location_count" -gt 1 ]; then
        echo "RECOMMENDATION: DELETE duplicates, keep only the one Xcode is using"
        echo "Files to delete:"
        echo "$locations" | grep -v "$xcode_path" | sed 's/^/  - /'
    fi

    echo ""
done

echo "========================================="
echo "Step 3: Finding files at root that should be in subdirectories..."
echo "========================================="
echo ""

# Step 3: Find Swift files at root level (excluding allowed files)
allowed_at_root=(
    "FastingTrackerApp.swift"
    "ContentView.swift"
)

find "$PROJECT_ROOT/FastingTracker" -maxdepth 1 -name "*.swift" -type f | while read -r filepath; do
    basename=$(basename "$filepath")

    # Check if this file is allowed at root
    is_allowed=false
    for allowed_file in "${allowed_at_root[@]}"; do
        if [ "$basename" == "$allowed_file" ]; then
            is_allowed=true
            break
        fi
    done

    if [ "$is_allowed" = false ]; then
        echo "WRONG LOCATION: $basename"
        echo "  Current: FastingTracker/$basename (root)"

        # Check if a subdirectory version exists
        subdirectory_version=$(find "$PROJECT_ROOT/FastingTracker" -mindepth 2 -name "$basename" -type f | head -1)
        if [ -n "$subdirectory_version" ]; then
            echo "  Duplicate exists at: ${subdirectory_version#$PROJECT_ROOT/FastingTracker/}"
            echo "  ACTION: DELETE root version, use subdirectory version"
        else
            echo "  ACTION: MOVE to appropriate subdirectory (UI/Components, Core/Managers, etc.)"
        fi
        echo ""
    fi
done

echo "========================================="
echo "SUMMARY"
echo "========================================="
echo ""
echo "Total duplicate basenames: $(cat /tmp/duplicate_basenames.txt 2>/dev/null | wc -l | tr -d ' ')"
echo "Files at root (should be moved): $(find "$PROJECT_ROOT/FastingTracker" -maxdepth 1 -name "*.swift" -type f | wc -l | tr -d ' ')"
echo ""
echo "Run this script again after fixing to verify all duplicates are resolved."
