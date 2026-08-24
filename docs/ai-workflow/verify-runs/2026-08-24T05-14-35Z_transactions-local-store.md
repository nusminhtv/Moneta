# Verify run — transactions-local-store

- **When (UTC):** 2026-08-24T05:14:48Z
- **Mode:** full
- **Commit:** 7ea6afe
- **Result:** ❌ FAIL

| Gate | Status | Detail |
| --- | --- | --- |
| format | PASS | Formatted 63 files (0 changed) in 0.10 seconds. |
| analyze | FAIL |    info - test/features/transactions/domain/transaction_test.dart:141:29 - The value of the argument is redundant because it matches the default value. Try removing the argument. - avoid_redundant_argument_values  8 issues found.  |
| architecture | PASS | Running build hooks...Running build hooks...✓ architecture: no layer-boundary violations |
| design-tokens | PASS | Running build hooks...Running build hooks...✓ design tokens: no hard-coded design values outside tokens/ |
| test | PASS | +375: All tests passed! |
| coverage | FAIL | Running build hooks...Running build hooks...coverage: 97.9% total (841/859 lines, 30 files) ✗ coverage below threshold:   lib/features/transactions/domain/transaction_repository.dart: 22.2% (critical minimum 85%)  |
