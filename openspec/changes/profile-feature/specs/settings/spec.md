## ADDED Requirements

### Requirement: The settings list is grouped, and each row's trailing states its promise

`08.03` SHALL implement node `100:428` as four labelled groups of rows, and each
row's trailing accessory SHALL match what activating it does:

- **chevron** — pushes another screen;
- **toggle** — changes something immediately, in place;
- **value** — shows current state without being tapped.

Annotation `100:728`: *"The Trailing variant is the whole information design of
a settings list. Chevron promises another screen, Toggle promises an immediate
change, Value shows state. Getting that mapping wrong is the most common
settings-screen mistake."*

#### Scenario: Four groups, each labelled
- **WHEN** the settings list is shown
- **THEN** it renders four section headers, each followed by its own rows

#### Scenario: A chevron row leads somewhere
- **WHEN** a row carries a chevron
- **THEN** activating it navigates
- **AND** it does not change any setting in place

#### Scenario: A toggle row changes state in place
- **WHEN** a row carries a toggle
- **THEN** activating it changes that setting immediately and does not navigate

#### Scenario: A value row shows state without being tapped
- **WHEN** a row carries a value
- **THEN** the current state is readable on the row itself

#### Scenario: No row promises the wrong thing
- **WHEN** every row is inspected
- **THEN** each row that navigates carries a chevron, each row that toggles
  carries a toggle, and no row carries both a toggle and a navigation

#### Scenario: A row whose destination is unbuilt says so
- **WHEN** a row leads to a screen this change does not build
- **THEN** it is either absent or visibly unavailable
- **AND** it does not navigate to a blank screen

### Requirement: Demo mode is switched from the settings list

The settings list SHALL carry the demo-mode switch as a **toggle** row, because
turning it on changes the active ledger immediately.

#### Scenario: The switch reflects the stored setting
- **WHEN** the settings list is shown
- **THEN** the demo row's toggle is on exactly when demo mode is active

#### Scenario: Turning it on switches the ledger
- **WHEN** the demo toggle is turned on
- **THEN** demo mode becomes active and the seeded ledger is what the app reads

#### Scenario: Turning it off restores the real ledger
- **WHEN** the demo toggle is turned off
- **THEN** the real ledger is active and unchanged

#### Scenario: The switch says what it does
- **WHEN** the demo row is shown
- **THEN** its supporting text states that the data is generated and that real
  data is untouched

### Requirement: Resetting the demo ledger asks first

Reset SHALL be offered only while demo mode is active, and SHALL request
confirmation before deleting anything.

#### Scenario: Reset is absent outside demo mode
- **WHEN** demo mode is off
- **THEN** no reset row is shown

#### Scenario: Reset asks before acting
- **WHEN** reset is activated
- **THEN** confirmation is requested
- **AND** declining leaves the demo ledger exactly as it was

#### Scenario: Confirming regenerates the dataset
- **WHEN** reset is confirmed
- **THEN** the demo ledger holds the seeded dataset again

### Requirement: A settings failure is reported, not swallowed

When a setting cannot be read or written, the list SHALL report it rather than
showing a default.

#### Scenario: The store cannot be read
- **WHEN** reading the demo setting fails
- **THEN** the failure is surfaced
- **AND** the toggle does not silently read as off

#### Scenario: A write fails
- **WHEN** writing the demo setting fails
- **THEN** the failure is surfaced and the row returns to its previous state
