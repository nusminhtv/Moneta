## Context

See `proposal.md` — Why.

- `lib/app/home_route_screen.dart:25` holds `const String _greeting = 'Hi
  there'`, passed to all three Home states (`:79`, `:86`, `:91`). Its own
  comment says why it is one constant: *"annotation `52:630` requires the bar to
  be identical while loading and once loaded. Two literals would be free to
  drift apart."*
- `profileProvider` (`lib/app/profile_providers.dart`) already exists and is
  what `08.01` and `08.03` read.
- `features/home` may not import `features/settings`
  (`tool/check_architecture.dart`), and does not need to: `HomeScreen` takes
  `greeting` as a `String` and `lib/app` supplies it — the pattern this project
  already uses everywhere.
- `MonetaAvatar.initialsOf` already strips non-letters with
  `RegExp('[^A-Za-zÀ-ỹ]')`, which keeps Vietnamese diacritics. The first-name
  rule uses the same class so `Đặng` survives.

## Decisions

### D1 — The first word, and the cost is written down

**Chosen:** the first whitespace-separated word.

The user chose it. What makes it a decision worth recording rather than a
preference: **no rule is right for both name orders**, and the two names in this
project disagree.

| Name | First word | Last word |
| --- | --- | --- |
| `Minh Tran` (the demo data) | **Minh** ✓ | Tran ✗ surname |
| `Trần Văn Minh` (Vietnamese order) | Trần ✗ surname | **Minh** ✓ |

Alternatives:

- *The last word.* Right for a Vietnamese name written surname-first, and wrong
  for `Minh Tran`, which is what this app's own demo data and every seeded
  profile use — so the demo would greet its user by surname.
- *Detect the order.* Rejected: it cannot be done from the string, and a
  heuristic that is right most of the time makes the greeting unpredictable,
  which is worse than being consistently one thing.
- *Greet the whole name.* Never wrong, and not a greeting.

### D2 — `Profile.firstName`, not a helper in Home

**Chosen:** a getter on `Profile`.

It is a fact about a profile, and Home is one reader of it — `08.01`'s avatar
already derives initials from the same name through a different rule. A helper
in `lib/app` would put a name rule where only one caller could find it.

### D3 — The greeting is computed once, which is why the constant existed

**Chosen:** one local, passed to all three states, exactly as the `const` was.

The risk of deriving it is that three `ref.watch` calls could read three
different values. Computing it once preserves the invariant the constant was
protecting, and the test asserts it across the three states rather than in one.

One behaviour does change: while `profileProvider` resolves, Home shows
`Hi there` and then the name. That is a single frame on a local read, and it is
the same thing `08.01` does with `Add your name`. Recorded rather than hidden
behind a spinner Home does not have.

## Risks / Trade-offs

- **The greeting is wrong for a surname-first name** → stated in the spec as
  the cost of D1, not discovered by a user.
- **A name of emoji or digits would render `Hi `** → the fallback is on the
  *first name being empty*, not on the profile being absent, so both routes
  reach `Hi there`.

## Verification

| Requirement | Test file | What catches a regression |
| --- | --- | --- |
| `firstName` is the first word | `test/features/settings/profile_store_test.dart` | a table including `Minh Tran`, `Trần Văn Minh`, `Đặng Thu Thảo`, punctuation, emoji |
| Home greets the name | `test/app/home_greeting_test.dart` | the bar's text with a profile overridden |
| Falls back with no name | same | no profile, and a letterless name |
| All three states agree | same | asserted across loading, loaded and error |

Mutations: use the last word (the `Minh Tran` case must fail); drop the
empty-first-name fallback (the letterless case must fail); read the profile
once per state instead of once (the three-state test must fail).

## Migration Plan

None.

## Open Questions

None.
