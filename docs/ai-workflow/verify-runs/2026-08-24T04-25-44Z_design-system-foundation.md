# Verify run — design-system-foundation

- **When (UTC):** 2026-08-24T04:25:56Z
- **Mode:** full
- **Commit:** 7380aaf
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| format | PASS | Formatted 30 files (0 changed) in 0.06 seconds. |
| analyze | FAIL |    info - test/design_system/atoms/moneta_icon_test.dart:142:9 - Unnecessary use of a raw string. Try using a normal string. - unnecessary_raw_strings  1 issue found.  |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| test | PASS | +127: All tests passed! |
| coverage | PASS | ✓ coverage: thresholds met |
