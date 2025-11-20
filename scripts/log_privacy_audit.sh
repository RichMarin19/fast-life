#!/usr/bin/env bash
# Purpose: Enforce Phase 2 logging/privacy guardrails by scanning for
#          (a) forbidden `privacy: .public` annotations outside AppLogger,
#          (b) AppLogger calls that log literal weight units (lbs/kg), and
#          (c) direct Crashlytics usage outside CrashReportManager.
# Usage:
#   ./scripts/log_privacy_audit.sh
#     (Run from anywhere; script auto-detects repo root.)
# Exit Codes:
#   0 – no violations
#   1 – violations found
#   2 – required tooling missing / unexpected error

set -euo pipefail

if ! command -v rg >/dev/null 2>&1; then
  echo "ripgrep (rg) is required for log privacy auditing." >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
source_dir="${repo_root}/FastingTracker"

violations=0

run_check() {
  local description="$1"
  shift

  set +e
  local output
  output=$("$@" 2>&1)
  local status=$?
  set -e

  case ${status} in
    0)
      echo "❌ ${description}" >&2
      echo "${output}" >&2
      violations=1
      ;;
    1)
      echo "✅ ${description}"
      ;;
    *)
      echo "⚠️ Failed to execute check: ${description}" >&2
      echo "${output}" >&2
      exit ${status}
      ;;
  esac
}

common_args=(
  --hidden
  --pcre2
  --glob '*.swift'
  --glob '!**/Legacy/**'
)

# 1. Block `privacy: .public` outside AppLogger.swift (helpers own the allow list).
run_check \
  "No forbidden 'privacy: .public' annotations" \
  rg "${common_args[@]}" --glob '!Core/Utilities/AppLogger.swift' \
     'privacy:\\s*\\.public' "${source_dir}"

# 2. Block direct Crashlytics usage outside CrashReportManager.
run_check \
  "Crashlytics usage confined to CrashReportManager" \
  rg "${common_args[@]}" --glob '!Core/Managers/CrashReportManager.swift' \
     'Crashlytics\\.crashlytics' "${source_dir}"

# 3. Block AppLogger calls that embed lbs/kg literals.
set +e
app_logger_output=$(rg "${common_args[@]}" '\b(?:lbs|pounds|kg|kilograms)\b' "${source_dir}" | rg 'AppLogger\.(info|debug|warning|error)')
app_logger_status=$?
set -e

if [[ ${app_logger_status} -eq 0 ]]; then
  echo "❌ AppLogger calls do not log literal weight units" >&2
  echo "${app_logger_output}" >&2
  violations=1
elif [[ ${app_logger_status} -eq 1 ]]; then
  echo "✅ AppLogger calls do not log literal weight units"
else
  echo "⚠️ Failed to execute check: AppLogger calls do not log literal weight units" >&2
  echo "${app_logger_output}" >&2
  exit ${app_logger_status}
fi

if [[ ${violations} -ne 0 ]]; then
  echo "\nLog privacy audit FAILED. Review the violations above." >&2
  exit 1
fi

echo "\nLog privacy audit passed (no violations detected)."
