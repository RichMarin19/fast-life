#!/bin/bash
# Set up Git pre-commit hooks for automated quality checks

set -e

HOOKS_DIR=".git/hooks"
HOOK_FILE="$HOOKS_DIR/pre-commit"

if [ ! -d ".git" ]; then
    echo "❌ Error: Not a git repository. Run 'git init' first."
    exit 1
fi

echo "🪝 Setting up Git pre-commit hooks..."

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Create pre-commit hook
cat > "$HOOK_FILE" << 'EOF'
#!/bin/bash
# Pre-commit hook: Run SwiftLint and quick tests

echo "🔍 Running pre-commit checks..."

# Run SwiftLint
echo "  Checking code style with SwiftLint..."
if command -v swiftlint &> /dev/null; then
    swiftlint lint --quiet --strict
    if [ $? -ne 0 ]; then
        echo "❌ SwiftLint failed. Fix errors before committing."
        echo "💡 Run: swiftlint lint --fix"
        exit 1
    fi
    echo "  ✅ SwiftLint passed"
else
    echo "  ⚠️  SwiftLint not installed. Run: brew install swiftlint"
fi

# Run quick tests (only critical tests to keep commits fast)
echo "  Running critical tests..."
xcodebuild test \
    -project FastingTracker.xcodeproj \
    -scheme FastingTracker \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -quiet \
    -only-testing:FastingTrackerTests 2>&1 | grep -E "Test Suite|passed|failed" || true

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ Tests failed. Fix tests before committing."
    echo "💡 Run full tests: fl-test"
    exit 1
fi

echo "  ✅ Tests passed"
echo "🎉 Pre-commit checks complete!"
EOF

# Make hook executable
chmod +x "$HOOK_FILE"

echo "✅ Pre-commit hook installed at: $HOOK_FILE"
echo ""
echo "📋 The hook will run automatically on every 'git commit'"
echo "   It checks:"
echo "   - SwiftLint (code style)"
echo "   - Unit tests (code correctness)"
echo ""
echo "💡 To skip the hook (not recommended):"
echo "   git commit --no-verify -m \"message\""
echo ""
echo "🧪 Test it now: Make a change and try to commit"
