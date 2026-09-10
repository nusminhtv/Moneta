# Verify run — insights-feature

- **When (UTC):** 2026-09-10T14:18:58Z
- **Mode:** full
- **Commit:** f7dda6c
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| timezone | PASS | Running build hooks...Running build hooks...✓ timezone: Asia/Ho_Chi_Minh (7:00:00.000000), local-time tests can discriminate |
| format | PASS | Formatted 254 files (0 changed) in 0.38 seconds. |
| analyze | PASS | No issues found! |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| hooks | PASS | ✓ hooks: 4 hook(s) parse and no-op cleanly |
| test | PASS | +1542: All tests passed! |
| coverage | FAIL | ✗ coverage below threshold:   lib/features/insights/domain/insights_entry.dart: 20.0% (critical minimum 85%)   lib/features/insights/domain/insights_summary.dart: 83.6% (critical minimum 85%)  |
