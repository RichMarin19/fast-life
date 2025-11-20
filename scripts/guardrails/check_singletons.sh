#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
BASELINE_DIR="$ROOT_DIR/scripts/guardrails/baseline"

if [[ ! -d "$BASELINE_DIR" ]]; then
  echo "Baseline directory not found: $BASELINE_DIR" >&2
  exit 1
fi

tmp_shared="$(mktemp)"
tmp_defaults="$(mktemp)"
cleanup() { rm -f "$tmp_shared" "$tmp_defaults"; }
trap cleanup EXIT

rg -n '\.shared' \
  "$ROOT_DIR/FastingTracker/UI" \
  "$ROOT_DIR/FastingTracker/Core/ViewModels" \
  | sort > "$tmp_shared"

rg -n 'UserDefaults\.standard' \
  "$ROOT_DIR/FastingTracker/UI" \
  "$ROOT_DIR/FastingTracker/Core/ViewModels" \
  | sort > "$tmp_defaults"

if ! diff -u "$BASELINE_DIR/shared_usage.txt" "$tmp_shared" > /dev/null; then
  echo "Detected changes in .shared usage. Please review and update the baseline if intentional." >&2
  diff -u "$BASELINE_DIR/shared_usage.txt" "$tmp_shared" || true
  exit 1
fi

if ! diff -u "$BASELINE_DIR/userdefaults_usage.txt" "$tmp_defaults" > /dev/null; then
  echo "Detected changes in UserDefaults.standard usage. Please review and update the baseline if intentional." >&2
  diff -u "$BASELINE_DIR/userdefaults_usage.txt" "$tmp_defaults" || true
  exit 1
fi

echo "Singleton/UserDefaults lint passed."
