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
