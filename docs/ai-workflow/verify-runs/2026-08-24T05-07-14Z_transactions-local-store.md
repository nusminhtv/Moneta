# Verify run — transactions-local-store

- **When (UTC):** 2026-08-24T05:07:28Z
- **Mode:** full
- **Commit:** 60d8a62
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| format | PASS | Formatted 54 files (0 changed) in 0.10 seconds. |
| analyze | FAIL |    info - test/data/migrations_test.dart:97:34 - Don't cast a nullable value to a non-nullable type. Try adding a not-null assertion ('!') to make the type non-nullable. - cast_nullable_to_non_nullable  2 issues found.  |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| test | PASS | +286: All tests passed! |
| coverage | PASS | ✓ coverage: thresholds met |
