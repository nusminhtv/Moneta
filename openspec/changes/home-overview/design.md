## Context

`home-overview` previously decided a cross-feature, data-backed Home overview
because the project believed Figma had no Home screens. That premise is false.
The Screen Index at node `5:24` lists six concrete screens for `📱 02 Home &
Dashboard`, and the parallel brief assigns this branch the Home and
notifications implementation.

The foundation commit `96dbff100846b721f9f7b006f88b1b329b54b2e1` split the
gallery catalog and gallery describer so this branch owns only:

- `lib/app/gallery/gallery_catalog_home.dart`
- `test/app/gallery_describe_home.dart`

The auth branch owns `AppBar` and `IconButton`. Home screens should be built so
they can consume those components once they land, but this branch does not edit
auth-owned files.

## Decisions

### D1 -- Figma node ids are part of the contract

Every screen and component implemented here names its Figma node in the code,
tests or spec:

| Artifact | Node |
| --- | --- |
| Home -- default | `52:2` |
| Home -- empty | `52:372` |
| Home -- loading | `52:547` |
| Home -- over-budget alert | `57:414` |
| Notifications -- list | `57:622` |
| Notifications -- empty | `57:840` |
| DateGroupHeader | `29:71` |
| EmptyState | `35:166` |
| Skeleton | `38:139` |
| ListRow | `35:113` |
| SectionHeader | `55:107` |
| Banner | `42:329` |

Each screen's sibling annotation frame must be read before final implementation.
This session has no callable Figma tool and the repository has not captured those
annotations. Until that access exists, any screen copy, fixture data, spacing or
accessibility detail not already present in `docs/design-system/figma-map.md` is
a placeholder decision and must be recorded as such.

### D2 -- Components land before screens

`ListRow` and `SectionHeader` unblock auth screens 01.10 and 01.12, so they are
implemented and committed before feature screens. The other home-owned component
sets follow before screen composition:

1. `ListRow` (`35:113`) and `SectionHeader` (`55:107`).
2. `DateGroupHeader`, `EmptyState`, `Skeleton` and `Banner`.
3. Home and notification screens.

The gallery is the integration surface for all component variants. A component
is not done until its full variant set is in `gallery_catalog_home.dart` and
`gallery_describe_home.dart`.

### D3 -- Home is fixture/state driven for this change

The six Figma screens are states, not a database contract. This change does not
add persistence, migrations or preference storage. If notification read-state or
home data persistence becomes necessary, work stops for a storage design because
the brief reserves the database schema to the auth branch.

### D4 -- TransactionRow gaps remain out of scope

`TransactionRow` is implemented for expense and income only, while Figma authors
four variants at `29:70`. The Home default and over-budget screens both use
`TransactionRow`; if either screen annotation or frame requires `Transfer` or
`Pending`, this change reports the mismatch and pauses rather than adding a
domain concept in UI code.

### D5 -- New UI resolves through design tokens

All new components and screens use the Figma spacing constants on
`MonetaSpacing` (`spaceBase`, `spaceLg`, and so on) rather than the deprecated
instance scale. Colours, typography, radii and elevation come from
`context.moneta` or token classes. No raw design values are introduced outside
token files.

### D6 -- ADR 0004 no longer directs implementation

ADR 0004's architecture reasoning was about a data-derived overview. The revised
scope is screen fidelity and component coverage for real Figma nodes. The ADR is
updated to say its Option F decision does not apply to this branch unless a later
change reintroduces live aggregation.

## Verification Plan

| Requirement | Verification |
| --- | --- |
| Full component variant coverage | Focused component tests plus
  `test/app/gallery_test.dart` |
| Gallery describer distinguishes home variants | `test/app/gallery_test.dart`
  fails if a variant cannot be described distinctly |
| Home screens use only owned/shared files | `dart run tool/check_architecture.dart` |
| Raw design values avoided | `dart run tool/check_design_tokens.dart` |
| OpenSpec matches real nodes | OpenSpec validation plus reviewer inspection of
  the node ids listed above |
| Final readiness | `bash tool/verify.sh --change home-overview` |

Before a task is marked done, mutate the behavior just added and confirm a test
fails. Record the verification output path in that task's commit message.
