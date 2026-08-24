#!/usr/bin/env bash
# Fast inner-loop check used by the PostToolUse hook after any .dart edit.
# Formats the touched file, then analyzes only its directory so the feedback
# loop stays under a couple of seconds.
set -uo pipefail
FILE="${1:-}"
[[ -z "$FILE" || "$FILE" != *.dart ]] && exit 0
[[ ! -f "$FILE" ]] && exit 0

cd "$(dirname "$0")/.." || exit 0
dart format --output=write "$FILE" >/dev/null 2>&1

OUT="$(dart analyze --fatal-infos "$FILE" 2>&1)"
if [[ $? -ne 0 ]]; then
  echo "dart analyze failed for $FILE — fix before continuing:" >&2
  echo "$OUT" >&2
  exit 2
fi
exit 0
