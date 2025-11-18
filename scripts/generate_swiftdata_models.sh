#!/bin/bash
# Convert Codable structs to SwiftData @Model classes

set -e

INPUT_FILE="$1"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <path-to-model-file.swift>"
    echo ""
    echo "Example:"
    echo "  $0 FastingTracker/FastingSession.swift"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Error: File not found: $INPUT_FILE"
    exit 1
fi

OUTPUT_FILE="${INPUT_FILE%.swift}_SwiftData.swift"

echo "🔄 Converting $INPUT_FILE to SwiftData..."
echo ""

# Create SwiftData version
cat "$INPUT_FILE" | \
    # Change struct to class
    sed 's/^struct \([A-Za-z]*\):/final class \1:/' | \
    sed 's/^struct \([A-Za-z]*\) {/final class \1 {/' | \
    # Remove Codable
    sed 's/: Codable, Identifiable/: Identifiable/' | \
    sed 's/: Identifiable, Codable/: Identifiable/' | \
    sed 's/: Codable//' | \
    sed 's/, Codable//' | \
    sed 's/Codable, //' | \
    # Add @Model before final class
    sed 's/^final class /@Model\nfinal class /' | \
    # Add imports at the top
    sed '1i\
import SwiftData\
import Foundation\
' > "$OUTPUT_FILE"

echo "✅ Created: $OUTPUT_FILE"
echo ""
echo "⚠️  Manual review required:"
echo ""
echo "1. Add @Relationship for relationships:"
echo "   @Relationship var weightEntries: [WeightEntry]"
echo ""
echo "2. Add @Transient for computed properties:"
echo "   @Transient var duration: TimeInterval { ... }"
echo ""
echo "3. Update initializers if needed:"
echo "   - SwiftData models need public init"
echo "   - All properties must be initialized"
echo ""
echo "4. Test compilation:"
echo "   - Open $OUTPUT_FILE in Xcode"
echo "   - Fix any compiler errors"
echo ""
echo "📖 See Phase 1 documentation for full SwiftData migration guide"
