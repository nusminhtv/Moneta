## Why

Home's app bar says **`Hi there`** to everyone, from a `const String` in
`home_route_screen.dart`. `profile-screens` gave the app a name the user chose
— `08.01`, `08.02` and `08.03` all read it — and Home is the one screen that
still greets a stranger.

The user-visible outcome: Home says `Hi Minh`.

## What Changes

- **The greeting is the profile's first name.** `Hi {first name}` when a
  profile is stored, and the existing `Hi there` when one is not — first run,
  or a name that yields no letters.
- **First name means the first word.** Decided by the user: `Minh Tran` →
  `Hi Minh`. The alternative was the last word, which is right for a
  Vietnamese name written surname-first (`Trần Văn Minh` → `Minh`) and wrong
  for the name this app's own demo data uses. The rule is written down because
  a string cannot say which order it is in, and either choice greets somebody
  by their surname.
- **`Profile.firstName`** carries the rule, beside `Profile` rather than in
  Home, because it is a fact about a profile and Home is one of its readers.

## Non-goals

- **No name-order detection.** There is no reliable way to tell `Minh Tran`
  from `Trần Văn Minh` apart from the string, and guessing per-name would make
  the greeting inconsistent in a way nobody could predict.
- **No greeting by time of day.** `52:3` authors one greeting; "Good morning"
  is a different string and is not in the file.
- **No change to `08.01`'s copy.** It shows the full name, which is what an
  identity block is for.

## Capabilities

### Modified Capabilities

- `profile`: what a profile's first name is, and what Home greets when there is
  no profile to greet.

## Impact

- **`lib/features/settings/domain/profile.dart`** — `firstName`.
- **`lib/app/home_route_screen.dart`** — the greeting is derived instead of
  constant, and computed **once** so all three Home states show the same one,
  which is what the existing `const` was there to guarantee.
- **`test/app/home_providers_test.dart`** or a sibling, and
  `test/features/settings/profile_store_test.dart`.
- No `design_system`, no `core`, no schema.
