#!/usr/bin/env bash
# PostToolUse hook: after any Edit/Write, format the touched Dart file and
# analyze it. Exit 2 feeds the analyzer output straight back to the agent, so a
# lint or type error is corrected in the same turn instead of surviving to review.
set -uo pipefail

PAYLOAD="$(cat)"
FILE="$(printf '%s' "$PAYLOAD" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print(d.get("tool_input", {}).get("file_path", ""))
' 2>/dev/null)"

[[ -z "$FILE" || "$FILE" != *.dart ]] && exit 0
[[ ! -f "$FILE" ]] && exit 0

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0

dart format --output=write "$FILE" >/dev/null 2>&1

if ! OUT="$(dart analyze --fatal-infos "$FILE" 2>&1)"; then
  {
    echo "dart analyze failed for $FILE. Fix these before moving on:"
    echo "$OUT" | grep -E '^\s+(info|warning|error)' | head -20
  } >&2
  exit 2
fi
exit 0
