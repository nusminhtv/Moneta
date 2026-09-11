# Verify run — profile-screens

- **When (UTC):** 2026-09-11T07:14:42Z
- **Mode:** full
- **Commit:** 1f26a26
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| timezone | PASS | Running build hooks...Running build hooks...✓ timezone: Asia/Ho_Chi_Minh (7:00:00.000000), local-time tests can discriminate |
| format | PASS | Formatted 279 files (0 changed) in 0.50 seconds. |
| analyze | PASS | No issues found! |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| hooks | PASS | ✓ hooks: 4 hook(s) parse and no-op cleanly |
| test | PASS | +1753: All tests passed! |
| coverage | FAIL | Running build hooks...Running build hooks...coverage: 92.2% total (5452/5912 lines, 143 files) ✗ coverage below threshold:   lib/data/preferences/preferences_store.dart: 83.3% (critical minimum 85%)  |
