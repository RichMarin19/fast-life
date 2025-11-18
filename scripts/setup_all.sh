#!/bin/bash
# Master setup script for Fast LIFe automation
# Installs dependencies and configures automation

set -e

echo "🚀 Setting up Fast LIFe automation..."
echo ""

# Check if running from project root
if [ ! -f "FastingTracker.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Run this from the project root (/Users/richmarin/fast-life)"
    exit 1
fi

# Install dependencies
echo "📦 Checking dependencies..."

if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Install from https://brew.sh"
    exit 1
fi

if ! command -v swiftlint &> /dev/null; then
    echo "Installing SwiftLint..."
    brew install swiftlint
else
    echo "✅ SwiftLint installed"
fi

if ! command -v swiftformat &> /dev/null; then
    echo "Installing SwiftFormat..."
    brew install swiftformat
else
    echo "✅ SwiftFormat installed"
fi

if ! command -v fswatch &> /dev/null; then
    echo "Installing fswatch (for auto-format)..."
    brew install fswatch
else
    echo "✅ fswatch installed"
fi

# Make all scripts executable
echo ""
echo "🔧 Making scripts executable..."
chmod +x scripts/*.sh scripts/*.py 2>/dev/null || true

# Set up Git hooks
echo ""
echo "🪝 Setting up Git hooks..."
if [ -f "scripts/setup_git_hooks.sh" ]; then
    ./scripts/setup_git_hooks.sh
else
    echo "⚠️  setup_git_hooks.sh not found, skipping"
fi

# Set up shell aliases
echo ""
echo "⚙️  Setting up shell aliases..."

SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
    # Check if aliases already exist
    if grep -q "# Fast LIFe aliases" "$SHELL_RC"; then
        echo "✅ Aliases already configured in $SHELL_RC"
    else
        cat >> "$SHELL_RC" << 'EOF'

# Fast LIFe aliases
alias fl-test='xcodebuild test -project FastingTracker.xcodeproj -scheme FastingTracker -destination "platform=iOS Simulator,name=iPhone 15 Pro"'
alias fl-build='xcodebuild build -project FastingTracker.xcodeproj -scheme FastingTracker'
alias fl-lint='swiftlint lint'
alias fl-format='swiftformat .'
alias fl-coverage='./scripts/coverage_report.sh'
alias fl-deploy='./scripts/deploy_testflight.sh'
alias fl-logs='./scripts/migrate_to_logger.sh'
alias fl-unwraps='./scripts/find_force_unwraps.sh'
EOF
        echo "✅ Aliases added to $SHELL_RC"
    fi
else
    echo "⚠️  Shell RC file not found, aliases not configured"
fi

# Test automation
echo ""
echo "🧪 Testing automation..."

if swiftlint version &> /dev/null; then
    echo "✅ SwiftLint working"
else
    echo "❌ SwiftLint test failed"
fi

if swiftformat --version &> /dev/null; then
    echo "✅ SwiftFormat working"
else
    echo "❌ SwiftFormat test failed"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📚 New commands available (restart terminal or run: source $SHELL_RC):"
echo "  fl-test      - Run all tests"
echo "  fl-build     - Build project"
echo "  fl-lint      - Run SwiftLint"
echo "  fl-format    - Format all code"
echo "  fl-coverage  - Generate coverage report"
echo "  fl-deploy    - Deploy to TestFlight"
echo "  fl-logs      - Migrate print() to AppLogger"
echo "  fl-unwraps   - Find force unwraps"
echo ""
echo "📖 See docs/AUTOMATION_GUIDE.md for full documentation"
echo ""
echo "🔥 Try now: fl-lint"
