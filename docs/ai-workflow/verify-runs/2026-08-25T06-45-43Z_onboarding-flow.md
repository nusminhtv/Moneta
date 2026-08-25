# Verify run — onboarding-flow

- **When (UTC):** 2026-08-25T06:46:07Z
- **Mode:** full
- **Commit:** 973a0d0
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| timezone | PASS | Running build hooks...Running build hooks...✓ timezone: Asia/Ho_Chi_Minh (7:00:00.000000), local-time tests can discriminate |
| format | PASS | Formatted 100 files (0 changed) in 0.16 seconds. |
| analyze | PASS | No issues found! |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| hooks | PASS | ✓ hooks: 4 hook(s) parse and no-op cleanly |
| test | PASS | +585: All tests passed! |
| coverage | FAIL | Running build hooks...Running build hooks...coverage: 93.7% total (1476/1575 lines, 49 files) ✗ coverage below threshold:   lib/data/app_providers.dart: 70.0% (critical minimum 85%)  |
