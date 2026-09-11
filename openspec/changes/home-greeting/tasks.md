## 1. The rule

- [x] 1.1 `Profile.firstName` — the first whitespace-separated word, non-letters
  stripped with the same class `MonetaAvatar.initialsOf` uses so diacritics
  survive, empty when nothing is left. Verified by
  `test/features/settings/profile_store_test.dart` with a table: `Minh Tran` →
  `Minh`; `Trần Văn Minh` → `Trần`; `Đặng Thu Thảo` → `Đặng`; `Minh` → `Minh`;
  `  Minh   Tran  ` and `Minh, Tran` → `Minh`; `👨‍👩‍👧`, `123` and `   ` → empty.
  **Mutation:** take the last word → the `Minh Tran` case must fail.

## 2. Home

- [x] 2.1 Home's greeting comes from `profileProvider`, computed once and passed
  to all three states. Verified by `test/app/home_greeting_test.dart`: a stored
  `Minh Tran` gives `Hi Minh`; no profile gives `Hi there`; a letterless name
  gives `Hi there`; and the three states show the identical string, asserted
  across them rather than in one.
  **Mutation:** drop the empty-first-name fallback → the letterless case must
  fail.
  **Mutation:** compute the greeting separately per state → the three-state
  test must fail.

## 3. Close-out

- [ ] 3.1 Full `tool/verify.sh --change home-greeting` green with its evidence
  file, the mutations recorded in `docs/ai-workflow/evidence-log.md`, and
  `change-verifier` consulted. **Commit with explicit paths** — `docs/training/`
  was swept into a commit by `git add -A -- <paths>` one change ago, and a path
  filter on `-A` is still `-A` under those paths.
