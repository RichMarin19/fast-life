#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
CHANGED_FILES="$(git diff --name-only --cached || true)"

if [[ -z "$CHANGED_FILES" ]]; then
  echo "No staged changes detected."
  exit 0
fi

if echo "$CHANGED_FILES" | grep -q '\.pbxproj$'; then
  if [[ "${ALLOW_PBXPROJ:-}" != "1" ]]; then
    echo "Detected staged changes to an Xcode project file. Set ALLOW_PBXPROJ=1 to bypass and document the reason in HANDOFF.md." >&2
    echo "$CHANGED_FILES" | grep '\.pbxproj$'
    exit 1
  fi
fi

echo "pbxproj guard passed."
