## Purpose

Defines what a first-time user sees before reaching the app, how they move
through it, and why they only see it once.

## Requirements

### Requirement: First run shows the introduction, later runs do not

The application SHALL show the introduction on first launch and SHALL NOT show it
again once the user has finished or skipped it.

#### Scenario: First launch
- **WHEN** the application starts and no completion has been recorded
- **THEN** the introduction is shown

#### Scenario: After finishing
- **WHEN** the user completes the last slide and the application is restarted
- **THEN** the app opens directly and the introduction is not shown

#### Scenario: After skipping
- **WHEN** the user skips and the application is restarted
- **THEN** the introduction is not shown — skipping is a completion, not a defer

#### Scenario: The record cannot be read
- **WHEN** reading the completion flag fails
- **THEN** the introduction is shown
- **AND** showing it twice is preferable to hiding the app behind a broken read

### Requirement: The introduction is three slides with a stable frame

The introduction SHALL present exactly three slides. Skip, the position
indicator and the forward action SHALL keep their positions across all three.

#### Scenario: Slide count and order
- **WHEN** the introduction is shown
- **THEN** there are three slides, each with its own illustration, title and body

#### Scenario: Advancing
- **WHEN** the forward action is used on slide one or two
- **THEN** the next slide is shown and the indicator moves

#### Scenario: The last slide finishes
- **WHEN** the forward action is used on the last slide
- **THEN** the introduction is recorded complete and the app is shown

#### Scenario: Skip is not offered on the last slide
- **WHEN** the last slide is shown
- **THEN** no Skip action is offered, because the forward action already ends it

#### Scenario: Swiping matches the buttons
- **WHEN** the user swipes between slides
- **THEN** the indicator follows, and the forward action still ends the
  introduction on the last slide

### Requirement: Position is never signalled by colour alone

The position indicator SHALL distinguish the current slide by **width as well as
colour**.

#### Scenario: The active dot
- **WHEN** a slide is shown
- **THEN** its dot is wider than the others and uses the brand colour
- **AND** the width difference alone identifies the position in greyscale

### Requirement: The splash hands over on its own

The splash SHALL show the brand mark and hand over without user action.

#### Scenario: Handover
- **WHEN** the splash has shown for its duration
- **THEN** the introduction or the app is shown, whichever applies
- **AND** the user is not required to tap anything
