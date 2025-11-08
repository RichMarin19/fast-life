#!/bin/bash
# Run all tests and generate coverage report
# Industry Standard: Apple WWDC 2017 - Testing in Xcode
# Requires: Test target configured in Xcode scheme (see TEST-CONFIGURATION-STATUS.md)

set -e

PROJECT_ROOT="/Users/richmarin/Desktop/FastingTracker"
cd "$PROJECT_ROOT"

echo "🧪 Running FastingTracker Test Suite"
echo "======================================"
echo ""

# Check if test target is configured
if ! xcodebuild -list -project FastingTracker.xcodeproj 2>/dev/null | grep -q "FastingTracker"; then
    echo "❌ ERROR: Project not found"
    exit 1
fi

# Run tests with coverage
echo "Running 88 existing tests..."
echo ""

if [[ -n "${FASTLIFE_DEVICE_UDID:-}" ]]; then
  echo "📱 FASTLIFE_DEVICE_UDID detected — enforcing console privacy on physical device."
  "$PROJECT_ROOT/scripts/run_device_privacy_tests.sh" "$FASTLIFE_DEVICE_UDID" 2>&1 | tee test_results.log
else
  echo "🖥️ No physical device UDID provided; running on simulator without console privacy harness."
  xcodebuild test \
    -project FastingTracker.xcodeproj \
    -scheme FastingTracker \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -enableCodeCoverage YES \
    -only-testing:FastingTrackerTests \
    2>&1 | tee test_results.log
fi

echo ""
echo "======================================"

# Parse results
if grep -q "TEST SUCCEEDED" test_results.log; then
    PASSED=$(grep "Executed.*tests" test_results.log | tail -1)
    echo "✅ ALL TESTS PASSED"
    echo "$PASSED"
    echo ""

    # Show test breakdown
    echo "Test Breakdown:"
    grep "Test Suite.*passed" test_results.log | grep -v "All tests" | while read line; do
        echo "  ✓ $line"
    done

    echo ""
    echo "📊 Coverage report available in:"
    echo "   DerivedData/.../Coverage.xccovarchive"
    exit 0
else
    echo "❌ TESTS FAILED"
    echo ""

    # Show failures
    echo "Failed Tests:"
    grep "error:" test_results.log || grep "failed" test_results.log | head -10
    exit 1
fi
