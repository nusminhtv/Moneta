## Purpose

Defines the two notifications states authored on `📱 02 Home & Dashboard`:
notification list and notification empty.

## ADDED Requirements

### Requirement: Notifications renders the list screen from node 57:622

The notifications route SHALL provide a list state matching Figma node `57:622`
and its sibling annotation frame.

#### Scenario: Notification list composition
- **WHEN** notifications are available
- **THEN** the screen uses `AppBar`, `BottomNav`, `ListRow` and `SectionHeader`
- **AND** the Home bottom navigation context remains available

### Requirement: Notifications renders the empty screen from node 57:840

The notifications route SHALL provide an empty state matching Figma node `57:840`
and its sibling annotation frame.

#### Scenario: Notification empty composition
- **WHEN** there are no notifications to show
- **THEN** the screen uses `AppBar`, `BottomNav` and `EmptyState`
- **AND** it is visually distinct from a loading state

### Requirement: Notifications does not persist read state in this change

Notification read/unread state SHALL NOT introduce persistence as part of
`home-overview`.

#### Scenario: Persistence is needed
- **WHEN** the notification design requires durable read state
- **THEN** implementation stops for an approved storage design
- **AND** no database migration, JSON store or shared-preferences workaround is
  added by this change
