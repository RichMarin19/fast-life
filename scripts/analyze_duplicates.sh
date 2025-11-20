#!/bin/bash

echo "Analyzing duplicate files..."
echo ""

# Check a few known duplicates
files=(
    "DSBanner.swift"
    "WeightNotificationManager.swift"
    "TrackerCard.swift"
    "CardManager.swift"
)

for file in "${files[@]}"; do
    echo "=== $file ==="
    
    # Find all instances
    instances=$(find FastingTracker -name "$file" -type f)
    
    if [ $(echo "$instances" | wc -l) -gt 1 ]; then
        echo "Found multiple instances:"
        echo "$instances"
        echo ""
        
        # Compare them
        root_file="FastingTracker/$file"
        if [ -f "$root_file" ]; then
            echo "Root file exists. Checking for differences..."
            for inst in $instances; do
                if [ "$inst" != "$root_file" ]; then
                    echo "Comparing $root_file vs $inst:"
                    diff -q "$root_file" "$inst"
                    if [ $? -eq 0 ]; then
                        echo "✅ FILES ARE IDENTICAL"
                    else
                        echo "⚠️ FILES ARE DIFFERENT"
                        echo "Line count difference:"
                        wc -l "$root_file" "$inst"
                    fi
                fi
            done
        fi
    fi
    echo ""
done
