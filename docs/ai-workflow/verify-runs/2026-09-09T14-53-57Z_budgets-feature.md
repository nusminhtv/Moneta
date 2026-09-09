# Verify run — budgets-feature

- **When (UTC):** 2026-09-09T14:54:36Z
- **Mode:** full
- **Commit:** 4fb726b
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| timezone | PASS | Running build hooks...Running build hooks...✓ timezone: Asia/Ho_Chi_Minh (7:00:00.000000), local-time tests can discriminate |
| format | PASS | Formatted 211 files (0 changed) in 0.38 seconds. |
| analyze | FAIL | warning - lib/features/budgets/presentation/budgets_screen.dart:12:8 - Unused import: 'package:moneta/features/budgets/domain/budget_period.dart'. Try removing the import directive. - unused_import  2 issues found.  |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| hooks | PASS | ✓ hooks: 4 hook(s) parse and no-op cleanly |
| test | PASS | +1241: All tests passed! |
| coverage | PASS | ✓ coverage: thresholds met |
