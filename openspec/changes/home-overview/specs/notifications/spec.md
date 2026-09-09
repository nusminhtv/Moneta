## Purpose

Defines the two notifications states authored on `📱 02 Home & Dashboard`:
notification list and notification empty.

Both requirements were checked against their sibling annotation frames, read on
2026-09-09: `57:830` and `57:935`.

## ADDED Requirements

### Requirement: Notifications renders the list screen from node 57:622

The notifications route SHALL provide a list state matching Figma node `57:622`
and its sibling annotation frame `57:830`.

#### Scenario: Notification list composition
- **WHEN** notifications are available
- **THEN** the screen uses `AppBar`, `BottomNav`, `ListRow` and `SectionHeader`
- **AND** the Home bottom navigation context remains available

#### Scenario: The app bar carries a back control
- **WHEN** the notifications list is rendered
- **THEN** the app bar is the `TitleBack` variant, per annotation `57:830`
- **AND** the Home tab remains the active bottom navigation destination, because
  notifications is a Home sub-screen rather than a tab of its own

#### Scenario: Section headers carry no action
- **WHEN** the notifications list is rendered
- **THEN** each `SectionHeader` is rendered without an action affordance, per
  annotation `57:830`

### Requirement: A notification's accessory follows whether it is actionable

Each notification row SHALL carry a chevron when acting on it leads somewhere,
and no trailing accessory when it is informational.

Annotation `57:830` states: *"actionable notifications get a chevron;
informational ones do not."* Frame `57:622` authors three chevron rows and two
without. The accessory is therefore derived from the notification, not chosen
per row by the screen.

#### Scenario: Actionable notification
- **WHEN** a notification can be acted on
- **THEN** its row renders the chevron accessory
- **AND** the row responds to being tapped

#### Scenario: Informational notification
- **WHEN** a notification is informational
- **THEN** its row renders no trailing accessory
- **AND** the row offers no tap affordance, so nothing suggests an action that
  does not exist

#### Scenario: The accessory cannot contradict the notification
- **WHEN** a notification row is built
- **THEN** the accessory is derived from whether the notification is actionable
- **AND** a row carrying a chevron with nowhere to go is not representable

### Requirement: Notifications are grouped Today and Earlier, newest first

The notifications list SHALL group entries under `Today` and `Earlier` and order
them newest first within each group.

Grouping is by **local** day, from an injected clock. A notification recorded at
23:30 local is stored as 16:30 UTC the same day, so grouping in UTC would file it
under the wrong heading. The gate pins `TZ=Asia/Ho_Chi_Minh`, so a test of this
can actually fail.

#### Scenario: Both groups are populated
- **WHEN** notifications exist from today and from earlier days
- **THEN** a `Today` section precedes an `Earlier` section
- **AND** entries within each section are ordered newest first

#### Scenario: Only one group is populated
- **WHEN** every notification falls in one group
- **THEN** only that group's `SectionHeader` is rendered
- **AND** no empty section heading is left behind

#### Scenario: Local day boundary
- **WHEN** a notification occurred late on the current local day
- **THEN** it appears under `Today` even though its stored UTC timestamp falls on
  a different date

### Requirement: Notifications renders the empty screen from node 57:840

The notifications route SHALL provide an empty state matching Figma node `57:840`
and its sibling annotation frame `57:935`.

#### Scenario: Notification empty composition
- **WHEN** there are no notifications to show
- **THEN** the screen uses `AppBar`, `BottomNav` and `EmptyState`
- **AND** it is visually distinct from a loading state

#### Scenario: This empty state deliberately offers no action
- **WHEN** the notifications empty state is rendered
- **THEN** it renders the `HasAction=false` form of `EmptyState`
- **AND** no action affordance is added to satisfy the general rule that an empty
  state should offer a next step

Annotation `57:935` sanctions this explicitly: *"the rare legitimate case for
HasAction=False — there is genuinely nothing for the user to do here"*, and
contrasts it with `02.02`, where an empty state must offer a next step.

### Requirement: Notifications does not persist read state in this change

Notification read/unread state SHALL NOT introduce persistence as part of
`home-overview`.

#### Scenario: Persistence is needed
- **WHEN** the notification design requires durable read state
- **THEN** implementation stops for an approved storage design
- **AND** no database migration, JSON store or shared-preferences workaround is
  added by this change
