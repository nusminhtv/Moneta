#!/usr/bin/env bash
# Stop hook: refuse to end a turn that left lib/ or test/ modified without a
# passing verify run. This is what makes "verify" a gate rather than a habit.
#
# It blocks at most once per distinct dirty state, so it cannot loop.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0

DIRTY="$(git status --porcelain -- lib test 2>/dev/null || true)"
[[ -z "$DIRTY" ]] && exit 0

LAST="$(ls -1t docs/ai-workflow/verify-runs/*.md 2>/dev/null | head -1 || true)"
NEWEST_SRC="$(find lib test -name '*.dart' -newer "${LAST:-/dev/null}" 2>/dev/null | head -1 || true)"

if [[ -n "$LAST" && -z "$NEWEST_SRC" ]]; then
  grep -q 'Result:\*\* ✅' "$LAST" && exit 0
fi

STATE_HASH="$(printf '%s' "$DIRTY" | shasum | cut -d' ' -f1)"
MARKER=".claude/.verify-nag"
[[ -f "$MARKER" && "$(cat "$MARKER")" == "$STATE_HASH" ]] && exit 0
printf '%s' "$STATE_HASH" > "$MARKER"

cat >&2 <<'MSG'
Dart sources under lib/ or test/ changed but no passing verify run covers them.

Run the gate before finishing:
  tool/verify.sh --change <openspec-change-name>

Use `tool/verify.sh --fast` only for an inner loop; the full gate (coverage
included) is required before /opsx:archive. If you deliberately want to stop
without verifying, say so and stop again — this guard fires once per state.
MSG
exit 2
