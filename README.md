# Moneta

Local-first personal finance app for iOS and Android. Flutter + Dart, SQLite,
built design-system-first from Figma.

This repository is also a worked example of an AI-assisted development workflow:
every behavioural change goes through [OpenSpec](https://github.com/Fission-AI/OpenSpec)
(spec → design → tasks → implement) and is gated by `tool/verify.sh` before it
can be archived. See [CLAUDE.md](CLAUDE.md) for the rules and
[docs/ai-workflow/](docs/ai-workflow/) for the artifacts each change leaves behind.

## Getting started

```bash
flutter pub get
bash tool/verify.sh        # the gate: format, analyze, architecture, tokens, tests, coverage
flutter run
```

## Workflow

```bash
npx -y @fission-ai/openspec@latest list      # active changes
```

| Step | Command |
| --- | --- |
| Open a change | `/opsx:propose "<what you want>"` |
| Audit the plan | `spec-auditor` agent |
| Implement | `/opsx:apply` |
| Close a task | `/moneta:checkpoint <change> "<step>"` |
| Verify | `/moneta:verify <change>` |
| Independent review | `change-verifier` agent |
| Archive | `/opsx:archive` |

## Layout

| Path | Contents |
| --- | --- |
| `lib/core` | Pure Dart: `Money`, `Result`, `Clock` |
| `lib/data` | Database, migrations, DAO infrastructure |
| `lib/design_system` | Tokens, theme, atoms/molecules/organisms |
| `lib/features/<f>` | `domain/` · `data/` · `presentation/` |
| `lib/app` | Composition root |
| `tool/` | Verification gate and custom checkers |
| `openspec/` | Change proposals, specs, designs, tasks |
| `docs/adr/` | Architecture decision records |
| `docs/ai-workflow/` | Verify-run evidence and the evidence log |
| `docs/design-system/figma-map.md` | Figma node → widget mapping |
