#!/usr/bin/env bash
# Hook health check.
#
# The hooks are the inner loop of this project's workflow, and nothing was
# checking them. `post_bash_dart.sh` shipped with the `case` pattern
# `*cat\ >*`: the backslash escapes the space, which leaves `>` bare, and a bare
# `>` inside a case pattern is a redirection operator. bash refused to parse the
# file, so the hook died on that line every single time it ran, for the whole of
# the transactions-local-store change.
#
# Silent, because a hook that crashes looks exactly like a hook with nothing to
# report. (First guess at the culprit was the `*">"*` pattern next to it — that
# one is legal. Checked before writing it down.)
#
# Two checks per hook:
#   1. It parses (`bash -n`).
#   2. Fed a payload it should ignore, it exits 0 — which a crashing hook cannot.
#
# stop_verify_guard is parse-checked only: its whole job is to exit 2 when the
# tree is dirty, so "exits 0" is not a property it has.
#
# Usage: bash tool/check_hooks.sh
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

HOOKS_DIR=".claude/hooks"
failures=0
checked=0

if [[ ! -d "$HOOKS_DIR" ]]; then
  echo "✗ hooks: $HOOKS_DIR not found" >&2
  exit 1
fi

# Payload each hook should treat as none of its business.
irrelevant_payload() {
  case "$1" in
    post_edit_dart.sh)
      printf '%s' '{"tool_input":{"file_path":"README.md"}}' ;;
    post_bash_dart.sh)
      printf '%s' '{"tool_input":{"command":"git status --porcelain"}}' ;;
    session_start.sh)
      printf '%s' '{}' ;;
    *)
      printf '' ;;
  esac
}

# Hooks whose no-op behaviour is safe to assert.
probes_noop() {
  case "$1" in
    post_edit_dart.sh|post_bash_dart.sh|session_start.sh) return 0 ;;
    *) return 1 ;;
  esac
}

for hook in "$HOOKS_DIR"/*.sh; do
  name="$(basename "$hook")"
  checked=$((checked + 1))

  if [[ ! -x "$hook" ]]; then
    echo "✗ $name is not executable" >&2
    failures=$((failures + 1))
    continue
  fi

  if ! err="$(bash -n "$hook" 2>&1)"; then
    echo "✗ $name does not parse:" >&2
    echo "    $err" >&2
    failures=$((failures + 1))
    continue
  fi

  if probes_noop "$name"; then
    out="$(irrelevant_payload "$name" | "$hook" 2>&1)"
    code=$?
    if [[ $code -ne 0 ]]; then
      echo "✗ $name exited $code on a payload it should ignore:" >&2
      echo "    $(printf '%s' "$out" | head -3)" >&2
      failures=$((failures + 1))
    fi
  fi
done

if [[ $failures -eq 0 ]]; then
  echo "✓ hooks: $checked hook(s) parse and no-op cleanly"
  exit 0
fi

echo "✗ hooks: $failures of $checked failed" >&2
exit 1
