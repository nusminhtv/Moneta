# Verify run — design-system-foundation

- **When (UTC):** 2026-08-24T04:29:47Z
- **Mode:** full
- **Commit:** c42b302
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| format | PASS | Formatted 36 files (0 changed) in 0.06 seconds. |
| analyze | FAIL |    info - test/design_system/molecules/progress_bar_test.dart:92:40 - The value of the argument is redundant because it matches the default value. Try removing the argument. - avoid_redundant_argument_values  1 issue found.  |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | FAIL |  Use MonetaTokens / Theme.of(context).extension<MonetaTheme>() instead. If a raw value is genuinely required, append "// design-token-ignore" with a reason on the same line.  |
| test | PASS | +166: All tests passed! |
| coverage | PASS | ✓ coverage: thresholds met |
