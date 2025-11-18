#!/bin/bash
# Generate API documentation from code comments using jazzy

set -e

if ! command -v jazzy &> /dev/null; then
    echo "Installing jazzy..."
    gem install jazzy || sudo gem install jazzy
fi

echo "📚 Generating API documentation..."
echo ""

jazzy \
    --clean \
    --author "Fast LIFe Team" \
    --author_url "https://github.com/yourusername/fast-life" \
    --github_url "https://github.com/yourusername/fast-life" \
    --module "FastingTracker" \
    --source-directory FastingTracker \
    --output docs/api \
    --theme fullwidth \
    --min-acl public \
    --exclude "*/Tests/*,*/Preview Content/*"

echo ""
echo "✅ Documentation generated successfully!"
echo "📄 Output: docs/api/index.html"
echo ""

if [ -f "docs/api/index.html" ]; then
    echo "🌐 Opening in browser..."
    open docs/api/index.html
else
    echo "❌ Error: Documentation not generated"
    exit 1
fi

echo ""
echo "💡 To improve documentation:"
echo "1. Add doc comments to public APIs:"
echo "   /// Description"
echo "   /// - Parameter name: description"
echo "   /// - Returns: description"
echo ""
echo "2. Regenerate: ./scripts/generate_docs.sh"
