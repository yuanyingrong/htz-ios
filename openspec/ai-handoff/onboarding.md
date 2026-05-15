# AI Onboarding Guide

## 🚀 Welcome, AI Engineer
You are here to modernize the HTZ iOS application. This is a high-stakes refactor of a media-heavy App.

## 1. Essential Reading Order
1. `openspec/project.md`: Understand the vision and principles.
2. `openspec/ai-handoff/current-state.md`: Know what is real and what is planned.
3. `openspec/ai-handoff/next-priority.md`: Find out exactly what to do next.
4. `openspec/ai-handoff/active-risks.md`: Understand where you might break things.
5. `openspec/specs/`: Read the relevant technical specification for your task.

## 2. Hard Constraints (What you CANNOT do)
- **Do NOT** refactor the audio engine core (`FreeStreamer`). Only wrap it.
- **Do NOT** change existing business logic in legacy files (`htz/htz/Class/`).
- **Do NOT** add new external dependencies to `Podfile` without user approval.
- **Do NOT** bypass the Design System tokens.
- **Do NOT** perform "Big Bang" refactors. Keep each `change` small and testable.

## 3. Standard Execution Workflow
Every time you perform a `change` from `openspec/changes/`:

1. **Review**: Read the `proposal.md`, `design.md`, and `tasks.md` in the change folder.
2. **Strategy**: Propose a step-by-step plan based on the tasks.
3. **Implementation**: Modify files in small, logical chunks.
4. **Validation**:
   - Ensure the project builds.
   - Run relevant unit tests (or add new ones for the change).
   - If UI, verify in Simulator if possible.
5. **Update Handoff**: Update `openspec/ai-handoff/current-state.md` and `next-priority.md` after completion.

## 4. Architectural Guardrails
- **TCA v1.10+**: Always use `@Reducer` and `@ObservableState`.
- **SPM**: New logic belongs in `Packages/`.
- **SwiftUI**: Use iOS 16+ APIs.
- **Async/Await**: Prefer over completion handlers.
