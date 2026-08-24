---
description: Close out a step of an OpenSpec change — verify, commit, record evidence
argument-hint: "<change-name> \"<what this step did>\""
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*), Bash(tool/verify.sh:*), Bash(bash tool/verify.sh:*), Read, Edit, Write
---

A checkpoint is the unit of control in this project: a reviewable diff whose
correctness is backed by a verify run. Create one at the end of every task in
`tasks.md`, not at the end of the whole change.

Arguments: `$ARGUMENTS` — change name, then a short description of the step.

## Steps

1. `git status --porcelain` and `git diff --stat` — show the user exactly what
   this checkpoint contains. If the diff spans work from more than one task,
   say so and propose splitting it.

2. Run the gate: `bash tool/verify.sh --change <change-name>`.
   Do not proceed while it fails.

3. Review your own diff before committing. Read `git diff` and call out, in your
   reply: anything you added that the spec did not ask for, anything specified
   that you did *not* implement, and any assumption you baked in. This is the
   step that catches silent scope drift.

4. Tick the matching task in `openspec/changes/<change-name>/tasks.md`
   (`- [ ]` → `- [x]`). Only if its specified behaviour is fully implemented.

5. Commit:
   ```
   git add -A
   git commit -m "<type>(<change-name>): <description>

   Task: <task text from tasks.md>
   Verify: <evidence file path>
   Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
   ```

6. Append a row to the change's table in `docs/ai-workflow/evidence-log.md`:
   `| <date> | checkpoint | <task> | <commit sha> | <evidence file> |`

## Hard rules

- No checkpoint without a passing verify run in the same session.
- Never `git push`. Pushing is the user's decision.
- If step 3 surfaces scope drift, stop and ask rather than committing it.
