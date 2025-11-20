#!/bin/bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <device-udid> <command...>" >&2
  exit 1
fi

device_udid="$1"
shift
test_command=("$@")

LOG_PATTERN='(lbs|pounds|kg|kilograms|goal weight|weight change|current weight)'
LOG_TEMP_DIR=$(mktemp -d)
LOG_FILE="$LOG_TEMP_DIR/fastlife.log"

cleanup() {
  rm -rf "$LOG_TEMP_DIR"
}
trap cleanup EXIT

log stream --style syslog \
  --predicate 'subsystem == "com.fastlife.FastLIFe"' \
  --source \
  --level info \
  --color never \
  > "$LOG_FILE" &
LOG_PID=$!

sleep 2

"${test_command[@]}"

kill $LOG_PID >/dev/null 2>&1 || true

if grep -E -i "$LOG_PATTERN" "$LOG_FILE"; then
  echo "\n🚨 Privacy regression detected (see matches above)." >&2
  exit 1
fi

echo "✅ Console log privacy check passed."
