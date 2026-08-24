#!/usr/bin/env bash
# SessionStart hook: put the workflow state in front of the agent immediately,
# so a new session resumes inside the framework instead of guessing.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0

echo "## Moneta workflow state"
echo ""

CHANGES="$(ls -1 openspec/changes 2>/dev/null | grep -v '^archive$' || true)"
if [[ -n "$CHANGES" ]]; then
  echo "Active OpenSpec changes:"
  while IFS= read -r c; do
    [[ -z "$c" ]] && continue
    TOTAL="$(grep -c '^\s*- \[' "openspec/changes/$c/tasks.md" 2>/dev/null || echo 0)"
    DONE="$(grep -c '^\s*- \[x\]' "openspec/changes/$c/tasks.md" 2>/dev/null || echo 0)"
    echo "  - $c ($DONE/$TOTAL tasks)"
  done <<< "$CHANGES"
else
  echo "No active OpenSpec change. Start one with /opsx:propose before editing lib/."
fi

LAST="$(ls -1t docs/ai-workflow/verify-runs/*.md 2>/dev/null | head -1 || true)"
if [[ -n "$LAST" ]]; then
  RESULT="$(grep -m1 '\*\*Result:\*\*' "$LAST" | sed 's/.*Result:\*\* //')"
  echo ""
  echo "Last verify: $(basename "$LAST") → $RESULT"
fi
exit 0
