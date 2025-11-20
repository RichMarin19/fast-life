#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_TESTS_SCRIPT="$PROJECT_ROOT/scripts/run-tests.sh"
LOG_PRIVACY_SCRIPT="$PROJECT_ROOT/scripts/log_privacy_audit.sh"
cd "$PROJECT_ROOT"

if [[ -x "$LOG_PRIVACY_SCRIPT" ]]; then
  echo "🔍 Running log privacy audit..."
  "$LOG_PRIVACY_SCRIPT"
else
  echo "⚠️ Missing log privacy audit script at $LOG_PRIVACY_SCRIPT" >&2
  exit 1
fi

if [[ -z "${FASTLIFE_DEVICE_UDID:-}" ]]; then
  DEVICE_LINE=$(xcrun xctrace list devices 2>/dev/null | grep -E "(iPhone|iPad)" | grep -v "(Simulator)" | head -n 1 || true)
  if [[ -n "$DEVICE_LINE" ]]; then
    DEVICE_UDID=$(echo "$DEVICE_LINE" | awk -F'[()]' '{print $(NF-1)}' | xargs)
    if [[ -n "$DEVICE_UDID" ]]; then
      echo "📱 Using connected device: $DEVICE_LINE"
      export FASTLIFE_DEVICE_UDID="$DEVICE_UDID"
    fi
  fi
else
  echo "📱 Using FASTLIFE_DEVICE_UDID=$FASTLIFE_DEVICE_UDID"
fi

if [[ -z "${FASTLIFE_DEVICE_UDID:-}" ]]; then
  echo "⚠️ No physical device detected. Running simulator tests without console privacy enforcement."
fi

"$RUN_TESTS_SCRIPT"
