#!/usr/bin/env bash
# Moneta verification gate.
#
# One command that decides whether a change is done. Every OpenSpec change must
# pass this before `/opsx:archive`. Each run appends a timestamped record to
# docs/ai-workflow/verify-runs/ so "kiểm chứng" is an artifact in the repo, not a
# claim in a chat log.
#
# Usage:
#   tool/verify.sh                    # full gate
#   tool/verify.sh --fast             # skip coverage + golden tests (inner loop)
#   tool/verify.sh --change <name>    # tag the evidence record with a change name
#   tool/verify.sh --no-record        # don't write an evidence record

set -uo pipefail

FAST=0
RECORD=1
CHANGE="unscoped"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --fast) FAST=1; shift ;;
    --no-record) RECORD=0; shift ;;
    --change) CHANGE="${2:-unscoped}"; shift 2 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

cd "$(dirname "$0")/.." || exit 2

STAMP="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
LOG_DIR="docs/ai-workflow/verify-runs"
LOG_FILE="$LOG_DIR/${STAMP}_${CHANGE}.md"
mkdir -p "$LOG_DIR"

RESULTS=()
FAILED=0

step() {
  local name="$1"; shift
  echo ""
  echo "── $name ─────────────────────────────────────────"
  local out
  out="$("$@" 2>&1)"
  local code=$?
  echo "$out"
  if [[ $code -eq 0 ]]; then
    RESULTS+=("PASS|$name|$(echo "$out" | tail -1)")
  else
    RESULTS+=("FAIL|$name|$(echo "$out" | tail -3 | tr '\n' ' ')")
    FAILED=1
  fi
  return 0
}

echo "Moneta verify — change: $CHANGE — $(date -u +%Y-%m-%dT%H:%M:%SZ)"

step "format"       dart format --set-exit-if-changed --output=none lib test tool
step "analyze"      dart analyze --fatal-infos --fatal-warnings
step "architecture" dart run tool/check_architecture.dart
step "design-tokens" dart run tool/check_design_tokens.dart
step "hooks"         bash tool/check_hooks.sh

if [[ $FAST -eq 1 ]]; then
  step "test"       flutter test --reporter=failures-only
else
  step "test"       flutter test --coverage --reporter=failures-only
  step "coverage"   dart run tool/check_coverage.dart --min 70 --critical-min 85
fi

echo ""
echo "══════════════════════════════════════════════════"
for r in "${RESULTS[@]}"; do
  IFS='|' read -r status name detail <<< "$r"
  printf '%-6s %-16s %s\n' "$status" "$name" "$detail"
done
echo "══════════════════════════════════════════════════"

if [[ $RECORD -eq 1 ]]; then
  {
    echo "# Verify run — $CHANGE"
    echo ""
    echo "- **When (UTC):** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "- **Mode:** $([[ $FAST -eq 1 ]] && echo fast || echo full)"
    echo "- **Commit:** $(git rev-parse --short HEAD 2>/dev/null || echo 'not committed')"
    echo "- **Result:** $([[ $FAILED -eq 0 ]] && echo '✅ PASS' || echo '❌ FAIL')"
    echo ""
    echo "| Gate | Status | Detail |"
    echo "| --- | --- | --- |"
    for r in "${RESULTS[@]}"; do
      IFS='|' read -r status name detail <<< "$r"
      echo "| $name | $status | ${detail//|/\\|} |"
    done
  } > "$LOG_FILE"
  echo "evidence → $LOG_FILE"
fi

if [[ $FAILED -eq 0 ]]; then
  echo "✅ verify PASSED"
  exit 0
fi
echo "❌ verify FAILED"
exit 1
