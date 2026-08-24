# Verify run — design-system-foundation

- **When (UTC):** 2026-08-24T04:44:06Z
- **Mode:** full
- **Commit:** 9442203
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| format | PASS | Formatted 44 files (0 changed) in 0.08 seconds. |
| analyze | FAIL |    info - test/design_system/organisms/bottom_nav_test.dart:135:19 - 'hasFlag' is deprecated and shouldn't be used. Use flagsCollection instead. This feature was deprecated after v3.32.0-0.0.pre. Try replacing the use of the deprecated member with the replacement. - deprecated_member_use  1 issue found.  |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| test | PASS | +243: All tests passed! |
| coverage | PASS | ✓ coverage: thresholds met |
