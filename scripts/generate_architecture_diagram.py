#!/usr/bin/env python3
"""
Generate architecture diagram from code structure using Mermaid syntax
"""

import os
from pathlib import Path

def scan_packages():
    """Scan for SPM packages and generate mermaid diagram"""

    packages_dir = Path("Packages")

    if not packages_dir.exists():
        print("⚠️  No Packages/ directory found.")
        print("   This script is most useful after Phase 1 (SPM modularization)")
        print("   For now, generating diagram based on current structure...")
        print("")
        generate_current_structure()
        return

    packages = [d.name for d in packages_dir.iterdir()
                if d.is_dir() and not d.name.startswith('.')]

    if not packages:
        print("⚠️  No packages found in Packages/")
        generate_current_structure()
        return

    print("📊 Architecture Diagram (Mermaid syntax)")
    print("")
    print("```mermaid")
    print("graph TD")
    print("    App[FastingTracker App]")
    print("")

    for pkg in sorted(packages):
        safe_name = pkg.replace('-', '')
        print(f"    {safe_name}[{pkg}]")
        print(f"    App --> {safe_name}")

    print("")

    # Add common dependencies
    if "DataLayer" in packages and "Core" in packages:
        print("    DataLayer --> Core")
    if "FeatureFasting" in packages:
        if "DataLayer" in packages:
            print("    FeatureFasting --> DataLayer")
        if "DesignSystem" in packages:
            print("    FeatureFasting --> DesignSystem")
    if "FeatureHydration" in packages:
        if "DataLayer" in packages:
            print("    FeatureHydration --> DataLayer")
        if "DesignSystem" in packages:
            print("    FeatureHydration --> DesignSystem")
    if "FeatureWeight" in packages:
        if "DataLayer" in packages:
            print("    FeatureWeight --> DataLayer")
        if "DesignSystem" in packages:
            print("    FeatureWeight --> DesignSystem")

    print("```")
    print("")
    print("📋 Copy this Mermaid diagram to your README.md")
    print("   GitHub will render it automatically")

def generate_current_structure():
    """Generate diagram for current (pre-modularization) structure"""

    print("📊 Current Architecture (Monolithic)")
    print("")
    print("```mermaid")
    print("graph TD")
    print("    App[FastingTracker App]")
    print("    App --> Views[Views Layer]")
    print("    App --> Managers[Managers Layer]")
    print("    App --> Models[Models Layer]")
    print("")
    print("    Views --> ContentView")
    print("    Views --> HistoryView")
    print("    Views --> HydrationTrackingView")
    print("    Views --> WeightTrackingView")
    print("")
    print("    Managers --> FastingManager")
    print("    Managers --> HydrationManager")
    print("    Managers --> WeightManager")
    print("    Managers --> HealthKitManager")
    print("")
    print("    Models --> FastingSession")
    print("    Models --> WeightEntry")
    print("    Models --> DrinkEntry")
    print("")
    print("    Managers --> Models")
    print("    Views --> Managers")
    print("```")
    print("")
    print("💡 After Phase 1, this will become modular with SPM packages")

if __name__ == "__main__":
    try:
        scan_packages()
    except KeyboardInterrupt:
        print("\n⚠️  Interrupted")
    except Exception as e:
        print(f"\n❌ Error: {e}")
