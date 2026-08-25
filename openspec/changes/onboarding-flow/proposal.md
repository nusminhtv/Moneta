## Why

Moneta opens on a placeholder. Figma page `5:14` has twelve finished screens for
first-run — splash, a three-slide carousel, auth, and setup — each with an
annotation frame specifying purpose, components, states and data. None of it is
built.

This change builds the **first-run introduction**: splash and the three
onboarding slides. It stops before auth, which is a larger question (the design
assumes accounts; the app is local-first) and is its own change.

User-visible outcome: launching the app for the first time shows the brand splash,
then three swipeable slides explaining what Moneta does, with Skip and Next; after
the last slide the user lands in the app and never sees it again.

## What Changes

- **Correct spacing tokens.** Figma's `space/*` collection (`107:75`) is added
  with Figma's names and values. The existing invented scale stays for now so
  nothing breaks; new work uses only the correct set. Migrating the old widgets is
  a follow-up.
- **New tokens** read from the design: `border-strong` (18% white),
  `text-secondary` (`#9AA3B4`), and the `body/lg` type style (Inter 400 16/24).
- **New atom `MonetaButton`** from Figma `13:2` — 5 styles × 3 sizes × 3 states.
  The design calls it "the highest-reach component in this system".
- **New molecule `MonetaPaginationDots`** from `70:223`.
- **New feature `onboarding`**: splash, three slides, and a "seen" flag persisted
  so first-run happens once.
- **App wiring**: the router decides between onboarding and the app shell.

## Capabilities

### New Capabilities
- `onboarding`: what first-run shows, how it advances, and how it is remembered.
- `storage/preferences`: a `settings` table (migration v2) and typed access to it.
  Not listed here originally — the change said the flag "uses the existing
  preferences work, which does not exist yet", which is a new capability
  described as an existing one. Caught during the pre-archive review, when three
  of the four capabilities this change touches turned out to have no spec delta.

### Modified Capabilities
- `design-system/components`: adds Button (45 variants), PaginationDots and
  OnboardingIllustration; corrects the `Component gallery` requirement so its
  coverage check reads the source tree instead of a hand-maintained list of six
  names; and corrects the `Transaction row` requirement, which asserted that
  Figma contains no transaction row and no screen frames. Both halves are false.
- `design-system/tokens`: adds `border-strong`, `text-secondary`, `body/lg` and
  Figma's twelve `space/*` values; removes the count from the typography
  requirement, which said "exactly the eight" styles while nine ship — the guard
  test having been re-pinned 8→9 to make it pass, undisclosed.

## Non-goals

- **No auth.** Screens 01.05–01.09 are out. The design assumes email/password
  accounts, OTP and social sign-in, which the app has no backend for. That
  conflict is decided in its own change.
- **No setup screens.** 01.10 currency, 01.11 Face ID, 01.12 link account.
- **No migration of the invented spacing scale.** Added alongside, not swapped.
- **No animation** beyond the page transition Flutter gives a PageView.

## Impact

- **Modules:** `lib/design_system` (tokens, one atom, one molecule),
  `lib/features/onboarding` (new), `lib/data` (the seen-flag uses the existing
  preferences work — which does not exist yet, so this change adds a minimal
  key/value store), `lib/app` (routing).
- **Assets:** none. Six decorative SVGs were planned; reading them showed every
  value is already a token, so the illustration is drawn natively — which also
  keeps it inside `check_design_tokens.dart`, a gate that cannot see into an SVG.
  See task 4.1.
- **Figma nodes:** `71:2`, `71:37`, `71:103`, `71:162` (screens); `13:2` (Button);
  `70:223` (PaginationDots); `107:75` (spacing).
