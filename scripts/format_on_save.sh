#!/bin/bash
# Watch Swift files and auto-format on save

set -e

if ! command -v fswatch &> /dev/null; then
    echo "❌ fswatch not found. Installing..."
    brew install fswatch
fi

if ! command -v swiftformat &> /dev/null; then
    echo "❌ swiftformat not found. Installing..."
    brew install swiftformat
fi

PROJECT_DIR="FastingTracker"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Error: $PROJECT_DIR directory not found"
    exit 1
fi

echo "👀 Watching $PROJECT_DIR/ for Swift file changes..."
echo "💡 Save any .swift file to trigger auto-formatting"
echo "⏹  Press Ctrl+C to stop"
echo ""

fswatch -o "$PROJECT_DIR"/**/*.swift | while read -r num; do
    echo "$(date '+%H:%M:%S') - Detected changes, formatting..."
    swiftformat "$PROJECT_DIR/" --quiet
    echo "$(date '+%H:%M:%S') - ✅ Formatting complete"
done
