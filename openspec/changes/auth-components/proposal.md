## Why

Eight of the twelve screens on `📱 01 Onboarding & Auth` are unbuilt. Every one
of them is blocked on design-system components that do not exist yet: a user
cannot be shown a sign-in screen without a text field, or an OTP screen without
an OTP field.

Two of those components — `AppBar` and `IconButton` — are also needed by all six
screens of `📱 02 Home & Dashboard`, which a second agent is building in
parallel. They are the critical path for both flows, so they are built first and
land before the rest of this change.

This change builds the components only. No screen, no storage, no routing —
those follow in `auth-screens`, which is where the question of what
authentication actually *means* in a local-only app gets decided.

## What Changes

Eight components, each with the **full variant set** Figma authors, not only the
variant the first screen needs:

| Component | Node | Variants |
| --- | --- | --- |
| `AppBar` | `39:112` | 4 — LargeTitle, TitleBack, TitleActions, Transparent |
| `IconButton` | `20:114` | 18 — 3 styles × 3 sizes × 2 states |
| `TextField` | `27:44` | 5 — Default, Focused, Filled, Error, Disabled |
| `OtpField` | `70:263` | 3 — Empty, Partial, Complete |
| `Select` | `38:131` | 2 — Placeholder, Value |
| `Checkbox` | `25:229` | 6 — 3 states × enabled/disabled |
| `Divider` | `21:126` | 4 — 2 orientations × 2 tones |
| `Logo` | `70:205` | 2 — mark alone, mark with wordmark |

Each is registered in the gallery in every variant. **The gallery does not
currently enforce that.** Its variant-count checks are one hand-written test per
component, covering the five that predate this change; the generic checks catch a
duplicate or a missing component but never a *shortfall*, so registering
`IconButton` with 2 of its 18 variants passes the whole gate today. An earlier
draft of this proposal claimed the enforcement existed. It does not, so this
change adds it: `GallerySection` gains a required `expectedVariants` read from
Figma, and one generic test asserts every section matches — including sections
added later, by either agent.

**Eight new tokens**, not the one an earlier draft claimed. Reading the nodes
surfaced them:

| Token | Value | Node |
| --- | --- | --- |
| `heading/h3` | Plus Jakarta Sans SemiBold 18/24 | `39:58` AppBar TitleActions |
| `border-default` | white 10% | `27:5` TextField body |
| `border-focus` | `#9A83FB` | `27:18` TextField focused |
| `text-disabled` | `#3D4553` | `27:38` TextField disabled |
| `border-width/hairline` | 1 | `27:5` |
| `border-width/emphasis` | 1.5 | `27:32` TextField error |
| `border-width/focus` | 2 | `27:18` |
| `gradient/mark` | violet-500 → mint-500 at 128.48° | `70:206` Logo mark |

Each needs its row in `docs/design-system/figma-tokens.md`, because
`test/design_system/tokens/token_provenance_test.dart` fails a token with no
recorded source.

The border widths matter beyond bookkeeping: the design-token gate does **not**
see a raw `BorderSide(width: 2)` — it matches only `Color(0x`, `Colors.*`,
`TextStyle(`, `EdgeInsets.*` with a literal, and `BorderRadius.circular(<digit>)`.
So nothing would have caught these being hardcoded. The repo's only
`// design-token-ignore` exists because a 2px stroke had no token to point at;
this change removes that excuse rather than adding a second annotation.

**One component deliberately not built.** Figma draws a `StatusBar` (`39:2`)
inside all four `AppBar` variants, and the Screen Index lists it as a component
used by four auth screens. It is not implemented: on a real device the OS draws
the status bar, and a widget that paints a fake 9:41 and three battery bars over
the real one is a bug, not fidelity. The 59px it occupies is read from
`MediaQuery` padding via `SafeArea` instead. Recorded as a deviation with its
reasoning, not skipped silently.

## Capabilities

### New Capabilities

None. These are components in an existing capability.

### Modified Capabilities

- `design-system/components`: adds `AppBar`, `IconButton`, `TextField`,
  `OtpField`, `Select`, `Checkbox`, `Divider` and `Logo` as requirements, each
  naming its Figma node and the variant set that must be covered.
- `design-system/tokens`: **three requirements change.** `Colour tokens` stops
  enumerating the surface/text/border members in a scenario that reads as the
  complete set and is not — the same defect as the typography requirement that
  once said "exactly the eight". Its gradient scenario currently says "no other
  gradient is defined anywhere in the application"; the `Logo` mark is a second
  one, which Figma's own note on `70:205` calls "the second and last hardcoded
  gradient in this system", so that scenario is corrected rather than quietly
  violated. And a new requirement states that disabled and focus have their own
  tokens rather than being approximated with opacity.

## Impact

- **Modules:** `lib/design_system` only — `tokens/`, `atoms/`, `molecules/`,
  `organisms/` — plus `lib/app/gallery/` to register the variants. This change
  touches **no** feature, no `lib/data`, and no `lib/core`.
- **No dependency and no asset.** `70:205` was read before this was written:
  the mark is a 48px rounded container with the brand gradient, the `glow/brand`
  effect and the existing `icon/zap` glyph at 26px, and the wordmark is "Moneta"
  in `heading/h1`. All of it is expressible from the token layer and the icon
  set, so `pubspec.yaml` is untouched. Had it needed an SVG, that would have been
  a build-config change and this bullet would have been wrong.
- **No schema migration.** The auth flow needs one for a hashed PIN, and it
  belongs to `auth-screens`, not here. `lib/data/database/**` is untouched, which
  also matters because the parallel agent is forbidden from touching it and a
  second writer would collide.
- **Parallel work:** `AppBar` and `IconButton` are tasks 1 and 2 so the
  home-dashboard agent can rebase on them early. They are blocked on all six of
  their screens until these land. See
  `docs/ai-workflow/parallel-brief-home-dashboard.md`.
- **Accessibility:** Figma's own notes state that `IconButton` Sm is 36×36 and
  "must sit inside a >=44px row" while Md meets the target alone, and that the
  `TextField` error state "colours the border and the helper text together —
  never colour alone". Both are carried into the spec as testable criteria rather
  than left as Figma comments.
- **Coverage:** `lib/design_system` is **not** in `tool/coverage_critical.txt`,
  so the 85% floor does not apply to any file this change adds — only the 70%
  project total. Stated because an earlier draft implied the stricter gate
  applied here.
- **Shared-file timing:** adding a required field to `GallerySection` edits
  `lib/app/gallery/gallery_catalog.dart`, which the parallel agent also touches.
  It is the first task precisely so it lands while their section list is still
  empty.

## Non-goals

- **No screens.** 01.05–01.12 are `auth-screens`.
- **No authentication behaviour.** No `AuthService`, no PIN storage, no session.
  The design assumes email/password, OTP and social sign-in against a backend
  this app does not have; that conflict is decided in `auth-screens`, and
  deciding it is not a prerequisite for drawing a text field.
- **No `StatusBar` widget**, for the reason above.
- **No reconciliation of `TransactionRow`** with its two missing variants, and no
  work on the other 30 unimplemented components in the library. Both are recorded
  in `docs/design-system/figma-map.md` as outstanding.
- **No Light mode.** Still never investigated; unchanged by this work.
