# Verify run — transactions-local-store

- **When (UTC):** 2026-08-24T05:33:36Z
- **Mode:** full
- **Commit:** 4b15ace
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| format | PASS | Formatted 79 files (0 changed) in 0.12 seconds. |
| analyze | FAIL |    info - test/features/transactions/presentation/add_transaction_test.dart:82:10 - Unnecessary escape of '''. Try changing the outer quotes to '"'. - avoid_escaping_inner_quotes  1 issue found.  |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| test | PASS | +471: All tests passed! |
| coverage | PASS | ✓ coverage: thresholds met |
