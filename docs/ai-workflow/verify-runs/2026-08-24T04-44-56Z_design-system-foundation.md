# Verify run — design-system-foundation

- **When (UTC):** 2026-08-24T04:45:08Z
- **Mode:** full
- **Commit:** 9442203
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| format | PASS | Formatted 44 files (0 changed) in 0.07 seconds. |
| analyze | FAIL |   error - test/design_system/organisms/bottom_nav_test.dart:149:17 - Undefined name 'Tristate'. Try correcting the name to one that is defined, or defining the name. - undefined_identifier  2 issues found.  |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| test | FAIL |                   ^^^^^^^^   . +224 -1: Some tests failed.  |
| coverage | PASS | ✓ coverage: thresholds met |
