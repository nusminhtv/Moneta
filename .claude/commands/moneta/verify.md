---
description: Run the Moneta verification gate and drive every failure to green
argument-hint: "[change-name] [--fast]"
allowed-tools: Bash(tool/verify.sh:*), Bash(bash tool/verify.sh:*), Bash(dart:*), Bash(flutter test:*), Read, Edit, Write, Grep, Glob
---

Run the verification gate and do not stop until it passes or you hit something
that genuinely needs a human decision.

Arguments: `$ARGUMENTS` (first token = OpenSpec change name, `--fast` = skip
coverage and run the inner-loop gate only).

## Steps

1. Determine the change name. If `$ARGUMENTS` has none, run
   `ls openspec/changes` and use the single active change; if several are active,
   ask which one.

2. Run the gate:
   ```
   bash tool/verify.sh --change <name>
   ```

3. Read the summary table. For every `FAIL` row, treat it as a distinct defect:

   | Gate | What a failure means | How to respond |
   | --- | --- | --- |
   | `format` | Formatting drift | `dart format lib test tool` |
   | `analyze` | Lint/type violation | Fix the code. Never silence a rule with `// ignore:` unless you state the reason in the same line and in the change's design notes. |
   | `architecture` | A layer boundary was crossed | Move the dependency or introduce a seam in `lib/core`. Do **not** widen `_allowedImports` in `tool/check_architecture.dart` to make a violation pass — that is changing the ruler, not the code. |
   | `design-tokens` | Hard-coded design value outside `tokens/` | Route it through `MonetaTokens`/`MonetaTheme`. Add the token if it is genuinely missing from Figma-derived tokens, and note the addition. |
   | `test` | Behaviour is wrong or the test is wrong | Decide which, explicitly. State in your reply which one you concluded and why before editing either. |
   | `coverage` | Untested critical code | Add tests for the uncovered lines. Do not lower the threshold. |

4. Re-run the gate after each fix round. Report the delta each round
   (`3 FAIL → 1 FAIL`), not just the final state.

5. When it passes, print the path of the evidence record that was written and
   append one line to `docs/ai-workflow/evidence-log.md` under the change's
   section, in this form:

   ```
   | <UTC date> | verify | full | ✅ | docs/ai-workflow/verify-runs/<file>.md |
   ```

## Hard rules

- Never weaken a gate to make it pass. If a gate is genuinely wrong, say so
  explicitly, explain why, and ask before changing it.
- Never report "verify passed" from memory. Only report it from a run in this
  session whose evidence file exists on disk.
- If a gate fails for a reason outside this change's scope, say so, fix it only
  if it is small, and otherwise record it in the change's design notes.
