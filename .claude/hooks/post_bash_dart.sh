#!/usr/bin/env bash
# PostToolUse hook for Bash.
#
# Closes the blind spot found while implementing the token layer: the Edit/Write
# hook keys off `tool_input.file_path`, so a .dart file written through a shell
# heredoc never reaches it and lint findings survive to the gate.
#
# This fires only when the Bash command text mentions a .dart path, so the common
# case (git, flutter test, openspec) pays nothing.
set -uo pipefail

PAYLOAD="$(cat)"
CMD="$(printf '%s' "$PAYLOAD" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print(d.get("tool_input", {}).get("command", ""))
' 2>/dev/null)"

# Cheap guard first: most commands never mention a .dart path.
case "$CMD" in
  *.dart*) ;;
  *) exit 0 ;;
esac

# Reading or running Dart is not writing it; only re-analyze when the command
# could have changed a file.
#
# Matched with a regex rather than a `case` pattern list. The pattern form was
# silently broken for the whole of change 2: it contained `*cat\ >*`, where the
# backslash escapes the space and leaves `>` bare — and a bare `>` in a case
# pattern is a redirection operator, so bash refused to parse the file. The hook
# crashed on that line every time it ran instead of analyzing anything, which is
# indistinguishable from a hook that found nothing.
#
# tool/check_hooks.sh now parses every hook, so this class cannot recur silently.
WRITES_RE='(cat[[:space:]]+>|tee|sed[[:space:]]+-i|python3|perl|awk|mv[[:space:]]|cp[[:space:]]|>>?[[:space:]]*[^|&])'
if [[ ! "$CMD" =~ $WRITES_RE ]]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0

dart format --output=write lib test tool >/dev/null 2>&1

if ! OUT="$(dart analyze --fatal-infos 2>&1)"; then
  {
    echo "dart analyze --fatal-infos failed after a Bash write. Fix before continuing:"
    echo "$OUT" | grep -E '^\s+(info|warning|error)' | head -25
  } >&2
  exit 2
fi
exit 0
