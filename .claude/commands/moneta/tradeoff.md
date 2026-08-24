---
description: Compare implementation options and record the decision as an ADR
argument-hint: "<decision title>"
---

Write a real comparison, then decide. The output is a numbered ADR in
`docs/adr/` — this is the artifact that shows a choice was reasoned about rather
than defaulted into.

Arguments: `$ARGUMENTS` — the decision to make.

## Steps

1. Find the next ADR number: `ls docs/adr/`.

2. Investigate the codebase *before* proposing options. Cite concrete files and
   constraints (`pubspec.yaml` deps, existing layers, `tool/check_architecture.dart`
   rules). An ADR whose options ignore what is already in the repo is worthless.

3. Produce **at least three** options, including the boring one (do nothing /
   keep the current approach). For each: how it works here specifically, cost,
   what it makes harder later, and what would have to be true for it to be wrong.

4. Score them against criteria you state up front and weight explicitly. Testability
   and reversibility carry real weight in this project; novelty carries none.

5. Recommend one, and name the strongest argument *against* your recommendation.

6. Write `docs/adr/NNNN-<kebab-title>.md`:

   ```markdown
   # NNNN. <Title>

   - **Status:** Proposed
   - **Date:** <YYYY-MM-DD>
   - **Change:** <OpenSpec change name, or "cross-cutting">

   ## Context
   ## Options considered
   ### Option A — ...
   ### Option B — ...
   ### Option C — ...
   ## Decision criteria
   ## Decision
   ## Consequences
   ## Strongest counter-argument
   ## Revisit when
   ```

7. Link the ADR from the relevant OpenSpec `design.md` and from
   `docs/ai-workflow/evidence-log.md`.

## Hard rules

- Do not write an ADR whose conclusion you had already decided before step 2.
- If the options are not genuinely different, say so and skip the ADR — a
  ceremonial ADR is worse than none.
