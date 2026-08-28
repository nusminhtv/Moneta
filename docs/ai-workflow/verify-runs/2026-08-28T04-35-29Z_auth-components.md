# Verify run — auth-components

- **When (UTC):** 2026-08-28T04:35:56Z
- **Mode:** full
- **Commit:** 6a5e08a
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| timezone | PASS | Running build hooks...Running build hooks...✓ timezone: Asia/Ho_Chi_Minh (7:00:00.000000), local-time tests can discriminate |
| format | PASS | Formatted 119 files (0 changed) in 0.19 seconds. |
| analyze | FAIL |   error - test/design_system/theme/moneta_theme_test.dart:73:17 - The named parameter 'textDisabled' is required, but there's no corresponding argument. Try adding the required argument. - missing_required_argument  3 issues found.  |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| hooks | PASS | ✓ hooks: 4 hook(s) parse and no-op cleanly |
| test | FAIL | +657 -1: /Users/mike/Documents/Workspace/Moneta-auth/test/data/database_test.dart: version mismatches a failing migration leaves the stored version behind error Bad state: boom during open, closing... +673 -1: Some tests failed.  |
| coverage | PASS | ✓ coverage: thresholds met |
