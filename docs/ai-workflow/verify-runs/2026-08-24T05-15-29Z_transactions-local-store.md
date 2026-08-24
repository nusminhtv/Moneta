# Verify run — transactions-local-store

- **When (UTC):** 2026-08-24T05:15:42Z
- **Mode:** full
- **Commit:** 7ea6afe
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| format | PASS | Formatted 64 files (0 changed) in 0.10 seconds. |
| analyze | FAIL | warning - test/features/transactions/data/transaction_repository_test.dart:10:8 - Unused import: 'package:moneta/features/transactions/domain/transaction_repository.dart'. Try removing the import directive. - unused_import  1 issue found.  |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| test | PASS | +382: All tests passed! |
| coverage | PASS | ✓ coverage: thresholds met |
