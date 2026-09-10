## Context

- Every component `100:428` instances exists: `MonetaAppBar`, `SectionHeader`
  and `ListRow` — whose `ListRowAccessory` already covers chevron, value,
  toggle, badge and none, which is precisely the mapping `100:728` calls the
  screen's information design.
- `demo-data` has a working `DemoModeController` with no control on screen.
- `Avatar` (`21:121`) is not built, which is what defers `08.01`.
- `tool/check_architecture.dart`: a feature may not import `lib/app`, so the
  screen is presentational and `lib/app` wires it.

## Goals / Non-Goals

Goals: the demo switch reachable in two taps; the trailing mapping correct and
tested as a mapping rather than row by row.

Non-goals: `08.01` and the nine other page-08 screens (see `proposal.md`); any
new component; real auth or purchases.

## Decisions

### D1 — The provisional settings screen is not built at all

`demo-data`'s group 7 planned one, while Figma was unreadable. It is readable
now, so the authored screen is built instead and the provisional one is dropped
rather than built and then replaced.

Recorded because `demo-data`'s tasks still describe it: those tasks are ticked
as superseded, with this change named.

### D2 — The demo switch is a toggle row, and reset is a separate row

Toggle, because `100:728` says a toggle promises an immediate change and turning
demo mode on *is* immediate — the ledger switches under the app.

Reset is its own row rather than a second control on the same one: it is
destructive, it needs a confirmation, and a row cannot promise both "flip me"
and "I will ask you something first".

### D3 — Rows whose destination is unbuilt are shown disabled, not hidden

`100:722` hides Face ID's row *on a device without biometrics* — absence of a
capability. A screen this change has not built yet is a different fact: the
capability exists, the screen does not.

So those rows are present and visibly unavailable, which tells the truth in a
demo. Hiding them would make the list look complete and shorter than the design;
letting them navigate would land on a blank screen.

### D4 — The mapping is tested as a mapping

Rather than asserting each row's accessory one by one, the test walks **every**
row and asserts the invariant: a row with an `onTap` destination carries a
chevron, a row with an `onToggle` carries a toggle, and none carries both. A
per-row assertion would pass a list where a new row was added with the wrong
trailing — which is the mistake `100:728` says is the most common one.

## Risks / Trade-offs

- **The Profile tab shows Settings, not `08.01`** → stated in the proposal and
  in `figma-map.md`. The alternative was building `Avatar` inside a settings
  change, which is a design-system obligation with its own variant set.
- **Reset is destructive and one tap from a demo** → it is only present in demo
  mode, it confirms first, and `demo-data`'s source check already proves no
  path can wipe the real ledger.

## Migration Plan

None. Additive screen and route.
