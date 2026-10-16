## ADDED Requirements

### Requirement: Search Albums And Chapters
The user SHALL search albums and chapters from one query.

#### Scenario: Matching results
- **WHEN** the user submits a non-empty query
- **THEN** the screen SHALL show matching albums and chapters from the search API.

#### Scenario: Open a result
- **WHEN** the user taps an album result
- **THEN** album detail SHALL open.
- **WHEN** the user taps a chapter result
- **THEN** playback SHALL use the same signed-URL flow as album detail.

### Requirement: Recent Searches
Recent queries SHALL be stored on device and shown before a new query is submitted.

#### Scenario: Repeat a recent query
- **WHEN** the user taps a stored query
- **THEN** the app SHALL run that search again.
