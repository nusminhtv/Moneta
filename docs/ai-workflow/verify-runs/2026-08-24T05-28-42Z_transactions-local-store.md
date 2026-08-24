# Verify run — transactions-local-store

- **When (UTC):** 2026-08-24T05:28:56Z
- **Mode:** full
- **Commit:** d56455a
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| format | PASS | Formatted 75 files (0 changed) in 0.11 seconds. |
| analyze | FAIL |    info - test/features/transactions/presentation/list_controller_test.dart:7:8 - The import of 'package:moneta/core/transaction_direction.dart' is unnecessary because all of the used elements are also provided by the import of 'package:moneta/features/transactions/domain/transaction.dart'. Try removing the import directive. - unnecessary_import  2 issues found.  |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| test | PASS | +438: All tests passed! |
| coverage | PASS | ✓ coverage: thresholds met |
