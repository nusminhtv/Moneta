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
**All six have now been read** (2026-09-09): `52:362`, `52:537`, `52:630`,
`57:612`, `57:830`, `57:935`.

This decision previously read "this session has no callable Figma tool", and on
that basis four screens were built against the frames alone. The tool was
callable. Screen copy, fixture data, spacing and accessibility rules are
therefore no longer placeholder decisions — they are transcriptions, and where
one still is not, it says so at the point of use.

The frames and the annotations do not always agree. Where they differ the
**annotation states the rule and the frame shows one instance of it** — a frame
drawing four transaction rows does not make four the cap. Reading them in the
other order is what produced `homeRecentLimit = 4`.

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

### D3 -- Home adds no persistence, but its figures are derived

The six Figma screens are states, not a database contract. This change adds no
persistence, migrations or preference storage. If notification read-state or home
data persistence becomes necessary, work stops for a storage design because the
brief reserves the database schema to the auth branch. Notifications are
consequently **not durable** in this change, which is why `02.05` ships without
read/unread state.

What this does *not* mean is that Home's numbers are fixtures. Annotations
`52:362` and `57:612` define safe-to-spend and the over-budget trigger in terms
of budget data, so both are read and computed — see D7. Reading is not
persisting: the `budgets` table already exists at schema v3 and this change adds
nothing to it.

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

**Qualified by D7.** Safe-to-spend and the over-budget trigger are live
aggregation, in the narrow sense the annotations require. ADR 0004's *mechanism*
survives and is reused — cross-feature assembly happens in `lib/app`, not through
a `HomeDataSource` interface with one implementation — so this is the ADR's
pattern being applied, not its decision being reversed. What does not return is a
general data-backed overview invented ahead of a design.

### D7 -- Two figures the annotations forced, and how far each goes

Both come from annotations read after the screens were built, and both contradict
merged code. Recorded here because the reasoning matters more than the values.

**Safe-to-spend is partial, and says so.** Annotation `52:362` defines it as
*"balance minus committed budgets minus scheduled bills to period end"*. Budgets
exist; scheduled bills do not exist anywhere in this codebase — no table, no
entity, no concept. So the implemented figure is
`balance − Σ each budget's unspent remainder`, and the missing term is recorded
as a deviation in `docs/design-system/figma-map.md` naming the annotation.

The alternative was to invent a scheduled-bills concept from one clause of one
annotation. That is precisely how the invented spacing scale happened: a
plausible number, consistently applied, wrong. A figure that is short by a term it
names is honest; a figure completed by guesswork is not, and it would be
indistinguishable from a correct one on screen.

The subtraction takes each budget's **unspent remainder**, not its whole limit.
This is the one point where the annotation's wording needed interpreting rather
than transcribing, so the reasoning is recorded: its two terms are parallel and
both name *future* outflows — budget money not yet spent, and bills not yet due
by period end. Money already spent against a budget has already left the balance,
so subtracting the full limit would deduct it twice: a fully spent 5m food budget
would cost the user 10m of headroom and safe-to-spend would drift further from the
truth the more diligently the user recorded their spending.

The remainder is clamped at zero, matching `BudgetProgress.remaining`. Unclamped,
an overspent budget would contribute a negative commitment and *raise*
safe-to-spend — the app would reward blowing a budget with more apparent headroom.

The first draft of this spec said "committed limits, not amounts already spent",
which is the opposite rule. It was written before the arithmetic was worked
through and is corrected here rather than left as a second, contradictory
statement of the same requirement.

**Quick actions reproduce the file, including what it points at.** `52:2` authors
Add, Transfer, Budgets and Goals. Transfer and Goals have no feature behind them.
They are rendered in a disabled state rather than dropped, for two reasons: the
frame's four-up layout at 82.25px per column is part of the design, and this
codebase already settled the question for `onLinkAccount` — *"a row that goes
nowhere is worse than a row that plainly does not respond, so it stays null until
it exists."* A disabled control tells the truth about the app; a missing one
quietly redesigns the screen, and a wired one lies.

This replaces the previously shipped set (Add, History, Insights, Profile), which
matched no Figma node.

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
