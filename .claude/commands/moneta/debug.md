---
description: Hypothesis-driven debugging with logged evidence
argument-hint: "<symptom>"
---

Debug by narrowing hypotheses against evidence, not by editing until the symptom
disappears.

Arguments: `$ARGUMENTS` — the observed symptom.

## Steps

1. **State the symptom precisely.** What was expected, what happened, and how you
   know. If you cannot reproduce it, reproducing it is the whole first step —
   write a failing test that captures it.

2. **List 3–5 candidate causes**, ranked by prior probability, each with the
   specific observation that would confirm or kill it.

3. **Gather evidence** in this order of preference: a failing test, then
   `flutter test --reporter=expanded` output, then targeted `debugPrint`/logs,
   then `flutter run` on the simulator. Paste the actual output — never
   paraphrase it.

4. **Kill hypotheses out loud.** For each one, say what the evidence showed and
   whether it is eliminated. Stop when exactly one survives.

5. **Fix the cause, not the symptom.** Then extend the failing test from step 1 so
   the bug cannot come back silently.

6. `bash tool/verify.sh --fast`, then record the finding in the change's
   `design.md` under a "Debugging notes" heading if the root cause changes any
   design assumption.

## Hard rules
- Never claim a fix without a test or command output that demonstrates it.
- If a change makes the symptom disappear but you cannot explain why, say that
  plainly — an unexplained fix is an open bug.
