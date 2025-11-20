#!/bin/bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <device-udid> [xcodebuild args...]" >&2
  exit 1
fi

device_udid="$1"
shift

if [ "$#" -eq 0 ]; then
  test_command=(
    xcodebuild
    -project FastingTracker.xcodeproj
    -scheme FastingTracker
    -configuration Debug
    -destination "id=$device_udid"
    test
  )
else
  test_command=("$@")
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_SCRIPT="$PROJECT_ROOT/scripts/console_privacy_check.sh"
"$LOG_SCRIPT" "$device_udid" "${test_command[@]}"
