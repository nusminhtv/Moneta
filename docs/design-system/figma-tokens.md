# Figma token harvest

Every design value used in code, with the Figma node it was read from. Produced by
task 1.1 of the `design-system-foundation` change.

**Method.** Figma's `get_variable_defs` requires a live selection in the desktop
app, which is not available to an automated read. Token values were therefore read
from `get_design_context` output on component nodes, where Figma emits them as
`var(--token-name, <resolved-value>)`. Chart *base* colours are not emitted that
way (they are baked into exported glyph SVGs), so they were read from the `stroke`
attribute of each downloaded glyph and **visually confirmed** against a screenshot
of node `33:311` — the concern being that an export could resolve light-mode
values. It does not: the rendered glyphs match the extracted strokes.

Anything marked *not observed* was not present in any node read here. It is
deliberately **not implemented**, rather than guessed.

## Colour — surface, text, border

| Token | Value | Source node |
| --- | --- | --- |
| `bg-canvas` | `#06070A` | `39:8` AppBar/LargeTitle |
| `bg-surface` | `#0A0C11` | `39:243` BottomNav |
| `bg-surface-raised` | `#0F1218` | `40:256` BudgetCard |
| `bg-track` | `#232935` | `21:139` ProgressBar |
| `border-subtle` | `rgba(255,255,255,0.06)` | `40:256`, `39:243` |
| `text-primary` | `#F6F8FB` | `40:256`, `39:8` |
| `text-tertiary` | `#7C8595` | `40:256`, `39:243` |
| `text-on-brand` | `#FFFFFF` | `40:161` BalanceCard |
| `text-secondary` | `#9AA3B4` | verified `107:75` (row descriptions) — was wrongly recorded as not observed |

## Colour — brand

| Token | Value | Source node |
| --- | --- | --- |
| `brand-base` | `#7A5AF8` | `39:243` FAB |
| `brand-on-surface` | `#876BF9` | `39:243` active tab |
| `violet-600` | `#6541EA` | `40:113` gradient stop 0 |
| `violet-500` | `#7A5AF8` | `40:113` gradient stop 1 |
| `mint-600` | `#12A87A` | `40:113` gradient stop 2 |

### Brand gradient

Read from `40:113`. Figma cannot bind variables to gradient stops, and the file's
own note says so: *"the gradient is the ONLY hardcoded paint in this system … if
those tokens change, this fill must be updated by hand."*

```
linear-gradient(137.66142364584857deg,
  #6541EA  7.3529%,
  #7A5AF8 47.794%,
  #12A87A 80.882%)
```

Implemented from the three named palette constants above, not from three fresh
hex literals, so a palette change does propagate.

## Colour — semantic

| Token | Value | Source node |
| --- | --- | --- |
| `income-base` | `#22D19A` | `21:139`, `40:256` |
| `income-subtle` | `#072A22` | `42:324` Banner/Success |
| `expense-base` | `#F4515C` | `21:139`, `40:256` |
| `expense-subtle` | `#2E0F13` | `42:312` Banner/Danger |
| `warning-base` | `#FFA92B` | `21:139`, `40:256` |
| `warning-subtle` | `#2E1E05` | `42:306` Banner/Warning |
| `info-base` | `#2E9BFF` | `42:318` Banner/Info |
| `info-subtle` | `#06203A` | `42:318` Banner/Info |

## Colour — chart palette (8 slots)

Base colours from each glyph's `stroke`; subtle tints from `var(--chart-N-subtle)`.
All slots read from `33:311` CategoryIcon.

| Slot | Hue (per Figma note) | Base | Subtle | Category |
| --- | --- | --- | --- | --- |
| 1 | mint | `#009E62` | `#051F18` | Salary |
| 2 | violet | `#8879FE` | `#1B1931` | Shopping |
| 3 | coral | `#B3041C` | `#22070D` | Health |
| 4 | sky | `#027ED8` | `#051A2B` | Transport |
| 5 | lime | `#769200` | `#181D08` | Gift |
| 6 | pink | `#A30088` | `#1F061E` | Entertainment |
| 7 | amber | `#AA7705` | `#201909` | Food |
| 8 | teal | `#0B9B9C` | `#071F21` | Bills |

Figma note, recorded because it constrains any future edit: *"The 8-slot chart
palette was validated with the dataviz validator: worst adjacent CVD deltaE 16.0
in both modes, all eight inside the OKLCH lightness band."* Changing one slot in
isolation breaks that guarantee.

## Typography

Two families: **Inter** (text) and **Plus Jakarta Sans** (display/headings).

| Token | Family | Weight | Size | Line height | Letter spacing | Source node |
| --- | --- | --- | --- | --- | --- | --- |
| `display/amount-xl` | Plus Jakarta Sans | 700 | 40 | 44 | −1% → −0.4 | `40:161` |
| `display/amount-md` | Plus Jakarta Sans | 600 | 20 | 26 | 0 | `40:256` |
| `heading/h1` | Plus Jakarta Sans | 700 | 28 | 34 | −1% → −0.28 | `39:8` |
| `title/md` | Inter | 600 | 16 | 22 | 0 | `40:256` |
| `body/md` | Inter | 400 | 14 | 20 | 0 | `42:329` |
| `label/md` | Inter | 500 | 14 | 18 | 0 | `40:161`, `39:8` |
| `label/sm` | Inter | 500 | 12 | 16 | 0 | `39:243` |
| `caption/md` | Inter | 400 | 12 | 16 | 0 | `40:161`, `40:256` |

### Resolved ambiguity — letter spacing units

Figma's style summary reports `letterSpacing: -1` for both `display/amount-xl` and
`heading/h1`, while the emitted CSS for the same nodes says `tracking-[-0.4px]`
(40px text) and `tracking-[-0.28px]` (28px text). −0.4 / 40 = −0.28 / 28 = −1%, so
the summary figure is a **percentage** and the CSS is the resolved pixel value.
Implemented as Flutter's absolute `letterSpacing`: `-0.4` and `-0.28`.

Recorded rather than picked silently, because taking `-1` literally would have made
both styles visibly too tight.

## Radius

| Token | Value | Source node |
| --- | --- | --- |
| `radius-md` | 14 | `42:329` Banner |
| `radius-lg` | 18 | `40:256` BudgetCard |
| `radius-xl` | 24 | `40:161` BalanceCard |
| `radius-pill` | 999 | `21:139`, `33:311`, `39:243` |
| `radius-xs` | 6 | verified `107:79` (`rounded-[var(--radius-xs,6px)]`) |
| `radius-sm` | *reported as 10, not yet verified by us* | — |

## Elevation and effects

| Token | Value | Source node |
| --- | --- | --- |
| `elevation/3` | drop shadow `#0000008C`, offset (0, 12), blur 32 | `40:161` |
| `glow/brand` | drop shadow `#7A5AF859`, offset (0, 0), blur 24 | `39:243` FAB |
| `elevation/1`, `elevation/2` | *not observed* | — |

## Spacing — ⚠️ OUR SCALE IS INVENTED AND WRONGLY NAMED

**Corrected 2026-08-25, verified directly against node `107:75`.**

The earlier text here said "No named spacing variables appear in any node read …
if a spacing variable collection exists in the file, this table should be replaced
by it." It exists. It was never looked for — only the component nodes were read,
and their literal gaps were reverse-engineered into a scale.

The real collection, read from `107:75`, with Figma's own stated purpose for each:

| Figma token | Value | Purpose (Figma's words) |
| --- | --- | --- |
| `space/0` | 0 | reset only |
| `space/2xs` | 2 | icon to label inside a chip |
| `space/xs` | 4 | label to value in a stat tile |
| `space/sm` | **8** | between rows in a dense list |
| `space/md` | **12** | default vertical rhythm on a screen |
| `space/base` | **16** | card inner padding |
| `space/lg` | **20** | screen horizontal gutter |
| `space/xl` | **24** | between sections |
| `space/2xl` | 32 | above a section header |
| `space/3xl` | 40 | hero block padding |
| `space/4xl` | 48 | empty-state breathing room |
| `space/5xl` | 64 | full-screen state centring |

Against `lib/design_system/tokens/spacing.dart`:

| Name | Ours | Figma | |
| --- | --- | --- | --- |
| `2xs` / `xxs` | 2 | 2 | ✓ |
| `xs` | 4 | 4 | ✓ |
| `sm` | 6 | **8** | ✗ |
| `md` | 8 | **12** | ✗ |
| `lg` | 10 | **20** | ✗ |
| `xl` | 12 | **24** | ✗ |
| — | 14, 28 | *do not exist* | ✗ |
| — | *missing* | 32, 40, 48, 64 | ✗ |

Only two of eleven steps are right. Every name past `xs` is bound to a smaller
number than Figma's, so a widget asking for `spacing.lg` gets 10 where the design
means 20.

`test/design_system/tokens/tokens_test.dart` asserts this scale under the name
*"matches the observed Figma values"*. It matches nothing that was ever read from
Figma. That test does not merely fail to catch the defect — it states a falsehood
and locks it in.

Note the purposes are directly useful: `space/lg` = 20 is the **screen horizontal
gutter**, which is exactly the value `TransactionRow` should use and where our 16
comes from a different token entirely.

| Step | Value | Observed in |
| --- | --- | --- |
| `xxs` | 2 | `40:256` name column gap |
| `xs` | 4 | `39:243` tab gap |
| `sm` | 6 | `40:161` card gap, `39:243` indicator gap |
| `md` | 8 | `39:243` tab row padding |
| `lg` | 10 | `40:256` card gap, `40:161` stats top padding |
| `xl` | 12 | `40:256` head gap, `42:329` vertical padding |
| `xxl` | 14 | `42:329` horizontal padding |
| `x3l` | 16 | `40:256` card padding |
| `x4l` | 20 | `40:161` card padding, `40:256` stats gap |
| `x5l` | 24 | `39:8` bar right padding |
| `x6l` | 28 | `39:8` status bar left padding |

## Layout constants

| Constant | Value | Source node |
| --- | --- | --- |
| Screen frame | 393 × 852 | `39:2` StatusBar note |
| Top safe area | 59 | `39:2` |
| Bottom safe area | 34 | `39:243` |
| Content column width | 353 | `40:161`, `40:256`, `42:329` |
| Bottom nav bar height | 64 (+ 34 safe area) | `39:243` |
| FAB | 56 × 56, floats 18–19 above the bar | `39:243` |
| Icon canvas | 24, stroke weight 1.75 | `5:7` and every icon note |
| Category icon | Sm 32 / glyph 16 · Md 40 / glyph 20 · Lg 48 / glyph 24 | `33:311` |
| Progress bar | height 10, `radius-pill` | `21:139` |
| Touch target | 44 minimum for icon actions | `20:90` IconButton note |

## Motion

*Not observed.* No transition or easing values appear in any node read. Motion
tokens are therefore defined from Material's standard emphasised durations and
curves, and marked in code as **not Figma-derived** — the one place in the token
layer where a value did not come from the design file.
