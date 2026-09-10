# Verify run — profile-feature

- **When (UTC):** 2026-09-10T15:31:46Z
- **Mode:** full
- **Commit:** d463f4f
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| timezone | PASS | Running build hooks...Running build hooks...✓ timezone: Asia/Ho_Chi_Minh (7:00:00.000000), local-time tests can discriminate |
| format | PASS | Formatted 268 files (0 changed) in 0.52 seconds. |
| analyze | PASS | No issues found! |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| hooks | PASS | ✓ hooks: 4 hook(s) parse and no-op cleanly |
| test | FAIL | +1597 -2: /Users/mike/Documents/Workspace/Moneta/test/data/database_test.dart: version mismatches a failing migration leaves the stored version behind error Bad state: boom during open, closing... +1634 -2: Some tests failed.  |
| coverage | PASS | ✓ coverage: thresholds met |
