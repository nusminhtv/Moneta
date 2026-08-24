# Verify run — design-system-foundation

- **When (UTC):** 2026-08-24T04:06:27Z
- **Mode:** full
- **Commit:** 9c9c51f
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| format | PASS | Formatted 20 files (0 changed) in 0.03 seconds. |
| analyze | FAIL |    info - test/design_system/tokens/typography_test.dart:169:22 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors  2 issues found.  |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| test | PASS | +81: All tests passed! |
| coverage | PASS | ✓ coverage: thresholds met |
