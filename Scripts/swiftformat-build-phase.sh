#!/bin/bash

# SwiftFormat Build Phase Script
# Add this as a "Run Script Phase" in Xcode Build Phases
# Input Files: $(SRCROOT)/.swiftformat
# Output Files: $(DERIVED_FILE_DIR)/swiftformat.log

export PATH="$PATH:/opt/homebrew/bin"

if which swiftformat > /dev/null; then
  echo "Running SwiftFormat..."
  swiftformat . --config .swiftformat
  echo "SwiftFormat completed successfully"
else
  echo "warning: SwiftFormat not installed, install with 'brew install swiftformat'"
fi