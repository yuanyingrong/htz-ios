## ADDED Requirements

### Requirement: Color Tokens
The DesignSystem module SHALL provide semantic color tokens that support both Light and Dark modes.

#### Scenario: Accessing a semantic color
- **WHEN** a view requests `Color.htzAccent`
- **THEN** the system returns the correct accent color based on the current user interface style.

### Requirement: Typography Tokens
The DesignSystem module SHALL provide standard typography styles using SF Pro and SF Pro Rounded fonts.

#### Scenario: Applying a title style
- **WHEN** a view applies the `htzTitle` font style
- **THEN** the text is rendered with the correct weight, size, and design (Rounded) as defined in the specification.

### Requirement: Spacing and Radius Tokens
The DesignSystem module SHALL provide a standardized set of spacing and corner radius values.

#### Scenario: Applying consistent padding
- **WHEN** a view uses `HTZSpacing.md`
- **THEN** it applies exactly 16pt of spacing as defined in the layout grid.
