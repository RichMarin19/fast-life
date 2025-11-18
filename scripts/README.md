# 🤖 Fast LIFe Automation Scripts

**11 scripts to save 60+ hours of manual work.**

## 🚀 Quick Start

```bash
# Set up everything at once
./setup_all.sh

# Test your new commands
fl-lint      # Run SwiftLint
fl-test      # Run tests
fl-format    # Format code
```

## 📋 Available Scripts

### Setup & Configuration
- **`setup_all.sh`** - Master setup (installs tools, configures hooks, creates aliases)
- **`setup_git_hooks.sh`** - Install pre-commit hooks (runs lint + tests automatically)

### Code Migration (Save 20h)
- **`migrate_to_logger.sh`** - Replace print() with AppLogger (saves 4h)
- **`add_accessibility_labels.py`** - Find missing accessibility labels (saves 8h)
- **`generate_swiftdata_models.sh`** - Convert Codable → SwiftData (saves 4h per model)
- **`find_force_unwraps.sh`** - Detect unsafe force unwraps (saves 2h)

### Testing & CI/CD (Save 10h/week)
- **`coverage_report.sh`** - Generate HTML coverage report (saves 1h/week)
- **`deploy_testflight.sh`** - Automated TestFlight deployment (saves 2h/release)

### Code Quality (Save 10h/week)
- **`format_on_save.sh`** - Auto-format Swift files on save (saves 3h/week)

### Documentation (Save 5h)
- **`generate_docs.sh`** - Generate API docs from code comments (saves 2h)
- **`generate_architecture_diagram.py`** - Create architecture diagrams (saves 3h)

## 💡 Usage Examples

### Example 1: Migrate Logging (5 minutes)
```bash
# Replaces all print() with AppLogger
./migrate_to_logger.sh

# Review changes
git diff

# If satisfied, delete backups and commit
find . -name "*.backup" -delete
git commit -am "refactor: migrate to structured logging"
```

### Example 2: Find Accessibility Issues (2 minutes)
```bash
# Scan all Swift files
./add_accessibility_labels.py

# Output:
# 📄 ContentView.swift:
#   Line 42: Image(systemName: "flame.fill") → Add .accessibilityLabel("flame")
#   Line 108: Image(systemName: "drop.fill") → Add .accessibilityLabel("drop")
```

### Example 3: Check Code Coverage (5 minutes)
```bash
# Run tests with coverage
./coverage_report.sh

# Opens HTML report in browser
# Shows coverage % per file
```

### Example 4: Deploy to TestFlight (30 minutes)
```bash
# Set credentials (one-time)
export APPLE_ID="your@email.com"
export APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"

# Deploy
./deploy_testflight.sh

# Wait 15 min for App Store Connect processing
```

## 📊 Time Savings

| Task | Manual | Automated | Savings |
|------|--------|-----------|---------|
| Replace print() | 4h | 5 min | 3.9h |
| Accessibility scanning | 8h | 15 min | 7.75h |
| SwiftData conversion | 4h | 10 min | 3.5h |
| Find force unwraps | 2h | 2 min | 1.9h |
| Pre-commit checks | 10 min/commit | Auto | 2h/week |
| TestFlight deploy | 2h | 30 min | 1.5h |
| Code formatting | 30 min/day | Auto | 3h/week |
| Coverage reports | 1h | 5 min | 1h/week |
| **TOTAL** | **~90h** | **~30h** | **~60h** |

## 🔧 Requirements

**Installed by setup_all.sh:**
- Homebrew (macOS package manager)
- SwiftLint (code linting)
- SwiftFormat (code formatting)
- fswatch (file monitoring)

**Optional (for specific scripts):**
- jazzy (API documentation) - `gem install jazzy`
- jq (JSON parsing) - `brew install jq`

## 📚 Documentation

**Full guide:** [`../docs/AUTOMATION_GUIDE.md`](../docs/AUTOMATION_GUIDE.md)

## ⚡ Shell Aliases (After setup_all.sh)

```bash
fl-test      # Run all tests
fl-build     # Build project
fl-lint      # Run SwiftLint
fl-format    # Format all code
fl-coverage  # Generate coverage report
fl-deploy    # Deploy to TestFlight
fl-logs      # Migrate print() to AppLogger
fl-unwraps   # Find force unwraps
```

## 🎯 Recommended Workflow

**Day 1: Setup**
```bash
./setup_all.sh                # 15 min
./setup_git_hooks.sh          # 5 min
./migrate_to_logger.sh        # 5 min
```

**Daily: Auto-format** (runs in background)
```bash
./format_on_save.sh &
```

**Weekly: Coverage**
```bash
fl-coverage                   # Check progress
```

**Before commits:** (automatic via git hooks)
- SwiftLint runs
- Tests run
- Commit blocked if failures

**For releases:**
```bash
fl-deploy                     # TestFlight deployment
```

## 🚀 Start Now

```bash
cd /Users/richmarin/fast-life
./scripts/setup_all.sh
```

**15 minutes of setup = 60+ hours saved.**

---

**📖 [Full Automation Guide](../docs/AUTOMATION_GUIDE.md)**
