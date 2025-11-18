#!/usr/bin/env python3
"""
Scan Swift files for accessibility issues and suggest fixes
"""

import re
import sys
from pathlib import Path

PROJECT_DIR = Path("FastingTracker")

def process_file(filepath):
    """Scan a Swift file for accessibility issues"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"❌ Error reading {filepath}: {e}")
        return []

    issues = []

    # Find Images without accessibility
    for match in re.finditer(r'Image\(systemName:\s*"([^"]+)"\)(?!\s*\.(accessibilityLabel|accessibilityHidden))', content):
        icon_name = match.group(1)
        human_name = icon_name.replace('.', ' ').replace('fill', '').replace('-', ' ').strip()
        line_num = content[:match.start()].count('\n') + 1
        issues.append({
            'line': line_num,
            'type': 'Image',
            'original': f'Image(systemName: "{icon_name}")',
            'suggestion': f'.accessibilityLabel("{human_name}")'
        })

    # Find Buttons that might need hints
    for match in re.finditer(r'Button\([^)]*\)\s*\{', content):
        context_start = max(0, match.start() - 50)
        context_end = min(len(content), match.end() + 200)
        context = content[context_start:context_end]

        # Check if accessibility is already present
        if '.accessibilityLabel' not in context and '.accessibilityHint' not in context:
            line_num = content[:match.start()].count('\n') + 1
            issues.append({
                'line': line_num,
                'type': 'Button',
                'original': match.group(0)[:50],
                'suggestion': 'Consider adding .accessibilityHint() if action is not obvious'
            })

    # Find Text with .font() but no accessibility context
    for match in re.finditer(r'Text\("([^"]+)"\)\s*\.font\(', content):
        text_content = match.group(1)
        if len(text_content) < 5:  # Short text might need context
            line_num = content[:match.start()].count('\n') + 1
            issues.append({
                'line': line_num,
                'type': 'Text',
                'original': f'Text("{text_content}")',
                'suggestion': f'Short text - consider if "{text_content}" needs .accessibilityLabel() for clarity'
            })

    return issues

def scan_project():
    """Scan all Swift files for accessibility issues"""
    print("🔍 Scanning for accessibility issues...\n")

    swift_files = list(PROJECT_DIR.rglob("*.swift"))
    total_issues = 0
    files_with_issues = 0

    for filepath in sorted(swift_files):
        issues = process_file(filepath)

        if issues:
            files_with_issues += 1
            total_issues += len(issues)
            print(f"\n📄 {filepath.name}:")

            for issue in issues:
                print(f"  Line {issue['line']}: {issue['type']}")
                print(f"    Found: {issue['original']}")
                print(f"    → {issue['suggestion']}")

    print(f"\n📊 Summary:")
    print(f"  Files scanned: {len(swift_files)}")
    print(f"  Files with issues: {files_with_issues}")
    print(f"  Total issues found: {total_issues}")

    print("\n💡 Next steps:")
    print("1. Review suggestions above")
    print("2. Add accessibility labels where needed")
    print("3. Test with VoiceOver: Cmd+F5 in Simulator")
    print("4. Run Xcode Accessibility Inspector")

    print("\n📖 Quick reference:")
    print("  .accessibilityLabel(\"what it is\")")
    print("  .accessibilityHint(\"what it does\")")
    print("  .accessibilityValue(\"current state\")")
    print("  .accessibilityHidden(true)  // for decorative elements")

    return total_issues

if __name__ == "__main__":
    try:
        total = scan_project()
        sys.exit(0 if total == 0 else 1)
    except KeyboardInterrupt:
        print("\n⚠️  Scan interrupted")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)
