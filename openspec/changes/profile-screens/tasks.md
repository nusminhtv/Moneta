Ordered so the gate is green after every task. The two enablers come first
because every screen needs one of them; the screens after them are independent.

Every task carries a **mutation**, run and recorded in
`docs/ai-workflow/evidence-log.md` in that task. Three traps are pre-named from
this session's four repeats: **no expected value may be derived from the
implementation's own constant**, a colour must be asserted on the object that
carries it *and* against the alternative it must differ from, and a bound must
be two-sided.

## 1. The enablers

- [x] 1.1 `PreferencesStore.readString`/`writeString` — same table, no
  migration. Verified by `test/data/preferences_store_test.dart`: round-trip;
  absent is `Ok(null)` while stored-empty is `Ok('')`; a second write replaces
  and leaves one row; a value carrying a quote, a newline, `👨‍👩‍👧` and `Trần`
  reads back identical; a 10,000-character value reads back with length exactly
  10,000; a throwing database gives `AppFailure(kind: storage)` with no
  exception escaping; a `writeBool` key read by `readString` gives the literal
  `'true'`, and a string key read by `readBool` still fails.
  **Mutation:** return `Ok('')` for a missing row → the absence case must fail.
- [x] 1.2 Move the address rule to `lib/core/email.dart`;
  `Credentials.isPlausibleEmail` delegates and keeps its API. Verified by
  `test/core/email_test.dart` (accepts `user+tag@sub.domain.co.uk`; rejects
  `minh.tran`, `@example.com`, `a@b`, `a b@c.com`, `''`) **and by
  `test/features/auth/credentials_test.dart` passing unmodified** — which is
  what makes this a move rather than a rewrite.
  **Mutation:** accept a domain with no dot → both files must fail, which also
  proves the delegation is real and not a copy.

## 2. 08.11 Help & FAQ

- [x] 2.1 `FaqEntry`, the five authored entries, and search with Vietnamese
  diacritic folding — pure, in `features/settings/domain`. Verified by
  `test/features/settings/faq_search_test.dart`: `du lieu` finds `dữ liệu`;
  `DU LIEU` and `Dữ Liệu` give the same result; a query matching neither
  question nor answer returns empty; the folding table is exercised for each
  vowel family it claims to cover.
  **Mutation:** drop the folding table → the `du lieu` case must fail.
- [x] 2.2 `08.11` (`102:1189`) — `SearchField`, five accordion items with the
  first expanded, a support `ListRow`, and `EmptyState` with an action when
  nothing matches. Verified by `test/features/settings/help_screen_test.dart`:
  **each** item's chevron asserted against that item's own expanded state;
  expanding a second leaves both open; `xyzzy` shows the empty state with the
  query still in the field; clearing restores one-expanded-four-collapsed.
  **Mutation:** point every chevron down → the per-item chevron test must fail
  (a test asserting only "one chevron-up exists" would survive it, which is why
  it is per item).
- [x] 2.3 Route it: `SettingsRoutes`, `router.dart`, `08.03`'s Help row loses
  `available: false`, and `08.01`'s Help row gets its chevron and destination.
  Verified by `test/app/settings_route_test.dart` navigating from both entry
  points and back, and by asserting **no row on either screen still reads "Not
  built yet" while having a destination**.
  **Mutation:** leave `08.03`'s row unavailable → the navigation test must fail.

## 3. 08.02 Edit profile

- [x] 3.1 `Profile` in `domain` and `ProfileStore` in
  **`features/settings/data/`** over `PreferencesStore`, control-scoped.
  Verified by `test/features/settings/profile_store_test.dart`: absent on first
  run; save and read back all three fields; an empty or whitespace name refused
  with `AppFailure(kind: validation)`; an empty email accepted; an invalid email
  refused with the rule's message.
  **Mutation:** accept a whitespace-only name → the validation case must fail.
- [x] 3.2 `08.02` (`100:276`) — `Avatar`, name and email `TextField`s, currency
  `Select`, sticky primary action, app-bar check invoking the same callback.
  Verified by `test/features/settings/edit_profile_screen_test.dart`: exactly
  two `TextField`s and one `Select`; both controls invoke one callback; an
  invalid email puts that field in `MonetaTextFieldState.error` with the rule's
  message; a failed save keeps what was typed; a 200-character name has
  `maxLines: 1` and `TextOverflow.ellipsis` asserted **on the widget**, not by
  measuring a width.
  **Mutation:** make the app-bar action a no-op → the both-controls test must
  fail.
- [x] 3.3 `08.01` and `08.03` read the store: name, email, avatar initials, and
  `08.03`'s `Main currency` row. `08.01`'s Edit button opens `08.02`; `08.03`'s
  Edit profile row loses `available: false`. Verified by
  `test/app/settings_route_test.dart`: saving `Trần Văn Minh` makes `08.01` show
  it with initials `TM`; the currency row shows the stored code; **with demo
  mode on**, the stored name is still shown.
  **Mutation:** read the profile from `activeDatabaseProvider` instead of the
  control database → the demo-mode-on case must fail. (Asserted with demo mode
  **on**, because once it is off the two are the same object and the mutation
  would survive.)

## 4. 08.10 Premium paywall

- [ ] 4.1 `PremiumPlan` in `domain` with `Money` prices and a **derived**
  saving. Verified by `test/features/settings/premium_plan_test.dart`: the
  authored prices give exactly 31; the intermediate value is 30.79 so `round`
  and `floor` differ and `round` is the one asserted; changing the yearly price
  to 600,000 changes the claim to 15; a zero monthly price gives `null`; a
  yearly price above twelve monthly payments gives `null`, not a negative.
  **Mutation:** use `floor` → the 31 case must fail (and would pass on a naive
  `closeTo`, which is why it is exact).
- [ ] 4.2 `08.10` (`102:1044`) — three plan cards, `Badge` on the middle,
  `SectionHeader`, comparison table, sticky action and fine print. Verified by
  `test/features/settings/premium_screen_test.dart`: yearly preselected;
  after tapping each card exactly one reads selected; a present feature's glyph
  is `income` and an absent one's `textDisabled`, asserted **to differ** and
  neither to be `expense`; activating the action reports purchases unavailable
  and stores nothing.
  **Mutation:** colour the absent features `expense` → the glyph test must fail.
- [ ] 4.3 Route it from `08.01`'s Premium row, which has no `onTap` today.
  Verified by `test/app/settings_route_test.dart`: the row navigates, and the
  screen can be closed by its app-bar action.
  **Mutation:** drop the close action → the closing test must fail.

## 5. 08.08 Manage categories

- [ ] 5.1 `CategoryUsage` in `domain`, the month window from an injected
  `Clock`, and the pure function from entries to a sorted list. Verified by
  `test/features/settings/category_usage_test.dart` with **literal** expected
  counts and totals; sorted by total descending with ties in enum order; a
  category with no transactions listed at zero; the
  **`2026-08-31T18:00Z` case included** because it is `2026-09-01T01:00` local;
  an empty ledger; a −20,000 refund; `(1 << 61) - 1`; two currencies in one
  category throwing `ArgumentError`.
  **Mutation:** compute the month boundary in UTC → the `18:00Z` case must fail.
  **Mutation:** drop zero-usage categories → the absence case must fail.
- [ ] 5.2 `08.08` (`101:978`) — two `Type=Filter` chips over
  `TransactionDirection`, one row per category with `CategoryIcon`, count and
  total. **No tap callback, no drag handle.** Verified by
  `test/features/settings/manage_categories_screen_test.dart`: the chips are
  never both selected and never both unselected; the rows change with the
  filter; the **semantics tree** under the list exposes no button and no tap
  action; the filter row is **44** tall, asserted as that literal.
  **Mutation:** let both chips read selected → the invariant must fail.
  **Mutation:** give each row an `onTap` → the semantics assertion must fail
  (a source scan for `onTap` would also pass a `GestureDetector`, which is why
  it is the semantics tree).
- [ ] 5.3 Wire real usage in `lib/app/` from the transaction repository and
  route it from `08.03`. Verified by `test/app/settings_route_test.dart` against
  a seeded ledger: the counts on screen equal the transactions inserted, and a
  transaction outside the month is excluded.
  **Mutation:** pass every transaction rather than the window's → the exclusion
  case must fail.

## 6. Close-out

- [ ] 6.1 `docs/design-system/figma-map.md`: page 08's table to **7 of 11**, and
  one row each for what ships less than the file draws — `08.08` without its
  editing half, its row taps or its drag handle, and its 44px filter row against
  the authored 34; `08.10`'s unavailable purchase. Plus the three blockers found
  for `08.04`/`08.05` — `ListRow` has no `enabled`, `MonetaOtpField` shows
  characters in the clear, and "erase all data" in real mode would delete the
  `settings` table — and what `08.07`/`08.09` still need, in their own words.
  Verified by `rg` for each new row's distinctive text.
- [ ] 6.2 Full `tool/verify.sh --change profile-screens` green with its evidence
  file, and `evidence-log.md` carrying every mutation from tasks 1–5 with its
  outcome. Verified by the gate's summary and by counting the log's entries for
  this change.
- [ ] 6.3 `change-verifier`, and its findings **fixed or recorded**. Verified by
  its verdict. The last four times it ran in this session it was right, and
  twice it found a test that could not fail in the work that had just fixed one.
