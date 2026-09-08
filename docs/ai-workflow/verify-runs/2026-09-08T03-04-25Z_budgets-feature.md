# Verify run — budgets-feature

- **When (UTC):** 2026-09-08T03:04:58Z
- **Mode:** full
- **Commit:** 9c3105a
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| timezone | PASS | Running build hooks...Running build hooks...✓ timezone: Asia/Ho_Chi_Minh (7:00:00.000000), local-time tests can discriminate |
| format | PASS | Formatted 177 files (0 changed) in 0.28 seconds. |
| analyze | PASS | No issues found! |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| hooks | PASS | ✓ hooks: 4 hook(s) parse and no-op cleanly |
| test | PASS | +951: All tests passed! |
| coverage | FAIL |   lib/features/budgets/domain/budget.dart: 65.6% (critical minimum 85%)   lib/features/budgets/domain/budget_progress.dart: 84.9% (critical minimum 85%)   lib/features/budgets/domain/spend_entry.dart: 33.3% (critical minimum 85%)  |
