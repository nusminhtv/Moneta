## 1. The rule

- [x] 1.1 `Profile.firstName` — the first whitespace-separated word **that has
  letters**, its non-letters stripped, empty when the whole name has none.
  Verified by `test/features/settings/profile_store_test.dart` with a table:
  `Minh Tran` → `Minh`; `Trần Văn Minh` → `Trần`; `Đặng Thu Thảo` → `Đặng`;
  `Minh` → `Minh`; `  Minh   Tran  ` and `Minh, Tran` → `Minh`; `123 Minh` and
  `--- Minh` → `Minh`; `李小龙` → `李小龙`; `김수현` → `김수현`; `× Minh` →
  `Minh`; `👨‍👩‍👧`, `123`, `÷` and `   ` → empty.
  **Mutation:** take the last word → the `Minh Tran` case must fail.
  **Mutation:** return the first word without skipping letterless ones →
  `123 Minh` must fail.
  **Mutation:** narrow the letter class back to `[A-Za-zÀ-ỹ]` → the CJK rows
  and the `× Minh` row must fail.

  The class started as `[A-Za-zÀ-ỹ]`, copied from `MonetaAvatar.initialsOf`,
  and `change-verifier` measured what it actually does: `李小龙` and `김수현`
  yield nothing (greeted as a stranger forever), while `×` U+00D7 and `÷`
  U+00F7 sit inside it and would be greeted as names. Now `\p{L}`.
  **`MonetaAvatar.initialsOf` still has the narrow range and the same defect** —
  a design-system component with its own node and tests, out of scope here,
  recorded in `docs/design-system/figma-map.md`.

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
  **Mutation:** fall back on `profile == null` instead of on an empty first
  name → the stored-`123` **widget** case must fail. It was previously pinned
  only on `greetingFor`, which a build free to take its own route past.

  Process note, recorded rather than tidied: 1.1 and 2.1 went into a single
  commit, against CLAUDE.md rule 3 (one checkpoint per task).

## 3. Close-out

- [x] 3.1 Full `tool/verify.sh --change home-greeting` green with its evidence
  file, the mutations recorded in `docs/ai-workflow/evidence-log.md`, and
  `change-verifier` consulted. **Commit with explicit paths** — `docs/training/`
  was swept into a commit by `git add -A -- <paths>` one change ago, and a path
  filter on `-A` is still `-A` under those paths.
