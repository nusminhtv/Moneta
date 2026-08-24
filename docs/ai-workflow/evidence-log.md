# Evidence log

Append-only record of how each change moved through the workflow. Written by
`/moneta:checkpoint` and `/moneta:verify`; read by `/moneta:evidence`.

Columns: date (UTC) · kind · what · reference · evidence file

## bootstrap — repository and workflow foundation

| Date | Kind | What | Ref | Evidence |
| --- | --- | --- | --- | --- |
| 2026-08-24 | setup | Flutter project, strict lints, core money/result/clock + 31 tests | — | `verify-runs/2026-08-24T03-38-35Z_bootstrap.md` |
| 2026-08-24 | setup | OpenSpec spec-driven schema initialised, project context + artifact rules | `openspec/config.yaml` | — |
| 2026-08-24 | setup | Verification gate: format, analyze, architecture, design-tokens, test, coverage | `tool/verify.sh` | — |
| 2026-08-24 | setup | Hooks: post-edit analyze, session-start state, stop-verify guard | `.claude/hooks/` | — |
| 2026-08-24 | setup | 6 reusable commands, 3 review agents | `.claude/commands/moneta/`, `.claude/agents/` | — |

## design-system-foundation

| Date | Kind | What | Ref | Evidence |
| --- | --- | --- | --- | --- |
| 2026-08-24 | plan | 4 OpenSpec artifacts + ADR 0002 (icon delivery); `validate --strict` clean | `openspec/changes/design-system-foundation/` | — |
| 2026-08-24 | checkpoint | 1.1 Figma token harvest; spec corrected 6→8 text styles mid-task | `docs/design-system/figma-tokens.md` | `verify-runs/2026-08-24T04-00-54Z_design-system-foundation.md` |
| 2026-08-24 | checkpoint | 1.2 colour tokens + 20 transcription tests | 46d866a | see below |
| 2026-08-24 | checkpoint | 1.3 bundled fonts + 8-style type scale, 15 tests | b088254 | see below |
| 2026-08-24 | checkpoint | 1.4 spacing / radii / elevation / motion, 15 tests | 18b8520 | see below |
| 2026-08-24 | gate-failure | The three commits above cited a FAILING verify run (analyze, 2 lint findings). Not amended — corrected in a follow-up commit so the mistake stays visible. | — | `verify-runs/2026-08-24T04-06-16Z_design-system-foundation.md` (FAIL) |
| 2026-08-24 | verify | Token layer green: 81 tests, coverage thresholds met | — | `verify-runs/2026-08-24T04-07-22Z_design-system-foundation.md` |

### Workflow finding: the PostToolUse hook has a blind spot

The hook runs `dart analyze` on the file path reported by Edit/Write. Files
created with a shell heredoc never pass through those tools, so the hook does not
fire and lint findings survive to the gate. Two consequences, both real:

- The gate is not redundant with the hook — it caught what the hook structurally
  could not.
- `tool/verify.sh --fast` should be run before any checkpoint even when the hook
  has been quiet, because silence from the hook is not evidence.
