## Context

Critical knowledge about project risks (FreeStreamer, legacy Controllers) was previously stored in an external file. To ensure long-term safety, we are moving this content into the `quality` spec. Other operational artifacts (onboarding, state, etc.) are excluded from this merge and will be handled separately.

## Goals / Non-Goals

**Goals:**
- Restore the active risk register.
- Integrate risks into the existing `quality` specification.

**Non-Goals:**
- Integrate onboarding, current state, or next priority documentation.
- Modify any application source code.

## Decisions

- **Decision: Risks in Quality Spec** → We will merge specific risks into `specs/quality/spec.md`. Risk mitigation is a fundamental component of software quality in a complex refactor.

## Risks / Trade-offs

- **[Risk] Spec Bloat** → Adding many risks could clutter the spec. Mitigation: Focus only on "Critical" and "High" project-wide risks.
