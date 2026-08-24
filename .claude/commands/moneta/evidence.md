---
description: Regenerate the Level-4 evidence report from repository artifacts
allowed-tools: Bash(git log:*), Bash(ls:*), Bash(openspec:*), Bash(npx -y @fission-ai/openspec@latest:*), Read, Write, Edit, Grep, Glob
---

Rebuild `docs/ai-workflow/level-4-evidence.md` from what is actually in the repo,
so the assessment maps to artifacts rather than recollection.

## Steps

1. Collect the facts. Do not write anything until you have all of them:
   - Active and archived changes: `ls openspec/changes` and `ls openspec/changes/archive`
   - Per change: which artifacts exist (`proposal.md`, `specs/`, `design.md`, `tasks.md`)
     and the task completion count
   - Verify runs: `ls docs/ai-workflow/verify-runs/` with each file's Result line
   - ADRs: `ls docs/adr/`
   - Checkpoint commits: `git log --oneline`
   - Reusable automation: `ls .claude/commands/moneta .claude/agents .claude/hooks tool`

2. Write the report with one section per NUS Level-4 criterion, and for each:
   the criterion, the concrete artifact paths that satisfy it, and an honest
   note where evidence is thin or missing.

   Criteria (from the NUS framework, Level 4 — "Workflow có framework và kiểm chứng"):
   - Uses a named framework/methodology end-to-end (spec → discuss → plan → execute → verify)
   - Task or refactor spanning multiple modules
   - Trade-off comparison
   - Combines test + static analysis + logs + docs
   - Uses checkpoints
   - Creates reusable commands / instructions / automation
   - At least 2 recent medium-size tasks applying the workflow end-to-end

3. **Report gaps as gaps.** If a criterion has no artifact behind it, write
   "not yet demonstrated" and say what would demonstrate it. Do not pad the
   report to look complete — a padded report fails the framework's own rule that
   a single trial run does not raise a level.
