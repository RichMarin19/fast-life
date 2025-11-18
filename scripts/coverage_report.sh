#!/bin/bash
# Generate code coverage report with HTML output

set -e

echo "🧪 Running tests with coverage enabled..."
echo ""

# Clean previous results
rm -rf build/TestResults.xcresult 2>/dev/null || true

# Run tests with coverage
xcodebuild test \
    -project FastingTracker.xcodeproj \
    -scheme FastingTracker \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -enableCodeCoverage YES \
    -resultBundlePath build/TestResults.xcresult

echo ""
echo "📊 Generating coverage report..."

# Create build directory if it doesn't exist
mkdir -p build

# Generate JSON report
xcrun xccov view --report --json build/TestResults.xcresult > build/coverage.json

# Parse coverage percentage
if command -v jq &> /dev/null; then
    COVERAGE=$(jq '.lineCoverage * 100' build/coverage.json | xargs printf "%.1f")
    echo ""
    echo "📈 Code Coverage: $COVERAGE%"
else
    echo "⚠️  Install jq for coverage percentage: brew install jq"
    COVERAGE="unknown"
fi

# Generate human-readable report
echo ""
echo "📄 Detailed coverage by file:"
xcrun xccov view --report build/TestResults.xcresult | grep -A 999 "FastingTracker" | head -30

# Generate HTML report if xcov is available
if command -v xcov &> /dev/null; then
    echo ""
    echo "🌐 Generating HTML report..."
    xcov \
        --scheme FastingTracker \
        --output_directory build/coverage_html \
        --json_report build/coverage.json

    echo "✅ HTML Report generated: build/coverage_html/index.html"
    echo ""

    # Open in browser
    if [ -f "build/coverage_html/index.html" ]; then
        open build/coverage_html/index.html
        echo "🌐 Opened in browser"
    fi
else
    echo ""
    echo "💡 Install xcov for HTML reports:"
    echo "   gem install xcov"
fi

# Check against target
echo ""
TARGET=70.0

if [ "$COVERAGE" != "unknown" ]; then
    if (( $(echo "$COVERAGE >= $TARGET" | bc -l) )); then
        echo "✅ Coverage meets enterprise target ($TARGET%)"
        echo "🎉 Ready for Phase 2 completion!"
        exit 0
    elif (( $(echo "$COVERAGE >= 50.0" | bc -l) )); then
        echo "⚠️  Coverage is good but below enterprise target"
        echo "   Current: $COVERAGE%"
        echo "   Target: $TARGET%"
        echo "   Gap: $(echo "$TARGET - $COVERAGE" | bc)%"
        exit 0
    else
        echo "❌ Coverage below minimum"
        echo "   Current: $COVERAGE%"
        echo "   Minimum (Phase 1): 50%"
        echo "   Target (Phase 2): $TARGET%"
        exit 1
    fi
else
    echo "⚠️  Could not determine coverage percentage"
    exit 0
fi
